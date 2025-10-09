--[[
    Vehicle Shop - Client Side UI
    Modern vehicle dealership interface
]]--

IonRP.VehicleShop = IonRP.VehicleShop or {}
IonRP.VehicleShop.UI = IonRP.VehicleShop.UI or {}

-- Configuration
IonRP.VehicleShop.UI.Config = {
  Width = ScrW() * 0.85,
  Height = ScrH() * 0.85,
  Padding = 16,
  HeaderHeight = 80,
  TabHeight = 50,
  
  Colors = {
    Background = Color(25, 25, 35, 250),
    Header = Color(45, 35, 60, 255),
    Panel = Color(35, 35, 45, 230),
    PanelHover = Color(45, 45, 55, 240),
    TabActive = Color(52, 152, 219, 230),
    TabInactive = Color(40, 40, 50, 220),
    TabHover = Color(50, 50, 60, 240),
    ButtonBuy = Color(46, 204, 113, 230),
    ButtonBuyHover = Color(56, 214, 123, 255),
    ButtonSpawn = Color(52, 152, 219, 230),
    ButtonSpawnHover = Color(62, 162, 229, 255),
    Text = Color(255, 255, 255, 255),
    TextDim = Color(200, 200, 210, 255),
    TextMuted = Color(160, 160, 175, 255),
    Accent = Color(120, 100, 255, 255),
    AccentCyan = Color(100, 200, 255, 255),
    Border = Color(60, 50, 80, 200),
  }
}

