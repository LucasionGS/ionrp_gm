--[[
    Property System - Server
    Handles property persistence, ownership, and door management
]]--

util.AddNetworkString("IonRP_Property_Sync")
util.AddNetworkString("IonRP_Property_UpdateDoor")

--- Initialize the property database tables
function IonRP.Properties:InitializeTables()
  -- Properties table
  local propertiesQuery = [[
    CREATE TABLE IF NOT EXISTS ionrp_properties (
      id INT AUTO_INCREMENT PRIMARY KEY,
      map_name VARCHAR(64) NOT NULL,
      name VARCHAR(128) NOT NULL,
      description TEXT,
      category VARCHAR(64) DEFAULT 'Other',
      purchasable TINYINT(1) DEFAULT 1,
      price INT NOT NULL DEFAULT 0,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      INDEX idx_map_name (map_name)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  ]]

  IonRP.Database:PreparedQuery(propertiesQuery, {}, function()
    print("[IonRP Properties] Properties table initialized")
  end, function(err)
    print("[IonRP Properties] Failed to initialize properties table: " .. err)
  end)

  -- Property doors table
  local doorsQuery = [[
    CREATE TABLE IF NOT EXISTS ionrp_property_doors (
      id INT AUTO_INCREMENT PRIMARY KEY,
      property_id INT NOT NULL,
      pos_x FLOAT NOT NULL,
      pos_y FLOAT NOT NULL,
      pos_z FLOAT NOT NULL,
      is_locked TINYINT(1) DEFAULT 0,
      is_gate TINYINT(1) DEFAULT 0,
      door_group VARCHAR(64) NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (property_id) REFERENCES ionrp_properties(id) ON DELETE CASCADE,
      INDEX idx_property (property_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  ]]

  IonRP.Database:PreparedQuery(doorsQuery, {}, function()
    print("[IonRP Properties] Property doors table initialized")
    
    -- Load properties for current map after tables are ready
    timer.Simple(0.5, function()
      IonRP.Properties:LoadPropertiesForMap()
    end)
  end, function(err)
    print("[IonRP Properties] Failed to initialize doors table: " .. err)
  end)
end

--- Save the current property and all its doors to the database
--- @param callback function|nil Optional callback(success, propertyId)
function PROPERTY:Save(callback)
  local mapName = game.GetMap()
  
  if self.id then
    -- Update existing property
    self:Update(callback)
    return
  end
  
  -- Insert new property
  local query = [[
    INSERT INTO ionrp_properties (map_name, name, description, category, purchasable, price)
    VALUES (?, ?, ?, ?, ?, ?)
  ]]
  
  IonRP.Database:PreparedQuery(
    query,
    { mapName, self.name, self.description, self.category, self.purchasable and 1 or 0, self.price },
    function(data, query)
      local propertyId = query:lastInsert()
      self.id = propertyId
      
      print("[IonRP Properties] Saved property '" .. self.name .. "' with ID: " .. propertyId)
      
      -- Now save all doors
      self:SaveDoors(function(doorsSuccess)
        if callback then
          callback(doorsSuccess, propertyId)
        end
        
        -- Sync to all clients
        if doorsSuccess then
          IonRP.Properties:SyncPropertyToClients(self)
        end
      end)
      
      -- Register in list
      IonRP.Properties.List[propertyId] = self
    end,
    function(err)
      print("[IonRP Properties] Failed to save property: " .. err)
      if callback then
        callback(false)
      end
    end
  )
end

--- Update an existing property in the database
--- @param callback function|nil Optional callback(success)
function PROPERTY:Update(callback)
  if not self.id then
    print("[IonRP Properties] Cannot update property without ID")
    if callback then callback(false) end
    return
  end
  
  local query = [[
    UPDATE ionrp_properties 
    SET name = ?, description = ?, category = ?, purchasable = ?, price = ?
    WHERE id = ?
  ]]
  
  IonRP.Database:PreparedQuery(
    query,
    { self.name, self.description, self.category, self.purchasable and 1 or 0, self.price, self.id },
    function()
      print("[IonRP Properties] Updated property ID: " .. self.id)
      
      -- Update doors as well
      self:SaveDoors(function(success)
        if callback then
          callback(success)
        end
        
        -- Sync to all clients
        if success then
          IonRP.Properties:SyncPropertyToClients(self)
        end
      end)
    end,
    function(err)
      print("[IonRP Properties] Failed to update property: " .. err)
      if callback then
        callback(false)
      end
    end
  )
end

--- Save all doors for this property
--- @param callback function|nil Optional callback(success)
function PROPERTY:SaveDoors(callback)
  if not self.id then
    print("[IonRP Properties] Cannot save doors without property ID")
    if callback then callback(false) end
    return
  end
  
  -- First, delete all existing doors for this property
  local deleteQuery = "DELETE FROM ionrp_property_doors WHERE property_id = ?"
  
  IonRP.Database:PreparedQuery(
    deleteQuery,
    { self.id },
    function()
      -- Now insert all doors
      local doorsToSave = #self.doors
      if doorsToSave == 0 then
        if callback then callback(true) end
        return
      end
      
      local doorsSaved = 0
      local hasError = false
      
      for _, door in ipairs(self.doors) do
        local insertQuery = [[
          INSERT INTO ionrp_property_doors (property_id, pos_x, pos_y, pos_z, is_locked, is_gate, door_group)
          VALUES (?, ?, ?, ?, ?, ?, ?)
        ]]
        
        IonRP.Database:PreparedQuery(
          insertQuery,
          { self.id, door.pos.x, door.pos.y, door.pos.z, door.isLocked and 1 or 0, door.isGate and 1 or 0, door.group },
          function(data, query)
            door.id = query:lastInsert()
            doorsSaved = doorsSaved + 1
            
            if doorsSaved == doorsToSave and not hasError then
              print("[IonRP Properties] Saved " .. doorsSaved .. " doors for property ID: " .. self.id)
              if callback then callback(true) end
            end
          end,
          function(err)
            print("[IonRP Properties] Failed to save door: " .. err)
            hasError = true
            if callback then callback(false) end
          end
        )
      end
    end,
    function(err)
      print("[IonRP Properties] Failed to delete old doors: " .. err)
      if callback then callback(false) end
    end
  )
end

--- Delete this property and all its doors from the database
--- @param callback function|nil Optional callback(success)
function PROPERTY:Delete(callback)
  if not self.id then
    print("[IonRP Properties] Cannot delete property without ID")
    if callback then callback(false) end
    return
  end
  
  local query = "DELETE FROM ionrp_properties WHERE id = ?"
  
  IonRP.Database:PreparedQuery(
    query,
    { self.id },
    function()
      print("[IonRP Properties] Deleted property ID: " .. self.id)
      
      -- Remove from list
      IonRP.Properties.List[self.id] = nil
      
      if callback then
        callback(true)
      end
    end,
    function(err)
      print("[IonRP Properties] Failed to delete property: " .. err)
      if callback then
        callback(false)
      end
    end
  )
end

--- Load all properties for the current map
function IonRP.Properties:LoadPropertiesForMap()
  local mapName = game.GetMap()
  
  local query = "SELECT * FROM ionrp_properties WHERE map_name = ?"
  
  IonRP.Database:PreparedQuery(
    query,
    { mapName },
    function(data)
      if not data or #data == 0 then
        print("[IonRP Properties] No properties found for map: " .. mapName)
        return
      end
      
      print("[IonRP Properties] Loading " .. #data .. " properties for map: " .. mapName)
      
      -- Load each property
      for _, propData in ipairs(data) do
        self:LoadProperty(propData)
      end
    end,
    function(err)
      print("[IonRP Properties] Failed to load properties: " .. err)
    end
  )
end

--- Load a single property and its doors from database
--- @param propData table Property data from database
function IonRP.Properties:LoadProperty(propData)
  -- Load doors for this property
  local doorsQuery = "SELECT * FROM ionrp_property_doors WHERE property_id = ?"
  
  IonRP.Database:PreparedQuery(
    doorsQuery,
    { propData.id },
    function(doorData)
      -- Create property instance
      local property = PROPERTY:New({
        id = propData.id,
        name = propData.name,
        description = propData.description,
        category = propData.category,
        purchasable = propData.purchasable == 1,
        price = propData.price
      }, {})
      
      -- Add doors
      if doorData and #doorData > 0 then
        for _, door in ipairs(doorData) do
          local doorObj = PROPERTY_DOOR:New({
            pos = Vector(door.pos_x, door.pos_y, door.pos_z),
            isLocked = door.is_locked == 1,
            isGate = door.is_gate == 1,
            group = door.door_group
          })
          doorObj.id = door.id
          doorObj.property = property
          table.insert(property.doors, doorObj)
        end
      end
      
      -- Owner is set at runtime, not loaded from database
      
      -- Find door entities
      property:FindDoorEntities()
      
      -- Register property
      IonRP.Properties.List[property.id] = property
      
      -- Sync to all clients
      self:SyncPropertyToClients(property)
      
      print("[IonRP Properties] Loaded property: " .. property.name .. " (ID: " .. property.id .. ") with " .. #property.doors .. " doors")
    end,
    function(err)
      print("[IonRP Properties] Failed to load doors for property ID " .. propData.id .. ": " .. err)
    end
  )
end

--- Sync a property to all clients
--- @param property Property The property to sync
function IonRP.Properties:SyncPropertyToClients(property)
  local propertyData = {
    id = property.id,
    name = property.name,
    description = property.description,
    category = property.category,
    purchasable = property.purchasable,
    price = property.price,
    ownerSteamID = IsValid(property.owner) and property.owner:SteamID64() or nil,
    doors = {}
  }
  
  -- Include door data
  for _, door in ipairs(property.doors) do
    table.insert(propertyData.doors, {
      pos = door.pos,
      isLocked = door.isLocked,
      isGate = door.isGate,
      group = door.group,
      _entityIndex = door._entityIndex or (door.entity and door.entity:EntIndex()) or nil,
    })
  end
  
  net.Start("IonRP_Property_Sync")
    net.WriteTable(propertyData)
  net.Broadcast()
end

--- Sync property to a specific player
--- @param ply Player The player to sync to
--- @param property Property The property to sync
function IonRP.Properties:SyncPropertyToPlayer(ply, property)
  if not IsValid(ply) then return end
  
  local propertyData = {
    id = property.id,
    name = property.name,
    description = property.description,
    category = property.category,
    purchasable = property.purchasable,
    price = property.price,
    ownerSteamID = IsValid(property.owner) and property.owner:SteamID64() or nil,
    doors = {},
  }
  
  -- Include door data
  for _, door in ipairs(property.doors) do
    table.insert(propertyData.doors, {
      pos = door.pos,
      isLocked = door.isLocked,
      isGate = door.isGate,
      group = door.group,
      _entityIndex = door._entityIndex or (door.entity and door.entity:EntIndex()) or nil,
    })
  end
  
  net.Start("IonRP_Property_Sync")
    net.WriteTable(propertyData)
  net.Send(ply)
end

--- Sync all properties to a player (on join)
--- @param ply Player The player to sync to
function IonRP.Properties:SyncAllToPlayer(ply)
  for id, property in pairs(self.List) do
    self:SyncPropertyToPlayer(ply, property)
  end
end

--- Find door entities for all doors in this property
function PROPERTY:FindDoorEntities()
  for _, door in ipairs(self.doors) do
    door:FindEntity()
  end
end

--- Find the door entity at this door's position
function PROPERTY_DOOR:FindEntity()
  -- Find closest door entity to this position
  local closestDoor = nil
  local closestDist = 50 -- Max 50 units away
  
  for _, ent in ipairs(ents.GetAll()) do
    if IsValid(ent) and (ent:GetClass() == "prop_door_rotating" or ent:GetClass() == "func_door" or ent:GetClass() == "func_door_rotating") then
      local dist = ent:GetPos():Distance(self.pos)
      if dist < closestDist then
        closestDoor = ent
        closestDist = dist
      end
    end
  end
  
  if closestDoor and IsValid(closestDoor) then
    self.entity = closestDoor
    self._entityIndex = closestDoor:EntIndex()
    
    -- Set door state
    if self.isLocked then
      closestDoor:Fire("Lock")
    else
      closestDoor:Fire("Unlock")
    end
    
    -- Store property reference on door
    closestDoor:SetNWInt("PropertyID", self.property.id or 0)
    closestDoor:SetNWString("PropertyName", self.property.name or "")
    closestDoor:SetNWEntity("PropertyOwner", self.property.owner or NULL)
  end
end

--- Set the lock state of this door
--- @param locked boolean Whether the door should be locked
function PROPERTY_DOOR:SetLocked(locked)
  self.isLocked = locked
  
  if IsValid(self.entity) then
    if locked then
      self.entity:Fire("Lock")
    else
      self.entity:Fire("Unlock")
    end
  end
end

--- Set the lock state for all doors in this property (or a specific group)
--- @param locked boolean Whether doors should be locked
--- @param group string|nil Optional door group to lock (nil = all doors)
function PROPERTY:SetDoorsLocked(locked, group)
  for _, door in ipairs(self.doors) do
    if not group or door.group == group then
      door:SetLocked(locked)
    end
  end
end

--- Set the owner of this property (runtime only, not saved to database)
--- @param ply Player|nil The new owner (nil to clear ownership)
function PROPERTY:SetOwner(ply)
  self.owner = ply
  
  -- Ownership is runtime only and cleared on server restart
  if ply and IsValid(ply) then
    print("[IonRP Properties] Set owner of property '" .. self.name .. "' to " .. ply:Nick())
  else
    print("[IonRP Properties] Cleared owner of property '" .. self.name .. "'")
  end
  
  -- Sync to clients
  IonRP.Properties:SyncPropertyToClients(self)
end

--- Purchase a property (handles bank transaction and ownership)
--- @param ply Player The player purchasing the property
--- @param propertyId number The ID of the property to purchase
--- @param callback function|nil Optional callback(success, message)
function IonRP.Properties:SV_PurchaseProperty(ply, propertyId, callback)
  if not IsValid(ply) then
    if callback then callback(false, "Invalid player") end
    return
  end
  
  -- Get property
  --- @type Property|nil
  local property = self.List[propertyId]
  if not property then
    if callback then callback(false, "Property not found") end
    return
  end
  
  -- Check if property is purchasable
  if not property.purchasable then
    if callback then callback(false, "This property is not for sale") end
    return
  end
  
  -- Check if already owned
  if property.owner and IsValid(property.owner) then
    if callback then callback(false, "This property is already owned by " .. property.owner:Nick()) end
    return
  end
  
  -- Check if player has enough money in bank
  local bank = ply:GetBank()
  if bank < property.price then
    if callback then callback(false, "Insufficient funds in bank account") end
    return
  end
  
  -- Deduct money from bank
  ply:SetBank(bank - property.price)
  
  -- Set owner
  property:SetOwner(ply)
  
  -- Success callback
  if callback then
    callback(true, string.format("Successfully purchased %s for %s", property.name, IonRP.Util:FormatMoney(property.price)))
  end
  
  print(string.format("[IonRP Properties] %s purchased property '%s' (ID: %d) for %s", 
    ply:Nick(), property.name, property.id, IonRP.Util:FormatMoney(property.price)))
end

--- Hook: Initialize on map load
hook.Add("InitPostEntity", "IonRP_Properties_LoadMap", function()
  timer.Simple(1, function()
    IonRP.Properties:LoadPropertiesForMap()
  end)
end)

--- Hook: Clean up property gun editing state when player disconnects
hook.Add("PlayerDisconnected", "IonRP_Properties_CleanupPropertyGun", function(ply)
  -- Clear any property gun editing state
  ply.PropertyGun_EditingProperty = nil
  ply.PropertyGun_IsNewProperty = nil
end)

--- Hook: Sync all properties to player when they join
hook.Add("PlayerInitialSpawn", "IonRP_Properties_SyncToPlayer", function(ply)
  -- Delay sync slightly to ensure client is ready
  timer.Simple(2, function()
    if IsValid(ply) then
      IonRP.Properties:SyncAllToPlayer(ply)
    end
  end)
end)

print("[IonRP Properties] Server module loaded")

-- Commands
IonRP.Commands.Add("property_gun", function(ply)
  ply:Give("weapon_ionrp_property_gun")
  ply:ChatPrint("[IonRP] Given property gun")
end, "Give yourself the property management gun", "developer")

IonRP.Commands.Add("keys", function(ply)
  ply:Give("weapon_ionrp_keys")
  ply:ChatPrint("[IonRP] Given keys")
end, "Give yourself keys to lock/unlock your properties and vehicles")