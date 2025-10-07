--[[
    IonRP Inventory System
    Server-side inventory management and database operations
]] --

include("sh_inventory.lua")
AddCSLuaFile("sh_inventory.lua")
AddCSLuaFile("cl_inventory.lua")

-- Network strings
util.AddNetworkString("IonRP_RequestOpenInventory")
util.AddNetworkString("IonRP_OpenInventory")
util.AddNetworkString("IonRP_CloseInventory")
util.AddNetworkString("IonRP_SyncInventory")
util.AddNetworkString("IonRP_MoveItem")
util.AddNetworkString("IonRP_UseItem")
util.AddNetworkString("IonRP_DropItem")
util.AddNetworkString("IonRP_SplitStack")

--[[
    Initialize inventory database tables
]] --
function IonRP.Inventory:InitializeTables()
  print("[IonRP Inventory] Initializing inventory tables...")

  -- Create inventories table
  local query = IonRP.Database:query([[
    CREATE TABLE IF NOT EXISTS ionrp_inventories (
      id INT AUTO_INCREMENT PRIMARY KEY,
      steam_id VARCHAR(32) NOT NULL,
      width INT NOT NULL DEFAULT 5,
      height INT NOT NULL DEFAULT 3,
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
    print("[IonRP Inventory] ERROR: " .. err)
    print("[IonRP Inventory] SQL: " .. sql)
  end

  query:start()

  -- Create inventory items table
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
    print("[IonRP Inventory] ERROR: " .. err)
    print("[IonRP Inventory] SQL: " .. sql)
  end

  itemsQuery:start()
end

--- Get or create a player's inventory
--- @param ply Player
--- @param callback fun(inv: Inventory|nil)
function IonRP.Inventory:GetOrCreate(ply, callback)
  if not IsValid(ply) then
    if callback then callback(nil) end
    return
  end

  local steamID = ply:SteamID64()

  -- Check if inventory exists
  IonRP.Database:PreparedQuery(
    "SELECT * FROM ionrp_inventories WHERE steam_id = ? LIMIT 1",
    { steamID },
    function(data)
      if data and #data > 0 then
        -- Load existing inventory
        self:Load(ply, data[1].id, callback)
      else
        -- Create new inventory
        self:Create(ply, callback)
      end
    end,
    function(err)
      print("[IonRP Inventory] Error getting inventory: " .. err)
      if callback then callback(nil) end
    end
  )
end

--- Create a new inventory for a player
--- @param ply Player
--- @param callback fun(inv: Inventory|nil)
function IonRP.Inventory:Create(ply, callback)
  if not IsValid(ply) then
    if callback then callback(nil) end
    return
  end

  local steamID = ply:SteamID64()

  IonRP.Database:PreparedQuery(
    "INSERT INTO ionrp_inventories (steam_id, width, height, max_weight) VALUES (?, ?, ?, ?)",
    { steamID, 5, 3, 50.0 },
    function(data)
      print("[IonRP Inventory] Created inventory for " .. ply:Nick())

      -- Load the newly created inventory
      self:GetOrCreate(ply, callback)
    end,
    function(err)
      print("[IonRP Inventory] Error creating inventory: " .. err)
      if callback then callback(nil) end
    end
  )
end

--- Load a player's inventory from database
--- @param _ply Player
--- @param inventoryID number
--- @param callback function(Inventory|nil)
function IonRP.Inventory:Load(_ply, inventoryID, callback)
  --- Used for proper typing
  --- @class Player
  local ply = _ply
  if not IsValid(ply) then
    if callback then callback(nil) end
    return
  end

  -- Get inventory metadata
  IonRP.Database:PreparedQuery(
    "SELECT * FROM ionrp_inventories WHERE id = ? LIMIT 1",
    { inventoryID },
    function(invData)
      if not invData or #invData == 0 then
        print("[IonRP Inventory] Inventory not found: " .. inventoryID)
        if callback then callback(nil) end
        return
      end

      local invMeta = invData[1]
      local inv = INVENTORY:New(
        tonumber(invMeta.width) or 5,
        tonumber(invMeta.height) or 3,
        tonumber(invMeta.max_weight) or 50.0
      )
      inv.owner = ply
      inv.id = tonumber(invMeta.id)

      -- Load inventory items
      IonRP.Database:PreparedQuery(
        "SELECT * FROM ionrp_inventory_items WHERE inventory_id = ?",
        { inventoryID },
        function(itemsData)
          if itemsData then
            for _, itemData in ipairs(itemsData) do
              local itemDef = IonRP.Items.List[itemData.item_identifier]

              if itemDef then
                local success, err = inv:AddItem(
                  itemDef,
                  tonumber(itemData.quantity) or 1,
                  tonumber(itemData.pos_x),
                  tonumber(itemData.pos_y)
                )

                if not success then
                  print("[IonRP Inventory] Warning: Failed to load item " ..
                    itemData.item_identifier .. ": " .. (err or "unknown error"))
                end
              else
                print("[IonRP Inventory] Warning: Unknown item: " .. itemData.item_identifier)
              end
            end
          end

          -- Store inventory on player
          ply.IonRP_Inventory = inv

          print("[IonRP Inventory] Loaded inventory for " .. ply:Nick() .. " with " .. table.Count(inv.slots) .. " slots")

          -- Send inventory to client immediately after loading
          timer.Simple(0.5, function()
            if IsValid(ply) then
              self:SendToClient(ply)
              print("[IonRP Inventory] Sent inventory to client for " .. ply:Nick())
            end
          end)

          if callback then callback(inv) end
        end,
        function(err)
          print("[IonRP Inventory] Error loading inventory items: " .. err)
          if callback then callback(nil) end
        end
      )
    end,
    function(err)
      print("[IonRP Inventory] Error loading inventory: " .. err)
      if callback then callback(nil) end
    end
  )
end

--- Save a player's inventory to database
--- @param ply Player
--- @param callback fun(saved: boolean)|nil
function IonRP.Inventory:Save(ply, callback)
  if not IsValid(ply) or not ply.IonRP_Inventory then
    if callback then callback(false) end
    return
  end

  local inv = ply.IonRP_Inventory

  if not inv.id then
    print("[IonRP Inventory] Cannot save inventory without ID")
    if callback then callback(false) end
    return
  end

  -- Clear existing items
  IonRP.Database:PreparedQuery(
    "DELETE FROM ionrp_inventory_items WHERE inventory_id = ?",
    { inv.id },
    function()
      -- Insert all current items
      local items = inv:GetAllItems()
      local inserted = 0
      local toInsert = #items

      if toInsert == 0 then
        print("[IonRP Inventory] Saved empty inventory for " .. ply:Nick())
        if callback then callback(true) end
        return
      end

      for _, entry in ipairs(items) do
        IonRP.Database:PreparedQuery(
          "INSERT INTO ionrp_inventory_items (inventory_id, item_identifier, quantity, pos_x, pos_y) VALUES (?, ?, ?, ?, ?)",
          { inv.id, entry.item.identifier, entry.quantity, entry.x, entry.y },
          function()
            inserted = inserted + 1

            if inserted >= toInsert then
              print("[IonRP Inventory] Saved inventory for " .. ply:Nick() .. " (" .. toInsert .. " items)")
              if callback then callback(true) end
            end
          end,
          function(err)
            print("[IonRP Inventory] Error inserting item: " .. err)
          end
        )
      end
    end,
    function(err)
      print("[IonRP Inventory] Error clearing inventory items: " .. err)
      if callback then callback(false) end
    end
  )
end

--[[
    Get a player's inventory (creates if doesn't exist)
    @param ply Player
    @return Inventory|nil
]] --
function IonRP.Inventory:Get(ply)
  if not IsValid(ply) then return nil end
  return ply.IonRP_Inventory
end

--[[
    Serialize inventory for network transmission
    @param inv Inventory
    @return table
]] --
function IonRP.Inventory:Serialize(inv)
  local data = {
    width = inv.width,
    height = inv.height,
    maxWeight = inv.maxWeight,
    currentWeight = inv:GetTotalWeight(),
    items = {}
  }

  for _, entry in ipairs(inv:GetAllItems()) do
    table.insert(data.items, {
      identifier = entry.item.identifier,
      quantity = entry.quantity,
      x = entry.x,
      y = entry.y
    })
  end

  return data
end

--- Send inventory to client
--- @param ply Player
function IonRP.Inventory:SendToClient(ply)
  if not IsValid(ply) or not ply.IonRP_Inventory then return end

  local invData = self:Serialize(ply.IonRP_Inventory)

  net.Start("IonRP_SyncInventory")
  net.WriteTable(invData)
  net.Send(ply)
end

--- Open inventory for player
--- @param ply Player
function IonRP.Inventory:Open(ply)
  if not IsValid(ply) or not ply.IonRP_Inventory then return end

  self:SendToClient(ply)

  net.Start("IonRP_OpenInventory")
  net.Send(ply)
end

-- Network handlers

-- Player requests to open inventory (sends fresh data)
net.Receive("IonRP_RequestOpenInventory", function(len, ply)
  print("[IonRP Inventory] " .. ply:Nick() .. " requested to open inventory")
  IonRP.Inventory:Open(ply)
end)

-- Player requests to move an item
net.Receive("IonRP_MoveItem", function(len, ply)
  local inv = IonRP.Inventory:Get(ply)
  if not inv then return end

  local fromX = net.ReadUInt(8)
  local fromY = net.ReadUInt(8)
  local toX = net.ReadUInt(8)
  local toY = net.ReadUInt(8)
  local quantity = net.ReadUInt(16) -- Read quantity (0 = move all)

  if quantity == 0 then quantity = nil end -- nil means move all

  print(string.format("[IonRP Inventory] Move request: from (%d,%d) to (%d,%d), quantity: %s", 
    fromX, fromY, toX, toY, tostring(quantity or "all")))

  local success, err = inv:MoveItem(fromX, fromY, toX, toY, quantity)

  if success then
    -- Resync inventory
    IonRP.Inventory:SendToClient(ply)

    -- Save to database
    timer.Simple(0.5, function()
      if IsValid(ply) then
        IonRP.Inventory:Save(ply)
      end
    end)
  else
    ply:ChatPrint("Cannot move item: " .. (err or "unknown error"))
  end
end)

-- Player requests to use an item
net.Receive("IonRP_UseItem", function(len, ply)
  local inv = IonRP.Inventory:Get(ply)
  if not inv then return end

  local x = net.ReadUInt(8)
  local y = net.ReadUInt(8)

  local slot = inv:GetSlot(x, y)
  if not slot or not slot.item then
    ply:ChatPrint("No item at that position")
    return
  end

  -- Create an owned instance of the item
  local itemInstance = slot.item:MakeOwnedInstance(ply)

  -- Call the server-side use function
  local shouldConsume = false
  if itemInstance.SV_Use then
    shouldConsume = itemInstance:SV_Use()
  end

  -- Consume the item if needed
  if shouldConsume then
    local success, _, _ = inv:RemoveItem(x, y, 1)

    if success then
      ply:ChatPrint("Used " .. slot.item.name)

      -- Resync inventory
      IonRP.Inventory:SendToClient(ply)

      -- Save to database
      timer.Simple(0.5, function()
        if IsValid(ply) then
          IonRP.Inventory:Save(ply)
        end
      end)
    end
  end
end)

-- Player disconnects - save inventory
hook.Add("PlayerDisconnected", "IonRP_SaveInventory", function(ply)
  if ply.IonRP_Inventory then
    IonRP.Inventory:Save(ply)
  end
end)

-- Autosave inventories every 5 minutes
timer.Create("IonRP_AutoSaveInventories", 300, 0, function()
  for _, ply in ipairs(player.GetAll()) do
    if ply.IonRP_Inventory then
      IonRP.Inventory:Save(ply)
    end
  end
  print("[IonRP Inventory] Auto-saved all inventories")
end)

-- Add player methods
--- @class Player
local playerMeta = FindMetaTable("Player")

--- Get the player's inventory
--- @return Inventory|nil
function playerMeta:GetInventory()
  return self.IonRP_Inventory
end

--- Open the inventory UI for this player
function playerMeta:OpenInventory()
  IonRP.Inventory:Open(self)
end

--- Give an item to the player
--- @param itemIdentifier string
--- @param quantity number
--- @return boolean, string|nil
function playerMeta:GiveItem(itemIdentifier, quantity)
  local inv = self:GetInventory()
  if not inv then return false, "No inventory" end

  local item = IonRP.Items.List[itemIdentifier]
  if not item then return false, "Invalid item" end

  local success, err = inv:AddItem(item, quantity or 1)

  if success then
    IonRP.Inventory:SendToClient(self)

    -- Save to database
    timer.Simple(0.5, function()
      if IsValid(self) then
        IonRP.Inventory:Save(self)
      end
    end)
  end

  return success, err
end

--- Remove an item from the player's inventory
--- @param itemIdentifier string
--- @param quantity number
--- @return boolean, string|nil
function playerMeta:TakeItem(itemIdentifier, quantity)
  local inv = self:GetInventory()
  if not inv then return false, "No inventory" end

  quantity = quantity or 1

  -- Find the item in inventory
  for _, entry in ipairs(inv:GetAllItems()) do
    if entry.item.identifier == itemIdentifier then
      local toRemove = math.min(quantity, entry.quantity)
      local success, _, removed = inv:RemoveItem(entry.x, entry.y, toRemove)

      if success then
        quantity = quantity - removed

        IonRP.Inventory:SendToClient(self)

        -- Save to database
        timer.Simple(0.5, function()
          if IsValid(self) then
            IonRP.Inventory:Save(self)
          end
        end)

        if quantity <= 0 then
          return true, nil
        end
      end
    end
  end

  if quantity > 0 then
    return false, "Not enough items"
  end

  return true, nil
end

--- Check if player has an item
--- @param itemIdentifier string
--- @param quantity number|nil
--- @return boolean
function playerMeta:HasItem(itemIdentifier, quantity)
  local inv = self:GetInventory()
  if not inv then return false end

  quantity = quantity or 1
  local found = 0

  for _, entry in ipairs(inv:GetAllItems()) do
    if entry.item.identifier == itemIdentifier then
      found = found + entry.quantity
    end
  end

  return found >= quantity
end

--- Equip a weapon from inventory
--- @param item ITEM The weapon item to equip
--- @return boolean
function playerMeta:SV_EquipWeapon(item)
  -- TODO: Implement Equip Weapon... and inventory lol
  -- The function should equip the specific weapon and put the item in the player's weapon slot
  -- It should unequip any existing weapon in that slot first as well, if applicable.
  
  if not item or item.type ~= "weapon" or not item.weaponClass then
    return false
  end

  -- TODO: Implement weapon slot management
  -- For now, just give the weapon
  if not self:HasWeapon(item.weaponClass) then
    self:Give(item.weaponClass)
    self:ChatPrint("Equipped " .. item.name)
    return true
  else
    self:ChatPrint("You already have this weapon equipped")
    return false
  end
end

print("[IonRP Inventory] Server-side inventory system loaded")
