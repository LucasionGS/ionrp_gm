--[[
    IonRP Inventory System - Shared
    Modern grid-based inventory with weight management
]]--

IonRP.Inventory = IonRP.Inventory or {}

--- @class InventoryItem
--- @field item ITEM Item definition
--- @field quantity number Stack quantity
--- @field x number Grid X position
--- @field y number Grid Y position

--- @class Inventory
--- @field width number Grid width
--- @field height number Grid height
--- @field maxWeight number Maximum weight in KG
--- @field items table<number, InventoryItem> Array of items
--- @field owner Player|nil Owner of inventory
--- @field id number|nil Database ID
local InventoryMeta = {}
InventoryMeta.__index = InventoryMeta

--- Create new inventory
--- @param width number
--- @param height number
--- @param maxWeight number
--- @return Inventory
function IonRP.Inventory.New(width, height, maxWeight)
  local inv = setmetatable({}, InventoryMeta)
  inv.width = width or 10
  inv.height = height or 10
  inv.maxWeight = maxWeight or 50
  inv.items = {}
  inv.owner = nil
  inv.id = nil
  return inv
end

--- Check if position is valid
--- @param x number
--- @param y number
--- @return boolean
function InventoryMeta:IsValidPos(x, y)
  return x >= 0 and x < self.width and y >= 0 and y < self.height
end

--- Get item at position
--- @param x number
--- @param y number
--- @return InventoryItem|nil
function InventoryMeta:GetItemAt(x, y)
  for _, invItem in ipairs(self.items) do
    local item = invItem.item
    if not item or not item.size then continue end
    
    -- Check if position is within item bounds
    if x >= invItem.x and x < invItem.x + item.size[1] and
       y >= invItem.y and y < invItem.y + item.size[2] then
      return invItem
    end
  end
  return nil
end

--- Check if area is free (excluding specific item)
--- @param x number
--- @param y number
--- @param width number
--- @param height number
--- @param excludeItem InventoryItem|nil
--- @return boolean
function InventoryMeta:IsAreaFree(x, y, width, height, excludeItem)
  -- Check bounds
  if not self:IsValidPos(x, y) then return false end
  if not self:IsValidPos(x + width - 1, y + height - 1) then return false end
  
  -- Check for overlapping items
  for _, invItem in ipairs(self.items) do
    if invItem == excludeItem then continue end
    if not invItem.item or not invItem.item.size then continue end
    
    local ix1, iy1 = invItem.x, invItem.y
    local ix2, iy2 = ix1 + invItem.item.size[1], iy1 + invItem.item.size[2]
    local x2, y2 = x + width, y + height
    
    -- Check overlap
    if not (x2 <= ix1 or x >= ix2 or y2 <= iy1 or y >= iy2) then
      return false
    end
  end
  
  return true
end

--- Find first free position for item
--- @param item ITEM
--- @return number|nil, number|nil
function InventoryMeta:FindFreePos(item)
  if not item or not item.size then return nil, nil end
  
  for y = 0, self.height - 1 do
    for x = 0, self.width - 1 do
      if self:IsAreaFree(x, y, item.size[1], item.size[2], nil) then
        return x, y
      end
    end
  end
  
  return nil, nil
end

--- Get total weight
--- @return number
function InventoryMeta:GetWeight()
  local total = 0
  for _, invItem in ipairs(self.items) do
    if invItem.item then
      total = total + (invItem.item.weight or 0) * invItem.quantity
    end
  end
  return total
end

--- Check if item can be added
--- @param item ITEM
--- @param quantity number
--- @param x number|nil
--- @param y number|nil
--- @return boolean, string|nil
function InventoryMeta:CanAdd(item, quantity, x, y)
  if not item then return false, "Invalid item" end
  if quantity <= 0 then return false, "Invalid quantity" end
  
  -- Check weight
  local newWeight = self:GetWeight() + (item.weight or 0) * quantity
  if self.maxWeight > 0 and newWeight > self.maxWeight then
    return false, "Too heavy"
  end
  
  -- If position specified, check it
  if x and y then
    if not item.size then return false, "Item has no size" end
    if not self:IsAreaFree(x, y, item.size[1], item.size[2], nil) then
      return false, "Space occupied"
    end
    return true
  end
  
  -- Try to stack with existing
  if item.stackSize and item.stackSize > 1 then
    for _, invItem in ipairs(self.items) do
      if invItem.item.identifier == item.identifier and invItem.quantity < item.stackSize then
        return true -- Can stack
      end
    end
  end
  
  -- Check if we can find space
  local px, py = self:FindFreePos(item)
  if not px then
    return false, "No space"
  end
  
  return true
