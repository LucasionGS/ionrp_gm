--[[
    IonRP Inventory System
    Shared inventory logic and data structures
]] --

IonRP.Inventory = IonRP.Inventory or {}

--- @class InventorySlot
--- @field item ITEM|nil The item in this slot
--- @field quantity number The quantity of items in this slot
--- @field equippedSlot number|nil The weapon slot this item is equipped in (1 = primary, 2 = secondary), if applicable
--- @field x number The X position in the inventory grid
--- @field y number The Y position in the inventory grid

--- @class Inventory
--- @field owner Player|nil The player who owns this inventory
--- @field width number The width of the inventory grid
--- @field height number The height of the inventory grid
--- @field slots table<string, InventorySlot> Table of slots indexed by "x_y"
--- @field maxWeight number Maximum weight capacity in KG (0 = unlimited)
--- @field id number|nil Database ID for this inventory
INVENTORY = INVENTORY or {}
INVENTORY.__index = INVENTORY

--- Create a new inventory instance
--- @param width number Grid width
--- @param height number Grid height
--- @param maxWeight number|nil Maximum weight capacity (default: 50)
--- @return Inventory
function INVENTORY:New(width, height, maxWeight)
  local inv = {}
  setmetatable(inv, self)

  inv.width = width or 10
  inv.height = height or 10
  inv.maxWeight = maxWeight or 50
  inv.slots = {}
  inv.owner = nil
  inv.id = nil

  return inv
end

--- Get the total weight of all items in the inventory
--- @return number
function INVENTORY:GetTotalWeight()
  local totalWeight = 0

  for _, slot in pairs(self.slots) do
    if slot.item then
      totalWeight = totalWeight + (slot.item.weight * slot.quantity)
    end
  end

  return totalWeight
end

--- Check if a position is within grid bounds
--- @param x number
--- @param y number
--- @return boolean
function INVENTORY:IsValidPosition(x, y)
  return x >= 0 and x < self.width and y >= 0 and y < self.height
end

--- Get slot key from coordinates
--- @param x number
--- @param y number
--- @return string
function INVENTORY:GetSlotKey(x, y)
  return x .. "_" .. y
end

--- Get slot at position
--- @param x number
--- @param y number
--- @return InventorySlot|nil
function INVENTORY:GetSlot(x, y)
  return self.slots[self:GetSlotKey(x, y)]
end

--- Check if an item can fit at the specified position
--- @param item ITEM
--- @param x number
--- @param y number
--- @param ignoreOccupied boolean|nil If true, ignore if slots are occupied (for moving items)
--- @param ignoreItemAt table|nil Table with {x=number, y=number} to ignore item at this origin position (for moving)
--- @return boolean, string|nil Returns true if can fit, or false with reason
function INVENTORY:CanFitItem(item, x, y, ignoreOccupied, ignoreItemAt)
  if not item then return false, "No item specified" end
  if not item.size or #item.size ~= 2 then return false, "Invalid item size" end

  local width, height = item.size[1], item.size[2]

  -- Check if item fits within grid bounds
  if not self:IsValidPosition(x, y) then
    return false, "Position out of bounds"
  end

  if x + width > self.width or y + height > self.height then
    return false, "Item too large for position"
  end

  -- Check if all required slots are empty
  if not ignoreOccupied then
    for ix = x, x + width - 1 do
      for iy = y, y + height - 1 do
        local slot = self:GetSlot(ix, iy)
        if slot and slot.item then
          -- If we have an ignoreItemAt position, check if this slot belongs to that item
          if ignoreItemAt then
            local ignoreSlot = self:GetSlot(ignoreItemAt.x, ignoreItemAt.y)
            if ignoreSlot and ignoreSlot.item then
              -- Check if this occupied slot is part of the item we're ignoring
              local isPartOfIgnoredItem = false
              if slot.x == ignoreSlot.x and slot.y == ignoreSlot.y then
                -- This is the origin of the item we're moving, ignore it
                isPartOfIgnoredItem = true
              else
                -- Check if this slot references the same item
                if slot.item == ignoreSlot.item then
                  isPartOfIgnoredItem = true
                end
              end
              
              if not isPartOfIgnoredItem then
                return false, "Slot occupied"
              end
            else
              return false, "Slot occupied"
            end
          else
            return false, "Slot occupied"
          end
        end
      end
    end
  end

  return true, nil
