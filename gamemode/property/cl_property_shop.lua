--[[
    Property Shop - Client Side UI
    Modern real estate interface
]] --

IonRP.PropertyShop = IonRP.PropertyShop or {}
IonRP.PropertyShop.UI = IonRP.PropertyShop.UI or {}

-- Configuration
IonRP.PropertyShop.UI.Config = {
  Width = ScrW() * 0.9,
  Height = ScrH() * 0.9,
  Padding = 20,
  HeaderHeight = 100,
  TabHeight = 55,

  Colors = {
    Background = Color(20, 20, 28, 250),
    BackgroundLight = Color(28, 28, 38, 240),
    Header = Color(35, 30, 50, 255),
    HeaderGradient = Color(45, 35, 65, 255),
    Panel = Color(32, 32, 42, 235),
    PanelLight = Color(38, 38, 48, 245),
    PanelHover = Color(42, 42, 52, 250),
    TabActive = Color(100, 200, 255, 255),
    TabInactive = Color(38, 38, 48, 230),
    TabHover = Color(48, 48, 58, 245),
    ButtonBuy = Color(46, 204, 113, 240),
    ButtonBuyHover = Color(52, 224, 123, 255),
    ButtonBuyGlow = Color(46, 204, 113, 100),
    Text = Color(255, 255, 255, 255),
    TextDim = Color(220, 220, 230, 255),
    TextMuted = Color(160, 160, 175, 220),
    Accent = Color(155, 89, 182, 255),
    AccentCyan = Color(100, 200, 255, 255),
    AccentGold = Color(255, 215, 0, 255),
    Border = Color(100, 200, 255, 180),
    BorderDark = Color(60, 50, 80, 200),
    Shadow = Color(0, 0, 0, 200),
  }
}