--- Open the vehicle shop with a specific category
--- @param category string|nil The category to show (default: first available)
function IonRP.VehicleShop.UI:Open(category)
  if IsValid(self.Frame) then
    self.Frame:Remove()
  end

  local cfg = self.Config
  local ply = LocalPlayer()

  -- Get categories from vehicle list
  local categories = {}
  local categoryVehicles = {}
  
  for identifier, vehicle in pairs(IonRP.Vehicles.List) do
    if vehicle.purchasable then
      local cat = vehicle.category or IonRP.Vehicles.Categories.OTHER
      
      if not categories[cat] then
        categories[cat] = true
        categoryVehicles[cat] = {}
      end
      
      table.insert(categoryVehicles[cat], vehicle)
    end
  end

  -- Default to first category if not specified
  if not category then
    for cat, _ in pairs(categories) do
      category = cat
      break
    end
  end

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
    draw.SimpleText("VEHICLE DEALERSHIP", "DermaLarge", cfg.Padding, 15, cfg.Colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    -- Subtitle
    draw.SimpleText("Browse and purchase vehicles", "DermaDefault", cfg.Padding, 45, cfg.Colors.TextDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    -- Player money
    local bank = ply:GetBank()
    local moneyText = "Your Bank Balance: " .. IonRP.Util:FormatMoney(bank)
    draw.SimpleText(moneyText, "DermaDefaultBold", w - cfg.Padding * 2, 30, cfg.Colors.Accent, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
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

  -- Category tabs
  local tabPanel = vgui.Create("DPanel", frame)
  tabPanel:Dock(TOP)
  tabPanel:SetTall(cfg.TabHeight)
  tabPanel:DockMargin(cfg.Padding, cfg.Padding, cfg.Padding, 0)
  tabPanel.Paint = function() end

  -- Content area
  local contentArea = vgui.Create("DPanel", frame)
  contentArea:Dock(FILL)
  contentArea:DockMargin(cfg.Padding, cfg.Padding, cfg.Padding, cfg.Padding)
  contentArea.Paint = function() end

  -- Create tab buttons
  local function CreateCategoryTab(cat)
    local btn = vgui.Create("DButton", tabPanel)
    btn:Dock(LEFT)
    btn:SetWide(120)
    btn:DockMargin(0, 0, 5, 0)
    btn:SetText("")

    btn.Paint = function(self, w, h)
      local col = cfg.Colors.TabInactive
      if cat == category then
        col = cfg.Colors.TabActive
      elseif self:IsHovered() then
        col = cfg.Colors.TabHover
      end

      draw.RoundedBox(6, 0, 0, w, h, col)
      draw.SimpleText(cat, "DermaDefaultBold", w / 2, h / 2, cfg.Colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    btn.DoClick = function()
      self:Open(cat)
    end
  end

  -- Create tabs for each category
  for cat, _ in SortedPairs(categories) do
    CreateCategoryTab(cat)
  end

  -- Populate vehicle list
  self:PopulateVehicleList(contentArea, categoryVehicles[category] or {})
end

--- Populate the vehicle list for the selected category
--- @param parent Panel The parent panel
--- @param vehicles VEHICLE[] List of vehicles to display
function IonRP.VehicleShop.UI:PopulateVehicleList(parent, vehicles)
  local cfg = self.Config
  local ply = LocalPlayer()

  -- Create scrollable list
  local scroll = vgui.Create("DScrollPanel", parent)
  scroll:Dock(FILL)

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

  -- Sort vehicles by market value
  table.sort(vehicles, function(a, b)
    return a.marketValue < b.marketValue
  end)

  -- Create vehicle entries
  for i, vehicle in ipairs(vehicles) do
    local vehPanel = vgui.Create("DPanel", scroll)
    vehPanel:Dock(TOP)
    vehPanel:SetTall(150)
    vehPanel:DockMargin(0, 0, 0, 8)

    vehPanel.Paint = function(self, w, h)
      local bgColor = i % 2 == 0 and cfg.Colors.Panel or Color(40, 40, 50, 220)

      if self:IsHovered() then
        bgColor = cfg.Colors.PanelHover
      end

      draw.RoundedBox(6, 0, 0, w, h, bgColor)
    end

    -- 3D Model preview
    local modelPanel = vgui.Create("DModelPanel", vehPanel)
    modelPanel:SetSize(150, 150)
    modelPanel:Dock(LEFT)
    modelPanel:SetModel(vehicle.model)

    local ent = modelPanel:GetEntity()
    if IsValid(ent) then
      local mn, mx = ent:GetRenderBounds()
      local size = 0
      size = math.max(size, math.abs(mn.x) + math.abs(mx.x))
      size = math.max(size, math.abs(mn.y) + math.abs(mx.y))
      size = math.max(size, math.abs(mn.z) + math.abs(mx.z))

      local scale = 2.2
      modelPanel:SetCamPos(Vector(size * scale, size * scale, size * scale * 0.5))
      modelPanel:SetLookAt((mn + mx) * 0.5)
      modelPanel:SetFOV(25)
    end

    modelPanel.LayoutEntity = function() end

    -- Info container
    local infoContainer = vgui.Create("DPanel", vehPanel)
    infoContainer:Dock(FILL)
    infoContainer:DockMargin(12, 12, 12, 12)
    infoContainer.Paint = function() end

    -- Button container (right side) - dock first so left side can fill properly
    local buttonContainer = vgui.Create("DPanel", infoContainer)
    buttonContainer:Dock(RIGHT)
    buttonContainer:SetWide(200)
    buttonContainer:DockMargin(12, 0, 0, 0)
    buttonContainer.Paint = function() end

    -- Left content container (for name, description, price)
    local leftContainer = vgui.Create("DPanel", infoContainer)
    leftContainer:Dock(FILL)
    leftContainer.Paint = function() end

    -- Vehicle name
    local nameLabel = vgui.Create("DLabel", leftContainer)
    nameLabel:Dock(TOP)
    nameLabel:SetText(vehicle.name)
    nameLabel:SetFont("DermaLarge")
    nameLabel:SetTextColor(cfg.Colors.Text)
    nameLabel:SetTall(30)
    nameLabel:DockMargin(0, 0, 0, 5)

    -- Vehicle description
    if vehicle.description and vehicle.description ~= "<No description>" then
      local descLabel = vgui.Create("DLabel", leftContainer)
      descLabel:Dock(TOP)
      descLabel:SetText(vehicle.description)
      descLabel:SetFont("DermaDefault")
      descLabel:SetTextColor(cfg.Colors.TextMuted)
      descLabel:SetWrap(true)
      descLabel:SetAutoStretchVertical(true)
      descLabel:DockMargin(0, 0, 0, 10)
    end

    -- Purchase button
    local buyBtn = vgui.Create("DButton", buttonContainer)
    buyBtn:Dock(TOP)
    buyBtn:SetTall(50)
    buyBtn:SetText("")

    local canAfford = ply:GetBank() >= vehicle.marketValue

    buyBtn.Paint = function(self, w, h)
      local col = canAfford and cfg.Colors.ButtonBuy or Color(100, 100, 100, 200)
      if canAfford and self:IsHovered() then
        col = cfg.Colors.ButtonBuyHover
      end

      draw.RoundedBox(6, 0, 0, w, h, col)
      
      local text = canAfford and "PURCHASE" or "INSUFFICIENT FUNDS"
      draw.SimpleText(text, "DermaDefaultBold", w / 2, h / 2 - 8, cfg.Colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
      draw.SimpleText(IonRP.Util:FormatMoney(vehicle.marketValue), "DermaDefault", w / 2, h / 2 + 10, cfg.Colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    buyBtn.DoClick = function()
      if not canAfford then
        chat.AddText(Color(255, 100, 100), "[IonRP] ", Color(255, 255, 255), "You cannot afford this vehicle!")
        surface.PlaySound("buttons/button10.wav")
        return
      end

      -- Show confirmation dialog
      self:ShowPurchaseConfirmation(vehicle)
    end

    -- Admin spawn button (if superadmin)
    if ply:IsSuperAdmin() then
      local spawnBtn = vgui.Create("DButton", buttonContainer)
      spawnBtn:Dock(TOP)
      spawnBtn:SetTall(40)
      spawnBtn:DockMargin(0, 8, 0, 0)
      spawnBtn:SetText("")

      spawnBtn.Paint = function(self, w, h)
        local col = cfg.Colors.ButtonSpawn
        if self:IsHovered() then
          col = cfg.Colors.ButtonSpawnHover
        end

        draw.RoundedBox(6, 0, 0, w, h, col)
        draw.SimpleText("SPAWN (ADMIN)", "DermaDefaultBold", w / 2, h / 2, cfg.Colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
      end

      spawnBtn.DoClick = function()
        net.Start("IonRP_VehicleShop_AdminSpawn")
        net.WriteString(vehicle.identifier)
        net.SendToServer()
        surface.PlaySound("buttons/button15.wav")
        self:Close()
      end
    end
  end

  -- No vehicles message
  if #vehicles == 0 then
    local noVehLabel = vgui.Create("DLabel", scroll)
    noVehLabel:SetText("No vehicles available in this category")
    noVehLabel:SetFont("DermaLarge")
    noVehLabel:SetTextColor(cfg.Colors.TextMuted)
    noVehLabel:SetContentAlignment(5)
    noVehLabel:Dock(TOP)
    noVehLabel:SetTall(100)
  end
end

--- Show purchase confirmation dialog
--- @param vehicle VEHICLE The vehicle to purchase
function IonRP.VehicleShop.UI:ShowPurchaseConfirmation(vehicle)
  local cfg = self.Config

  local dialog = vgui.Create("DFrame")
  dialog:SetSize(450, 250)
  dialog:Center()
  dialog:SetTitle("")
  dialog:SetDraggable(false)
  dialog:ShowCloseButton(false)
  dialog:MakePopup()

  dialog.Paint = function(self, w, h)
    draw.RoundedBox(8, 0, 0, w, h, cfg.Colors.Background)
    surface.SetDrawColor(cfg.Colors.AccentCyan)
    surface.DrawOutlinedRect(0, 0, w, h, 2)
  end

  -- Title
  local title = vgui.Create("DLabel", dialog)
  title:SetPos(16, 16)
  title:SetText("Confirm Purchase")
  title:SetFont("DermaLarge")
  title:SetTextColor(cfg.Colors.Text)
  title:SizeToContents()

  -- Message
  local message = vgui.Create("DLabel", dialog)
  message:SetPos(16, 55)
  message:SetWide(418)
  message:SetText(string.format("Are you sure you want to purchase a %s for %s?", 
    vehicle.name, IonRP.Util:FormatMoney(vehicle.marketValue)))
  message:SetFont("DermaDefault")
  message:SetTextColor(cfg.Colors.TextDim)
  message:SetWrap(true)
  message:SetAutoStretchVertical(true)

  -- Warning
  local warning = vgui.Create("DLabel", dialog)
  warning:SetPos(16, 110)
  warning:SetWide(418)
  warning:SetText("This vehicle will be added to your garage and can be spawned at any time.")
  warning:SetFont("DermaDefault")
  warning:SetTextColor(cfg.Colors.TextMuted)
  warning:SetWrap(true)
  warning:SetAutoStretchVertical(true)

  -- Buttons
  local cancelBtn = vgui.Create("DButton", dialog)
  cancelBtn:SetPos(16, 185)
  cancelBtn:SetSize(200, 45)
  cancelBtn:SetText("")

  cancelBtn.Paint = function(self, w, h)
    local col = Color(100, 100, 100, 200)
    if self:IsHovered() then
      col = Color(120, 120, 120, 240)
    end
    draw.RoundedBox(6, 0, 0, w, h, col)
    draw.SimpleText("CANCEL", "DermaDefaultBold", w / 2, h / 2, cfg.Colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end

  cancelBtn.DoClick = function()
    surface.PlaySound("buttons/button15.wav")
    dialog:Close()
  end

  local confirmBtn = vgui.Create("DButton", dialog)
  confirmBtn:SetPos(234, 185)
  confirmBtn:SetSize(200, 45)
  confirmBtn:SetText("")

  confirmBtn.Paint = function(self, w, h)
    local col = cfg.Colors.ButtonBuy
    if self:IsHovered() then
      col = cfg.Colors.ButtonBuyHover
    end
    draw.RoundedBox(6, 0, 0, w, h, col)
    draw.SimpleText("PURCHASE", "DermaDefaultBold", w / 2, h / 2, cfg.Colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end

  confirmBtn.DoClick = function()
    net.Start("IonRP_VehicleShop_Purchase")
    net.WriteString(vehicle.identifier)
    net.SendToServer()
    surface.PlaySound("buttons/button15.wav")
    dialog:Close()
    self:Close()
  end
end

--- Close the vehicle shop
function IonRP.VehicleShop.UI:Close()
  if IsValid(self.Frame) then
    self.Frame:AlphaTo(0, 0.2, 0, function()
      if IsValid(self.Frame) then
        self.Frame:Remove()
      end
    end)
  end
end

-- Network receivers
net.Receive("IonRP_VehicleShop_Open", function()
  IonRP.VehicleShop.UI:Open()
end)

-- Console command
concommand.Add("ionrp_vehicleshop", function()
  IonRP.VehicleShop.UI:Open()
end)

print("[IonRP Vehicle Shop] Client-side UI loaded")
