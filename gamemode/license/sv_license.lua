--- Server-side license management
--- Handles database operations, granting, suspending, and syncing licenses

util.AddNetworkString("IonRP_License_Sync")
util.AddNetworkString("IonRP_License_SyncAll")

--- Initialize the licenses database table
function IonRP.Licenses:InitializeTables()
  local query = [[
    CREATE TABLE IF NOT EXISTS ionrp_licenses (
      id INT AUTO_INCREMENT PRIMARY KEY,
      steam_id VARCHAR(32) NOT NULL,
      license_type VARCHAR(64) NOT NULL,
      state ENUM('active', 'suspended') DEFAULT 'active',
      reason TEXT NULL,
      activate_on DATETIME NULL,
      granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      UNIQUE KEY unique_player_license (steam_id, license_type),
      INDEX idx_steam_id (steam_id),
      INDEX idx_license_type (license_type),
      INDEX idx_state (state)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  ]]

  IonRP.Database:PreparedQuery(query, {}, function()
    print("[IonRP Licenses] Database table initialized")
  end, function(err)
    print("[IonRP Licenses] Failed to initialize table: " .. err)
  end)
end

--- Grant a license to a player
--- @param ply Player The player to grant the license to
--- @param licenseIdentifier string The license type identifier
--- @param activateOn string|nil Optional ISO datetime when license becomes active
--- @param callback function|nil Optional callback when complete
function IonRP.Licenses:Grant(ply, licenseIdentifier, activateOn, callback)
  if not IsValid(ply) then return end
  
  local licenseType = IonRP.Licenses.List[licenseIdentifier]
  if not licenseType then
    print("[IonRP Licenses] Unknown license type: " .. licenseIdentifier)
    return
  end
  
  local steamID = ply:SteamID64()
  local activateOnSQL = activateOn and ("'" .. activateOn .. "'") or "NULL"
  
  local query = [[
    INSERT INTO ionrp_licenses (steam_id, license_type, state, activate_on)
    VALUES (?, ?, 'active', ]] .. activateOnSQL .. [[)
    ON DUPLICATE KEY UPDATE 
      state = 'active',
      activate_on = ]] .. activateOnSQL .. [[,
      reason = NULL,
      updated_at = CURRENT_TIMESTAMP
  ]]
  
  IonRP.Database:PreparedQuery(query, {steamID, licenseIdentifier}, function()
    print("[IonRP Licenses] Granted " .. licenseType.name .. " to " .. ply:Nick())
    self:LoadPlayerLicenses(ply)
    
    if callback then callback(true) end
  end, function(err)
    print("[IonRP Licenses] Failed to grant license: " .. err)
    if callback then callback(false) end
  end)
end

--- Suspend a player's license
--- @param ply Player The player whose license to suspend
--- @param licenseIdentifier string The license type identifier
--- @param reason string|nil The reason for suspension
--- @param callback function|nil Optional callback when complete
function IonRP.Licenses:Suspend(ply, licenseIdentifier, reason, callback)
  if not IsValid(ply) then return end
  
  local steamID = ply:SteamID64()
  local reasonSQL = reason and ("'" .. IonRP.Database:Escape(reason) .. "'") or "NULL"
  
  local query = [[
    UPDATE ionrp_licenses 
    SET state = 'suspended', reason = ]] .. reasonSQL .. [[, updated_at = CURRENT_TIMESTAMP
    WHERE steam_id = ? AND license_type = ?
  ]]
  
  IonRP.Database:PreparedQuery(query, {steamID, licenseIdentifier}, function(data)
    print("[IonRP Licenses] Suspended " .. licenseIdentifier .. " for " .. ply:Nick())
    self:LoadPlayerLicenses(ply)
    
    if callback then callback(true) end
  end, function(err)
    print("[IonRP Licenses] Failed to suspend license: " .. err)
    if callback then callback(false) end
  end)
end

--- Reactivate a suspended license
--- @param ply Player The player whose license to reactivate
--- @param licenseIdentifier string The license type identifier
--- @param callback function|nil Optional callback when complete
function IonRP.Licenses:Reactivate(ply, licenseIdentifier, callback)
  if not IsValid(ply) then return end
  
  local steamID = ply:SteamID64()
  
  local query = [[
    UPDATE ionrp_licenses 
    SET state = 'active', reason = NULL, updated_at = CURRENT_TIMESTAMP
    WHERE steam_id = ? AND license_type = ?
  ]]
  
  IonRP.Database:PreparedQuery(query, {steamID, licenseIdentifier}, function(data)
    print("[IonRP Licenses] Reactivated " .. licenseIdentifier .. " for " .. ply:Nick())
    self:LoadPlayerLicenses(ply)
    
    if callback then callback(true) end
  end, function(err)
    print("[IonRP Licenses] Failed to reactivate license: " .. err)
    if callback then callback(false) end
  end)
end

--- Revoke (delete) a player's license
--- @param ply Player The player whose license to revoke
--- @param licenseIdentifier string The license type identifier
--- @param callback function|nil Optional callback when complete
function IonRP.Licenses:Revoke(ply, licenseIdentifier, callback)
  if not IsValid(ply) then return end
  
  local steamID = ply:SteamID64()
  
  local query = "DELETE FROM ionrp_licenses WHERE steam_id = ? AND license_type = ?"
  
  IonRP.Database:PreparedQuery(query, {steamID, licenseIdentifier}, function()
    print("[IonRP Licenses] Revoked " .. licenseIdentifier .. " from " .. ply:Nick())
    self:LoadPlayerLicenses(ply)
    
    if callback then callback(true) end
  end, function(err)
    print("[IonRP Licenses] Failed to revoke license: " .. err)
    if callback then callback(false) end
  end)
end

--- Load all licenses for a player from the database
--- @param ply Player The player to load licenses for
function IonRP.Licenses:LoadPlayerLicenses(ply)
  if not IsValid(ply) then return end
  
  local steamID = ply:SteamID64()
  
  local query = "SELECT * FROM ionrp_licenses WHERE steam_id = ?"
  
  IonRP.Database:PreparedQuery(query, {steamID}, function(data)
    ply.IonRP_Licenses = {}
    
    if data and #data > 0 then
      for _, row in ipairs(data) do
        local licenseType = IonRP.Licenses.List[row.license_type]
        
        if licenseType then
          local licenseInstance = licenseType:MakeOwnedInstance(
            ply,
            row.state,
            row.reason,
            row.activate_on,
            row.granted_at,
            row.updated_at
          )
          
          ply.IonRP_Licenses[row.license_type] = licenseInstance
        end
      end
      
      print("[IonRP Licenses] Loaded " .. #data .. " licenses for " .. ply:Nick())
    else
      print("[IonRP Licenses] No licenses found for " .. ply:Nick())
    end
    
    self:SyncToClient(ply)
  end, function(err)
    print("[IonRP Licenses] Failed to load licenses: " .. err)
  end)
end

--- Sync a player's licenses to their client
--- @param ply Player The player to sync to
function IonRP.Licenses:SyncToClient(ply)
  if not IsValid(ply) then return end
  
  local licensesData = {}
  
  if ply.IonRP_Licenses then
    for licenseType, licenseInstance in pairs(ply.IonRP_Licenses) do
      table.insert(licensesData, {
        identifier = licenseType,
        state = licenseInstance.state,
        reason = licenseInstance.reason,
        activateOn = licenseInstance.activateOn,
        grantedAt = licenseInstance.grantedAt,
        updatedAt = licenseInstance.updatedAt
      })
    end
  end
  
  net.Start("IonRP_License_SyncAll")
  net.WriteTable(licensesData)
  net.Send(ply)
end

--- Auto-activate licenses that have passed their activation date
function IonRP.Licenses:CheckActivations()
  local query = [[
    UPDATE ionrp_licenses 
    SET activate_on = NULL, updated_at = CURRENT_TIMESTAMP
    WHERE activate_on IS NOT NULL AND activate_on <= NOW()
  ]]
  
  IonRP.Database:PreparedQuery(query, {}, function(data)
    if data and data.affectedRows and data.affectedRows > 0 then
      print("[IonRP Licenses] Auto-activated " .. data.affectedRows .. " licenses")
      
      -- Reload licenses for online players
      for _, ply in ipairs(player.GetAll()) do
        self:LoadPlayerLicenses(ply)
      end
    end
  end, function(err)
    print("[IonRP Licenses] Failed to check activations: " .. err)
  end)
end

--- Initialize auto-activation timer (runs every 60 seconds)
timer.Create("IonRP_License_AutoActivation", 60, 0, function()
  IonRP.Licenses:CheckActivations()
end)

--- Hook: Load player licenses when they spawn
hook.Add("PlayerInitialSpawn", "IonRP_License_LoadOnSpawn", function(ply)
  timer.Simple(1, function()
    if IsValid(ply) then
      IonRP.Licenses:LoadPlayerLicenses(ply)
    end
  end)
end)
