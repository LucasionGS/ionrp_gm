--[[
    IonRP Shop System - Client
    Shop UI with IonRP styling
]] --

include("sh_shop.lua")

IonRP.ShopUI = IonRP.ShopUI or {}

-- Config
IonRP.ShopUI.Config = {
  ItemSize = 120,
  ItemPadding = 8,
  HeaderHeight = 100,
  FooterHeight = 50,
  Padding = 12,

  Colors = {
    Background = Color(25, 25, 35, 250),
    Header = Color(45, 35, 60, 255),
    ItemBackground = Color(35, 35, 45, 200),
    ItemHover = Color(55, 50, 70, 230),
    ItemBorder = Color(60, 50, 80, 200),

    BuyButton = Color(70, 180, 70, 200),
    BuyButtonHover = Color(90, 200, 90, 230),
    SellButton = Color(180, 70, 70, 200),
    SellButtonHover = Color(200, 90, 90, 230),

    Divider = Color(100, 80, 120, 100),
    Text = Color(255, 255, 255, 255),
    TextDim = Color(200, 200, 210, 255),
    TextMuted = Color(160, 160, 175, 255),
    Accent = Color(120, 100, 255, 255),
    AccentCyan = Color(100, 200, 255, 255),
    AccentGreen = Color(100, 255, 150, 255),
    Border = Color(100, 200, 255, 220),
  }
}

--- Format money for display
--- @param amount number
--- @return string
local function FormatMoney(amount)
  local formatted = tostring(amount)
  local k
  while true do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    if k == 0 then break end
  end
  return "$" .. formatted
end

--- Receive shop open request from server
net.Receive("IonRP_Shop_Open", function()
  local shopIdentifier = net.ReadString()
  local shopName = net.ReadString()
  local shopDescription = net.ReadString()
  local taxRate = net.ReadFloat()
  local itemCount = net.ReadUInt(16)

  local items = {}
  for i = 1, itemCount do
    local identifier = net.ReadString()
    local hasBuyPrice = net.ReadBool()
    local buyPrice = hasBuyPrice and net.ReadUInt(32) or nil
    local hasSellPrice = net.ReadBool()
    local sellPrice = hasSellPrice and net.ReadUInt(32) or nil

    table.insert(items, {
      identifier = identifier,
      buyPrice = buyPrice,
      sellPrice = sellPrice
    })
  end

  IonRP.ShopUI:Open(shopIdentifier, shopName, shopDescription, taxRate, items)
end)

