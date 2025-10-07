--[[
    IonSys - Admin Panel System
    Client-side admin panel UI
]] --

include("sh_ionsys.lua")

IonRP.IonSys = IonRP.IonSys or {}
IonRP.IonSys.UI = IonRP.IonSys.UI or {}

-- Config
IonRP.IonSys.UI.Config = {
  Width = 1200,
  Height = 700,
  Padding = 12,
  HeaderHeight = 60,

  Colors = {
    Background = Color(25, 25, 35, 250),
    Header = Color(45, 35, 60, 255),
    Panel = Color(35, 35, 45, 230),
    PanelHover = Color(45, 45, 55, 240),
    Button = Color(52, 152, 219, 230),
    ButtonHover = Color(62, 162, 229, 255),
    ButtonDanger = Color(231, 76, 60, 230),
    ButtonDangerHover = Color(241, 86, 70, 255),
    ButtonSuccess = Color(46, 204, 113, 230),
    ButtonSuccessHover = Color(56, 214, 123, 255),
    Text = Color(255, 255, 255, 255),
    TextDim = Color(200, 200, 210, 255),
    TextMuted = Color(160, 160, 175, 255),
    Accent = Color(120, 100, 255, 255),
    AccentCyan = Color(100, 200, 255, 255),
    Border = Color(60, 50, 80, 200),
    ListAlt = Color(40, 40, 50, 200),
  }
}

--- Current panel data
--- @type IonSys_PanelData|nil
IonRP.IonSys.UI.CurrentData = nil

-- Network receivers

--- Receive panel open request
net.Receive("IonSys_OpenPanel", function()
  IonRP.IonSys.UI:Open()
end)

--- Receive panel data from server
net.Receive("IonSys_SendData", function()
  local data = net.ReadTable()
  IonRP.IonSys.UI.CurrentData = data

  -- Refresh UI if open
  if IsValid(IonRP.IonSys.UI.Frame) then
    IonRP.IonSys.UI:RefreshContent()
  end
end)

