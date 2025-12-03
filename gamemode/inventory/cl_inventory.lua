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
  tooltipPos = {x = 0, y = 0}
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
  
  -- Refresh UI if open - recreate grid to show changes
  if IsValid(State.frame) and IsValid(State.gridContainer) then
    IonRP.InventoryUI:CreateGrid(State.gridContainer)
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
  
  local tabs = {"Inventory", "Mixtures", "Soda", "Genetics"}
  local tabWidth = 120
  local tabX = 10
  
  for i, tabName in ipairs(tabs) do
    local tab = vgui.Create("DButton", tabBar)
    tab:SetPos(tabX, 5)
    tab:SetSize(tabWidth, Config.TabHeight - 10)
    tab:SetText("")
    
    local isActive = (i == 1) -- First tab is active
    
    tab.Paint = function(self, w, h)
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
      -- Only Inventory tab is functional for now
      if i ~= 1 then
        chat.AddText(Color(255, 200, 100), "[Inventory] ", Color(255, 255, 255), tabName .. " coming soon!")
      end
    end
    
    tabX = tabX + tabWidth + 5
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
  if not State.inventory then return end
  
  local inv = State.inventory
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
  
  -- Create slot grid
  grid.slots = {}
  for y = 0, inv.height - 1 do
    grid.slots[y] = {}
    for x = 0, inv.width - 1 do
      local slot = self:CreateSlot(grid, x, y)
      grid.slots[y][x] = slot
    end
  end
  
  -- Overlay for items and drag preview
  local overlay = vgui.Create("DPanel", grid)
  overlay:SetSize(gridW, gridH)
  overlay:SetMouseInputEnabled(false)
  
  overlay.Paint = function(self, w, h)
    -- Draw items
    for _, invItem in ipairs(inv:GetItems()) do
      self:DrawItem(invItem, false)
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
    
    -- Slightly darker background for occupied slots
    draw.RoundedBox(2, x, y, w, h, ColorAlpha(Config.Colors.SlotOccupied, alpha))
    
    -- Darker inner border
    surface.SetDrawColor(ColorAlpha(Config.Colors.BorderDark, alpha))
    surface.DrawOutlinedRect(x, y, w, h, 1)
    
    -- Light outer border
    surface.SetDrawColor(ColorAlpha(Config.Colors.Border, alpha))
    surface.DrawOutlinedRect(x + 1, y + 1, w - 2, h - 2, 1)
    
    -- Model preview placeholder (dark area in center)
    local iconPad = 8
    local iconW = w - iconPad * 2
    local iconH = h - iconPad * 2
    if iconH > 20 then
      draw.RoundedBox(2, x + iconPad, y + iconPad, iconW, iconH, ColorAlpha(Color(12, 12, 15), alpha))
    end
    
    -- Quantity badge (top-left corner like reference image)
    if invItem.quantity > 1 then
      local qtyText = tostring(invItem.quantity)
      surface.SetFont("DermaDefaultBold")
      local tw, th = surface.GetTextSize(qtyText)
      
      -- Small dark background
      draw.RoundedBox(0, x + 2, y + 2, tw + 6, th + 4, ColorAlpha(Color(0, 0, 0, 200), alpha))
      draw.SimpleText(qtyText, "DermaDefaultBold", x + 5, y + 4, ColorAlpha(Config.Colors.TextBright, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
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
    local inv = State.inventory
    if not inv then return end
    
    local invItem = inv:GetItemAt(x, y)
    local isOrigin = invItem and invItem.x == x and invItem.y == y
    
    -- Background - very dark slot
    local bgColor = Config.Colors.SlotEmpty
    
    if self:IsHovered() then
      bgColor = Config.Colors.SlotHover
      
      -- Show tooltip
      if isOrigin then
        State.tooltipItem = invItem
        State.tooltipPos.x, State.tooltipPos.y = gui.MouseX(), gui.MouseY()
      end
    end
    
    -- Drag preview
    if State.draggedItem and not (invItem and invItem == State.draggedItem) then
      local canPlace = inv:IsAreaFree(x, y, State.draggedItem.item.size[1], State.draggedItem.item.size[2], State.draggedItem)
      if canPlace then
        bgColor = Config.Colors.SlotValid
      else
        bgColor = Config.Colors.SlotInvalid
      end
    end
    
    draw.RoundedBox(0, 0, 0, w, h, bgColor)
    
    -- Darker border
    surface.SetDrawColor(Config.Colors.BorderDark)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
  end
  
  slot.OnMousePressed = function(self, mouse)
    local inv = State.inventory
    if not inv then return end
    
    local invItem = inv:GetItemAt(x, y)
    if not invItem then return end
    
    State.mouseDownSlot = {x = x, y = y, item = invItem, button = mouse}
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
      local sx, sy = self:LocalToScreen(0, 0)
      local dist = math.sqrt((mx - sx)^2 + (my - sy)^2)
      
      if dist > 10 and not State.draggedItem then
        -- Start drag
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
  if IsValid(State.frame) then
    State.frame:Remove()
    State.frame = nil
  end
  
  State.draggedItem = nil
  State.mouseDownSlot = nil
  State.tooltipItem = nil
end

--- Draw tooltip
hook.Add("HUDPaint", "IonRP_Inventory_Tooltip", function()
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
    if not keyHeld and not vgui.CursorVisible() then
      keyHeld = true
      RunConsoleCommand("ionrp_inventory")
    end
  else
    if keyHeld then
      keyHeld = false
      IonRP.InventoryUI:Close()
    end
  end
end)

print("[IonRP Inventory] Client-side inventory UI loaded")
