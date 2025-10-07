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
    SlotInvalid = Color(80, 30, 30, 200),
    SlotValid = Color(30, 80, 50, 200),
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

--[[
    Receive inventory sync from server
]] --
net.Receive("IonRP_SyncInventory", function()
  local invData = net.ReadTable()

  -- Reconstruct inventory on client
  local inv = INVENTORY:New(invData.width, invData.height, invData.maxWeight)

  for _, itemData in ipairs(invData.items) do
    local itemDef = IonRP.Items.List[itemData.identifier]
    if itemDef then
      inv:AddItem(itemDef, itemData.quantity, itemData.x, itemData.y)
    end
  end

  IonRP.InventoryUI.CurrentInventory = inv

  -- Refresh UI if open
  if IsValid(IonRP.InventoryUI.Frame) then
    IonRP.InventoryUI:RefreshGrid()
  end
end)

--[[
    Open inventory UI
]] --
net.Receive("IonRP_OpenInventory", function()
  IonRP.InventoryUI:Open()
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
  if IsValid(self.Frame) then
    self.Frame:Remove()
  end

  if not self.CurrentInventory then
    chat.AddText(Color(255, 100, 100), "[Inventory] ", Color(255, 255, 255), "No inventory data loaded")
    return
  end

  local cfg = self.Config
  local inv = self.CurrentInventory

  local frameWidth = (inv.width * (cfg.SlotSize + cfg.SlotPadding)) + (cfg.Padding * 2) + cfg.SlotPadding
  local frameHeight = (inv.height * (cfg.SlotSize + cfg.SlotPadding)) + cfg.HeaderHeight + cfg.FooterHeight +
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

    -- Weight display
    local currentWeight = inv:GetTotalWeight()
    local maxWeight = inv.maxWeight
    local weightText = string.format("Weight: %.1f / %.1f KG", currentWeight, maxWeight)
    local weightColor = cfg.Colors.TextDim

    if currentWeight > maxWeight * 0.9 then
      weightColor = Color(255, 100, 100)
    elseif currentWeight > maxWeight * 0.7 then
      weightColor = Color(255, 200, 100)
    end

    draw.SimpleText(weightText, "DermaDefault", cfg.Padding, 40, weightColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

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
  self.GridPanel = vgui.Create("DPanel", gridContainer)
  self.GridPanel:SetSize(
    inv.width * (cfg.SlotSize + cfg.SlotPadding) + cfg.SlotPadding,
    inv.height * (cfg.SlotSize + cfg.SlotPadding) + cfg.SlotPadding
  )
  self.GridPanel.Paint = function(self, w, h) end

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
    draw.SimpleText("Left Click: Use Item | Right Click: Drop | Drag to move", "DermaDefault",
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
      slot.GridX = x
      slot.GridY = y

      slot.Paint = function(self, w, h)
        local invSlot = inv:GetSlot(x, y)
        local bgColor = cfg.Colors.SlotBackground

        -- Check if this is the origin of an item
        local isOrigin = invSlot and invSlot.x == x and invSlot.y == y

        if invSlot and invSlot.item then
          bgColor = cfg.Colors.SlotOccupied
        end

        if self:IsHovered() then
          bgColor = cfg.Colors.SlotHover
        end

        -- Check if dragging over this slot
        if IonRP.InventoryUI.DraggedItem then
          local canFit, _ = inv:CanFitItem(IonRP.InventoryUI.DraggedItem, x, y, true)
          if canFit then
            bgColor = cfg.Colors.SlotValid
          else
            bgColor = cfg.Colors.SlotInvalid
          end
        end

        draw.RoundedBox(4, 0, 0, w, h, bgColor)

        -- Border
        surface.SetDrawColor(cfg.Colors.Border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        -- Draw item if this is the origin slot
        if isOrigin and invSlot and invSlot.item then
          --- @type ITEM
          local item = invSlot.item

          -- Draw item model/icon
          if item.model then
            -- For now, draw a simple colored box representing the item
            local itemW = item.size[1] * (cfg.SlotSize + cfg.SlotPadding) - cfg.SlotPadding
            local itemH = item.size[2] * (cfg.SlotSize + cfg.SlotPadding) - cfg.SlotPadding

            -- Item background
            draw.RoundedBox(4, 2, 2, itemW - 4, itemH - 4, Color(60, 60, 70, 230))

            -- Item name (truncated if too long)
            local name = item.name
            if #name > 10 then
              name = string.sub(name, 1, 8) .. ".."
            end

            draw.SimpleText(name, "DermaDefault", itemW / 2, 8, cfg.Colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

            -- Quantity (if stackable)
            if item.stackSize > 1 and invSlot.quantity > 1 then
              draw.SimpleText("x" .. invSlot.quantity, "DermaDefaultBold", itemW - 4, itemH - 4, cfg.Colors.AccentCyan,
                TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
            end

            -- Weight
            local weight = item.weight * invSlot.quantity
            draw.SimpleText(string.format("%.1fkg", weight), "DermaDefault", 4, itemH - 4, cfg.Colors.TextMuted,
              TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
          end
        end
      end

      -- Mouse interaction
      slot.OnMousePressed = function(self, mouse)
        local invSlot = inv:GetSlot(x, y)

        if not invSlot or not invSlot.item then return end

        -- Only interact with origin slots
        if invSlot.x ~= x or invSlot.y ~= y then return end

        if mouse == MOUSE_LEFT then
          -- Start dragging
          IonRP.InventoryUI.DraggedItem = invSlot.item
          IonRP.InventoryUI.DraggedFrom = { x = x, y = y }
        elseif mouse == MOUSE_RIGHT then
          -- Use item
          net.Start("IonRP_UseItem")
          net.WriteUInt(x, 8)
          net.WriteUInt(y, 8)
          net.SendToServer()
        end
      end

      slot.OnMouseReleased = function(self, mouse)
        if mouse == MOUSE_LEFT and IonRP.InventoryUI.DraggedItem then
          -- Drop item here
          local fromPos = IonRP.InventoryUI.DraggedFrom

          if fromPos then
            -- Send move request to server
            net.Start("IonRP_MoveItem")
            net.WriteUInt(fromPos.x, 8)
            net.WriteUInt(fromPos.y, 8)
            net.WriteUInt(x, 8)
            net.WriteUInt(y, 8)
            net.SendToServer()
          end

          -- Clear drag state
          IonRP.InventoryUI.DraggedItem = nil
          IonRP.InventoryUI.DraggedFrom = nil
        end
      end

      self.GridSlots[y][x] = slot
    end
  end
end

--[[
    Refresh the grid (re-render items)
]] --
function IonRP.InventoryUI:RefreshGrid()
  if not IsValid(self.GridPanel) then return end

  -- Just trigger a repaint, the Paint function will handle the rest
  self.GridPanel:InvalidateLayout(true)
end

--[[
    Close the inventory UI
]] --
function IonRP.InventoryUI:Close()
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

-- Command to open inventory (local)
concommand.Add("ionrp_inventory", function(ply)
  if IonRP.InventoryUI.CurrentInventory then
    IonRP.InventoryUI:Open()
  else
    chat.AddText(Color(255, 100, 100), "[Inventory] ", Color(255, 255, 255), "Inventory not loaded yet")
  end
end)

-- Bind key to open inventory (I key)
hook.Add("PlayerButtonDown", "IonRP_InventoryKey", function(ply, button)
  if button == KEY_I then
    RunConsoleCommand("ionrp_inventory")
  end
end)

print("[IonRP Inventory] Client-side inventory UI loaded")