--- Open the property shop with a specific category
--- @param category string|nil The category to show (default: first available)
function IonRP.PropertyShop.UI:Open(category)
  if IsValid(self.Frame) then
    self.Frame:Remove()
  end

  local cfg = self.Config
  local ply = LocalPlayer()

  -- Get categories from property list
  local categories = {}
  local categoryProperties = {}

  for identifier, property in pairs(IonRP.Properties.List) do
    if property.purchasable then
      local cat = property.category or "Other"

      if not categories[cat] then
        categories[cat] = true
        categoryProperties[cat] = {}
      end

      table.insert(categoryProperties[cat], property)
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
    -- Outer glow/shadow effect
    for i = 1, 5 do
      local alpha = 40 - (i * 6)
      draw.RoundedBox(10, -i, -i, w + (i * 2), h + (i * 2), Color(0, 0, 0, alpha))
    end

    -- Main background with subtle gradient
    draw.RoundedBox(10, 0, 0, w, h, cfg.Colors.Background)

    -- Subtle inner highlight
    surface.SetDrawColor(255, 255, 255, 8)
    surface.DrawRect(10, 10, w - 20, 2)

    -- Glowing accent border
    surface.SetDrawColor(cfg.Colors.AccentCyan)
    surface.DrawOutlinedRect(0, 0, w, h, 2)

    -- Inner glow effect for border
    surface.SetDrawColor(cfg.Colors.AccentCyan.r, cfg.Colors.AccentCyan.g, cfg.Colors.AccentCyan.b, 30)
    surface.DrawOutlinedRect(1, 1, w - 2, h - 2, 1)

    -- Top accent line with gradient effect
    draw.RoundedBoxEx(0, 0, 0, w, 4, cfg.Colors.AccentCyan, true, true, false, false)
    surface.SetDrawColor(cfg.Colors.AccentCyan.r, cfg.Colors.AccentCyan.g, cfg.Colors.AccentCyan.b, 80)
    surface.DrawRect(0, 4, w, 8)
  end

  -- Header
  local header = vgui.Create("DPanel", frame)
  header:Dock(TOP)
  header:SetTall(cfg.HeaderHeight)
  header:DockMargin(0, 0, 0, 0)

  header.Paint = function(self, w, h)
    -- Simple purple background
    draw.RoundedBoxEx(10, 0, 0, w, h, cfg.Colors.Header, true, true, false, false)

    -- Title with shadow
    draw.SimpleText("REAL ESTATE AGENCY", "DermaLarge", cfg.Padding + 2, 22, Color(0, 0, 0, 100), TEXT_ALIGN_LEFT,
      TEXT_ALIGN_TOP)
    draw.SimpleText("REAL ESTATE AGENCY", "DermaLarge", cfg.Padding, 20, cfg.Colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    -- Subtitle
    draw.SimpleText("Browse and purchase premium properties", "DermaDefault", cfg.Padding, 52, cfg.Colors.TextDim,
      TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    -- Player money with icon-like background
    local bank = ply:GetBank()
    local moneyText = IonRP.Util:FormatMoney(bank)
    local moneyBoxW = 250
    local moneyBoxH = 45
    local moneyX = w - cfg.Padding - moneyBoxW
    local moneyY = (h - moneyBoxH) / 2

    -- Money box background
    draw.RoundedBox(8, moneyX, moneyY, moneyBoxW, moneyBoxH, Color(0, 0, 0, 100))
    draw.RoundedBox(8, moneyX + 1, moneyY + 1, moneyBoxW - 2, moneyBoxH - 2, cfg.Colors.BackgroundLight)

    -- Border
    surface.SetDrawColor(cfg.Colors.Accent)
    surface.DrawOutlinedRect(moneyX, moneyY, moneyBoxW, moneyBoxH, 1)

    -- Money label
    draw.SimpleText("BANK BALANCE", "DermaDefault", moneyX + moneyBoxW / 2, moneyY + 10, cfg.Colors.TextMuted,
      TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    draw.SimpleText(moneyText, "DermaDefaultBold", moneyX + moneyBoxW / 2, moneyY + 24, cfg.Colors.Accent,
      TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
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
    btn:SetWide(140)
    btn:DockMargin(0, 0, 8, 0)
    btn:SetText("")

    btn.Paint = function(self, w, h)
      local isActive = cat == category
      local isHovered = self:IsHovered()

      local col = cfg.Colors.TabInactive
      if isActive then
        col = cfg.Colors.TabActive
      elseif isHovered then
        col = cfg.Colors.TabHover
      end

      -- Background with shadow
      if isActive or isHovered then
        draw.RoundedBox(8, 0, 2, w, h - 2, Color(0, 0, 0, 80))
      end

      draw.RoundedBox(8, 0, 0, w, h, col)

      -- Active tab indicator
      if isActive then
        draw.RoundedBox(0, 0, h - 4, w, 4, cfg.Colors.AccentCyan)

        -- Glow effect
        surface.SetDrawColor(cfg.Colors.AccentCyan.r, cfg.Colors.AccentCyan.g, cfg.Colors.AccentCyan.b, 60)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
      end

      -- Text with shadow
      local textColor = isActive and Color(255, 255, 255) or cfg.Colors.TextDim
      if isActive then
        draw.SimpleText(cat, "DermaDefaultBold", w / 2 + 1, h / 2 + 1, Color(0, 0, 0, 100), TEXT_ALIGN_CENTER,
          TEXT_ALIGN_CENTER)
      end
      draw.SimpleText(cat, "DermaDefaultBold", w / 2, h / 2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    btn.DoClick = function()
      surface.PlaySound("buttons/button14.wav")
      self:Open(cat)
    end
  end

  -- Create tabs for each category
  for cat, _ in SortedPairs(categories) do
    CreateCategoryTab(cat)
  end

  -- Populate property list
  self:PopulatePropertyList(contentArea, categoryProperties[category] or {})
end

--- Populate the property list for the selected category
--- @param parent Panel The parent panel
--- @param properties Property[] List of properties to display
function IonRP.PropertyShop.UI:PopulatePropertyList(parent, properties)
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

  -- Sort properties by price
  table.sort(properties, function(a, b)
    return a.price < b.price
  end)

  -- Create property entries
  for i, property in ipairs(properties) do
    local propPanel = vgui.Create("DPanel", scroll)
    propPanel:Dock(TOP)
    propPanel:SetTall(170)
    propPanel:DockMargin(0, 0, 0, 12)
    propPanel.HoverAlpha = 0

    propPanel.Paint = function(self, w, h)
      local isHovered = self:IsHovered()

      -- Animate hover effect
      if isHovered then
        self.HoverAlpha = math.Approach(self.HoverAlpha, 255, FrameTime() * 600)
      else
        self.HoverAlpha = math.Approach(self.HoverAlpha, 0, FrameTime() * 400)
      end

      local bgColor = i % 2 == 0 and cfg.Colors.Panel or cfg.Colors.PanelLight

      -- Shadow
      draw.RoundedBox(10, 2, 2, w, h, Color(0, 0, 0, 100))

      -- Main background
      draw.RoundedBox(10, 0, 0, w, h, bgColor)

      -- Hover overlay
      if self.HoverAlpha > 0 then
        draw.RoundedBox(10, 0, 0, w, h, Color(255, 255, 255, math.min(self.HoverAlpha * 0.05, 12)))

        -- Hover border glow
        surface.SetDrawColor(cfg.Colors.AccentCyan.r, cfg.Colors.AccentCyan.g, cfg.Colors.AccentCyan.b,
          self.HoverAlpha * 0.6)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
      end

      -- Subtle inner border
      surface.SetDrawColor(255, 255, 255, 8)
      surface.DrawOutlinedRect(1, 1, w - 2, h - 2, 1)
    end

    -- Icon container (left side)
    local iconContainer = vgui.Create("DPanel", propPanel)
    iconContainer:SetSize(180, 170)
    iconContainer:Dock(LEFT)
    iconContainer.Paint = function(self, w, h)
      -- Gradient background for icon
      draw.RoundedBox(8, 5, 5, w - 10, h - 10, Color(15, 15, 22, 255))

      -- Subtle gradient overlay
      surface.SetDrawColor(cfg.Colors.AccentCyan.r, cfg.Colors.AccentCyan.g, cfg.Colors.AccentCyan.b, 20)
      surface.DrawRect(5, 5, w - 10, (h - 10) / 2)

      -- Border accent
      surface.SetDrawColor(cfg.Colors.AccentCyan.r, cfg.Colors.AccentCyan.g, cfg.Colors.AccentCyan.b, 80)
      surface.DrawOutlinedRect(5, 5, w - 10, h - 10, 1)
      
      -- Property icon (house symbol)
      draw.SimpleText("🏠", "DermaLarge", w / 2, h / 2 - 10, cfg.Colors.AccentCyan, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
      
      -- Door count
      local doorText = #property.doors .. " Door" .. (#property.doors ~= 1 and "s" or "")
      draw.SimpleText(doorText, "DermaDefault", w / 2, h / 2 + 30, cfg.Colors.TextMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- Info container
    local infoContainer = vgui.Create("DPanel", propPanel)
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

    -- Property name
    local nameLabel = vgui.Create("DLabel", leftContainer)
    nameLabel:Dock(TOP)
    nameLabel:SetText(property.name)
    nameLabel:SetFont("DermaLarge")
    nameLabel:SetTextColor(cfg.Colors.Text)
    nameLabel:SetTall(30)
    nameLabel:DockMargin(0, 0, 0, 5)

    -- Property description
    if property.description and property.description ~= "<No description>" then
      local descLabel = vgui.Create("DLabel", leftContainer)
      descLabel:Dock(TOP)
      descLabel:SetText(property.description)
      descLabel:SetFont("DermaDefault")
      descLabel:SetTextColor(cfg.Colors.TextMuted)
      descLabel:SetWrap(true)
      descLabel:SetAutoStretchVertical(true)
      descLabel:DockMargin(0, 0, 0, 10)
    end

    -- Ownership status
    local ownerLabel = vgui.Create("DLabel", leftContainer)
    ownerLabel:Dock(TOP)
    ownerLabel:SetTall(20)
    ownerLabel:DockMargin(0, 5, 0, 0)
    
    if property.owner and IsValid(property.owner) then
      ownerLabel:SetText("Currently owned by: " .. property.owner:Nick())
      ownerLabel:SetTextColor(Color(255, 100, 100))
    else
      ownerLabel:SetText("Available for purchase")
      ownerLabel:SetTextColor(Color(100, 255, 100))
    end
    ownerLabel:SetFont("DermaDefault")

    -- Purchase button
    local buyBtn = vgui.Create("DButton", buttonContainer)
    buyBtn:Dock(TOP)
    buyBtn:SetTall(60)
    buyBtn:SetText("")
    buyBtn.PulseAlpha = 0
    buyBtn.PulseDirection = 1

    local isOwned = property.owner and IsValid(property.owner)
    local canAfford = ply:GetBank() >= property.price and not isOwned

    buyBtn.Paint = function(self, w, h)
      local isHovered = self:IsHovered()

      -- Animate pulse effect
      self.PulseAlpha = self.PulseAlpha + (FrameTime() * 200 * self.PulseDirection)
      if self.PulseAlpha > 100 then
        self.PulseAlpha = 100
        self.PulseDirection = -1
      elseif self.PulseAlpha < 0 then
        self.PulseAlpha = 0
        self.PulseDirection = 1
      end

      local col = canAfford and cfg.Colors.ButtonBuy or Color(70, 70, 80, 220)
      local hoverCol = canAfford and cfg.Colors.ButtonBuyHover or Color(80, 80, 90, 240)

      if isHovered and canAfford then
        col = hoverCol
      end

      -- Shadow
      draw.RoundedBox(10, 2, 2, w, h, Color(0, 0, 0, 120))

      -- Button background
      draw.RoundedBox(10, 0, 0, w, h, col)

      -- Pulse glow effect for affordable items
      if canAfford then
        surface.SetDrawColor(cfg.Colors.ButtonBuy.r, cfg.Colors.ButtonBuy.g, cfg.Colors.ButtonBuy.b,
          self.PulseAlpha * 0.5)
        surface.DrawOutlinedRect(0, 0, w, h, 2)

        -- Inner highlight
        surface.SetDrawColor(255, 255, 255, isHovered and 30 or 15)
        surface.DrawRect(5, 5, w - 10, 2)
      end

      local text = "PURCHASE PROPERTY"
      if isOwned then
        text = "ALREADY OWNED"
      elseif not canAfford then
        text = "INSUFFICIENT FUNDS"
      end
      
      local textCol = canAfford and Color(255, 255, 255) or Color(180, 180, 190)

      -- Text shadow
      if canAfford then
        draw.SimpleText(text, "DermaDefaultBold", w / 2 + 1, h / 2 - 9, Color(0, 0, 0, 150), TEXT_ALIGN_CENTER,
          TEXT_ALIGN_CENTER)
      end
      draw.SimpleText(text, "DermaDefaultBold", w / 2, h / 2 - 10, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

      -- Price
      local priceCol = canAfford and Color(230, 255, 230) or Color(160, 160, 170)
      draw.SimpleText(IonRP.Util:FormatMoney(property.price), "DermaDefault", w / 2, h / 2 + 10, priceCol,
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    buyBtn.DoClick = function()
      if isOwned then
        chat.AddText(Color(255, 100, 100), "[IonRP] ", Color(255, 255, 255), "This property is already owned!")
        surface.PlaySound("buttons/button10.wav")
        return
      end
      
      if not canAfford then
        chat.AddText(Color(255, 100, 100), "[IonRP] ", Color(255, 255, 255), "You cannot afford this property!")
        surface.PlaySound("buttons/button10.wav")
        return
      end

      -- Show confirmation dialog
      self:ShowPurchaseConfirmation(property)
    end
  end

  -- No properties message
  if #properties == 0 then
    local noPropLabel = vgui.Create("DLabel", scroll)
    noPropLabel:SetText("No properties available in this category")
    noPropLabel:SetFont("DermaLarge")
    noPropLabel:SetTextColor(cfg.Colors.TextMuted)
    noPropLabel:SetContentAlignment(5)
    noPropLabel:Dock(TOP)
    noPropLabel:SetTall(100)
  end
end

--- Show purchase confirmation dialog
--- @param property Property The property to purchase
function IonRP.PropertyShop.UI:ShowPurchaseConfirmation(property)
  local cfg = self.Config

  local dialog = vgui.Create("DFrame")
  dialog:SetSize(450, 250)
  dialog:Center()
  dialog:SetTitle("")
  dialog:SetDraggable(false)
  dialog:ShowCloseButton(false)
  dialog:MakePopup()

  dialog.Paint = function(self, w, h)
    -- Shadow
    for i = 1, 4 do
      local alpha = 50 - (i * 10)
      draw.RoundedBox(10, -i, -i, w + (i * 2), h + (i * 2), Color(0, 0, 0, alpha))
    end

    -- Background
    draw.RoundedBox(10, 0, 0, w, h, cfg.Colors.Background)

    -- Gradient overlay
    surface.SetDrawColor(cfg.Colors.Header)
    surface.DrawRect(0, 0, w, 60)

    -- Border glow
    surface.SetDrawColor(cfg.Colors.AccentCyan)
    surface.DrawOutlinedRect(0, 0, w, h, 2)

    surface.SetDrawColor(cfg.Colors.AccentCyan.r, cfg.Colors.AccentCyan.g, cfg.Colors.AccentCyan.b, 40)
    surface.DrawOutlinedRect(1, 1, w - 2, h - 2, 1)
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
  message:SetText(string.format("Are you sure you want to purchase %s for %s?",
    property.name, IonRP.Util:FormatMoney(property.price)))
  message:SetFont("DermaDefault")
  message:SetTextColor(cfg.Colors.TextDim)
  message:SetWrap(true)
  message:SetAutoStretchVertical(true)

  -- Warning
  local warning = vgui.Create("DLabel", dialog)
  warning:SetPos(16, 110)
  warning:SetWide(418)
  warning:SetText("Ownership is temporary and will be reset on server restart. Funds will be deducted from your bank account.")
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
    local isHovered = self:IsHovered()
    local col = Color(60, 60, 70, 230)
    if isHovered then
      col = Color(80, 80, 90, 250)
    end

    -- Shadow
    draw.RoundedBox(8, 1, 1, w, h, Color(0, 0, 0, 120))

    -- Background
    draw.RoundedBox(8, 0, 0, w, h, col)

    -- Border
    surface.SetDrawColor(100, 100, 110, isHovered and 200 or 120)
    surface.DrawOutlinedRect(0, 0, w, h, 1)

    -- Text
    draw.SimpleText("CANCEL", "DermaDefaultBold", w / 2 + 1, h / 2 + 1, Color(0, 0, 0, 100), TEXT_ALIGN_CENTER,
      TEXT_ALIGN_CENTER)
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
    local isHovered = self:IsHovered()
    local col = cfg.Colors.ButtonBuy
    if isHovered then
      col = cfg.Colors.ButtonBuyHover
    end

    -- Shadow
    draw.RoundedBox(8, 1, 1, w, h, Color(0, 0, 0, 120))

    -- Background
    draw.RoundedBox(8, 0, 0, w, h, col)

    -- Glow effect
    surface.SetDrawColor(cfg.Colors.ButtonBuy.r, cfg.Colors.ButtonBuy.g, cfg.Colors.ButtonBuy.b, isHovered and 150 or 80)
    surface.DrawOutlinedRect(0, 0, w, h, 2)

    -- Inner highlight
    if isHovered then
      surface.SetDrawColor(255, 255, 255, 30)
      surface.DrawRect(5, 5, w - 10, 2)
    end

    -- Text with shadow
    draw.SimpleText("✓ CONFIRM PURCHASE", "DermaDefaultBold", w / 2 + 1, h / 2 + 1, Color(0, 0, 0, 150),
      TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("✓ CONFIRM PURCHASE", "DermaDefaultBold", w / 2, h / 2, cfg.Colors.Text, TEXT_ALIGN_CENTER,
      TEXT_ALIGN_CENTER)
  end

  confirmBtn.DoClick = function()
    net.Start("IonRP_PropertyShop_Purchase")
    net.WriteInt(property.id, 32)
    net.SendToServer()
    surface.PlaySound("buttons/button15.wav")
    dialog:Close()
    self:Close()
  end
end

--- Close the property shop
function IonRP.PropertyShop.UI:Close()
  if IsValid(self.Frame) then
    self.Frame:AlphaTo(0, 0.2, 0, function()
      if IsValid(self.Frame) then
        self.Frame:Remove()
      end
    end)
  end
end

-- Network receivers
net.Receive("IonRP_PropertyShop_Open", function()
  IonRP.PropertyShop.UI:Open()
end)

-- Console command
concommand.Add("ionrp_propertyshop", function()
  IonRP.PropertyShop.UI:Open()
end)

print("[IonRP Property Shop] Client-side UI loaded")
