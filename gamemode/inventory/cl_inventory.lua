--[[
    IonRP Inventory System - Client
    Modern UI with drag & drop, tooltips, and realistic design
]]--

include("sh_inventory.lua")

IonRP.InventoryUI = IonRP.InventoryUI or {}

-- Configuration
local Config = {
  SlotSize = 100,
  SlotGap = 3,
  TabHeight = 50,
  EquipmentWidth = 320,
  Padding = 15,
  
  Colors = {
    Background = Color(10, 10, 12, 250),
    TabBar = Color(15, 15, 18, 255),
    TabActive = Color(25, 28, 32, 255),
    TabInactive = Color(15, 15, 18, 200),
    SlotEmpty = Color(18, 18, 22, 200),
    SlotHover = Color(35, 38, 42, 220),
    SlotOccupied = Color(22, 24, 28, 240),
    SlotValid = Color(40, 60, 40, 180),
    SlotInvalid = Color(60, 30, 30, 180),
    Border = Color(40, 42, 46, 255),
    BorderDark = Color(8, 8, 10, 255),
    Text = Color(200, 205, 210, 255),
    TextDim = Color(140, 145, 150, 255),
    TextBright = Color(255, 255, 255, 255),
    Accent = Color(80, 140, 200, 255),
    WeightGood = Color(80, 160, 100, 255),
    WeightWarn = Color(220, 160, 80, 255),
    WeightBad = Color(200, 80, 80, 255),
  }
}

-- State
local State = {
  inventory = nil,
  frame = nil,
  draggedItem = nil,
  dragStartX = nil,
  dragStartY = nil,
  dragQuantity = nil,
  mouseDownSlot = nil,
  tooltipItem = nil,
  tooltipPos = {x = 0, y = 0},
  activeTab = "Inventory", -- Track active tab
  mixturesScroll = nil, -- Store mixtures scroll panel
}

--- Receive inventory sync
net.Receive("IonRP_Inventory_Sync", function()
  local data = net.ReadTable()
  
  -- Reconstruct inventory
  local inv = IonRP.Inventory.New(data.width, data.height, data.maxWeight)
  
  for _, itemData in ipairs(data.items) do
    local item = IonRP.Items.List[itemData.identifier]
    if item then
      inv:AddItem(item, itemData.quantity, itemData.x, itemData.y)
    end
  end
  
  State.inventory = inv
  LocalPlayer().IonRP_ClientInventory = inv
  
  -- Refresh UI if open - update the active tab
  if IsValid(State.frame) and State.activeTab then
    IonRP.InventoryUI:SwitchTab(State.activeTab)
  end
end)

--- Open inventory UI
net.Receive("IonRP_Inventory_Open", function()
  timer.Simple(0.05, function()
    IonRP.InventoryUI:Open()
  end)
end)