--- Open shop UI
--- @param shopIdentifier string
--- @param shopName string
--- @param shopDescription string
--- @param taxRate number
--- @param items table
function IonRP.ShopUI:Open(shopIdentifier, shopName, shopDescription, taxRate, items)
  if IsValid(self.Frame) then
    self.Frame:Remove()
  end

  local cfg = self.Config
  local scrW, scrH = ScrW(), ScrH()

  -- Calculate frame size
  local frameWidth = math.min(scrW * 0.8, 1200)
  local frameHeight = math.min(scrH * 0.8, 800)

  -- Main frame
  local frame = vgui.Create("DFrame")
  frame:SetSize(frameWidth, frameHeight)
  frame:Center()
  frame:SetTitle("")
  frame:SetDraggable(false)
  frame:ShowCloseButton(false)
  frame:MakePopup()
  self.Frame = frame

  frame.Paint = function(self, w, h)
    -- Shadow
    draw.RoundedBox(8, 3, 3, w, h, Color(0, 0, 0, 100))

    -- Main background
    draw.RoundedBox(8, 0, 0, w, h, cfg.Colors.Background)

    -- Border
    surface.SetDrawColor(cfg.Colors.Border)
    surface.DrawOutlinedRect(0, 0, w, h, 3)

    -- Top accent
    draw.RoundedBoxEx(8, 0, 0, w, 3, cfg.Colors.Border, true, true, false, false)
  end

  -- Header
  local header = vgui.Create("DPanel", frame)
  header:Dock(TOP)
  header:SetTall(cfg.HeaderHeight)
  header:DockMargin(0, 0, 0, cfg.Padding)

  header.Paint = function(self, w, h)
    draw.RoundedBoxEx(8, 0, 0, w, h, cfg.Colors.Header, true, true, false, false)

    -- Animated gradient
    local time = CurTime()
    for i = 0, 10 do
      local x = (w / 10 * i + math.sin(time * 2 + i) * 20) % w
      local y = 5 + math.sin(time * 3 + i * 0.5) * 8
      local size = 2 + math.sin(time * 4 + i) * 1.5
      local hue = (i * 36 + time * 100) % 360
      local col = HSVToColor(hue, 0.7, 1)
      col.a = 120
      draw.NoTexture()
      surface.SetDrawColor(col)
      surface.DrawTexturedRectRotated(x, y, size, size, time * 50 + i * 10)
    end
  end

  -- Shop name
  local titleLabel = vgui.Create("DLabel", header)
  titleLabel:SetText(shopName)
  titleLabel:SetFont("DermaLarge")
  titleLabel:SetTextColor(cfg.Colors.Text)
  titleLabel:SizeToContents()
  titleLabel:SetPos(cfg.Padding, 15)

  -- Description
  local descLabel = vgui.Create("DLabel", header)
  descLabel:SetText(shopDescription)
  descLabel:SetFont("DermaDefault")
  descLabel:SetTextColor(cfg.Colors.TextDim)
  descLabel:SizeToContents()
  descLabel:SetPos(cfg.Padding, 45)

  -- Player money info
  local ply = LocalPlayer()
  local moneyLabel = vgui.Create("DLabel", header)
  moneyLabel:SetFont("DermaDefault")
  moneyLabel:SetTextColor(cfg.Colors.AccentGreen)

  moneyLabel.Think = function(self)
    local wallet = ply:GetWallet()
    self:SetText("Wallet: " .. FormatMoney(wallet))
    self:SizeToContents()
    self:SetPos(frameWidth - self:GetWide() - cfg.Padding * 4, 15)
  end

  -- Tax info
  if taxRate > 0 then
    local taxLabel = vgui.Create("DLabel", header)
    taxLabel:SetText(string.format("Tax: %.1f%%", taxRate * 100))
    taxLabel:SetFont("DermaDefault")
    taxLabel:SetTextColor(cfg.Colors.TextMuted)
    taxLabel:SizeToContents()
    taxLabel:SetPos(frameWidth - taxLabel:GetWide() - cfg.Padding, 45)
  end

  -- Close button
  local closeBtn = vgui.Create("DButton", header)
  closeBtn:SetText("✕")
  closeBtn:SetFont("DermaLarge")
  closeBtn:SetTextColor(cfg.Colors.Text)
  closeBtn:SetSize(30, 30)
  closeBtn:SetPos(frameWidth - 40, 10)

  closeBtn.Paint = function(self, w, h)
    local col = self:IsHovered() and Color(200, 70, 70, 230) or Color(150, 50, 50, 200)
    draw.RoundedBox(4, 0, 0, w, h, col)
  end

  closeBtn.DoClick = function()
    frame:Close()
  end

  -- Scroll panel for items
  local scroll = vgui.Create("DScrollPanel", frame)
  scroll:Dock(FILL)
  scroll:DockMargin(cfg.Padding, 0, cfg.Padding, cfg.Padding)

  -- Custom scrollbar
  local sbar = scroll:GetVBar()
  sbar:SetWide(8)
  sbar:SetHideButtons(true)

  function sbar:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 30, 220))
  end

  function sbar.btnGrip:Paint(w, h)
    local time = CurTime()
    for i = 0, h, 4 do
      local hue = ((i / h * 180) + (time * 80)) % 360
      local col = HSVToColor(hue, 0.7, 1)
      col.a = 220
      surface.SetDrawColor(col)
      surface.DrawRect(0, i, w, 4)
    end
  end

  -- Icon layout for items
  local iconLayout = vgui.Create("DIconLayout", scroll)
  iconLayout:Dock(FILL)
  iconLayout:SetSpaceX(cfg.ItemPadding)
  iconLayout:SetSpaceY(cfg.ItemPadding)

  -- Create shop
  local shop = {
    identifier = shopIdentifier,
    taxRate = taxRate
  }

  -- Create item panels
  for _, shopItem in ipairs(items) do
    self:CreateItemPanel(iconLayout, shop, shopItem)
  end
end

