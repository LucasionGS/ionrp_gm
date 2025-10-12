--[[
    Garage Menu UI - Client
    Displays player's owned vehicles with spawn functionality
]]--

--- Color scheme
local Colors = {
  Background = Color(25, 25, 35, 250),
  Header = Color(45, 35, 60, 255),
  Card = Color(35, 35, 45, 230),
  CardHover = Color(45, 45, 55, 240),
  ButtonPrimary = Color(100, 200, 255, 255),
  ButtonPrimaryHover = Color(120, 220, 255, 255),
  ButtonDisabled = Color(80, 80, 90, 255),
  Text = Color(255, 255, 255, 255),
  TextMuted = Color(160, 160, 175, 255),
  TextDark = Color(25, 25, 35, 255),
  Accent = Color(100, 200, 255, 255),
  Success = Color(100, 255, 150, 255),
}

--- Stored vehicle data from server
IonRP.Garage.PlayerVehicles = IonRP.Garage.PlayerVehicles or {}

--- Stored nearby vehicles data from server
IonRP.Garage.NearbyVehicles = IonRP.Garage.NearbyVehicles or {}

--- Currently open menu frame
IonRP.Garage.MenuFrame = nil

--- Create and display the garage menu
function IonRP.Garage:OpenGarageMenu()
  -- Close existing menu if open
  if IsValid(self.MenuFrame) then
    self.MenuFrame:Remove()
  end
  
  local scrW, scrH = ScrW(), ScrH()
  local frameW, frameH = math.min(1200, scrW * 0.9), math.min(800, scrH * 0.9)
  
  -- Main frame
  local frame = vgui.Create("DFrame")
  frame:SetSize(frameW, frameH)
  frame:Center()
  frame:SetTitle("")
  frame:SetDraggable(true)
  frame:ShowCloseButton(false)
  frame:MakePopup()
  
  frame.Paint = function(self, w, h)
    -- Background
    draw.RoundedBox(8, 0, 0, w, h, Colors.Background)
    
    -- Header bar
    draw.RoundedBoxEx(8, 0, 0, w, 60, Colors.Header, true, true, false, false)
    
    -- Title
    draw.SimpleText("Your Garage", "DermaLarge", 20, 20, Colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- Vehicle count
    local vehicleCount = #IonRP.Garage.PlayerVehicles
    local countText = vehicleCount == 1 and "1 vehicle" or vehicleCount .. " vehicles"
    draw.SimpleText(countText, "DermaDefault", 20, 45, Colors.TextMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
  end
  
  -- Close button
  local closeBtn = vgui.Create("DButton", frame)
  closeBtn:SetPos(frameW - 50, 10)
  closeBtn:SetSize(40, 40)
  closeBtn:SetText("✕")
  closeBtn:SetFont("DermaLarge")
  closeBtn:SetTextColor(Colors.Text)
  
  closeBtn.Paint = function(self, w, h)
    if self:IsHovered() then
      draw.RoundedBox(4, 0, 0, w, h, Color(255, 100, 100, 200))
    end
  end
  
  closeBtn.DoClick = function()
    frame:Close()
  end
  
  -- Scroll panel for vehicle cards
  local scroll = vgui.Create("DScrollPanel", frame)
  scroll:SetPos(20, 80)
  scroll:SetSize(frameW - 40, frameH - 100)
  
  -- Scrollbar styling
  local sbar = scroll:GetVBar()
  sbar:SetWide(8)
  sbar:SetHideButtons(true)
  
  function sbar:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, Color(45, 45, 55, 100))
  end
  
  function sbar.btnGrip:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, Colors.Accent)
  end
  
  -- Container for vehicle cards
  local container = vgui.Create("DIconLayout", scroll)
  container:SetSpaceX(15)
  container:SetSpaceY(15)
  container:SetBorder(0)
  container:Dock(FILL)
  
  -- Show nearby vehicles section if any
  if #self.NearbyVehicles > 0 then
    local nearbyHeader = vgui.Create("DPanel", scroll)
    nearbyHeader:Dock(TOP)
    nearbyHeader:SetTall(40)
    nearbyHeader:DockMargin(0, 0, 0, 10)
    
    nearbyHeader.Paint = function(self, w, h)
      draw.RoundedBox(6, 0, 0, w, h, Colors.Header)
      draw.SimpleText("Nearby Vehicles (Within 1000 units)", "DermaDefaultBold", 15, h / 2, 
        Colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
      draw.SimpleText("Click to return to garage", "DermaDefault", w - 15, h / 2, 
        Colors.TextMuted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
    
    -- Create cards for nearby vehicles
    for _, vehicleData in ipairs(self.NearbyVehicles) do
      self:CreateNearbyVehicleCard(container, vehicleData, frameW - 60)
    end
    
    -- Spacer
    local spacer = vgui.Create("DPanel", scroll)
    spacer:Dock(TOP)
    spacer:SetTall(20)
    spacer.Paint = function() end
  end
  
  -- Section header for all vehicles
  if #self.PlayerVehicles > 0 then
    local allVehiclesHeader = vgui.Create("DPanel", scroll)
    allVehiclesHeader:Dock(TOP)
    allVehiclesHeader:SetTall(40)
    allVehiclesHeader:DockMargin(0, 0, 0, 10)
    
    allVehiclesHeader.Paint = function(self, w, h)
      draw.RoundedBox(6, 0, 0, w, h, Colors.Header)
      draw.SimpleText("All Your Vehicles", "DermaDefaultBold", 15, h / 2, 
        Colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
  end
  
  -- Check if player has vehicles
  if #self.PlayerVehicles == 0 then
    local emptyPanel = vgui.Create("DPanel", scroll)
    emptyPanel:Dock(FILL)
    
    emptyPanel.Paint = function(self, w, h)
      draw.SimpleText("You don't own any vehicles", "DermaLarge", w / 2, h / 2 - 30, 
        Colors.TextMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
      draw.SimpleText("Visit a car dealer to purchase your first vehicle!", "DermaDefault", w / 2, h / 2, 
        Colors.TextMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
      draw.SimpleText("Use /vehicleshop or talk to an NPC car dealer", "DermaDefault", w / 2, h / 2 + 25, 
        Colors.Accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
  else
    -- Create vehicle cards
    for _, vehicleData in ipairs(self.PlayerVehicles) do
      self:CreateVehicleCard(container, vehicleData, frameW - 60)
    end
  end
  
  self.MenuFrame = frame
end

--- Create a vehicle card
--- @param parent Panel Parent panel
--- @param vehicleData table Vehicle data
--- @param maxWidth number Maximum card width
function IonRP.Garage:CreateVehicleCard(parent, vehicleData, maxWidth)
  local cardW = math.min(350, maxWidth)
  local cardH = 220
  
  local card = vgui.Create("DPanel", parent)
  card:SetSize(cardW, cardH)
  
  local isHovered = false
  
  card.Paint = function(self, w, h)
    local bgColor = isHovered and Colors.CardHover or Colors.Card
    draw.RoundedBox(8, 0, 0, w, h, bgColor)
    
    -- Status badge if spawned
    if vehicleData.isSpawned then
      draw.RoundedBox(4, w - 100, 10, 90, 25, Colors.Success)
      draw.SimpleText("SPAWNED", "DermaDefaultBold", w - 55, 22, Colors.TextDark, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
  end
  
  card.OnCursorEntered = function()
    isHovered = true
  end
  
  card.OnCursorExited = function()
    isHovered = false
  end
  
  -- Vehicle model preview
  local modelPanel = vgui.Create("DModelPanel", card)
  modelPanel:SetPos(10, 10)
  modelPanel:SetSize(cardW - 20, 120)
  modelPanel:SetModel(vehicleData.model)
  modelPanel:SetFOV(50)
  modelPanel:SetCamPos(Vector(100, 100, 50))
  modelPanel:SetLookAt(Vector(0, 0, 0))
  
  function modelPanel:LayoutEntity(ent)
    ent:SetAngles(Angle(0, RealTime() * 20, 0))
  end
  
  modelPanel.Paint = function(self, w, h)
    draw.RoundedBox(6, 0, 0, w, h, Color(20, 20, 25, 200))
  end
  
  -- Vehicle name
  local nameLabel = vgui.Create("DLabel", card)
  nameLabel:SetPos(15, 140)
  nameLabel:SetSize(cardW - 30, 20)
  nameLabel:SetFont("DermaDefaultBold")
  nameLabel:SetTextColor(Colors.Text)
  nameLabel:SetText(vehicleData.name)
  
  -- Vehicle value
  local valueLabel = vgui.Create("DLabel", card)
  valueLabel:SetPos(15, 160)
  valueLabel:SetSize(cardW - 30, 16)
  valueLabel:SetFont("DermaDefault")
  valueLabel:SetTextColor(Colors.Accent)
  valueLabel:SetText("Value: " .. IonRP.Util:FormatMoney(vehicleData.marketValue))
  
  -- Spawn button
  local spawnBtn = vgui.Create("DButton", card)
  spawnBtn:SetPos(15, cardH - 40)
  spawnBtn:SetSize(cardW - 30, 30)
  spawnBtn:SetText("")
  
  spawnBtn.Paint = function(self, w, h)
    local btnColor = Colors.ButtonDisabled
    
    if not vehicleData.isSpawned then
      btnColor = self:IsHovered() and Colors.ButtonPrimaryHover or Colors.ButtonPrimary
    end
    
    draw.RoundedBox(6, 0, 0, w, h, btnColor)
    
    local text = vehicleData.isSpawned and "Already Spawned" or "Spawn at Garage"
    draw.SimpleText(text, "DermaDefaultBold", w / 2, h / 2, Colors.TextDark, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end
  
  spawnBtn.DoClick = function()
    if vehicleData.isSpawned then
      chat.AddText(Color(255, 100, 100), "[Garage] ", Colors.Text, "This vehicle is already spawned!")
      return
    end
    
    -- Send spawn request to server
    net.Start("IonRP_Garage_SpawnVehicle")
    net.WriteUInt(vehicleData.dbId, 32)
    net.SendToServer()
    
    -- Close menu
    if IsValid(IonRP.Garage.MenuFrame) then
      IonRP.Garage.MenuFrame:Close()
    end
    
    chat.AddText(Colors.Accent, "[Garage] ", Colors.Text, "Requesting spawn for " .. vehicleData.name .. "...")
  end
end

--- Create a nearby vehicle card with despawn option
--- @param parent Panel Parent panel
--- @param vehicleData table Vehicle data
--- @param maxWidth number Maximum card width
function IonRP.Garage:CreateNearbyVehicleCard(parent, vehicleData, maxWidth)
  local cardW = math.min(350, maxWidth)
  local cardH = 220
  
  local card = vgui.Create("DPanel", parent)
  card:SetSize(cardW, cardH)
  
  local isHovered = false
  
  card.Paint = function(self, w, h)
    local bgColor = isHovered and Colors.CardHover or Colors.Card
    draw.RoundedBox(8, 0, 0, w, h, bgColor)
    
    -- Distance badge
    draw.RoundedBox(4, w - 110, 10, 100, 25, Colors.Accent)
    draw.SimpleText(vehicleData.distance .. " units", "DermaDefaultBold", w - 60, 22, Colors.TextDark, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end
  
  card.OnCursorEntered = function()
    isHovered = true
  end
  
  card.OnCursorExited = function()
    isHovered = false
  end
  
  -- Vehicle model preview
  local modelPanel = vgui.Create("DModelPanel", card)
  modelPanel:SetPos(10, 10)
  modelPanel:SetSize(cardW - 20, 120)
  modelPanel:SetModel(vehicleData.model)
  modelPanel:SetFOV(50)
  modelPanel:SetCamPos(Vector(100, 100, 50))
  modelPanel:SetLookAt(Vector(0, 0, 0))
  
  function modelPanel:LayoutEntity(ent)
    ent:SetAngles(Angle(0, RealTime() * 20, 0))
  end
  
  modelPanel.Paint = function(self, w, h)
    draw.RoundedBox(6, 0, 0, w, h, Color(20, 20, 25, 200))
  end
  
  -- Vehicle name
  local nameLabel = vgui.Create("DLabel", card)
  nameLabel:SetPos(15, 140)
  nameLabel:SetSize(cardW - 30, 20)
  nameLabel:SetFont("DermaDefaultBold")
  nameLabel:SetTextColor(Colors.Text)
  nameLabel:SetText(vehicleData.name)
  
  -- Status text
  local statusLabel = vgui.Create("DLabel", card)
  statusLabel:SetPos(15, 160)
  statusLabel:SetSize(cardW - 30, 16)
  statusLabel:SetFont("DermaDefault")
  statusLabel:SetTextColor(Colors.Success)
  statusLabel:SetText("Currently spawned nearby")
  
  -- Despawn button
  local despawnBtn = vgui.Create("DButton", card)
  despawnBtn:SetPos(15, cardH - 40)
  despawnBtn:SetSize(cardW - 30, 30)
  despawnBtn:SetText("")
  
  despawnBtn.Paint = function(self, w, h)
    local btnColor = self:IsHovered() and Color(240, 100, 100, 255) or Color(220, 80, 80, 240)
    
    draw.RoundedBox(6, 0, 0, w, h, btnColor)
    
    draw.SimpleText("Return to Garage", "DermaDefaultBold", w / 2, h / 2, Colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end
  
  despawnBtn.DoClick = function()
    -- Send despawn request to server
    net.Start("IonRP_Garage_DespawnVehicle")
    net.WriteUInt(vehicleData.entIndex, 16)
    net.SendToServer()
    
    -- Close menu
    if IsValid(IonRP.Garage.MenuFrame) then
      IonRP.Garage.MenuFrame:Close()
    end
    
    chat.AddText(Colors.Accent, "[Garage] ", Colors.Text, "Returning " .. vehicleData.name .. " to garage...")
  end
end

--[[
    Network Receivers
]]--

--- Receive vehicle data from server
net.Receive("IonRP_Garage_SyncVehicles", function()
  local vehicleData = net.ReadTable()
  IonRP.Garage.PlayerVehicles = vehicleData
  
  print(string.format("[IonRP Garage] Received %d vehicle(s) from server", #vehicleData))
end)

--- Receive nearby vehicles data from server
net.Receive("IonRP_Garage_SyncNearbyVehicles", function()
  local nearbyData = net.ReadTable()
  IonRP.Garage.NearbyVehicles = nearbyData
  
  print(string.format("[IonRP Garage] Found %d nearby vehicle(s)", #nearbyData))
end)

--- Open the garage menu
net.Receive("IonRP_Garage_OpenMenu", function()
  IonRP.Garage:OpenGarageMenu()
end)

--- Console command to open garage (also sends request to server)
concommand.Add("ionrp_garage", function()
  net.Start("IonRP_Garage_OpenMenu")
  net.SendToServer()
end)

print("[IonRP Garage] Vehicle menu UI loaded (client)")