--- Open inventory
function IonRP.InventoryUI:Open()
  if not State.inventory then
    chat.AddText(Color(255, 100, 100), "[Inventory] ", Color(255, 255, 255), "Loading...")
    return
  end
  
  if IsValid(State.frame) then
    State.frame:Remove()
  end
  
  local inv = State.inventory
  
  -- Calculate dimensions
  local gridWidth = inv.width * (Config.SlotSize + Config.SlotGap) + Config.SlotGap
  local gridHeight = inv.height * (Config.SlotSize + Config.SlotGap) + Config.SlotGap
  local frameW = gridWidth + Config.EquipmentWidth + Config.Padding * 3
  local frameH = gridHeight + Config.TabHeight + Config.Padding * 2 + 30 -- 30 for instruction text
  
  -- Main frame
  local frame = vgui.Create("DFrame")
  frame:SetSize(frameW, frameH)
  frame:Center()
  frame:SetTitle("")
  frame:SetDraggable(true)
  frame:ShowCloseButton(false)
  frame:MakePopup()
  State.frame = frame
  
  frame.Paint = function(self, w, h)
    -- Dark background
    draw.RoundedBox(0, 0, 0, w, h, Config.Colors.Background)
    
    -- Outer border
    surface.SetDrawColor(Config.Colors.BorderDark)
    surface.DrawOutlinedRect(0, 0, w, h, 2)
    
    -- Inner border accent
    surface.SetDrawColor(Config.Colors.Border)
    surface.DrawOutlinedRect(2, 2, w - 4, h - 4, 1)
  end
  
  -- Tab bar
  self:CreateTabBar(frame, frameW)
  
  -- Content container
  local content = vgui.Create("DPanel", frame)
  content:SetPos(0, Config.TabHeight)
  content:SetSize(frameW, frameH - Config.TabHeight)
  content.Paint = function() end
  State.contentPanel = content
  
  -- Inventory grid (left side)
  local gridContainer = vgui.Create("DPanel", content)
  gridContainer:SetPos(Config.Padding, Config.Padding)
  gridContainer:SetSize(gridWidth, gridHeight)
  gridContainer.Paint = function(self, w, h)
    -- Instruction text at top
    draw.SimpleText("Scroll over an item to see it's description.", "DermaDefault", w / 2, -25, Config.Colors.TextDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
  end
  
  State.gridContainer = gridContainer -- Store reference
  self:CreateGrid(gridContainer)
  
  -- Equipment panel (right side)
  self:CreateEquipmentPanel(content, gridWidth + Config.Padding * 2, Config.Padding, Config.EquipmentWidth, gridHeight)
  
  -- Bottom instruction
  local instrY = Config.TabHeight + gridHeight + Config.Padding * 2 + 10
  frame.PaintOver = function(self, w, h)
    draw.SimpleText("Left Click: Use | Drag: Move | Right Drag: Move 1", "DermaDefault", w / 2, h - 15, Config.Colors.TextDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end
  
  -- Initialize with last active tab (default to Inventory if none set)
  local lastTab = State.activeTab or "Inventory"
  self:SwitchTab(lastTab)
end

--- Create tab bar
function IonRP.InventoryUI:CreateTabBar(parent, width)
  local tabBar = vgui.Create("DPanel", parent)
  tabBar:SetPos(0, 0)
  tabBar:SetSize(width, Config.TabHeight)
  
  tabBar.Paint = function(self, w, h)
    draw.RoundedBox(0, 0, 0, w, h, Config.Colors.TabBar)
    
    -- Bottom border
    surface.SetDrawColor(Config.Colors.BorderDark)
    surface.DrawLine(0, h - 1, w, h - 1)
  end
  
  local tabs = {"Inventory", "Mixtures", "Skills", "Genetics"}
  local tabWidth = 120
  local tabX = 10
  
  for i, tabName in ipairs(tabs) do
    local tab = vgui.Create("DButton", tabBar)
    tab:SetPos(tabX, 5)
    tab:SetSize(tabWidth, Config.TabHeight - 10)
    tab:SetText("")
    
    tab.Paint = function(self, w, h)
      local isActive = (State.activeTab == tabName)
      local bgColor = isActive and Config.Colors.TabActive or Config.Colors.TabInactive
      
      if self:IsHovered() and not isActive then
        bgColor = Color(20, 22, 26, 220)
      end
      
      draw.RoundedBoxEx(4, 0, 0, w, h + 4, bgColor, true, true, false, false)
      
      -- Border
      surface.SetDrawColor(Config.Colors.Border)
      surface.DrawLine(0, 0, w, 0) -- Top
      surface.DrawLine(0, 0, 0, h) -- Left
      surface.DrawLine(w - 1, 0, w - 1, h) -- Right
      
      -- Text
      local textColor = isActive and Config.Colors.TextBright or Config.Colors.TextDim
      draw.SimpleText(tabName, "DermaDefault", w / 2, h / 2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    tab.DoClick = function()
      State.activeTab = tabName
      IonRP.InventoryUI:SwitchTab(tabName)
    end
    
    tabX = tabX + tabWidth + 5
  end
end

--- Switch between tabs
function IonRP.InventoryUI:SwitchTab(tabName)
  if not IsValid(State.contentPanel) then return end
  
  -- Clear content panel
  State.contentPanel:Clear()
  
  if tabName == "Inventory" then
    self:ShowInventoryTab()
  elseif tabName == "Mixtures" then
    self:ShowMixturesTab()
  else
    -- Coming soon tabs
    local label = vgui.Create("DLabel", State.contentPanel)
    label:SetText(tabName .. " coming soon!")
    label:SetFont("DermaLarge")
    label:SetTextColor(Config.Colors.TextDim)
    label:SizeToContents()
    label:Center()
  end
end

--- Show inventory tab content
function IonRP.InventoryUI:ShowInventoryTab()
  if not State.inventory then return end
  
  local inv = State.inventory
  local gridWidth = inv.width * (Config.SlotSize + Config.SlotGap) + Config.SlotGap
  local gridHeight = inv.height * (Config.SlotSize + Config.SlotGap) + Config.SlotGap
  
  -- Inventory grid (left side)
  local gridContainer = vgui.Create("DPanel", State.contentPanel)
  gridContainer:SetPos(Config.Padding, Config.Padding)
  gridContainer:SetSize(gridWidth, gridHeight)
  gridContainer.Paint = function(self, w, h)
    draw.SimpleText("Scroll over an item to see it's description.", "DermaDefault", w / 2, -25, Config.Colors.TextDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
  end
  
  State.gridContainer = gridContainer
  self:CreateGrid(gridContainer)
  
  -- Equipment panel (right side)
  self:CreateEquipmentPanel(State.contentPanel, gridWidth + Config.Padding * 2, Config.Padding, Config.EquipmentWidth, gridHeight)
end

--- Show mixtures tab content
function IonRP.InventoryUI:ShowMixturesTab()
  if not State.inventory then return end
  
  local inv = State.inventory
  local gridHeight = inv.height * (Config.SlotSize + Config.SlotGap) + Config.SlotGap
  local contentWidth = State.contentPanel:GetWide() - Config.Padding * 2
  
  -- Mixtures scroll panel
  local scroll = vgui.Create("DScrollPanel", State.contentPanel)
  scroll:SetPos(Config.Padding, Config.Padding)
  scroll:SetSize(contentWidth, gridHeight)
  State.mixturesScroll = scroll
  
  -- Style the scrollbar
  local sbar = scroll:GetVBar()
  sbar:SetWide(8)
  sbar.Paint = function(self, w, h)
    draw.RoundedBox(4, 0, 0, w, h, Color(15, 15, 18, 200))
  end
  sbar.btnGrip.Paint = function(self, w, h)
    draw.RoundedBox(4, 0, 0, w, h, Config.Colors.Border)
  end
  
  -- Get all recipes
  local recipes = IonRP.Recipes and IonRP.Recipes.List or {}
  local yPos = 0
  
  for identifier, recipe in pairs(recipes) do
    self:CreateRecipeEntry(scroll, recipe, yPos, contentWidth - 10)
    yPos = yPos + 90 -- Height of each entry + spacing
  end
end

--- Create a recipe entry panel
function IonRP.InventoryUI:CreateRecipeEntry(parent, recipe, yPos, width)
  local entry = vgui.Create("DPanel", parent)
  entry:SetPos(0, yPos)
  entry:SetSize(width, 85)
  
  -- Check if craftable (client-side guess based on inventory)
  local canCraft = true
  local missingItems = {}
  
  if recipe.ingredients then
    for itemId, amount in pairs(recipe.ingredients) do
      local hasAmount = State.inventory:CountItem(itemId)
      if hasAmount < amount then
        canCraft = false
        table.insert(missingItems, {id = itemId, need = amount, have = hasAmount})
      end
    end
  end
  
  local borderColor = canCraft and Color(80, 200, 100, 255) or Color(200, 80, 80, 255)
  
  entry.Paint = function(self, w, h)
    -- Background
    draw.RoundedBox(4, 0, 0, w, h, Color(22, 24, 28, 240))
    
    -- Border with color based on craftability
    surface.SetDrawColor(borderColor)
    surface.DrawOutlinedRect(0, 0, w, h, 2)
    
    -- Inner darker border
    surface.SetDrawColor(Config.Colors.BorderDark)
    surface.DrawOutlinedRect(2, 2, w - 4, h - 4, 1)
  end
  
  -- Icon (left side)
  local iconSize = 60
  if recipe.result then
    local resultItem = IonRP.Items.List[recipe.result]
    if resultItem and resultItem.model then
      local icon = vgui.Create("DModelPanel", entry)
      icon:SetPos(8, 12)
      icon:SetSize(iconSize, iconSize)
      icon:SetModel(resultItem.model)
      icon:SetFOV(45)
      icon:SetMouseInputEnabled(false)
      
      local ent = icon:GetEntity()
      if IsValid(ent) then
        local mins, maxs = ent:GetRenderBounds()
        local size = maxs - mins
        local radius = math.max(size.x, size.y, size.z)
        local offset = size / 2 + mins
        icon:SetCamPos(Vector(radius * 1.2, radius * 1.2, radius * 0.8))
        icon:SetLookAt(offset)
      end
    end
  end
  
  -- Name and price (top)
  local nameX = iconSize + 20
  
  local nameLabel = vgui.Create("DLabel", entry)
  nameLabel:SetPos(nameX, 8)
  nameLabel:SetFont("DermaDefaultBold")
  nameLabel:SetText(recipe.name or "Unknown Recipe")
  nameLabel:SetTextColor(Config.Colors.TextBright)
  nameLabel:SizeToContents()
  
  -- Required items (middle)
  local reqText = "Required Items: "
  if recipe.ingredients then
    local items = {}
    for itemId, amount in pairs(recipe.ingredients) do
      local item = IonRP.Items.List[itemId]
      local itemName = item and item.name or itemId
      table.insert(items, itemName .. " x " .. amount)
    end
    reqText = reqText .. table.concat(items, ", ")
  end
  
  local reqLabel = vgui.Create("DLabel", entry)
  reqLabel:SetPos(nameX, 28)
  reqLabel:SetFont("DermaDefault")
  reqLabel:SetText(reqText)
  reqLabel:SetTextColor(Config.Colors.Text)
  reqLabel:SetWide(width - nameX - 120)
  reqLabel:SetWrap(true)
  reqLabel:SetAutoStretchVertical(true)
  
  -- Required skills (bottom)
  if recipe.description then
    local descLabel = vgui.Create("DLabel", entry)
    descLabel:SetPos(nameX, 50)
    descLabel:SetFont("DermaDefault")
    descLabel:SetText(recipe.description)
    descLabel:SetTextColor(Config.Colors.TextDim)
    descLabel:SetWide(width - nameX - 120)
    descLabel:SetWrap(true)
  end
  
  -- Craft button (right side)
  local btn = vgui.Create("DButton", entry)
  btn:SetPos(width - 110, 25)
  btn:SetSize(100, 35)
  btn:SetText("")
  
  btn.Paint = function(self, w, h)
    local bgColor = canCraft and Color(60, 140, 80, 255) or Color(100, 100, 110, 255)
    
    if canCraft and self:IsHovered() then
      bgColor = Color(80, 180, 100, 255)
    end
    
    draw.RoundedBox(4, 0, 0, w, h, bgColor)
    
    -- Border
    surface.SetDrawColor(Config.Colors.BorderDark)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
    
    -- Text
    local btnText = canCraft and "CRAFT" or "LOCKED"
    draw.SimpleText(btnText, "DermaDefaultBold", w / 2, h / 2, Config.Colors.TextBright, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end
  
  btn.DoClick = function()
    if canCraft then
      -- Send craft request to server
      net.Start("IonRP_Inventory_Craft")
      net.WriteString(recipe.identifier)
      net.SendToServer()
    end
  end
end

--- Create equipment panel
function IonRP.InventoryUI:CreateEquipmentPanel(parent, x, y, w, h)
  local panel = vgui.Create("DPanel", parent)
  panel:SetPos(x, y)
  panel:SetSize(w, h)
  
  panel.Paint = function(self, pw, ph)
    -- Background
    draw.RoundedBox(0, 0, 0, pw, ph, Color(12, 12, 15, 240))
    
    -- Border
    surface.SetDrawColor(Config.Colors.BorderDark)
    surface.DrawOutlinedRect(0, 0, pw, ph, 1)
    
    -- Weapon slots section
    local weaponY = 10
    local slotH = 120
    
    -- MAIN weapon slot
    draw.SimpleText("MAIN", "DermaDefaultBold", pw / 2, weaponY, Config.Colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    local mainSlotY = weaponY + 25
    draw.RoundedBox(4, 10, mainSlotY, pw - 20, slotH, Config.Colors.SlotEmpty)
    surface.SetDrawColor(Config.Colors.Border)
    surface.DrawOutlinedRect(10, mainSlotY, pw - 20, slotH, 1)
    
    -- Weapon silhouette placeholder
    draw.SimpleText("No weapon", "DermaDefault", pw / 2, mainSlotY + slotH / 2, Config.Colors.TextDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- SIDEARM weapon slot
    local sidearmY = mainSlotY + slotH + 30
    draw.SimpleText("SIDEARM", "DermaDefaultBold", pw / 2, sidearmY, Config.Colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    local sidearmSlotY = sidearmY + 25
    draw.RoundedBox(4, 10, sidearmSlotY, pw - 20, slotH, Config.Colors.SlotEmpty)
    surface.SetDrawColor(Config.Colors.Border)
    surface.DrawOutlinedRect(10, sidearmSlotY, pw - 20, slotH, 1)
    
    -- Weapon silhouette placeholder
    draw.SimpleText("No weapon", "DermaDefault", pw / 2, sidearmSlotY + slotH / 2, Config.Colors.TextDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Weight info at bottom
    if State.inventory then
      local weight = State.inventory:GetWeight()
      local maxWeight = State.inventory.maxWeight
      local weightText = string.format("%.1f / %.1f KG", weight, maxWeight)
      
      local weightColor = Config.Colors.WeightGood
      if weight > maxWeight * 0.9 then
        weightColor = Config.Colors.WeightBad
      elseif weight > maxWeight * 0.7 then
        weightColor = Config.Colors.WeightWarn
      end
      
      local weightY = ph - 60
      draw.SimpleText("WEIGHT", "DermaDefault", pw / 2, weightY, Config.Colors.TextDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
      draw.SimpleText(weightText, "DermaDefaultBold", pw / 2, weightY + 18, weightColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
      
      -- Weight bar
      local barW = pw - 40
      local barH = 6
      local barX = 20
      local barY = weightY + 40
      
      draw.RoundedBox(2, barX, barY, barW, barH, Color(15, 15, 18, 255))
      
      local fillW = math.Clamp(barW * (weight / maxWeight), 0, barW)
      draw.RoundedBox(2, barX, barY, fillW, barH, weightColor)
    end
  end
end

--- Create header (deprecated - using tab bar now)
function IonRP.InventoryUI:CreateHeader(parent, width)
  local header = vgui.Create("DPanel", parent)
  header:Dock(TOP)
  header:SetTall(Config.HeaderHeight)
  header:DockMargin(0, 0, 0, Config.Padding)
  
  header.Paint = function(self, w, h)
    draw.RoundedBox(0, 0, 0, w, h, Config.Colors.Header)
    
    -- Bottom border
    surface.SetDrawColor(Config.Colors.Border)
    surface.DrawLine(0, h - 1, w, h - 1)
    
    -- Title
    draw.SimpleText("INVENTORY", "DermaLarge", Config.Padding, 15, Config.Colors.TextBright, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- Weight
    if State.inventory then
      local weight = State.inventory:GetWeight()
      local maxWeight = State.inventory.maxWeight
      local weightText = string.format("%.1f / %.1f KG", weight, maxWeight)
      
      local weightColor = Config.Colors.WeightGood
      if weight > maxWeight * 0.9 then
        weightColor = Config.Colors.WeightBad
      elseif weight > maxWeight * 0.7 then
        weightColor = Config.Colors.WeightWarn
      end
      
      draw.SimpleText(weightText, "DermaDefault", Config.Padding, 50, weightColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
      
      -- Weight bar
      local barW = 200
      local barH = 6
      local barX = Config.Padding
      local barY = 68
      
      draw.RoundedBox(2, barX, barY, barW, barH, Color(20, 20, 25, 255))
      
      local fillW = math.Clamp(barW * (weight / maxWeight), 0, barW)
      draw.RoundedBox(2, barX, barY, fillW, barH, weightColor)
    end
  end
  
  -- Close button
  local closeBtn = vgui.Create("DButton", header)
  closeBtn:SetPos(width - Config.Padding - 35, 15)
  closeBtn:SetSize(35, 35)
  closeBtn:SetText("")
  
  closeBtn.Paint = function(self, w, h)
    local col = self:IsHovered() and Color(255, 100, 100) or Config.Colors.Border
    draw.RoundedBox(4, 0, 0, w, h, col)
    
    surface.SetDrawColor(Config.Colors.TextBright)
    surface.DrawLine(10, 10, w - 10, h - 10)
    surface.DrawLine(w - 10, 10, 10, h - 10)
  end
  
  closeBtn.DoClick = function()
    IonRP.InventoryUI:Close()
  end
end

--- Create grid
function IonRP.InventoryUI:CreateGrid(parent)
  local inv = State.inventory
  if not inv then return end
  
  local gridW = inv.width * (Config.SlotSize + Config.SlotGap) + Config.SlotGap
  local gridH = inv.height * (Config.SlotSize + Config.SlotGap) + Config.SlotGap
  
  -- Clear ALL children from parent to ensure clean slate
  if IsValid(parent) then
    parent:Clear()
  end
  
  local grid = vgui.Create("DPanel", parent)
  grid:SetSize(gridW, gridH)
  grid:Center()
  grid.Paint = function() end
  
  State.gridPanel = grid
  
  -- Background layer - paint slot backgrounds FIRST (bottom layer)
  local bgLayer = vgui.Create("DPanel", grid)
  bgLayer:SetSize(gridW, gridH)
  bgLayer:SetMouseInputEnabled(false)
  
  bgLayer.Paint = function(self, w, h)
    -- Draw slot backgrounds
    for y = 0, inv.height - 1 do
      for x = 0, inv.width - 1 do
        local slotX = Config.SlotGap + x * (Config.SlotSize + Config.SlotGap)
        local slotY = Config.SlotGap + y * (Config.SlotSize + Config.SlotGap)
        
        local bgColor = Config.Colors.SlotEmpty
        
        -- Check if mouse is hovering this slot
        local mx, my = self:CursorPos()
        if mx >= slotX and mx <= slotX + Config.SlotSize and 
           my >= slotY and my <= slotY + Config.SlotSize then
          bgColor = Config.Colors.SlotHover
        end
        
        -- Drag preview
        if State.draggedItem then
          local invItem = inv:GetItemAt(x, y)
          if not (invItem and invItem == State.draggedItem) then
            local canPlace = inv:IsAreaFree(x, y, State.draggedItem.item.size[1], State.draggedItem.item.size[2], State.draggedItem)
            if canPlace then
              bgColor = Config.Colors.SlotValid
            elseif mx >= slotX and mx <= slotX + Config.SlotSize and 
                   my >= slotY and my <= slotY + Config.SlotSize then
              bgColor = Config.Colors.SlotInvalid
            end
          end
        end
        
        draw.RoundedBox(0, slotX, slotY, Config.SlotSize, Config.SlotSize, bgColor)
        
        -- Border
        surface.SetDrawColor(Config.Colors.BorderDark)
        surface.DrawOutlinedRect(slotX, slotY, Config.SlotSize, Config.SlotSize, 1)
      end
    end
  end
  
  -- Force background layer to redraw
  bgLayer:InvalidateLayout(true)
  
  -- Create slots (interactive layer - transparent)
  grid.slots = {}
  for y = 0, inv.height - 1 do
    grid.slots[y] = {}
    for x = 0, inv.width - 1 do
      local slot = self:CreateSlot(grid, x, y)
      grid.slots[y][x] = slot
    end
  end
  
  -- Store model panels for cleanup
  State.modelPanels = State.modelPanels or {}
  
  -- Clean up old model panels
  for _, mdl in pairs(State.modelPanels) do
    if IsValid(mdl) then
      mdl:Remove()
    end
  end
  State.modelPanels = {}
  
  -- Create model panels for each item (middle layer - visual)
  for _, invItem in ipairs(inv:GetItems()) do
    if invItem.item and invItem.item.model then
      local item = invItem.item
      local x = Config.SlotGap + invItem.x * (Config.SlotSize + Config.SlotGap)
      local y = Config.SlotGap + invItem.y * (Config.SlotSize + Config.SlotGap)
      local w = item.size[1] * (Config.SlotSize + Config.SlotGap) - Config.SlotGap
      local h = item.size[2] * (Config.SlotSize + Config.SlotGap) - Config.SlotGap
      
      local modelPanel = vgui.Create("DModelPanel", grid)
      modelPanel:SetPos(x + 4, y + 4)
      modelPanel:SetSize(w - 8, h - 8)
      modelPanel:SetModel(item.model)
      modelPanel:SetMouseInputEnabled(false)
      modelPanel:SetKeyboardInputEnabled(false)
      modelPanel:SetFOV(45)
      modelPanel:SetPaintedManually(false) -- Make sure it renders normally
      
      -- Store item reference
      modelPanel.ItemX = invItem.x
      modelPanel.ItemY = invItem.y
      modelPanel.Item = item
      
      -- Auto-fit the model
      local ent = modelPanel:GetEntity()
      if IsValid(ent) then
        local mins, maxs = ent:GetRenderBounds()
        local size = maxs - mins
        local radius = math.max(size.x, size.y, size.z)
        local offset = size / 2 + mins
        
        local distanceMultiplier = 1.3
        modelPanel:SetCamPos(Vector(radius * distanceMultiplier, radius * distanceMultiplier, radius * 0.8))
        modelPanel:SetLookAt(offset)
      end
      
      table.insert(State.modelPanels, modelPanel)
    end
  end
  
  -- Overlay for text/badges/drag preview (top layer - non-interactive)
  local overlay = vgui.Create("DPanel", grid)
  overlay:SetSize(gridW, gridH)
  overlay:SetMouseInputEnabled(false)
  
  overlay.Paint = function(self, w, h)
    -- Draw item overlays (quantity badges, type bars, borders)
    for _, invItem in ipairs(inv:GetItems()) do
      -- Hide model panel if being dragged
      local isDragged = State.draggedItem == invItem
      
      for _, mdl in pairs(State.modelPanels or {}) do
        if IsValid(mdl) and mdl.ItemX == invItem.x and mdl.ItemY == invItem.y then
          mdl:SetVisible(not isDragged)
        end
      end
      
      -- Draw only text/badges/bars, not backgrounds
      local item = invItem.item
      if not item or not item.size then continue end
      
      local x = Config.SlotGap + invItem.x * (Config.SlotSize + Config.SlotGap)
      local y = Config.SlotGap + invItem.y * (Config.SlotSize + Config.SlotGap)
      local w = item.size[1] * (Config.SlotSize + Config.SlotGap) - Config.SlotGap
      local h = item.size[2] * (Config.SlotSize + Config.SlotGap) - Config.SlotGap
      
      if not isDragged then
        -- Quantity badge (top-left corner)
        if invItem.quantity > 1 then
          local qtyText = tostring(invItem.quantity)
          surface.SetFont("DermaDefaultBold")
          local tw, th = surface.GetTextSize(qtyText)
          
          draw.RoundedBox(0, x + 4, y + 4, tw + 6, th + 4, Color(0, 0, 0, 220))
          draw.SimpleText(qtyText, "DermaDefaultBold", x + 7, y + 6, Config.Colors.TextBright, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
        
        -- Item type indicator (bottom bar)
        local typeColor = Color(100, 100, 110, 180)
        if item.type == "weapon" then
          typeColor = Color(200, 80, 80, 200)
        elseif item.type == "consumable" then
          typeColor = Color(80, 200, 100, 200)
        elseif item.type == "drug" then
          typeColor = Color(150, 80, 200, 200)
        elseif item.type == "material" then
          typeColor = Color(80, 150, 200, 200)
        end
        draw.RoundedBox(0, x + 2, y + h - 4, w - 4, 2, typeColor)
      end
    end
    
    -- Draw dragged item
    if State.draggedItem then
      local mx, my = self:CursorPos()
      self:DrawDraggedItem(State.draggedItem, mx, my)
    end
  end
  
  overlay.DrawItem = function(self, invItem, ghost)
    local item = invItem.item
    if not item or not item.size then return end
    
    local x = Config.SlotGap + invItem.x * (Config.SlotSize + Config.SlotGap)
    local y = Config.SlotGap + invItem.y * (Config.SlotSize + Config.SlotGap)
    local w = item.size[1] * (Config.SlotSize + Config.SlotGap) - Config.SlotGap
    local h = item.size[2] * (Config.SlotSize + Config.SlotGap) - Config.SlotGap
    
    local alpha = ghost and 120 or 255
    
    -- Background for occupied slots
    draw.RoundedBox(2, x + 2, y + 2, w - 4, h - 4, ColorAlpha(Config.Colors.SlotOccupied, alpha))
    
    -- Border
    surface.SetDrawColor(ColorAlpha(Config.Colors.Border, alpha))
    surface.DrawOutlinedRect(x + 2, y + 2, w - 4, h - 4, 1)
    
    -- Quantity badge (top-left corner like reference image)
    if invItem.quantity > 1 then
      local qtyText = tostring(invItem.quantity)
      surface.SetFont("DermaDefaultBold")
      local tw, th = surface.GetTextSize(qtyText)
      
      -- Small dark background
      draw.RoundedBox(0, x + 4, y + 4, tw + 6, th + 4, ColorAlpha(Color(0, 0, 0, 220), alpha))
      draw.SimpleText(qtyText, "DermaDefaultBold", x + 7, y + 6, ColorAlpha(Config.Colors.TextBright, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    
    -- Item type indicator (bottom bar)
    local typeColor = Color(100, 100, 110, 180)
    if item.type == "weapon" then
      typeColor = Color(200, 80, 80, 200)
    elseif item.type == "consumable" then
      typeColor = Color(80, 200, 100, 200)
    elseif item.type == "drug" then
      typeColor = Color(150, 80, 200, 200)
    elseif item.type == "material" then
      typeColor = Color(80, 150, 200, 200)
    end
    draw.RoundedBox(0, x + 2, y + h - 4, w - 4, 2, ColorAlpha(typeColor, alpha))
  end
  
  overlay.DrawDraggedItem = function(self, invItem, mx, my)
    local item = invItem.item
    if not item or not item.size then return end
    
    local w = item.size[1] * (Config.SlotSize + Config.SlotGap) - Config.SlotGap
    local h = item.size[2] * (Config.SlotSize + Config.SlotGap) - Config.SlotGap
    
    self:DrawItem({
      item = item,
      quantity = State.dragQuantity or invItem.quantity,
      x = (mx - w / 2 - Config.SlotGap) / (Config.SlotSize + Config.SlotGap),
      y = (my - h / 2 - Config.SlotGap) / (Config.SlotSize + Config.SlotGap)
    }, true)
  end
  
  grid.overlay = overlay
  State.gridPanel = grid
  
  -- Force overlay to redraw immediately
  overlay:InvalidateLayout(true)
  overlay:InvalidateParent(true)
end

--- Create slot
function IonRP.InventoryUI:CreateSlot(parent, x, y)
  local slot = vgui.Create("DPanel", parent)
  slot:SetPos(
    Config.SlotGap + x * (Config.SlotSize + Config.SlotGap),
    Config.SlotGap + y * (Config.SlotSize + Config.SlotGap)
  )
  slot:SetSize(Config.SlotSize, Config.SlotSize)
  slot.gridX = x
  slot.gridY = y
  
  slot.Paint = function(self, w, h)
    -- Don't paint anything - let the background grid and models show through
    -- Only handle hover state for tooltips
    local inv = State.inventory
    if not inv then return end
    
    local invItem = inv:GetItemAt(x, y)
    local isOrigin = invItem and invItem.x == x and invItem.y == y
    
    if self:IsHovered() and isOrigin then
      State.tooltipItem = invItem
      State.tooltipPos.x, State.tooltipPos.y = gui.MouseX(), gui.MouseY()
    end
  end
  
  slot.OnMousePressed = function(self, mouse)
    local inv = State.inventory
    if not inv then return end
    
    local invItem = inv:GetItemAt(x, y)
    if not invItem then return end
    
    local mx, my = input.GetCursorPos()
    State.mouseDownSlot = {x = x, y = y, item = invItem, button = mouse, startX = mx, startY = my}
  end
  
  slot.OnMouseReleased = function(self, mouse)
    local inv = State.inventory
    if not inv then return end
    
    if State.draggedItem then
      -- Drop item
      net.Start("IonRP_Inventory_Move")
      net.WriteUInt(State.dragStartX, 8)
      net.WriteUInt(State.dragStartY, 8)
      net.WriteUInt(x, 8)
      net.WriteUInt(y, 8)
      net.WriteUInt(State.dragQuantity or 0, 16)
      net.SendToServer()
      
      State.draggedItem = nil
      State.dragStartX = nil
      State.dragStartY = nil
      State.dragQuantity = nil
    elseif State.mouseDownSlot and State.mouseDownSlot.x == x and State.mouseDownSlot.y == y then
      -- Click to use
      if mouse == MOUSE_LEFT then
        local invItem = inv:GetItemAt(x, y)
        if invItem then
          net.Start("IonRP_Inventory_Use")
          net.WriteUInt(x, 8)
          net.WriteUInt(y, 8)
          net.SendToServer()
        end
      end
    end
    
    State.mouseDownSlot = nil
  end
  
  slot.Think = function(self)
    if State.mouseDownSlot and State.mouseDownSlot.x == x and State.mouseDownSlot.y == y then
      local mx, my = input.GetCursorPos()
      local startX = State.mouseDownSlot.startX or mx
      local startY = State.mouseDownSlot.startY or my
      local dist = math.sqrt((mx - startX)^2 + (my - startY)^2)
      
      if dist > 15 and not State.draggedItem then
        -- Start drag only after moving 15 pixels from initial position
        State.draggedItem = State.mouseDownSlot.item
        State.dragStartX = x
        State.dragStartY = y
        
        if State.mouseDownSlot.button == MOUSE_RIGHT then
          State.dragQuantity = 1
        end
      end
    end
    
    -- Clear tooltip if not hovering
    if not self:IsHovered() and State.tooltipItem then
      local anyHovered = false
      if IsValid(State.gridPanel) then
        for _, row in pairs(State.gridPanel.slots or {}) do
          for _, slot in pairs(row) do
            if IsValid(slot) and slot:IsHovered() then
              anyHovered = true
              break
            end
          end
        end
      end
      
      if not anyHovered then
        State.tooltipItem = nil
      end
    end
  end
  
  return slot
end

--- Refresh grid
function IonRP.InventoryUI:RefreshGrid()
  if not State.inventory or not IsValid(State.frame) then return end
  
  -- Force full repaint of overlay to show updated items
  if IsValid(State.gridPanel) and State.gridPanel.overlay then
    State.gridPanel.overlay:InvalidateLayout(true)
    State.gridPanel.overlay:InvalidateParent(true)
  end
end

--- Close inventory
function IonRP.InventoryUI:Close()
  -- Clean up model panels
  if State.modelPanels then
    for _, mdl in pairs(State.modelPanels) do
      if IsValid(mdl) then
        mdl:Remove()
      end
    end
    State.modelPanels = {}
  end
  
  if IsValid(State.frame) then
    State.frame:Remove()
    State.frame = nil
  end
  
  State.draggedItem = nil
  State.mouseDownSlot = nil
  State.tooltipItem = nil
  State.gridContainer = nil
  State.gridPanel = nil
end

--- Draw tooltip (on top of everything)
hook.Add("DrawOverlay", "IonRP_Inventory_Tooltip", function()
  if not State.tooltipItem then return end
  
  local item = State.tooltipItem.item
  if not item then return end
  
  local x, y = State.tooltipPos.x + 15, State.tooltipPos.y + 15
  local w, h = 280, 80
  
  -- Adjust if off screen
  if x + w > ScrW() then x = ScrW() - w - 5 end
  if y + h > ScrH() then y = ScrH() - h - 5 end
  
  -- Dark background
  draw.RoundedBox(4, x, y, w, h, Color(8, 8, 10, 250))
  
  -- Border
  surface.SetDrawColor(Config.Colors.Border)
  surface.DrawOutlinedRect(x, y, w, h, 2)
  
  -- Inner accent border
  surface.SetDrawColor(Config.Colors.Accent)
  surface.DrawOutlinedRect(x + 2, y + 2, w - 4, h - 4, 1)
  
  -- Title
  draw.SimpleText(item.name, "DermaDefaultBold", x + 10, y + 10, Config.Colors.TextBright, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
  
  -- Description
  if item.description then
    local desc = item.description
    if #desc > 80 then desc = string.sub(desc, 1, 77) .. "..." end
    draw.SimpleText(desc, "DermaDefault", x + 10, y + 30, Config.Colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
  end
  
  -- Weight
  local weight = (item.weight or 0) * State.tooltipItem.quantity
  draw.SimpleText(string.format("Weight: %.2f KG", weight), "DermaDefault", x + 10, y + h - 20, Config.Colors.TextDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
  
  -- Quantity
  if State.tooltipItem.quantity > 1 then
    draw.SimpleText(string.format("x%d", State.tooltipItem.quantity), "DermaDefaultBold", x + w - 10, y + 10, Config.Colors.Accent, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
  end
end)

--- Key bind
concommand.Add("ionrp_inventory", function()
  net.Start("IonRP_Inventory_Open")
  net.SendToServer()
end)

local keyHeld = false
hook.Add("Think", "IonRP_Inventory_Key", function()
  if input.IsKeyDown(KEY_Q) then
    if not keyHeld then
      keyHeld = true
      -- Toggle inventory
      if IsValid(State.frame) then
        IonRP.InventoryUI:Close()
      else
        RunConsoleCommand("ionrp_inventory")
      end
    end
  else
    if keyHeld then
      keyHeld = false
      IonRP.InventoryUI:Close()
    end
  end
end)

print("[IonRP Inventory] Client-side inventory UI loaded")