--- Create an item panel
--- @param parent Panel
--- @param shop table
--- @param shopItem table
function IonRP.ShopUI:CreateItemPanel(parent, shop, shopItem)
  local cfg = self.Config
  local itemDef = IonRP.Items.List[shopItem.identifier]

  if not itemDef then
    print("[IonRP Shop] Unknown item: " .. shopItem.identifier)
    return
  end

  -- Calculate prices with tax
  local buyPrice = shopItem.buyPrice and math.floor(shopItem.buyPrice + (shopItem.buyPrice * shop.taxRate)) or nil
  local sellPrice = shopItem.sellPrice

  -- Item container
  local itemPanel = vgui.Create("DPanel", parent)
  itemPanel:SetSize(cfg.ItemSize, cfg.ItemSize + 50)

  itemPanel.Paint = function(self, w, h)
    local bgCol = self:IsHovered() and cfg.Colors.ItemHover or cfg.Colors.ItemBackground
    draw.RoundedBox(6, 0, 0, w, h, bgCol)

    -- Border
    surface.SetDrawColor(cfg.Colors.ItemBorder)
    surface.DrawOutlinedRect(0, 0, w, h, 2)

    -- Glow on hover
    if self:IsHovered() then
      local time = CurTime()
      local pulse = math.abs(math.sin(time * 3)) * 0.5 + 0.5
      local glowCol = Color(cfg.Colors.Accent.r, cfg.Colors.Accent.g, cfg.Colors.Accent.b, 40 * pulse)
      draw.RoundedBox(6, -2, -2, w + 4, h + 4, glowCol)
    end
  end

  -- Model icon
  local icon = vgui.Create("DModelPanel", itemPanel)
  icon:SetSize(cfg.ItemSize, cfg.ItemSize)
  icon:SetPos(0, 0)

  -- Precache and set model
  if itemDef.model and itemDef.model ~= "" then
    util.PrecacheModel(itemDef.model)
    icon:SetModel(itemDef.model)
  else
    -- Fallback model
    icon:SetModel("models/error.mdl")
  end

  -- Store rotation angle for mouse dragging
  icon.ModelRotation = 0
  icon.IsDragging = false
  icon.LastMouseX = 0
  icon.CameraSetup = false

  -- Initial camera setup (fallback values)
  icon:SetCamPos(Vector(50, 50, 40))
  icon:SetLookAt(Vector(0, 0, 0))
  icon:SetFOV(45)

  -- Set up camera position once entity is spawned
  function icon:SetupCamera()
    if self.CameraSetup then return end

    local ent = self:GetEntity()
    if not IsValid(ent) then return end

    local mins, maxs = ent:GetRenderBounds()
    if not mins or not maxs then return end

    local size = maxs - mins
    local radius = math.max(size.x, size.y, size.z)

    if radius > 0 then
      local distance = radius * 2.5
      self:SetCamPos(Vector(distance, distance, distance * 0.5))
      self:SetLookAt((mins + maxs) / 2)
      self:SetFOV(45)
      self.CameraSetup = true
    end
  end

  -- Mouse drag to rotate
  icon.OnMousePressed = function(self, keyCode)
    if keyCode == MOUSE_LEFT then
      self.IsDragging = true
      self.LastMouseX = gui.MouseX()
      return true
    end
  end

  icon.OnMouseReleased = function(self, keyCode)
    if keyCode == MOUSE_LEFT then
      self.IsDragging = false
    end
  end

  icon.Think = function(self)
    -- Set up camera once entity is ready
    if not self.CameraSetup then
      self:SetupCamera()
    end

    if self.IsDragging then
      local mouseX = gui.MouseX()
      local delta = mouseX - self.LastMouseX
      self.ModelRotation = self.ModelRotation + (delta * 0.5)
      self.LastMouseX = mouseX
    else
      -- Auto-rotate when not dragging
      self.ModelRotation = self.ModelRotation + (FrameTime() * 30)
    end
  end

  -- Animated rotation with drag support
  icon.LayoutEntity = function(self, ent)
    if not IsValid(ent) then return end

    -- Ensure model is visible
    ent:SetColor(Color(255, 255, 255, 255))
    ent:SetSkin(0)
    ent:SetAngles(Angle(0, self.ModelRotation, 0))
  end

  -- Background with model rendering
  icon.PaintOver = function(self, w, h)
    -- Subtle gradient overlay at bottom
    surface.SetDrawColor(60, 50, 80, 80)
    surface.DrawRect(0, h * 0.75, w, h * 0.25)

    -- Hint text on hover
    if self:IsHovered() and not self.IsDragging then
      draw.SimpleText("Drag to rotate", "DermaDefault", w / 2, h - 10,
        Color(200, 200, 210, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
  end

  -- Set lighting for better visibility
  icon:SetAmbientLight(Color(255, 255, 255))
  icon:SetDirectionalLight(BOX_TOP, Color(255, 255, 255))
  icon:SetDirectionalLight(BOX_FRONT, Color(200, 200, 255))

  -- Item name
  local nameLabel = vgui.Create("DLabel", itemPanel)
  nameLabel:SetText(itemDef.name)
  nameLabel:SetFont("DermaDefaultBold")
  nameLabel:SetTextColor(cfg.Colors.Text)
  nameLabel:SizeToContents()
  nameLabel:SetPos((cfg.ItemSize - nameLabel:GetWide()) / 2, cfg.ItemSize + 5)

  -- Price label
  local priceLabel = vgui.Create("DLabel", itemPanel)
  local priceText = ""
  if buyPrice then
    priceText = "Buy: " .. FormatMoney(buyPrice)
  end
  if sellPrice then
    if priceText ~= "" then priceText = priceText .. " | " end
    priceText = priceText .. "Sell: " .. FormatMoney(sellPrice)
  end
  if priceText == "" then
    priceText = "No price"
  end

  priceLabel:SetText(priceText)
  priceLabel:SetFont("DermaDefault")
  priceLabel:SetTextColor(cfg.Colors.TextDim)
  priceLabel:SizeToContents()
  priceLabel:SetPos((cfg.ItemSize - priceLabel:GetWide()) / 2, cfg.ItemSize + 25)

  -- Click handlers
  itemPanel.OnMousePressed = function(self, keyCode)
    if keyCode == MOUSE_LEFT and buyPrice then
      -- Buy single
      self:BuyItem(shop, shopItem, itemDef, 1)
    elseif keyCode == MOUSE_RIGHT then
      -- Open context menu
      self:OpenContextMenu(shop, shopItem, itemDef, buyPrice, sellPrice)
    end
  end

  -- Buy item function
  itemPanel.BuyItem = function(self, shop, shopItem, itemDef, quantity)
    net.Start("IonRP_Shop_Buy")
    net.WriteString(shop.identifier)
    net.WriteString(shopItem.identifier)
    net.WriteUInt(quantity, 16)
    net.SendToServer()
  end

  -- Sell item function
  itemPanel.SellItem = function(self, shop, shopItem, itemDef, quantity)
    net.Start("IonRP_Shop_Sell")
    net.WriteString(shop.identifier)
    net.WriteString(shopItem.identifier)
    net.WriteUInt(quantity, 16)
    net.SendToServer()
  end

  -- Context menu
  itemPanel.OpenContextMenu = function(self, shop, shopItem, itemDef, buyPrice, sellPrice)
    local menu = DermaMenu()
    menu:SetMinimumWidth(150)

    if buyPrice then
      menu:AddOption("Buy 1x - " .. FormatMoney(buyPrice), function()
        self:BuyItem(shop, shopItem, itemDef, 1)
      end):SetIcon("icon16/cart_add.png")

      menu:AddOption("Buy Bulk...", function()
        IonRP.Dialog:RequestString("Buy Items", "How many would you like to buy?", "1", function(value)
          local amount = tonumber(value)
          if amount and amount > 0 then
            self:BuyItem(shop, shopItem, itemDef, amount)
          end
        end)
      end):SetIcon("icon16/cart_add.png")

      menu:AddSpacer()
    end

    if sellPrice then
      local ply = LocalPlayer()
      local inv = ply.IonRP_ClientInventory
      local hasAmount = inv and inv:CountItem(itemDef) or 0

      if hasAmount > 0 then
        menu:AddOption("Sell 1x - " .. FormatMoney(sellPrice), function()
          self:SellItem(shop, shopItem, itemDef, 1)
        end):SetIcon("icon16/coins.png")

        if hasAmount > 1 then
          menu:AddOption("Sell Bulk...", function()
            IonRP.Dialog:RequestString("Sell Items", "How many would you like to sell? (You have " .. hasAmount .. ")",
              "1", function(value)
              local amount = tonumber(value)
              if amount and amount > 0 then
                self:SellItem(shop, shopItem, itemDef, math.min(amount, hasAmount))
              end
            end)
          end):SetIcon("icon16/coins.png")

          menu:AddOption("Sell All (" .. hasAmount .. "x) - " .. FormatMoney(sellPrice * hasAmount), function()
            self:SellItem(shop, shopItem, itemDef, hasAmount)
          end):SetIcon("icon16/coins.png")
        end
      else
        local opt = menu:AddOption("(You don't own any)", function() end)
        opt:SetEnabled(false)
      end
    end

    menu:Open()
  end

  -- Tooltip
  itemPanel:SetTooltip(itemDef.description)
end

--- Close shop UI
function IonRP.ShopUI:Close()
  if IsValid(self.Frame) then
    self.Frame:Close()
  end
end

print("[IonRP Shop] Client module loaded")
