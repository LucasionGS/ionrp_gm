--[[
    IonRP Inventory System - Server
    Database operations and network handlers
]]--

include("sh_inventory.lua")
AddCSLuaFile("sh_inventory.lua")
AddCSLuaFile("cl_inventory.lua")

-- Network strings
util.AddNetworkString("IonRP_Inventory_Open")
util.AddNetworkString("IonRP_Inventory_Close")
util.AddNetworkString("IonRP_Inventory_Sync")
util.AddNetworkString("IonRP_Inventory_Move")
util.AddNetworkString("IonRP_Inventory_Use")
util.AddNetworkString("IonRP_Inventory_Drop")
util.AddNetworkString("IonRP_Inventory_Craft")
util.AddNetworkString("IonRP_Inventory_UnequipWeapon")

--- Initialize database tables
function IonRP.Inventory:InitializeTables()
  print("[IonRP Inventory] Initializing database tables...")
  
  local query = IonRP.Database:query([[
    CREATE TABLE IF NOT EXISTS ionrp_inventories (
      id INT AUTO_INCREMENT PRIMARY KEY,
      steam_id VARCHAR(32) NOT NULL,
      width INT NOT NULL DEFAULT 10,
      height INT NOT NULL DEFAULT 10,
      max_weight FLOAT NOT NULL DEFAULT 50.0,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      UNIQUE KEY unique_steamid (steam_id),
      INDEX idx_steam_id (steam_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  ]])
  
  function query:onSuccess()
    print("[IonRP Inventory] Inventories table ready")
  end
  
  function query:onError(err, sql)
    print("[IonRP Inventory] ERROR: Failed to create inventories table:")
    print("[IonRP Inventory] " .. err)
  end
  
  query:start()
  
  local itemsQuery = IonRP.Database:query([[
    CREATE TABLE IF NOT EXISTS ionrp_inventory_items (
      id INT AUTO_INCREMENT PRIMARY KEY,
      inventory_id INT NOT NULL,
      item_identifier VARCHAR(64) NOT NULL,
      quantity INT NOT NULL DEFAULT 1,
      pos_x INT NOT NULL,
      pos_y INT NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      FOREIGN KEY (inventory_id) REFERENCES ionrp_inventories(id) ON DELETE CASCADE,
      INDEX idx_inventory_id (inventory_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  ]])
  
  function itemsQuery:onSuccess()
    print("[IonRP Inventory] Inventory items table ready")
  end
  
  function itemsQuery:onError(err, sql)
    print("[IonRP Inventory] ERROR: Failed to create inventory items table:")
    print("[IonRP Inventory] " .. err)
  end
  
  itemsQuery:start()
end

--- Load player inventory from database
--- @param ply Player
--- @param callback function
function IonRP.Inventory:Load(ply, callback)
  if not IsValid(ply) then
    if callback then callback(nil) end
    return
  end
  
  local steamID = ply:SteamID64()
  
  IonRP.Database:PreparedQuery(
    "SELECT * FROM ionrp_inventories WHERE steam_id = ? LIMIT 1",
    {steamID},
    function(data)
      if data and #data > 0 then
        local invData = data[1]
        local inv = IonRP.Inventory.New(
          tonumber(invData.width) or IonRP.Inventory.DefaultWidth,
          tonumber(invData.height) or IonRP.Inventory.DefaultHeight,
          tonumber(invData.max_weight) or IonRP.Inventory.DefaultWeight
        )
        inv.id = tonumber(invData.id)
        inv.owner = ply
        
        -- Load items
        IonRP.Database:PreparedQuery(
          "SELECT * FROM ionrp_inventory_items WHERE inventory_id = ?",
          {inv.id},
          function(itemsData)
            if itemsData then
              for _, itemData in ipairs(itemsData) do
                local item = IonRP.Items.List[itemData.item_identifier]
                if item then
                  inv:AddItem(
                    item,
                    tonumber(itemData.quantity) or 1,
                    tonumber(itemData.pos_x),
                    tonumber(itemData.pos_y)
                  )
                end
              end
            end
            
            ply.IonRP_Inventory = inv
            print("[IonRP Inventory] Loaded inventory for " .. ply:Nick())
            
            if callback then callback(inv) end
          end
        )
      else
        -- Create new inventory
        IonRP.Database:PreparedQuery(
          "INSERT INTO ionrp_inventories (steam_id, width, height, max_weight) VALUES (?, ?, ?, ?)",
          {steamID, 10, 10, 50.0},
          function()
            IonRP.Inventory:Load(ply, callback)
          end
        )
      end
    end
  )
end

--- Save player inventory to database
--- @param ply Player
--- @param callback function|nil
function IonRP.Inventory:Save(ply, callback)
  if not IsValid(ply) or not ply.IonRP_Inventory then
    if callback then callback(false) end
    return
  end
  
  local inv = ply.IonRP_Inventory
  if not inv.id then
    if callback then callback(false) end
    return
  end
  
  -- Clear existing items
  IonRP.Database:PreparedQuery(
    "DELETE FROM ionrp_inventory_items WHERE inventory_id = ?",
    {inv.id},
    function()
      local items = inv:GetItems()
      if #items == 0 then
        if callback then callback(true) end
        return
      end
      
      local saved = 0
      for _, invItem in ipairs(items) do
        IonRP.Database:PreparedQuery(
          "INSERT INTO ionrp_inventory_items (inventory_id, item_identifier, quantity, pos_x, pos_y) VALUES (?, ?, ?, ?, ?)",
          {inv.id, invItem.item.identifier, invItem.quantity, invItem.x, invItem.y},
          function()
            saved = saved + 1
            if saved >= #items then
              if callback then callback(true) end
            end
          end
        )
      end
    end
  )
end

--- Serialize inventory for network
--- @param inv Inventory
--- @return table
function IonRP.Inventory:Serialize(inv)
  local data = {
    width = inv.width,
    height = inv.height,
    maxWeight = inv.maxWeight,
    weight = inv:GetWeight(),
    items = {}
  }
  
  for _, invItem in ipairs(inv:GetItems()) do
    table.insert(data.items, {
      identifier = invItem.item.identifier,
      quantity = invItem.quantity,
      x = invItem.x,
      y = invItem.y
    })
  end
  
  return data
end

--- Send inventory to client
--- @param ply Player
function IonRP.Inventory:SendToClient(ply)
  if not IsValid(ply) or not ply.IonRP_Inventory then return end
  
  local data = self:Serialize(ply.IonRP_Inventory)
  
  net.Start("IonRP_Inventory_Sync")
  net.WriteTable(data)
  net.Send(ply)
end

--- Open inventory for player
--- @param ply Player
function IonRP.Inventory:Open(ply)
  if not IsValid(ply) or not ply.IonRP_Inventory then return end
  
  self:SendToClient(ply)
  
  net.Start("IonRP_Inventory_Open")
  net.Send(ply)
end

-- Network receivers

net.Receive("IonRP_Inventory_Open", function(len, ply)
  IonRP.Inventory:Open(ply)
end)

net.Receive("IonRP_Inventory_Move", function(len, ply)
  local inv = ply.IonRP_Inventory
  if not inv then return end
  
  local fromX = net.ReadUInt(8)
  local fromY = net.ReadUInt(8)
  local toX = net.ReadUInt(8)
  local toY = net.ReadUInt(8)
  local quantity = net.ReadUInt(16)
  
  if quantity == 0 then quantity = nil end
  
  local fromItem = inv:GetItemAt(fromX, fromY)
  if not fromItem then return end
  
  local success, err = inv:MoveItem(fromItem, toX, toY, quantity)
  
  if success then
    IonRP.Inventory:SendToClient(ply)
    timer.Simple(0.5, function()
      if IsValid(ply) then
        IonRP.Inventory:Save(ply)
      end
    end)
  else
    ply:ChatPrint("Cannot move: " .. (err or "unknown error"))
  end
end)

net.Receive("IonRP_Inventory_Use", function(len, ply)
  local inv = ply.IonRP_Inventory
  if not inv then return end
  
  local x = net.ReadUInt(8)
  local y = net.ReadUInt(8)
  
  local invItem = inv:GetItemAt(x, y)
  if not invItem then return end
  
  local item = invItem.item:MakeOwnedInstance(ply)
  
  local consume = false
  if item.SV_Use then
    consume = item:SV_Use()
  end
  
  if consume then
    inv:RemoveItem(invItem, 1)
    IonRP.Inventory:SendToClient(ply)
    
    timer.Simple(0.5, function()
      if IsValid(ply) then
        IonRP.Inventory:Save(ply)
      end
    end)
  end
end)

net.Receive("IonRP_Inventory_Craft", function(len, ply)
  local recipeId = net.ReadString()
  
  local recipe = IonRP.Recipes and IonRP.Recipes.List and IonRP.Recipes.List[recipeId]
  if not recipe then
    ply:ChatPrint("Invalid recipe!")
    return
  end
  
  local success, err = recipe:SV_Craft(ply)
  
  if success then
    ply:ChatPrint("Crafted " .. recipe.name .. "!")
    IonRP.Inventory:SendToClient(ply)
    
    timer.Simple(0.5, function()
      if IsValid(ply) then
        IonRP.Inventory:Save(ply)
      end
    end)
  else
    ply:ChatPrint("Cannot craft: " .. (err or "unknown error"))
  end
end)

-- Auto-save every 5 minutes
timer.Create("IonRP_Inventory_AutoSave", 300, 0, function()
  for _, ply in ipairs(player.GetAll()) do
    if ply.IonRP_Inventory then
      IonRP.Inventory:Save(ply)
    end
  end
end)

-- Player meta functions
--- @class Player
local plyMeta = FindMetaTable("Player")

---@return Inventory|nil
function plyMeta:GetInventory()
  return self.IonRP_Inventory
end

function plyMeta:OpenInventory()
  IonRP.Inventory:Open(self)
end

function plyMeta:GiveItem(identifier, quantity)
  local inv = self:GetInventory()
  if not inv then return false, "No inventory" end
  
  local item = IonRP.Items.List[identifier]
  if not item then return false, "Invalid item" end
  
  local success, err = inv:AddItem(item, quantity or 1)
  
  if success then
    IonRP.Inventory:SendToClient(self)
    timer.Simple(0.5, function()
      if IsValid(self) then
        IonRP.Inventory:Save(self)
      end
    end)
  end
  
  return success, err
end

function plyMeta:TakeItem(identifier, quantity, noSync)
  local inv = self:GetInventory()
  if not inv then return false, "No inventory" end
  
  quantity = quantity or 1
  local remaining = quantity
  
  for _, invItem in ipairs(inv:GetItems()) do
    if invItem.item.identifier == identifier and remaining > 0 then
      local remove = math.min(remaining, invItem.quantity)
      inv:RemoveItem(invItem, remove)
      remaining = remaining - remove
    end
  end
  
  if remaining < quantity then
    if not noSync then
      IonRP.Inventory:SendToClient(self)
      timer.Simple(0.5, function()
        if IsValid(self) then
          IonRP.Inventory:Save(self)
        end
      end)
    end
    return true
  end
  
  return false, "Not enough items"
end

function plyMeta:TakeItems(items)
  for i, entry in ipairs(items) do
    local success, err = self:TakeItem(entry.itemIdentifier, entry.quantity, i < #items)
    if not success then return false, err end
  end
  return true
end

function plyMeta:HasItem(identifier, quantity)
  local inv = self:GetInventory()
  if not inv then return false end
  
  return inv:CountItem(identifier) >= (quantity or 1)
end

function plyMeta:SV_EquipWeapon(item)
  if not item or item.type ~= "weapon" or not item.weaponClass then
    return false
  end
  
  if not self:HasWeapon(item.weaponClass) then
    self:Give(item.weaponClass, true)
    self:ChatPrint("Equipped " .. item.name)
    return true
  else
    self:ChatPrint("You already have this weapon equipped")
    return false
  end
end

-- Network handler: Unequip weapon and add back to inventory
net.Receive("IonRP_Inventory_UnequipWeapon", function(len, ply)
  local itemIdentifier = net.ReadString()
  
  if not IsValid(ply) then return end
  
  local item = IonRP.Items.List[itemIdentifier]
  if not item or item.type ~= "weapon" or not item.weaponClass then
    ply:ChatPrint("[IonRP] Invalid weapon item")
    return
  end
  
  -- Check if player has the weapon equipped
  if not ply:HasWeapon(item.weaponClass) then
    ply:ChatPrint("[IonRP] You don't have this weapon equipped")
    return
  end
  
  local inv = ply:GetInventory()
  if not inv then
    ply:ChatPrint("[IonRP] No inventory available")
    return
  end
  
  -- Check if there's space in inventory
  if not inv:CanFitQuantity(item, 1) then
    ply:ChatPrint("[IonRP] Not enough space in inventory")
    return
  end
  
  -- Remove weapon from player
  ply:StripWeapon(item.weaponClass)
  
  -- Add to inventory
  local success, err = inv:AddItem(item, 1)
  if success then
    ply:ChatPrint("Unequipped " .. item.name)
    IonRP.Inventory:SendToClient(ply)
    timer.Simple(0.5, function()
      if IsValid(ply) then
        IonRP.Inventory:Save(ply)
      end
    end)
  else
    -- If adding to inventory failed, give weapon back
    ply:Give(item.weaponClass)
    ply:ChatPrint("[IonRP] Failed to add weapon to inventory: " .. (err or "Unknown error"))
  end
end)

print("[IonRP Inventory] Server-side inventory system loaded")
