--[[
    IonRP Inventory System
    Client-side inventory UI with drag-and-drop functionality
]] --

include("sh_inventory.lua")

IonRP.InventoryUI = IonRP.InventoryUI or {}

-- Config
IonRP.InventoryUI.Config = {
  SlotSize = 64,
  SlotPadding = 4,
  HeaderHeight = 60,
  FooterHeight = 40,
  Padding = 12,

  Colors = {
    Background = Color(25, 25, 35, 250),
    Header = Color(45, 35, 60, 255),
    SlotBackground = Color(35, 35, 45, 200),
    SlotHover = Color(55, 50, 70, 230),
    SlotOccupied = Color(45, 45, 55, 220),

    SlotInvalid = Color(80, 30, 30, 100),
    SlotValid = Color(30, 80, 50, 100),

    Divider = Color(100, 80, 120, 100),
    Text = Color(255, 255, 255, 255),
    TextDim = Color(200, 200, 210, 255),
    TextMuted = Color(160, 160, 175, 255),
    Accent = Color(120, 100, 255, 255),
    AccentCyan = Color(100, 200, 255, 255),
    Border = Color(60, 50, 80, 200),
  }
}

-- Local inventory data
IonRP.InventoryUI.CurrentInventory = nil
IonRP.InventoryUI.DraggedItem = nil
IonRP.InventoryUI.DraggedFrom = nil
IonRP.InventoryUI.DraggedQuantity = nil -- How many items are being dragged
IonRP.InventoryUI.MouseDownPos = nil    -- Track mouse position when pressed
IonRP.InventoryUI.MouseDownTime = nil   -- Track when mouse was pressed
IonRP.InventoryUI.MouseDownButton = nil -- Track which button was pressed
IonRP.InventoryUI.MouseDownSlot = nil   -- Track which slot was pressed

