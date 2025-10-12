--[[
  Buddy System - Server
  Manages buddy relationships with database persistence
]]--

util.AddNetworkString("IonRP_Buddy_Sync")
util.AddNetworkString("IonRP_Buddy_Add")
util.AddNetworkString("IonRP_Buddy_Remove")
util.AddNetworkString("IonRP_Buddy_UpdatePermissions")
util.AddNetworkString("IonRP_Buddy_Response")

--- Initialize buddy database table
function IonRP.Buddy:InitializeTables()
  local query = [[
    CREATE TABLE IF NOT EXISTS ionrp_buddies (
      id INT AUTO_INCREMENT PRIMARY KEY,
      owner_steam_id VARCHAR(32) NOT NULL,
      buddy_steam_id VARCHAR(32) NOT NULL,
      permissions JSON NOT NULL DEFAULT '{"vehicles": true, "properties": true}',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      UNIQUE KEY unique_buddy_pair (owner_steam_id, buddy_steam_id),
      INDEX idx_owner (owner_steam_id),
      INDEX idx_buddy (buddy_steam_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  ]]

  IonRP.Database:PreparedQuery(query, {}, function()
    print("[IonRP Buddy] Database table initialized")
  end, function(err)
    print("[IonRP Buddy] Failed to initialize table: " .. err)
  end)
end

--- Load all buddies for a player from the database
--- @param ply Player The player to load buddies for
function IonRP.Buddy:LoadPlayerBuddies(ply)
  if not IsValid(ply) then return end
  
  local steamID = ply:SteamID64()
  
  local query = "SELECT buddy_steam_id, permissions FROM ionrp_buddies WHERE owner_steam_id = ?"
  
  IonRP.Database:PreparedQuery(query, {steamID}, function(data)
    ply.IonRP_Buddies = {}
    
    if data and #data > 0 then
      for _, row in ipairs(data) do
        -- Parse JSON permissions
        local permissions = util.JSONToTable(row.permissions) or {vehicles = true, properties = true}
        ply.IonRP_Buddies[row.buddy_steam_id] = permissions
      end
      print("[IonRP Buddy] Loaded " .. #data .. " buddies for " .. ply:Nick())
    else
      print("[IonRP Buddy] No buddies found for " .. ply:Nick())
    end
    
    self:SyncToClient(ply)
  end, function(err)
    print("[IonRP Buddy] Failed to load buddies: " .. err)
    ply.IonRP_Buddies = {}
  end)
end

--- Add a buddy relationship
--- @param ply Player The player adding the buddy
--- @param targetPly Player The player to add as buddy
--- @param permissions table|nil Optional permissions table {vehicles: bool, properties: bool}
--- @param callback function|nil Optional callback(success, message)
function IonRP.Buddy:Add(ply, targetPly, permissions, callback)
  if not IsValid(ply) or not IsValid(targetPly) then
    if callback then callback(false, "Invalid player") end
    return
  end
  
  if ply == targetPly then
    if callback then callback(false, "You cannot add yourself as a buddy") end
    return
  end
  
  local ownerSteamID = ply:SteamID64()
  local buddySteamID = targetPly:SteamID64()
  
  -- Check if already buddies
  if ply.IonRP_Buddies and ply.IonRP_Buddies[buddySteamID] then
    if callback then callback(false, targetPly:GetRPName() .. " is already your buddy") end
    return
  end
  
  -- Default permissions: all enabled
  permissions = permissions or {vehicles = true, properties = true}
  local permissionsJSON = util.TableToJSON(permissions)
  
  local query = [[
    INSERT INTO ionrp_buddies (owner_steam_id, buddy_steam_id, permissions)
    VALUES (?, ?, ?)
    ON DUPLICATE KEY UPDATE permissions = VALUES(permissions)
  ]]
  
  IonRP.Database:PreparedQuery(query, {ownerSteamID, buddySteamID, permissionsJSON}, function()
    -- Update in-memory buddy list
    ply.IonRP_Buddies = ply.IonRP_Buddies or {}
    ply.IonRP_Buddies[buddySteamID] = permissions
    
    print("[IonRP Buddy] " .. ply:Nick() .. " added " .. targetPly:Nick() .. " as a buddy")
    
    -- Sync to client
    self:SyncToClient(ply)
    
    if callback then callback(true, "Added " .. targetPly:GetRPName() .. " as a buddy!") end
  end, function(err)
    print("[IonRP Buddy] Failed to add buddy: " .. err)
    if callback then callback(false, "Database error occurred") end
  end)
end

--- Remove a buddy relationship
--- @param ply Player The player removing the buddy
--- @param targetSteamID string The steam ID of the buddy to remove
--- @param callback function|nil Optional callback(success, message)
function IonRP.Buddy:Remove(ply, targetSteamID, callback)
  if not IsValid(ply) then
    if callback then callback(false, "Invalid player") end
    return
  end
  
  local ownerSteamID = ply:SteamID64()
  
  -- Check if they are buddies
  if not ply.IonRP_Buddies or not ply.IonRP_Buddies[targetSteamID] then
    if callback then callback(false, "This player is not your buddy") end
    return
  end
  
  local query = "DELETE FROM ionrp_buddies WHERE owner_steam_id = ? AND buddy_steam_id = ?"
  
  IonRP.Database:PreparedQuery(query, {ownerSteamID, targetSteamID}, function()
    -- Update in-memory buddy list
    if ply.IonRP_Buddies then
      ply.IonRP_Buddies[targetSteamID] = nil
    end
    
    print("[IonRP Buddy] " .. ply:Nick() .. " removed buddy " .. targetSteamID)
    
    -- Sync to client
    self:SyncToClient(ply)
    
    if callback then callback(true, "Buddy removed") end
  end, function(err)
    print("[IonRP Buddy] Failed to remove buddy: " .. err)
    if callback then callback(false, "Database error occurred") end
  end)
end

--- Update buddy permissions
--- @param ply Player The player updating permissions
--- @param targetSteamID string The buddy's steam ID
--- @param permissions table Permissions table {vehicles: bool, properties: bool}
--- @param callback function|nil Optional callback(success, message)
function IonRP.Buddy:UpdatePermissions(ply, targetSteamID, permissions, callback)
  if not IsValid(ply) then
    if callback then callback(false, "Invalid player") end
    return
  end
  
  local ownerSteamID = ply:SteamID64()
  
  -- Check if they are buddies
  if not ply.IonRP_Buddies or not ply.IonRP_Buddies[targetSteamID] then
    if callback then callback(false, "This player is not your buddy") end
    return
  end
  
  local permissionsJSON = util.TableToJSON(permissions)
  
  local query = "UPDATE ionrp_buddies SET permissions = ? WHERE owner_steam_id = ? AND buddy_steam_id = ?"
  
  IonRP.Database:PreparedQuery(query, {permissionsJSON, ownerSteamID, targetSteamID}, function()
    -- Update in-memory buddy list
    if ply.IonRP_Buddies then
      ply.IonRP_Buddies[targetSteamID] = permissions
    end
    
    print("[IonRP Buddy] " .. ply:Nick() .. " updated permissions for buddy " .. targetSteamID)
    
    -- Sync to client
    self:SyncToClient(ply)
    
    if callback then callback(true, "Permissions updated") end
  end, function(err)
    print("[IonRP Buddy] Failed to update permissions: " .. err)
    if callback then callback(false, "Database error occurred") end
  end)
end

--- Sync a player's buddy list to their client
--- @param ply Player The player to sync to
function IonRP.Buddy:SyncToClient(ply)
  if not IsValid(ply) then return end
  
  local buddyList = {}
  
  if ply.IonRP_Buddies then
    for steamID, permissions in pairs(ply.IonRP_Buddies) do
      table.insert(buddyList, {
        steamID = steamID,
        permissions = permissions
      })
    end
  end
  
  net.Start("IonRP_Buddy_Sync")
    net.WriteTable(buddyList)
  net.Send(ply)
end

--- Network: Handle add buddy request
net.Receive("IonRP_Buddy_Add", function(len, ply)
  local targetSteamID = net.ReadString()
  
  -- Find target player
  local targetPly = nil
  for _, p in ipairs(player.GetAll()) do
    if p:SteamID64() == targetSteamID then
      targetPly = p
      break
    end
  end
  
  if not targetPly then
    net.Start("IonRP_Buddy_Response")
      net.WriteBool(false)
      net.WriteString("Player not found")
    net.Send(ply)
    return
  end
  
  IonRP.Buddy:Add(ply, targetPly, nil, function(success, message)
    net.Start("IonRP_Buddy_Response")
      net.WriteBool(success)
      net.WriteString(message)
    net.Send(ply)
  end)
end)

--- Network: Handle remove buddy request
net.Receive("IonRP_Buddy_Remove", function(len, ply)
  local targetSteamID = net.ReadString()
  
  IonRP.Buddy:Remove(ply, targetSteamID, function(success, message)
    net.Start("IonRP_Buddy_Response")
      net.WriteBool(success)
      net.WriteString(message)
    net.Send(ply)
  end)
end)

--- Network: Handle permission update request
net.Receive("IonRP_Buddy_UpdatePermissions", function(len, ply)
  local targetSteamID = net.ReadString()
  local permissions = net.ReadTable()
  
  IonRP.Buddy:UpdatePermissions(ply, targetSteamID, permissions, function(success, message)
    if not success then
      net.Start("IonRP_Buddy_Response")
        net.WriteBool(false)
        net.WriteString(message)
      net.Send(ply)
    end
  end)
end)

--- Hook: Load player buddies when they spawn
hook.Add("PlayerInitialSpawn", "IonRP_Buddy_LoadOnSpawn", function(ply)
  timer.Simple(1, function()
    if IsValid(ply) then
      IonRP.Buddy:LoadPlayerBuddies(ply)
    end
  end)
end)

print("[IonRP Buddy] Server-side buddy system loaded")