end

--- Find the first available position for an item
--- @param item ITEM
--- @return number|nil, number|nil Returns x, y if found, or nil if no space
function INVENTORY:FindAvailablePosition(item)
  for y = 0, self.height - 1 do
    for x = 0, self.width - 1 do
      local canFit, _ = self:CanFitItem(item, x, y, false)
      if canFit then
        return x, y
      end
    end
  end

  return nil, nil
end

--- Check if adding an item would exceed weight limit
--- @param item ITEM
--- @param quantity number
--- @return boolean
function INVENTORY:WouldExceedWeight(item, quantity)
  if self.maxWeight == 0 then return false end -- Unlimited weight

  local currentWeight = self:GetTotalWeight()
  local addedWeight = item.weight * quantity

  return (currentWeight + addedWeight) > self.maxWeight
end

--- Find an existing stack that can accept more items
--- @param item ITEM
--- @return number|nil, number|nil, number|nil Returns x, y, currentQuantity if found
function INVENTORY:FindStackableSlot(item)
  if not item or item.stackSize <= 1 then return nil, nil, nil end

  for key, slot in pairs(self.slots) do
    if slot.item and slot.item.identifier == item.identifier then
      if slot.quantity < item.stackSize then
        return slot.x, slot.y, slot.quantity
      end
    end
  end

  return nil, nil, nil
end

--- Add an item to the inventory
--- @param item ITEM
--- @param quantity number
--- @param x number|nil Optional position, will auto-find if nil
--- @param y number|nil Optional position, will auto-find if nil
--- @return boolean, string|nil Returns true on success, or false with reason
function INVENTORY:AddItem(item, quantity, x, y)
  quantity = quantity or 1

  if quantity <= 0 then return false, "Invalid quantity" end

  -- Check weight limit
  if self:WouldExceedWeight(item, quantity) then
    return false, "Would exceed weight limit"
  end

  local remainingQuantity = quantity

  -- Try to stack with existing items first
  if item.stackSize > 1 then
    while remainingQuantity > 0 do
      local sx, sy, currentQty = self:FindStackableSlot(item)

      if not sx or not sy or not currentQty then break end -- No more stackable slots

      local slot = self:GetSlot(sx, sy)
      if not slot then break end

      local canAdd = math.min(remainingQuantity, item.stackSize - currentQty)

      slot.quantity = slot.quantity + canAdd
      remainingQuantity = remainingQuantity - canAdd
    end
  end

  -- Place remaining items in new slots
  while remainingQuantity > 0 do
    local posX, posY = x, y

    -- Auto-find position if not specified
    if not posX or not posY then
      posX, posY = self:FindAvailablePosition(item)
    end

    if not posX or not posY then
      return false, "No space in inventory"
    end

    local canFit, reason = self:CanFitItem(item, posX, posY, false)
    if not canFit then
      return false, reason
    end

    -- Calculate how many to add to this stack
    local addQuantity = math.min(remainingQuantity, item.stackSize)

    -- Occupy all grid cells for this item
    local width, height = item.size[1], item.size[2]
    for ix = posX, posX + width - 1 do
      for iy = posY, posY + height - 1 do
        local slotKey = self:GetSlotKey(ix, iy)
        self.slots[slotKey] = {
          item = item,
          quantity = addQuantity,
          x = posX, -- Store origin position
          y = posY
        }
      end
    end

    remainingQuantity = remainingQuantity - addQuantity

    -- Clear position for next iteration (force auto-find)
    x, y = nil, nil
  end

  return true, nil
end

--- Remove an item from the inventory
--- @param x number
--- @param y number
--- @param quantity number|nil Amount to remove (default: all)
--- @return boolean success
--- @return ITEM|nil item Returns the item removed
--- @return number quantity Returns the quantity removed
function INVENTORY:RemoveItem(x, y, quantity)
  local slot = self:GetSlot(x, y)

  if not slot or not slot.item then
    return false, nil, 0
  end

  local item = slot.item
  if not item or not item.size or #item.size ~= 2 then
    return false, nil, 0
  end

  local originX, originY = slot.x, slot.y
  quantity = quantity or slot.quantity

  if quantity <= 0 then return false, nil, 0 end
  if quantity > slot.quantity then quantity = slot.quantity end

  slot.quantity = slot.quantity - quantity

  -- If slot is empty, clear all grid cells for this item
  if slot.quantity <= 0 then
    local width, height = item.size[1], item.size[2]
    for ix = originX, originX + width - 1 do
      for iy = originY, originY + height - 1 do
        self.slots[self:GetSlotKey(ix, iy)] = nil
      end
    end
  end

  return true, item, quantity
