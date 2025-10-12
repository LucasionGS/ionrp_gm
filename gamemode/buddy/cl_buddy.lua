--[[
  Buddy System - Client
  UI for managing buddy list (F3 key)
]]--

--- Store local player's buddy list
LocalPlayer().IonRP_Buddies = LocalPlayer().IonRP_Buddies or {}

--- UI Colors
local Colors = {
  Background = Color(25, 25, 35, 250),
  Header = Color(45, 35, 60, 255),
  Panel = Color(35, 35, 45, 230),
  Hover = Color(55, 50, 70, 230),
  Accent = Color(120, 100, 255, 255),
  AccentGreen = Color(100, 255, 150, 255),
  AccentRed = Color(255, 100, 100, 255),
  Text = Color(255, 255, 255, 255),
  TextMuted = Color(160, 160, 175, 255),
}

--- Receive buddy list sync from server
net.Receive("IonRP_Buddy_Sync", function()
  local buddyList = net.ReadTable()
  local ply = LocalPlayer()
  
  ply.IonRP_Buddies = {}
  for _, steamID in ipairs(buddyList) do
    ply.IonRP_Buddies[steamID] = true
  end
  
  print("[IonRP Buddy] Synced " .. #buddyList .. " buddies from server")
  
  -- Refresh UI if it's open
  if IsValid(IonRP.Buddy.UI_Frame) then
    IonRP.Buddy:OpenMenu()
  end
end)

--- Receive response from buddy add/remove operations
net.Receive("IonRP_Buddy_Response", function()
  local success = net.ReadBool()
  local message = net.ReadString()
  
  if success then
    notification.AddLegacy(message, NOTIFY_GENERIC, 3)
    surface.PlaySound("buttons/lightswitch2.wav")
  else
    notification.AddLegacy(message, NOTIFY_ERROR, 3)
    surface.PlaySound("buttons/button10.wav")
  end
end)

--- Get buddy name by steam ID (checks online players)
--- @param steamID string Steam ID to look up
--- @return string Player name or "Unknown"
local function GetBuddyName(steamID)
  for _, ply in ipairs(player.GetAll()) do
    if ply:SteamID64() == steamID then
      return ply:GetRPName()
    end
  end
  return "Unknown (Offline)"
end

--- Open the buddy management menu
function IonRP.Buddy:OpenMenu()
  if IsValid(self.UI_Frame) then
    self.UI_Frame:Remove()
  end
  
  local ply = LocalPlayer()
  local scrW, scrH = ScrW(), ScrH()
  
  -- Main frame
  local frame = vgui.Create("DFrame")
  frame:SetSize(800, 600)
  frame:Center()
  frame:SetTitle("")
  frame:SetDraggable(true)
  frame:ShowCloseButton(false)
  frame:MakePopup()
  
  frame.Paint = function(self, w, h)
    -- Background
    draw.RoundedBox(8, 0, 0, w, h, Colors.Background)
    
    -- Header
    draw.RoundedBox(8, 0, 0, w, 50, Colors.Header)
    draw.RoundedBox(0, 0, 42, w, 8, Colors.Header)
    
    -- Title
    draw.SimpleText("Buddy List", "DermaLarge", 20, 25, Colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    
    -- Subtitle
    draw.SimpleText("Manage your friends who can access your properties and vehicles", "DermaDefault", 20, 60, Colors.TextMuted, TEXT_ALIGN_LEFT)
  end
  
  self.UI_Frame = frame
  
  -- Close button
  local closeBtn = vgui.Create("DButton", frame)
  closeBtn:SetPos(frame:GetWide() - 40, 10)
  closeBtn:SetSize(30, 30)
  closeBtn:SetText("")
  
  closeBtn.Paint = function(self, w, h)
    local col = self:IsHovered() and Colors.AccentRed or Colors.TextMuted
    draw.SimpleText("✕", "DermaLarge", w/2, h/2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end
  
  closeBtn.DoClick = function()
    frame:Close()
  end
  
  -- Left panel: Current buddies
  local leftPanel = vgui.Create("DPanel", frame)
  leftPanel:SetPos(20, 80)
  leftPanel:SetSize(360, 490)
  
  leftPanel.Paint = function(self, w, h)
    draw.RoundedBox(6, 0, 0, w, h, Colors.Panel)
    draw.SimpleText("Your Buddies", "DermaDefaultBold", 10, 10, Colors.Text, TEXT_ALIGN_LEFT)
  end
  
  local buddyScroll = vgui.Create("DScrollPanel", leftPanel)
  buddyScroll:SetPos(10, 35)
  buddyScroll:SetSize(340, 445)
  
  local yPos = 0
  
  -- List current buddies
  local hasBuddies = false
  for steamID, _ in pairs(ply.IonRP_Buddies) do
    hasBuddies = true
    local buddyName = GetBuddyName(steamID)
    local isOnline = buddyName ~= "Unknown (Offline)"
    
    local buddyCard = vgui.Create("DPanel", buddyScroll)
    buddyCard:SetPos(0, yPos)
    buddyCard:SetSize(320, 50)
    
    buddyCard.Paint = function(self, w, h)
      local col = self:IsHovered() and Colors.Hover or Color(45, 45, 55, 200)
      draw.RoundedBox(4, 0, 0, w, h, col)
      
      -- Status indicator
      local statusCol = isOnline and Colors.AccentGreen or Colors.TextMuted
      draw.RoundedBox(3, 10, h/2 - 3, 6, 6, statusCol)
      
      -- Name
      draw.SimpleText(buddyName, "DermaDefaultBold", 25, h/2, Colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    -- Remove button
    local removeBtn = vgui.Create("DButton", buddyCard)
    removeBtn:SetPos(270, 10)
    removeBtn:SetSize(40, 30)
    removeBtn:SetText("")
    
    removeBtn.Paint = function(self, w, h)
      local col = self:IsHovered() and Colors.AccentRed or Colors.TextMuted
      draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, 100))
      draw.SimpleText("✕", "DermaDefault", w/2, h/2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    removeBtn.DoClick = function()
      -- Send remove request to server
      net.Start("IonRP_Buddy_Remove")
        net.WriteString(steamID)
      net.SendToServer()
    end
    
    yPos = yPos + 55
  end
  
  if not hasBuddies then
    local emptyLabel = vgui.Create("DLabel", buddyScroll)
    emptyLabel:SetPos(0, 100)
    emptyLabel:SetSize(320, 60)
    emptyLabel:SetFont("DermaDefault")
    emptyLabel:SetTextColor(Colors.TextMuted)
    emptyLabel:SetText("You don't have any buddies yet.\n\nAdd online players from the list on the right.")
    emptyLabel:SetContentAlignment(5)
    emptyLabel:SetWrap(true)
    emptyLabel:SetAutoStretchVertical(true)
  end
  
  -- Right panel: Online players
  local rightPanel = vgui.Create("DPanel", frame)
  rightPanel:SetPos(400, 80)
  rightPanel:SetSize(380, 490)
  
  rightPanel.Paint = function(self, w, h)
    draw.RoundedBox(6, 0, 0, w, h, Colors.Panel)
    draw.SimpleText("Online Players", "DermaDefaultBold", 10, 10, Colors.Text, TEXT_ALIGN_LEFT)
  end
  
  local playerScroll = vgui.Create("DScrollPanel", rightPanel)
  playerScroll:SetPos(10, 35)
  playerScroll:SetSize(360, 445)
  
  yPos = 0
  
  -- List all online players except self
  for _, targetPly in ipairs(player.GetAll()) do
    if targetPly == ply then continue end
    
    local targetSteamID = targetPly:SteamID64()
    local isAlreadyBuddy = ply.IonRP_Buddies[targetSteamID] ~= nil
    
    local playerCard = vgui.Create("DPanel", playerScroll)
    playerCard:SetPos(0, yPos)
    playerCard:SetSize(340, 50)
    
    playerCard.Paint = function(self, w, h)
      local col = self:IsHovered() and Colors.Hover or Color(45, 45, 55, 200)
      draw.RoundedBox(4, 0, 0, w, h, col)
      
      -- Name
      draw.SimpleText(targetPly:GetRPName(), "DermaDefaultBold", 10, h/2, Colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
      
      -- Status
      if isAlreadyBuddy then
        draw.SimpleText("✓ Already buddy", "DermaDefault", w - 100, h/2, Colors.AccentGreen, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
      end
    end
    
    if not isAlreadyBuddy then
      -- Add button
      local addBtn = vgui.Create("DButton", playerCard)
      addBtn:SetPos(250, 10)
      addBtn:SetSize(80, 30)
      addBtn:SetText("")
      
      addBtn.Paint = function(self, w, h)
        local col = self:IsHovered() and Colors.AccentGreen or Colors.Accent
        draw.RoundedBox(4, 0, 0, w, h, col)
        draw.SimpleText("Add", "DermaDefaultBold", w/2, h/2, Colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
      end
      
      addBtn.DoClick = function()
        -- Send add request to server
        net.Start("IonRP_Buddy_Add")
          net.WriteString(targetSteamID)
        net.SendToServer()
      end
    end
    
    yPos = yPos + 55
  end
end

--- Bind F3 key to open buddy menu
hook.Add("PlayerButtonDown", "IonRP_Buddy_OpenMenu", function(ply, button)
  if button == KEY_F3 then
    IonRP.Buddy:OpenMenu()
  end
end)

print("[IonRP Buddy] Client-side buddy system loaded")