--[[
    Receive inventory sync from server
]] --
net.Receive("IonRP_SyncInventory", function()
  local invData = net.ReadTable()

  print("[IonRP Inventory] Received inventory sync from server")
  print(string.format("[IonRP Inventory] Size: %dx%d, Max Weight: %.1f, Items: %d",
    invData.width, invData.height, invData.maxWeight, #invData.items))

  -- Reconstruct inventory on client
  local inv = INVENTORY:New(invData.width, invData.height, invData.maxWeight)

  for _, itemData in ipairs(invData.items) do
    local itemDef = IonRP.Items.List[itemData.identifier]
    if itemDef then
      inv:AddItem(itemDef, itemData.quantity, itemData.x, itemData.y)
    else
      print("[IonRP Inventory] Warning: Unknown item on client: " .. itemData.identifier)
    end
  end

  IonRP.InventoryUI.CurrentInventory = inv
  print("[IonRP Inventory] Client inventory updated successfully")

  -- Refresh UI if open
  if IsValid(IonRP.InventoryUI.Frame) then
    IonRP.InventoryUI:RefreshGrid()
  end
end)

--[[
    Open inventory UI (called when server sends fresh data)
]] --
net.Receive("IonRP_OpenInventory", function()
  -- Wait a tiny bit for the sync data to arrive first
  timer.Simple(0.1, function()
    IonRP.InventoryUI:Open()
  end)
end)

--[[
    Close inventory UI
]] --
net.Receive("IonRP_CloseInventory", function()
  IonRP.InventoryUI:Close()
end)

--[[
    Open the inventory UI
]] --
function IonRP.InventoryUI:Open()
  if not self.CurrentInventory then
    chat.AddText(Color(255, 100, 100), "[Inventory] ", Color(255, 255, 255), "No inventory data loaded")
    return
  end

  -- If already open, close and reopen with fresh data
  if IsValid(self.Frame) then
    print("[IonRP Inventory] Refreshing open inventory UI")
    self.Frame:Remove()
  end

  local cfg = self.Config
  local inv = self.CurrentInventory

  local frameWidth = (inv.width * (cfg.SlotSize + cfg.SlotPadding)) + (cfg.Padding * 2) + cfg.SlotPadding
  local frameHeight = (inv.height * (cfg.SlotSize + cfg.SlotPadding)) + cfg.HeaderHeight + cfg.FooterHeight * 2 +
      (cfg.Padding * 2) + cfg.SlotPadding

  -- Main frame
  --- @class DFrame
  local frame = vgui.Create("DFrame")
  frame:SetSize(frameWidth, frameHeight)
  frame:Center()
  frame:SetTitle("")
  frame:SetDraggable(true)
  frame:ShowCloseButton(false)
  frame:MakePopup()
  frame:SetAlpha(0)
  frame:AlphaTo(255, 0.2, 0)
  self.Frame = frame

  -- Check if Q key is still held down (since MakePopup captures input)
  frame.Think = function(self)
    if not input.IsKeyDown(KEY_Q) then
      IonRP.InventoryUI:Close()
    end
  end

  -- Custom paint
  frame.Paint = function(self, w, h)
    -- Shadow
    draw.RoundedBox(8, 3, 3, w, h, Color(0, 0, 0, 150))

    -- Main background
    draw.RoundedBox(8, 0, 0, w, h, cfg.Colors.Background)

    -- Accent border (cyan)
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
    draw.SimpleText("INVENTORY", "DermaLarge", cfg.Padding, 10, cfg.Colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    -- Weight display (use CurrentInventory reference to get live updates)
    local currentInv = IonRP.InventoryUI.CurrentInventory
    if not currentInv then return end

    local currentWeight = currentInv:GetTotalWeight()
    local maxWeight = currentInv.maxWeight
    local weightText = string.format("Weight: %.1f / %.1f KG", currentWeight, maxWeight)
    local weightColor = cfg.Colors.TextDim

    if currentWeight > maxWeight * 0.9 then
      weightColor = Color(255, 100, 100)
    elseif currentWeight > maxWeight * 0.7 then
      weightColor = Color(255, 200, 100)
    end

    draw.SimpleText(weightText, "DermaDefault", cfg.Padding, 36, weightColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    -- Weight bar
    local barX = cfg.Padding
    local barY = 52
    local barW = 200
    local barH = 4

    draw.RoundedBox(2, barX, barY, barW, barH, Color(20, 20, 30, 200))

    local fillW = math.min(barW * (currentWeight / maxWeight), barW)
    local barColor = cfg.Colors.AccentCyan

    if currentWeight > maxWeight * 0.9 then
      barColor = Color(255, 100, 100)
    elseif currentWeight > maxWeight * 0.7 then
      barColor = Color(255, 200, 100)
    end

    draw.RoundedBox(2, barX, barY, fillW, barH, barColor)
  end

  -- Close button
  local closeBtn = vgui.Create("DButton", header)
  closeBtn:SetPos(frameWidth - 40, 10)
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
    IonRP.InventoryUI:Close()
  end

  -- Grid container
  local gridContainer = vgui.Create("DPanel", frame)
  gridContainer:Dock(FILL)
  gridContainer:DockMargin(cfg.Padding, cfg.Padding, cfg.Padding, cfg.Padding)

  gridContainer.Paint = function(self, w, h)
    -- Grid background
  end

  -- Create grid panel
  --- @class DPanel
  self.GridPanel = vgui.Create("DPanel", gridContainer)
  self.GridPanel:SetSize(
    inv.width * (cfg.SlotSize + cfg.SlotPadding) + cfg.SlotPadding,
    inv.height * (cfg.SlotSize + cfg.SlotPadding) + cfg.SlotPadding
  )
  self.GridPanel.Paint = function(self, w, h) end

  -- Think hook to detect drag start
  self.GridPanel.Think = function(self)
    -- Check if mouse is down and hasn't started dragging yet
    if IonRP.InventoryUI.MouseDownPos and not IonRP.InventoryUI.DraggedItem then
      local mx, my = input.GetCursorPos()
      local downPos = IonRP.InventoryUI.MouseDownPos

      -- Calculate distance moved
      local dx = mx - downPos.x
      local dy = my - downPos.y
      local distance = math.sqrt(dx * dx + dy * dy)

      -- Start drag if moved more than 5 pixels
      if distance > 5 then
        local downSlot = IonRP.InventoryUI.MouseDownSlot
        local downButton = IonRP.InventoryUI.MouseDownButton

        if downSlot and downSlot.item then
          if downButton == MOUSE_LEFT then
            -- Left click = drag full stack
            IonRP.InventoryUI.DraggedItem = downSlot.item
            IonRP.InventoryUI.DraggedFrom = { x = downSlot.x, y = downSlot.y }
            IonRP.InventoryUI.DraggedQuantity = downSlot.quantity
          elseif downButton == MOUSE_RIGHT then
            -- Right click = drag single item (or all if only 1)
            IonRP.InventoryUI.DraggedItem = downSlot.item
            IonRP.InventoryUI.DraggedFrom = { x = downSlot.x, y = downSlot.y }
            IonRP.InventoryUI.DraggedQuantity = math.min(1, downSlot.quantity)
          end

          -- Clear mouse down state once drag starts
          IonRP.InventoryUI.MouseDownPos = nil
          IonRP.InventoryUI.MouseDownTime = nil
          IonRP.InventoryUI.MouseDownButton = nil
          IonRP.InventoryUI.MouseDownSlot = nil
        end
      end
    end
  end

  -- Create grid slots
  self:CreateGrid()

  -- Footer
  local footer = vgui.Create("DPanel", frame)
  footer:Dock(BOTTOM)
  footer:SetTall(cfg.FooterHeight)
  footer:DockMargin(0, 0, 0, 0)

  footer.Paint = function(self, w, h)
    draw.RoundedBoxEx(8, 0, 0, w, h, cfg.Colors.Header, false, false, true, true)

    -- Instructions
    draw.SimpleText("Click: Use Item | Drag: Move Item (Left=All, Right=1)", "DermaDefault",
      w / 2, h / 2, cfg.Colors.TextMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end

  -- Handle ESC key
  frame.OnKeyCodePressed = function(self, key)
    if key == KEY_ESCAPE then
      IonRP.InventoryUI:Close()
    end
  end
end

--[[
    Create the inventory grid
]] --
function IonRP.InventoryUI:CreateGrid()
  if not IsValid(self.GridPanel) or not self.CurrentInventory then return end

  local cfg = self.Config
  local inv = self.CurrentInventory

  -- Clean up old model panels
  if self.GridSlots then
    for y = 0, inv.height - 1 do
      if self.GridSlots[y] then
        for x = 0, inv.width - 1 do
          local slot = self.GridSlots[y][x]
          if IsValid(slot) and istable(slot) then
            -- Remove any model panels attached to this slot
            for k, v in pairs(slot) do
              if type(k) == "string" and string.StartsWith(k, "model_") and IsValid(v) then
                v:Remove()
              end
            end
          end
        end
      end
    end
  end

  self.GridPanel:Clear()
  self.GridSlots = {}

  -- Create all grid slots
  for y = 0, inv.height - 1 do
    self.GridSlots[y] = {}

    for x = 0, inv.width - 1 do
      --- @class DPanel
      local slot = vgui.Create("DPanel", self.GridPanel)
      slot:SetPos(
        cfg.SlotPadding + (x * (cfg.SlotSize + cfg.SlotPadding)),
        cfg.SlotPadding + (y * (cfg.SlotSize + cfg.SlotPadding))
      )
      slot:SetSize(cfg.SlotSize, cfg.SlotSize)
      slot:SetPaintedManually(false)
      slot:SetDrawOnTop(true) -- Draw items on top of other slots
      slot.GridX = x
      slot.GridY = y

      slot.Paint = function(self, w, h)
        -- Always use the current inventory reference for real-time updates
        local currentInv = IonRP.InventoryUI.CurrentInventory
        if not currentInv then return end

        local invSlot = currentInv:GetSlot(x, y)
        --- @type Color|nil
        local bgColor = cfg.Colors.SlotBackground
        -- local bgColor = nil

        -- Check if this is the origin of an item
        local isOrigin = invSlot and invSlot.x == x and invSlot.y == y

        if invSlot and invSlot.item then
          -- bgColor = cfg.Colors.SlotOccupied
          bgColor = nil
        end

        if self:IsHovered() and not (invSlot and invSlot.item) then
          bgColor = cfg.Colors.SlotHover
        end

        -- Check if dragging over this slot
        if IonRP.InventoryUI.DraggedItem and IonRP.InventoryUI.DraggedFrom then
          -- Pass the origin position so we can ignore slots occupied by the item we're moving
          local canFit, _ = currentInv:CanFitItem(
            IonRP.InventoryUI.DraggedItem,
            x, y,
            false,
            { x = IonRP.InventoryUI.DraggedFrom.x, y = IonRP.InventoryUI.DraggedFrom.y }
          )
          if canFit then
            bgColor = cfg.Colors.SlotValid
          else
            bgColor = cfg.Colors.SlotInvalid
          end
        end

        if bgColor then
          draw.RoundedBox(4, 0, 0, w, h, bgColor)
        end

        -- Border
        surface.SetDrawColor(cfg.Colors.Border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        -- Items are now rendered by the overlay panel (self.ItemOverlay) to ensure proper layering
      end

      -- Mouse interaction
      slot.OnMousePressed = function(self, mouse)
        -- Always use the current inventory reference for real-time updates
        local currentInv = IonRP.InventoryUI.CurrentInventory
        if not currentInv then return end

        local invSlot = currentInv:GetSlot(x, y)

        if not invSlot or not invSlot.item then return end

        -- Allow interaction from ANY cell the item occupies (not just origin)
        -- Get the origin position of the item
        local originX, originY = invSlot.x, invSlot.y

        -- Check if already dragging - if so, don't start a new drag
        if IonRP.InventoryUI.DraggedItem then
          return -- Let OnMouseReleased handle the drop
        end

        -- Track mouse down state (don't start drag yet, wait for movement)
        -- Use the ORIGIN position for all operations, not the clicked cell
        local mx, my = input.GetCursorPos()
        IonRP.InventoryUI.MouseDownPos = { x = mx, y = my }
        IonRP.InventoryUI.MouseDownTime = SysTime()
        IonRP.InventoryUI.MouseDownButton = mouse
        IonRP.InventoryUI.MouseDownSlot = { x = originX, y = originY, quantity = invSlot.quantity, item = invSlot.item }
      end

      slot.OnMouseReleased = function(self, mouse)
        -- Handle drop if we're actually dragging
        if IonRP.InventoryUI.DraggedItem then
          local fromPos = IonRP.InventoryUI.DraggedFrom
          if fromPos then
            -- Send move request to server with quantity
            net.Start("IonRP_MoveItem")
            net.WriteUInt(fromPos.x, 8)
            net.WriteUInt(fromPos.y, 8)
            net.WriteUInt(x, 8)
            net.WriteUInt(y, 8)
            net.WriteUInt(IonRP.InventoryUI.DraggedQuantity or 0, 16)
            net.SendToServer()
          end

          -- Clear drag state
          IonRP.InventoryUI.DraggedItem = nil
          IonRP.InventoryUI.DraggedFrom = nil
          IonRP.InventoryUI.DraggedQuantity = nil
        elseif IonRP.InventoryUI.MouseDownSlot then
          -- Mouse was pressed but never moved = click action
          local downSlot = IonRP.InventoryUI.MouseDownSlot
          local downButton = IonRP.InventoryUI.MouseDownButton

          -- Get the current slot (might be any cell of a multi-cell item)
          local currentInv = IonRP.InventoryUI.CurrentInventory
          local invSlot = currentInv and currentInv:GetSlot(x, y)
          local originX, originY = invSlot and invSlot.x or x, invSlot and invSlot.y or y

          -- Check if we released on the same ITEM (any cell) we pressed on
          if downSlot.x == originX and downSlot.y == originY and downButton == mouse then
            if mouse == MOUSE_LEFT then
              -- Left click = use item (use the origin position)
              net.Start("IonRP_UseItem")
              net.WriteUInt(downSlot.x, 8)
              net.WriteUInt(downSlot.y, 8)
              net.SendToServer()
            elseif mouse == MOUSE_RIGHT then
              -- Right click on single item or stack = drop a single item from the stack
              -- TODO: implement this
            end
          end
        end

        -- Clear mouse down state
        IonRP.InventoryUI.MouseDownPos = nil
        IonRP.InventoryUI.MouseDownTime = nil
        IonRP.InventoryUI.MouseDownButton = nil
        IonRP.InventoryUI.MouseDownSlot = nil
      end

      self.GridSlots[y][x] = slot
    end
  end

  -- Store model panels for cleanup
  self.ModelPanels = self.ModelPanels or {}

  -- Helper function to render an item
  local function RenderItem(item, invSlot, slotX, slotY, alpha)
    alpha = alpha or 255
    local itemW = item.size[1] * (cfg.SlotSize + cfg.SlotPadding) - cfg.SlotPadding
    local itemH = item.size[2] * (cfg.SlotSize + cfg.SlotPadding) - cfg.SlotPadding

    -- Item background with gradient effect
    draw.RoundedBox(4, slotX + 2, slotY + 2, itemW - 4, itemH - 4, ColorAlpha(Color(50, 50, 60, 240), alpha))

    -- Subtle inner highlight
    surface.SetDrawColor(ColorAlpha(Color(70, 70, 80, 200), alpha))
    surface.DrawOutlinedRect(slotX + 2, slotY + 2, itemW - 4, itemH - 4, 1)

    -- Item name
    local name = item.name
    local maxNameChars = math.max(8, item.size[1] * 5)
    if #name > maxNameChars then
      name = string.sub(name, 1, maxNameChars - 2) .. ".."
    end

    surface.SetFont("DermaDefault")
    local nameW, nameH = surface.GetTextSize(name)
    draw.RoundedBox(2, slotX + (itemW / 2) - (nameW / 2) - 4, slotY + 4, nameW + 8, 16,
      ColorAlpha(Color(0, 0, 0, 200), alpha))
    draw.SimpleText(name, "DermaDefault", slotX + itemW / 2, slotY + 6, ColorAlpha(cfg.Colors.Text, alpha),
      TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    -- Quantity badge
    if invSlot and item.stackSize > 1 and invSlot.quantity > 1 then
      local qtyText = "x" .. invSlot.quantity
      surface.SetFont("DermaDefaultBold")
      local qtyW = surface.GetTextSize(qtyText)
      draw.RoundedBox(3, slotX + itemW - qtyW - 12, slotY + itemH - 20, qtyW + 8, 16,
        ColorAlpha(cfg.Colors.AccentCyan, alpha))
      draw.SimpleText(qtyText, "DermaDefaultBold", slotX + itemW - 6, slotY + itemH - 6,
        ColorAlpha(Color(255, 255, 255, 255), alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
    end

    -- Weight display
    if item.size[2] >= 2 or item.size[1] >= 2 then
      local weight = invSlot and (item.weight * invSlot.quantity) or item.weight
      local weightText = string.format("%.1fkg", weight)
      surface.SetFont("DermaDefault")
      local weightW = surface.GetTextSize(weightText)
      draw.RoundedBox(2, slotX + 4, slotY + itemH - 18, weightW + 6, 14, ColorAlpha(Color(0, 0, 0, 180), alpha))
      draw.SimpleText(weightText, "DermaDefault", slotX + 7, slotY + itemH - 16, ColorAlpha(cfg.Colors.TextMuted, alpha),
        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    -- Item type indicator
    local typeColor = Color(120, 120, 120)
    if item.type == "weapon" then
      typeColor = Color(255, 100, 100, 200)
    elseif item.type == "consumable" then
      typeColor = Color(100, 255, 100, 200)
    elseif item.type == "misc" then
      typeColor = Color(100, 150, 255, 200)
    end
    draw.RoundedBox(0, slotX + 2, slotY + itemH - 3, itemW - 4, 2, ColorAlpha(typeColor, alpha))
  end

  -- Create item overlay panel that renders on top of all slots
  -- Created AFTER slots so it renders on top
  local itemOverlay = vgui.Create("DPanel", self.GridPanel)
  itemOverlay:SetPos(0, 0)
  itemOverlay:SetSize(self.GridPanel:GetSize())
  itemOverlay:SetMouseInputEnabled(false) -- Allow clicks to pass through to slots
  itemOverlay:SetKeyboardInputEnabled(false)

  -- Clean up old model panels
  for _, mdl in pairs(self.ModelPanels or {}) do
    if IsValid(mdl) then
      mdl:Remove()
    end
  end
  self.ModelPanels = {}

  -- Create model panels for each item
  for iy = 0, inv.height - 1 do
    for ix = 0, inv.width - 1 do
      local invSlot = inv:GetSlot(ix, iy)
      local isOrigin = invSlot and invSlot.x == ix and invSlot.y == iy

      if isOrigin and invSlot and invSlot.item then
        --- @type ITEM
        local item = invSlot.item

        -- Calculate position and size
        local slotX = cfg.SlotPadding + (ix * (cfg.SlotSize + cfg.SlotPadding))
        local slotY = cfg.SlotPadding + (iy * (cfg.SlotSize + cfg.SlotPadding))
        local itemW = item.size[1] * (cfg.SlotSize + cfg.SlotPadding) - cfg.SlotPadding
        local itemH = item.size[2] * (cfg.SlotSize + cfg.SlotPadding) - cfg.SlotPadding

        -- Create model panel if item has a model
        if item.model then
          --- @class DModelPanel
          local modelPanel = vgui.Create("DModelPanel", itemOverlay)
          modelPanel:SetPos(slotX + 2, slotY + 2)
          modelPanel:SetSize(itemW - 4, itemH - 4)
          modelPanel:SetModel(item.model)
          modelPanel:SetMouseInputEnabled(false)
          modelPanel:SetKeyboardInputEnabled(false)
          modelPanel:SetFOV(50) -- Slightly wider FOV to reduce zoom

          -- Store reference with position for later management
          modelPanel.ItemX = ix
          modelPanel.ItemY = iy
          modelPanel.Item = item

          -- Auto-fit the model in the view with better padding
          local ent = modelPanel:GetEntity()
          if IsValid(ent) then
            local mins, maxs = ent:GetRenderBounds()
            local size = maxs - mins
            local radius = math.max(size.x, size.y, size.z)
            local offset = size / 2 + mins

            -- Increase distance multiplier to zoom out more and add padding
            -- Use larger multipliers to ensure model doesn't hit corners
            local distanceMultiplier = 1.2 -- Increased from 0.75 to give more space
            modelPanel:SetCamPos(Vector(radius * distanceMultiplier, radius * distanceMultiplier, radius * 0.8))
            modelPanel:SetLookAt(offset)
          end

          -- Store panel for management
          table.insert(self.ModelPanels, modelPanel)
        end
      end
    end
  end

  -- Simple paint for item backgrounds only
  itemOverlay.Paint = function(pnl, w, h)
    local currentInv = IonRP.InventoryUI.CurrentInventory
    if not currentInv then return end

    -- Only render backgrounds and borders here
    for iy = 0, inv.height - 1 do
      for ix = 0, inv.width - 1 do
        local invSlot = currentInv:GetSlot(ix, iy)
        local isOrigin = invSlot and invSlot.x == ix and invSlot.y == iy

        if isOrigin and invSlot and invSlot.item then
          --- @type ITEM
          local item = invSlot.item
          local slotX = cfg.SlotPadding + (ix * (cfg.SlotSize + cfg.SlotPadding))
          local slotY = cfg.SlotPadding + (iy * (cfg.SlotSize + cfg.SlotPadding))
          local itemW = item.size[1] * (cfg.SlotSize + cfg.SlotPadding) - cfg.SlotPadding
          local itemH = item.size[2] * (cfg.SlotSize + cfg.SlotPadding) - cfg.SlotPadding

          local isDragged = IonRP.InventoryUI.DraggedItem == item and
              IonRP.InventoryUI.DraggedFrom and
              IonRP.InventoryUI.DraggedFrom.x == ix and
              IonRP.InventoryUI.DraggedFrom.y == iy

          if isDragged then
            -- Hide model panel for dragged items
            for _, mdl in pairs(IonRP.InventoryUI.ModelPanels or {}) do
              if IsValid(mdl) and mdl.ItemX == ix and mdl.ItemY == iy then
                mdl:SetVisible(false)
              end
            end
          else
            -- Show model panel
            for _, mdl in pairs(IonRP.InventoryUI.ModelPanels or {}) do
              if IsValid(mdl) and mdl.ItemX == ix and mdl.ItemY == iy then
                mdl:SetVisible(true)
              end
            end

            -- Draw item background and border only (no text)
            local alpha = 255
            draw.RoundedBox(4, slotX + 2, slotY + 2, itemW - 4, itemH - 4, ColorAlpha(Color(50, 50, 60, 240), alpha))
            surface.SetDrawColor(ColorAlpha(Color(70, 70, 80, 200), alpha))
            surface.DrawOutlinedRect(slotX + 2, slotY + 2, itemW - 4, itemH - 4, 1)

            -- Item type indicator at bottom
            local typeColor = Color(120, 120, 120)
            if item.type == "weapon" then
              typeColor = Color(255, 100, 100, 200)
            elseif item.type == "consumable" then
              typeColor = Color(100, 255, 100, 200)
            elseif item.type == "misc" then
              typeColor = Color(100, 150, 255, 200)
            end
            draw.RoundedBox(0, slotX + 2, slotY + itemH - 3, itemW - 4, 2, ColorAlpha(typeColor, alpha))
          end
        end
      end
    end
  end
  self.ItemOverlay = itemOverlay

  -- Create text overlay panel on top of everything (models and backgrounds)
  local textOverlay = vgui.Create("DPanel", self.GridPanel)
  textOverlay:SetPos(0, 0)
  textOverlay:SetSize(self.GridPanel:GetSize())
  textOverlay:SetMouseInputEnabled(false)
  textOverlay:SetKeyboardInputEnabled(false)

  textOverlay.Paint = function(pnl, w, h)
    local currentInv = IonRP.InventoryUI.CurrentInventory
    if not currentInv then return end

    -- Render text labels on top of models
    for iy = 0, inv.height - 1 do
      for ix = 0, inv.width - 1 do
        local invSlot = currentInv:GetSlot(ix, iy)
        local isOrigin = invSlot and invSlot.x == ix and invSlot.y == iy

        if isOrigin and invSlot and invSlot.item then
          --- @type ITEM
          local item = invSlot.item
          local slotX = cfg.SlotPadding + (ix * (cfg.SlotSize + cfg.SlotPadding))
          local slotY = cfg.SlotPadding + (iy * (cfg.SlotSize + cfg.SlotPadding))
          local itemW = item.size[1] * (cfg.SlotSize + cfg.SlotPadding) - cfg.SlotPadding
          local itemH = item.size[2] * (cfg.SlotSize + cfg.SlotPadding) - cfg.SlotPadding

          local isDragged = IonRP.InventoryUI.DraggedItem == item and
              IonRP.InventoryUI.DraggedFrom and
              IonRP.InventoryUI.DraggedFrom.x == ix and
              IonRP.InventoryUI.DraggedFrom.y == iy

          if isDragged then
            -- If doing a partial drag, show remaining quantity
            if IonRP.InventoryUI.DraggedQuantity and IonRP.InventoryUI.DraggedQuantity < invSlot.quantity then
              local alpha = 128
              -- Draw dimmed text for remaining items
              local name = item.name
              local maxNameChars = math.max(8, item.size[1] * 5)
              if #name > maxNameChars then
                name = string.sub(name, 1, maxNameChars - 2) .. ".."
              end

              surface.SetFont("DermaDefault")
              local nameW, nameH = surface.GetTextSize(name)
              draw.RoundedBox(2, slotX + (itemW / 2) - (nameW / 2) - 4, slotY + 4, nameW + 8, 16,
                ColorAlpha(Color(0, 0, 0, 200), alpha))
              draw.SimpleText(name, "DermaDefault", slotX + itemW / 2, slotY + 6, ColorAlpha(cfg.Colors.Text, alpha),
                TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

              -- Show remaining quantity
              local remainingQty = invSlot.quantity - IonRP.InventoryUI.DraggedQuantity
              if item.stackSize > 1 and remainingQty > 1 then
                local qtyText = "x" .. remainingQty
                surface.SetFont("DermaDefaultBold")
                local qtyW = surface.GetTextSize(qtyText)
                draw.RoundedBox(3, slotX + itemW - qtyW - 12, slotY + itemH - 20, qtyW + 8, 16,
                  ColorAlpha(cfg.Colors.AccentCyan, alpha))
                draw.SimpleText(qtyText, "DermaDefaultBold", slotX + itemW - 6, slotY + itemH - 6,
                  ColorAlpha(Color(255, 255, 255, 255), alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
              end
            end
          else
            -- Normal text rendering
            local alpha = 255

            -- Item name with background
            local name = item.name
            local maxNameChars = math.max(8, item.size[1] * 5)
            if #name > maxNameChars then
              name = string.sub(name, 1, maxNameChars - 2) .. ".."
            end

            surface.SetFont("DermaDefault")
            local nameW, nameH = surface.GetTextSize(name)
            draw.RoundedBox(2, slotX + (itemW / 2) - (nameW / 2) - 4, slotY + 4, nameW + 8, 16,
              ColorAlpha(Color(0, 0, 0, 200), alpha))
            draw.SimpleText(name, "DermaDefault", slotX + itemW / 2, slotY + 6, ColorAlpha(cfg.Colors.Text, alpha),
              TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

            -- Quantity badge
            if item.stackSize > 1 and invSlot.quantity > 1 then
              local qtyText = "x" .. invSlot.quantity
              surface.SetFont("DermaDefaultBold")
              local qtyW = surface.GetTextSize(qtyText)
              draw.RoundedBox(3, slotX + itemW - qtyW - 12, slotY + itemH - 20, qtyW + 8, 16,
                ColorAlpha(cfg.Colors.AccentCyan, alpha))
              draw.SimpleText(qtyText, "DermaDefaultBold", slotX + itemW - 6, slotY + itemH - 6,
                ColorAlpha(Color(255, 255, 255, 255), alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
            end

            -- Weight display
            if item.size[2] >= 2 or item.size[1] >= 2 then
              local weight = item.weight * invSlot.quantity
              local weightText = string.format("%.1fkg", weight)
              surface.SetFont("DermaDefault")
              local weightW = surface.GetTextSize(weightText)
              draw.RoundedBox(2, slotX + 4, slotY + itemH - 18, weightW + 6, 14, ColorAlpha(Color(0, 0, 0, 180), alpha))
              draw.SimpleText(weightText, "DermaDefault", slotX + 7, slotY + itemH - 16,
                ColorAlpha(cfg.Colors.TextMuted, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
          end
        end
      end
    end

    -- Render dragged item at cursor position (ghost)
    if IonRP.InventoryUI.DraggedItem then
      local mx, my = pnl:CursorPos()
      --- @type ITEM
      local item = IonRP.InventoryUI.DraggedItem
      local itemW = item.size[1] * (cfg.SlotSize + cfg.SlotPadding) - cfg.SlotPadding
      local itemH = item.size[2] * (cfg.SlotSize + cfg.SlotPadding) - cfg.SlotPadding

      local ghostX = mx - (itemW / 2)
      local ghostY = my - (itemH / 2)

      local draggedSlot = {
        item = item,
        quantity = IonRP.InventoryUI.DraggedQuantity or 1,
        x = 0,
        y = 0
      }

      -- Render ghost with transparency
      RenderItem(item, draggedSlot, ghostX, ghostY, 180)
    end
  end
  self.TextOverlay = textOverlay
end

--[[
    Refresh the grid (re-render items)
]] --
function IonRP.InventoryUI:RefreshGrid()
  if not IsValid(self.GridPanel) then return end

  -- Recreate the entire grid to update item positions and models
  self:CreateGrid()
end

--[[
    Close the inventory UI
]] --
function IonRP.InventoryUI:Close()
  -- Clean up all model panels before closing
  if self.ModelPanels then
    for _, mdl in pairs(self.ModelPanels) do
      if IsValid(mdl) then
        mdl:Remove()
      end
    end
    self.ModelPanels = {}
  end

  if self.GridSlots then
    for _, row in pairs(self.GridSlots) do
      for _, slot in pairs(row) do
        if IsValid(slot) and istable(slot) then
          for k, v in pairs(slot) do
            if type(k) == "string" and string.StartsWith(k, "model_") and IsValid(v) then
              v:Remove()
            end
          end
        end
      end
    end
  end

  if IsValid(self.Frame) then
    self.Frame:AlphaTo(0, 0.2, 0, function()
      if IsValid(self.Frame) then
        self.Frame:Remove()
      end
    end)
  end

  -- Clear drag state
  self.DraggedItem = nil
  self.DraggedFrom = nil
end

-- Command to open inventory - requests fresh data from server
concommand.Add("ionrp_inventory", function(ply)
  -- Request server to send fresh inventory data and open
  net.Start("IonRP_RequestOpenInventory")
  net.SendToServer()

  print("[IonRP Inventory] Requesting inventory from server...")
end)

local Q_held = false
-- Bind key to open inventory (Q key - hold to keep open)
hook.Add("PlayerButtonDown", "IonRP_InventoryKey", function(ply, button)
  if button == KEY_Q then
    if Q_held then return end
    Q_held = true
    RunConsoleCommand("ionrp_inventory")
  end
end)

-- Close inventory when Q is released
hook.Add("PlayerButtonUp", "IonRP_InventoryKeyRelease", function(ply, button)
  if button == KEY_Q then
    IonRP.InventoryUI:Close()
    Q_held = false
  end
end)

print("[IonRP Inventory] Client-side inventory UI loaded")