end

--- Add item to inventory
--- @param item ITEM
--- @param quantity number
--- @param x number|nil
--- @param y number|nil
--- @return boolean, string|nil
function InventoryMeta:AddItem(item, quantity, x, y)
  quantity = quantity or 1
  
  local canAdd, err = self:CanAdd(item, quantity, x, y)
  if not canAdd then return false, err end
  
  -- Try stacking first if no position specified
  if not x and not y and item.stackSize and item.stackSize > 1 then
    for _, invItem in ipairs(self.items) do
      if invItem.item.identifier == item.identifier and invItem.quantity < item.stackSize then
        local addQty = math.min(quantity, item.stackSize - invItem.quantity)
        invItem.quantity = invItem.quantity + addQty
        quantity = quantity - addQty
        
        if quantity <= 0 then return true end
      end
    end
  end
  
  -- Place new stacks
  while quantity > 0 do
    local px, py = x, y
    if not px then
      px, py = self:FindFreePos(item)
      if not px then return false, "No space" end
    end
    
    local stackQty = math.min(quantity, item.stackSize or 1)
    
    table.insert(self.items, {
      item = item,
      quantity = stackQty,
      x = px,
      y = py
    })
    
    quantity = quantity - stackQty
    x, y = nil, nil -- Force search for next stack
  end
  
  return true
end

--- Remove item
--- @param invItem InventoryItem
--- @param quantity number
--- @return boolean, number
function InventoryMeta:RemoveItem(invItem, quantity)
  if not invItem then return false, 0 end
  
  quantity = math.min(quantity or invItem.quantity, invItem.quantity)
  invItem.quantity = invItem.quantity - quantity
  
  if invItem.quantity <= 0 then
    for i, item in ipairs(self.items) do
      if item == invItem then
        table.remove(self.items, i)
        break
      end
    end
  end
  
  return true, quantity
end

--- Move item to new position
--- @param invItem InventoryItem
--- @param toX number
--- @param toY number
--- @param quantity number|nil
--- @return boolean, string|nil
function InventoryMeta:MoveItem(invItem, toX, toY, quantity)
  if not invItem or not invItem.item then return false, "Invalid item" end
  
  quantity = quantity or invItem.quantity
  quantity = math.min(quantity, invItem.quantity)
  
  -- Check if moving to same position
  if invItem.x == toX and invItem.y == toY then
    return true
  end
  
  -- Check if target has same item (for stacking)
  local targetItem = self:GetItemAt(toX, toY)
  if targetItem and targetItem ~= invItem then
    if targetItem.item.identifier == invItem.item.identifier then
      local stackSize = invItem.item.stackSize or 1
      if targetItem.quantity < stackSize then
        -- Stack items
        local addQty = math.min(quantity, stackSize - targetItem.quantity)
        targetItem.quantity = targetItem.quantity + addQty
        self:RemoveItem(invItem, addQty)
        return true
      end
    end
    return false, "Space occupied"
  end
  
  -- Check if area is free
  if not self:IsAreaFree(toX, toY, invItem.item.size[1], invItem.item.size[2], invItem) then
    return false, "Space occupied"
  end
  
  -- Split or move
  if quantity < invItem.quantity then
    -- Split stack
    table.insert(self.items, {
      item = invItem.item,
      quantity = quantity,
      x = toX,
      y = toY
    })
    invItem.quantity = invItem.quantity - quantity
  else
    -- Move entire stack
    invItem.x = toX
    invItem.y = toY
  end
  
  return true
end

--- Get all items
--- @return InventoryItem[]
function InventoryMeta:GetItems()
  return self.items
end

--- Count item by identifier
--- @param identifier string
--- @return number
function InventoryMeta:CountItem(identifier)
  local total = 0
  for _, invItem in ipairs(self.items) do
    if invItem.item.identifier == identifier then
      total = total + invItem.quantity
    end
  end
  return total
end

--- Clear inventory
function InventoryMeta:Clear()
  self.items = {}
end

print("[IonRP Inventory] Shared inventory system loaded")