end

--- Move an item from one position to another
--- @param fromX number
--- @param fromY number
--- @param toX number
--- @param toY number
--- @return boolean, string|nil
function INVENTORY:MoveItem(fromX, fromY, toX, toY)
  local fromSlot = self:GetSlot(fromX, fromY)

  if not fromSlot or not fromSlot.item then
    return false, "No item at source position"
  end

  local item = fromSlot.item
  local quantity = fromSlot.quantity
  local originX, originY = fromSlot.x, fromSlot.y

  -- Check if we're moving to the origin position (no-op)
  if fromX == originX and fromY == originY and toX == fromX and toY == fromY then
    return true, nil
  end

  -- Check if destination can accept the item
  local destSlot = self:GetSlot(toX, toY)

  -- Try to stack with existing item (but not if it's the same item we're moving!)
  if destSlot and destSlot.item and item and item.identifier and destSlot.item.identifier == item.identifier then
    -- Check if the destination slot is part of the same item instance we're moving
    local isSameItemInstance = false
    if destSlot.x == originX and destSlot.y == originY then
      -- Destination is the origin of the item we're moving
      isSameItemInstance = true
    elseif destSlot.item == item then
      -- Destination references the exact same item instance
      isSameItemInstance = true
    end

    if not isSameItemInstance then
      -- Only try to stack if it's a different item instance
      if item.stackSize and destSlot.quantity and destSlot.quantity < item.stackSize then
        local canAdd = math.min(quantity, item.stackSize - destSlot.quantity)

        -- Remove from source
        self:RemoveItem(originX, originY, canAdd)

        -- Add to destination
        destSlot.quantity = destSlot.quantity + canAdd

        return true, nil
      else
        return false, "Destination stack is full"
      end
    end
    -- If it's the same item instance, fall through to the move logic below
  end

  -- Check if we can fit at new position
  if not item then
    return false, "Invalid item"
  end

  -- Pass the origin position so we can ignore slots occupied by the item we're moving
  local canFit, reason = self:CanFitItem(item, toX, toY, false, {x = originX, y = originY})

  if not canFit then
    return false, reason
  end

  -- Remove from old position
  local success, removedItem, removedQty = self:RemoveItem(originX, originY, quantity)

  if not success or not removedItem then
    return false, "Failed to remove item"
  end

  -- Add to new position
  local addSuccess, addReason = self:AddItem(removedItem, removedQty, toX, toY)

  if not addSuccess then
    -- Rollback: add back to original position
    self:AddItem(removedItem, removedQty, originX, originY)
    return false, addReason
  end

  return true, nil
end

--- Get all items in the inventory as a flat list
--- @return table<number, {item: ITEM, quantity: number, x: number, y: number}>
function INVENTORY:GetAllItems()
  local items = {}
  local processed = {}

  for key, slot in pairs(self.slots) do
    if slot.item then
      local originKey = self:GetSlotKey(slot.x, slot.y)

      -- Only add origin slots to avoid duplicates
      if not processed[originKey] then
        processed[originKey] = true
        table.insert(items, {
          item = slot.item,
          quantity = slot.quantity,
          x = slot.x,
          y = slot.y
        })
      end
    end
  end

  return items
end

--- Clear the entire inventory
function INVENTORY:Clear()
  self.slots = {}
end

--- Debug: Print inventory contents
function INVENTORY:Debug()
  print("=== Inventory Debug ===")
  print(string.format("Size: %dx%d, Weight: %.2f/%.2f KG",
    self.width, self.height, self:GetTotalWeight(), self.maxWeight))

  local items = self:GetAllItems()
  print("Items:")
  for _, entry in ipairs(items) do
    print(string.format("  [%d,%d] %s x%d (%.2f KG)",
      entry.x, entry.y, entry.item.name, entry.quantity,
      entry.item.weight * entry.quantity))
  end
  print("=====================")
end