--- Open the admin panel
function IonRP.IonSys.UI:Open()
  if IsValid(self.Frame) then
    self.Frame:Remove()
  end

  if not self.CurrentData then
    chat.AddText(Color(255, 100, 100), "[IonSys] ", Color(255, 255, 255), "Loading admin panel data...")
    return
  end

  local cfg = self.Config

  -- Main frame
  local frame = vgui.Create("DFrame")
  frame:SetSize(cfg.Width, cfg.Height)
  frame:Center()
  frame:SetTitle("")
  frame:SetDraggable(true)
  frame:ShowCloseButton(false)
  frame:MakePopup()
  frame:SetAlpha(0)
  frame:AlphaTo(255, 0.2, 0)
  self.Frame = frame

  -- Custom paint
  frame.Paint = function(self, w, h)
    -- Shadow
    draw.RoundedBox(8, 3, 3, w, h, Color(0, 0, 0, 150))

    -- Main background
    draw.RoundedBox(8, 0, 0, w, h, cfg.Colors.Background)

    -- Accent border
    surface.SetDrawColor(cfg.Colors.AccentCyan)
    surface.DrawOutlinedRect(0, 0, w, h, 2)

    -- Top accent line
    draw.RoundedBox(0, 0, 0, w, 3, cfg.Colors.AccentCyan)
  end

  -- Header
  local header = vgui.Create("DPanel", frame)
  header:Dock(TOP)
  header:SetTall(cfg.HeaderHeight)
  header:DockMargin(0, 0, 0, 0)

  header.Paint = function(self, w, h)
    draw.RoundedBoxEx(8, 0, 0, w, h, cfg.Colors.Header, true, true, false, false)

    -- Title
    draw.SimpleText("IONSYS ADMIN PANEL", "DermaLarge", cfg.Padding, 10, cfg.Colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    -- Subtitle
    draw.SimpleText("Server Administration", "DermaDefault", cfg.Padding, 40, cfg.Colors.TextDim, TEXT_ALIGN_LEFT,
      TEXT_ALIGN_TOP)
  end

  -- Close button
  local closeBtn = vgui.Create("DButton", header)
  closeBtn:SetPos(cfg.Width - 40, 10)
  closeBtn:SetSize(30, 30)
  closeBtn:SetText("")

  closeBtn.Paint = function(self, w, h)
    local col = cfg.Colors.Border
    if self:IsHovered() then
      col = Color(255, 100, 100)
    end

    draw.RoundedBox(4, 0, 0, w, h, col)

    -- X
    surface.SetDrawColor(255, 255, 255)
    surface.DrawLine(8, 8, w - 8, h - 8)
    surface.DrawLine(w - 8, 8, 8, h - 8)
  end

  closeBtn.DoClick = function()
    self:Close()
  end

  -- Refresh button
  local refreshBtn = vgui.Create("DButton", header)
  refreshBtn:SetPos(cfg.Width - 80, 10)
  refreshBtn:SetSize(30, 30)
  refreshBtn:SetText("")

  refreshBtn.Paint = function(self, w, h)
    local col = cfg.Colors.Border
    if self:IsHovered() then
      col = cfg.Colors.AccentCyan
    end

    draw.RoundedBox(4, 0, 0, w, h, col)

    -- Refresh icon (circular arrow)
    draw.SimpleText("⟳", "DermaLarge", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end

  refreshBtn.DoClick = function()
    -- Request fresh data from server
    net.Start("IonSys_RequestData")
    net.SendToServer()
  end

  -- Create tabs
  local contentPanel = vgui.Create("DPanel", frame)
  contentPanel:Dock(FILL)
  contentPanel:DockMargin(cfg.Padding, cfg.Padding, cfg.Padding, cfg.Padding)
  contentPanel.Paint = function() end

  --- @class DPropertySheet
  local tabs = vgui.Create("DPropertySheet", contentPanel)
  tabs:Dock(FILL)

  -- Style the tabs
  tabs.Paint = function(self, w, h)
    draw.RoundedBox(4, 0, 20, w, h - 20, cfg.Colors.Panel)
  end

  -- Player Management Tab
  local playerPanel = self:CreatePlayerPanel()
  tabs:AddSheet("Player Management", playerPanel, "icon16/group.png")

  -- Item Management Tab
  local itemPanel = self:CreateItemPanel()
  tabs:AddSheet("Item Spawner", itemPanel, "icon16/package.png")

  self.Tabs = tabs
end

--- Create the player management panel
--- @return Panel
function IonRP.IonSys.UI:CreatePlayerPanel()
  local cfg = self.Config
  local panel = vgui.Create("DPanel")
  panel.Paint = function() end

  if not self.CurrentData or not self.CurrentData.players then
    return panel
  end

  -- Player list
  local scroll = vgui.Create("DScrollPanel", panel)
  scroll:Dock(FILL)
  scroll:DockMargin(cfg.Padding, cfg.Padding, cfg.Padding, cfg.Padding)

  -- Custom scrollbar
  local sbar = scroll:GetVBar()
  sbar:SetWide(8)
  sbar:SetHideButtons(true)

  function sbar:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 30, 220))
  end

  function sbar.btnGrip:Paint(w, h)
    local col = cfg.Colors.AccentCyan
    draw.RoundedBox(4, 0, 0, w, h, col)
  end

  -- Create player entries
  for i, playerData in ipairs(self.CurrentData.players) do
    local playerRow = vgui.Create("DPanel", scroll)
    playerRow:Dock(TOP)
    playerRow:SetTall(80)
    playerRow:DockMargin(0, 0, 0, 4)

    playerRow.Paint = function(self, w, h)
      local bgColor = i % 2 == 0 and cfg.Colors.Panel or cfg.Colors.ListAlt

      if self:IsHovered() then
        bgColor = cfg.Colors.PanelHover
      end

      draw.RoundedBox(4, 0, 0, w, h, bgColor)

      -- Player info
      draw.SimpleText(playerData.name, "DermaDefaultBold", 12, 10, cfg.Colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
      draw.SimpleText("Rank: " .. playerData.rank, "DermaDefault", 12, 30, playerData.rankColor, TEXT_ALIGN_LEFT,
        TEXT_ALIGN_TOP)
      draw.SimpleText("SteamID: " .. playerData.steamid, "DermaDefault", 12, 48, cfg.Colors.TextMuted, TEXT_ALIGN_LEFT,
        TEXT_ALIGN_TOP)

      -- Stats
      draw.SimpleText("HP: " .. playerData.health, "DermaDefault", w - 250, 10, cfg.Colors.TextDim, TEXT_ALIGN_LEFT,
        TEXT_ALIGN_TOP)
      draw.SimpleText("Armor: " .. playerData.armor, "DermaDefault", w - 250, 28, cfg.Colors.TextDim, TEXT_ALIGN_LEFT,
        TEXT_ALIGN_TOP)
      draw.SimpleText("Ping: " .. playerData.ping, "DermaDefault", w - 250, 46, cfg.Colors.TextDim, TEXT_ALIGN_LEFT,
        TEXT_ALIGN_TOP)
    end

    -- Kick button
    local kickBtn = vgui.Create("DButton", playerRow)
    kickBtn:SetPos(playerRow:GetWide() - 150, 15)
    kickBtn:SetSize(60, 50)
    kickBtn:SetText("Kick")

    kickBtn.Paint = function(self, w, h)
      local col = cfg.Colors.Button
      if self:IsHovered() then
        col = cfg.Colors.ButtonHover
      end

      draw.RoundedBox(4, 0, 0, w, h, col)
      draw.SimpleText("Kick", "DermaDefaultBold", w / 2, h / 2, cfg.Colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    kickBtn.DoClick = function()
      self:ShowKickDialog(playerData)
    end

    -- Ban button
    local banBtn = vgui.Create("DButton", playerRow)
    banBtn:SetPos(playerRow:GetWide() - 80, 15)
    banBtn:SetSize(60, 50)
    banBtn:SetText("Ban")

    banBtn.Paint = function(self, w, h)
      local col = cfg.Colors.ButtonDanger
      if self:IsHovered() then
        col = cfg.Colors.ButtonDangerHover
      end

      draw.RoundedBox(4, 0, 0, w, h, col)
      draw.SimpleText("Ban", "DermaDefaultBold", w / 2, h / 2, cfg.Colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    banBtn.DoClick = function()
      self:ShowBanDialog(playerData)
    end
  end

  return panel
end

--- Create the item spawner panel
--- @return Panel
function IonRP.IonSys.UI:CreateItemPanel()
  local cfg = self.Config
  local panel = vgui.Create("DPanel")
  panel.Paint = function() end

  if not self.CurrentData or not self.CurrentData.items then
    return panel
  end

  -- Search bar
  local searchPanel = vgui.Create("DPanel", panel)
  searchPanel:Dock(TOP)
  searchPanel:SetTall(50)
  searchPanel:DockMargin(cfg.Padding, cfg.Padding, cfg.Padding, 0)

  searchPanel.Paint = function(self, w, h)
    draw.RoundedBox(4, 0, 0, w, h, cfg.Colors.Panel)
    draw.SimpleText("Search Items:", "DermaDefault", 12, 16, cfg.Colors.TextDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
  end

  --- @class DTextEntry
  local searchBox = vgui.Create("DTextEntry", searchPanel)
  searchBox:SetPos(120, 12)
  searchBox:SetSize(300, 26)
  searchBox:SetPlaceholderText("Type to search...")

  -- Item list
  local scroll = vgui.Create("DScrollPanel", panel)
  scroll:Dock(FILL)
  scroll:DockMargin(cfg.Padding, cfg.Padding, cfg.Padding, cfg.Padding)

  -- Custom scrollbar
  local sbar = scroll:GetVBar()
  sbar:SetWide(8)
  sbar:SetHideButtons(true)

  function sbar:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 30, 220))
  end

  function sbar.btnGrip:Paint(w, h)
    local col = cfg.Colors.AccentCyan
    draw.RoundedBox(4, 0, 0, w, h, col)
  end

  --- Function to populate items
  --- @param filter string|nil
  local function PopulateItems(filter)
    scroll:Clear()

    filter = filter and string.lower(filter) or ""

    for i, itemData in ipairs(self.CurrentData.items) do
      -- Apply filter
      if filter ~= "" then
        local nameMatch = string.find(string.lower(itemData.name), filter, 1, true)
        local idMatch = string.find(string.lower(itemData.identifier), filter, 1, true)

        if not nameMatch and not idMatch then
          continue
        end
      end

      local itemRow = vgui.Create("DPanel", scroll)
      itemRow:Dock(TOP)
      itemRow:SetTall(90)
      itemRow:DockMargin(0, 0, 0, 4)

      itemRow.Paint = function(self, w, h)
        local bgColor = i % 2 == 0 and cfg.Colors.Panel or cfg.Colors.ListAlt

        if self:IsHovered() then
          bgColor = cfg.Colors.PanelHover
        end

        draw.RoundedBox(4, 0, 0, w, h, bgColor)

        -- Item info
        draw.SimpleText(itemData.name, "DermaDefaultBold", 12, 10, cfg.Colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(itemData.identifier, "DermaDefault", 12, 28, cfg.Colors.TextMuted, TEXT_ALIGN_LEFT,
          TEXT_ALIGN_TOP)
        draw.SimpleText(itemData.description, "DermaDefault", 12, 46, cfg.Colors.TextDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        -- Stats
        draw.SimpleText("Type: " .. itemData.type, "DermaDefault", 12, 64, cfg.Colors.TextDim, TEXT_ALIGN_LEFT,
          TEXT_ALIGN_TOP)
        draw.SimpleText("Weight: " .. itemData.weight .. " KG", "DermaDefault", 150, 64, cfg.Colors.TextDim,
          TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Stack: " .. itemData.stackSize, "DermaDefault", 300, 64, cfg.Colors.TextDim, TEXT_ALIGN_LEFT,
          TEXT_ALIGN_TOP)
      end

      -- Quantity selector
      local qtyLabel = vgui.Create("DLabel", itemRow)
      qtyLabel:SetPos(itemRow:GetWide() - 220, 20)
      qtyLabel:SetSize(60, 20)
      qtyLabel:SetText("Quantity:")
      qtyLabel:SetTextColor(cfg.Colors.TextDim)

      local qtyBox = vgui.Create("DNumberWang", itemRow)
      qtyBox:SetPos(itemRow:GetWide() - 150, 20)
      qtyBox:SetSize(60, 50)
      qtyBox:SetMin(1)
      qtyBox:SetMax(itemData.stackSize or 999)
      qtyBox:SetValue(1)

      -- Give button
      local giveBtn = vgui.Create("DButton", itemRow)
      giveBtn:SetPos(itemRow:GetWide() - 80, 20)
      giveBtn:SetSize(60, 50)
      giveBtn:SetText("Give")

      giveBtn.Paint = function(self, w, h)
        local col = cfg.Colors.ButtonSuccess
        if self:IsHovered() then
          col = cfg.Colors.ButtonSuccessHover
        end

        draw.RoundedBox(4, 0, 0, w, h, col)
        draw.SimpleText("Give", "DermaDefaultBold", w / 2, h / 2, cfg.Colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
      end

      giveBtn.DoClick = function()
        local quantity = qtyBox:GetValue()
        self:GiveItem(itemData.identifier, quantity)
      end
    end
  end

  -- Initial population
  PopulateItems()

  -- Search functionality
  searchBox.OnValueChange = function(self, value)
    PopulateItems(value)
  end

  return panel
end

--- Show kick dialog
--- @param playerData IonSys_PlayerData
function IonRP.IonSys.UI:ShowKickDialog(playerData)
  local cfg = self.Config

  -- Create dialog
  local dialog = vgui.Create("DFrame")
  dialog:SetSize(400, 200)
  dialog:Center()
  dialog:SetTitle("")
  dialog:SetDraggable(true)
  dialog:ShowCloseButton(false)
  dialog:MakePopup()

  dialog.Paint = function(self, w, h)
    draw.RoundedBox(8, 0, 0, w, h, cfg.Colors.Background)
    surface.SetDrawColor(cfg.Colors.AccentCyan)
    surface.DrawOutlinedRect(0, 0, w, h, 2)
  end

  -- Title
  local title = vgui.Create("DLabel", dialog)
  title:SetPos(12, 12)
  title:SetSize(376, 30)
  title:SetText("Kick Player: " .. playerData.name)
  title:SetFont("DermaLarge")
  title:SetTextColor(cfg.Colors.Text)

  -- Reason input
  local reasonLabel = vgui.Create("DLabel", dialog)
  reasonLabel:SetPos(12, 50)
  reasonLabel:SetSize(376, 20)
  reasonLabel:SetText("Reason:")
  reasonLabel:SetTextColor(cfg.Colors.TextDim)

  local reasonBox = vgui.Create("DTextEntry", dialog)
  reasonBox:SetPos(12, 75)
  reasonBox:SetSize(376, 30)
  reasonBox:SetPlaceholderText("Enter kick reason...")

  -- Buttons
  local cancelBtn = vgui.Create("DButton", dialog)
  cancelBtn:SetPos(12, 150)
  cancelBtn:SetSize(180, 40)
  cancelBtn:SetText("Cancel")

  cancelBtn.Paint = function(self, w, h)
    local col = cfg.Colors.Panel
    if self:IsHovered() then
      col = cfg.Colors.PanelHover
    end
    draw.RoundedBox(4, 0, 0, w, h, col)
    draw.SimpleText("Cancel", "DermaDefaultBold", w / 2, h / 2, cfg.Colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end

  cancelBtn.DoClick = function()
    dialog:Close()
  end

  local kickBtn = vgui.Create("DButton", dialog)
  kickBtn:SetPos(208, 150)
  kickBtn:SetSize(180, 40)
  kickBtn:SetText("Kick")

  kickBtn.Paint = function(self, w, h)
    local col = cfg.Colors.ButtonDanger
    if self:IsHovered() then
      col = cfg.Colors.ButtonDangerHover
    end
    draw.RoundedBox(4, 0, 0, w, h, col)
    draw.SimpleText("Kick", "DermaDefaultBold", w / 2, h / 2, cfg.Colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end

  kickBtn.DoClick = function()
    local reason = reasonBox:GetValue()

    -- Send kick request to server
    net.Start("IonSys_KickPlayer")
    net.WriteUInt(playerData.userid, 16)
    net.WriteString(reason)
    net.SendToServer()

    dialog:Close()

    chat.AddText(Color(100, 200, 255), "[IonSys] ", Color(255, 255, 255), "Kick request sent for " .. playerData.name)
  end
end

--- Show ban dialog
--- @param playerData IonSys_PlayerData
function IonRP.IonSys.UI:ShowBanDialog(playerData)
  local cfg = self.Config

  -- Create dialog
  local dialog = vgui.Create("DFrame")
  dialog:SetSize(400, 280)
  dialog:Center()
  dialog:SetTitle("")
  dialog:SetDraggable(true)
  dialog:ShowCloseButton(false)
  dialog:MakePopup()

  dialog.Paint = function(self, w, h)
    draw.RoundedBox(8, 0, 0, w, h, cfg.Colors.Background)
    surface.SetDrawColor(cfg.Colors.AccentCyan)
    surface.DrawOutlinedRect(0, 0, w, h, 2)
  end

  -- Title
  local title = vgui.Create("DLabel", dialog)
  title:SetPos(12, 12)
  title:SetSize(376, 30)
  title:SetText("Ban Player: " .. playerData.name)
  title:SetFont("DermaLarge")
  title:SetTextColor(cfg.Colors.Text)

  -- Duration input
  local durationLabel = vgui.Create("DLabel", dialog)
  durationLabel:SetPos(12, 50)
  durationLabel:SetSize(376, 20)
  durationLabel:SetText("Duration (minutes, 0 = permanent):")
  durationLabel:SetTextColor(cfg.Colors.TextDim)

  local durationBox = vgui.Create("DNumberWang", dialog)
  durationBox:SetPos(12, 75)
  durationBox:SetSize(376, 30)
  durationBox:SetMin(0)
  durationBox:SetMax(99999)
  durationBox:SetValue(0)

  -- Reason input
  local reasonLabel = vgui.Create("DLabel", dialog)
  reasonLabel:SetPos(12, 115)
  reasonLabel:SetSize(376, 20)
  reasonLabel:SetText("Reason:")
  reasonLabel:SetTextColor(cfg.Colors.TextDim)

  local reasonBox = vgui.Create("DTextEntry", dialog)
  reasonBox:SetPos(12, 140)
  reasonBox:SetSize(376, 30)
  reasonBox:SetPlaceholderText("Enter ban reason...")

  -- Buttons
  local cancelBtn = vgui.Create("DButton", dialog)
  cancelBtn:SetPos(12, 230)
  cancelBtn:SetSize(180, 40)
  cancelBtn:SetText("Cancel")

  cancelBtn.Paint = function(self, w, h)
    local col = cfg.Colors.Panel
    if self:IsHovered() then
      col = cfg.Colors.PanelHover
    end
    draw.RoundedBox(4, 0, 0, w, h, col)
    draw.SimpleText("Cancel", "DermaDefaultBold", w / 2, h / 2, cfg.Colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end

  cancelBtn.DoClick = function()
    dialog:Close()
  end

  local banBtn = vgui.Create("DButton", dialog)
  banBtn:SetPos(208, 230)
  banBtn:SetSize(180, 40)
  banBtn:SetText("Ban")

  banBtn.Paint = function(self, w, h)
    local col = cfg.Colors.ButtonDanger
    if self:IsHovered() then
      col = cfg.Colors.ButtonDangerHover
    end
    draw.RoundedBox(4, 0, 0, w, h, col)
    draw.SimpleText("BAN", "DermaDefaultBold", w / 2, h / 2, cfg.Colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end

  banBtn.DoClick = function()
    local duration = durationBox:GetValue()
    local reason = reasonBox:GetValue()

    -- Send ban request to server
    net.Start("IonSys_BanPlayer")
    net.WriteUInt(playerData.userid, 16)
    net.WriteUInt(duration, 32)
    net.WriteString(reason)
    net.SendToServer()

    dialog:Close()

    chat.AddText(Color(255, 100, 100), "[IonSys] ", Color(255, 255, 255), "Ban request sent for " .. playerData.name)
  end
end

--- Give item to self
--- @param identifier string The item identifier
--- @param quantity number The quantity to give
function IonRP.IonSys.UI:GiveItem(identifier, quantity)
  net.Start("IonSys_GiveItem")
  net.WriteString(identifier)
  net.WriteUInt(quantity, 16)
  net.SendToServer()
end

--- Refresh panel content
function IonRP.IonSys.UI:RefreshContent()
  if not IsValid(self.Frame) or not IsValid(self.Tabs) then return end

  -- Clear and recreate tabs
  self.Tabs:Clear()

  local playerPanel = self:CreatePlayerPanel()
  self.Tabs:AddSheet("Player Management", playerPanel, "icon16/group.png")

  local itemPanel = self:CreateItemPanel()
  self.Tabs:AddSheet("Item Spawner", itemPanel, "icon16/package.png")
end

--- Close the admin panel
function IonRP.IonSys.UI:Close()
  if IsValid(self.Frame) then
    self.Frame:AlphaTo(0, 0.2, 0, function()
      if IsValid(self.Frame) then
        self.Frame:Remove()
      end
    end)
  end
end

-- Console command to open admin panel
concommand.Add("ionsys", function()
  net.Start("IonSys_OpenPanel")
  net.SendToServer()
end)

-- Keybind
hook.Add("PlayerButtonDown", "IonSys_KeyBind", function(ply, button)
  if button == KEY_F4 then
    RunConsoleCommand("ionsys")
  end
end)

print("[IonSys] Client-side admin panel loaded")
