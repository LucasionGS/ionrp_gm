--[[
    IonRP Genetics System - Server
    Database management and upgrade logic
]]--

include("sh_genetics.lua")

util.AddNetworkString("IonRP_Genetics_Sync")
util.AddNetworkString("IonRP_Genetics_Upgrade")

--- Initialize database table
function IonRP.Genetics:InitializeTables()
  print("[IonRP Genetics] Initializing database tables...")
  
  local query = IonRP.Database:query([[
    CREATE TABLE IF NOT EXISTS ionrp_genetics (
      id INT AUTO_INCREMENT PRIMARY KEY,
      steam_id VARCHAR(32) NOT NULL,
      strength INT DEFAULT 0,
      intelligence INT DEFAULT 0,
      dexterity INT DEFAULT 0,
      influence INT DEFAULT 0,
      perception INT DEFAULT 0,
      available_points INT DEFAULT 0,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      UNIQUE KEY unique_steamid (steam_id),
      INDEX idx_steam_id (steam_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  ]])
  
  function query:onSuccess()
    print("[IonRP Genetics] Genetics table ready")
  end
  
  function query:onError(err, sql)
    print("[IonRP Genetics] ERROR: Failed to create genetics table:")
    print("[IonRP Genetics] " .. err)
  end
  
  query:start()
end

--- Load genetics for a player
--- @param ply Player
--- @param callback function
function IonRP.Genetics:Load(ply, callback)
  if not IsValid(ply) then return end
  
  local steamID = ply:SteamID64()
  
  IonRP.Database:PreparedQuery(
    "SELECT * FROM ionrp_genetics WHERE steam_id = ? LIMIT 1",
    {steamID},
    function(data)
      local genetics
      
      if data and #data > 0 then
        -- Load existing genetics
        local row = data[1]
        genetics = {
          strength = tonumber(row.strength) or 0,
          intelligence = tonumber(row.intelligence) or 0,
          dexterity = tonumber(row.dexterity) or 0,
          influence = tonumber(row.influence) or 0,
          perception = tonumber(row.perception) or 0,
          availablePoints = tonumber(row.available_points) or 0
        }
      else
        -- Create new genetics
        genetics = IonRP.Genetics.New()
        self:Save(ply, genetics)
      end
      
      -- Store on player
      ply.IonRP_Genetics = genetics
      
      -- Send to client
      self:SendToClient(ply, genetics)
      
      if callback then callback(genetics) end
    end,
    function(err)
      print("[IonRP Genetics] Load error: " .. err)
      
      -- Fallback to new genetics
      local genetics = IonRP.Genetics.New()
      ply.IonRP_Genetics = genetics
      self:SendToClient(ply, genetics)
      
      if callback then callback(genetics) end
    end
  )
end

--- Save genetics for a player
--- @param ply Player
--- @param genetics GeneticsData
function IonRP.Genetics:Save(ply, genetics)
  if not IsValid(ply) or not genetics then return end
  if not IonRP.Genetics.Validate(genetics) then
    print("[IonRP Genetics] Invalid genetics data for " .. ply:Nick())
    return
  end
  
  local steamID = ply:SteamID64()
  
  IonRP.Database:PreparedQuery(
    [[INSERT INTO ionrp_genetics 
      (steam_id, strength, intelligence, dexterity, influence, perception, available_points)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE
        strength = VALUES(strength),
        intelligence = VALUES(intelligence),
        dexterity = VALUES(dexterity),
        influence = VALUES(influence),
        perception = VALUES(perception),
        available_points = VALUES(available_points)]],
    {
      steamID,
      genetics.strength,
      genetics.intelligence,
      genetics.dexterity,
      genetics.influence,
      genetics.perception,
      genetics.availablePoints
    },
    function()
      -- Success
    end,
    function(err)
      print("[IonRP Genetics] Save error: " .. err)
    end
  )
end

--- Send genetics to client
--- @param ply Player
--- @param genetics GeneticsData
function IonRP.Genetics:SendToClient(ply, genetics)
  if not IsValid(ply) or not genetics then return end
  
  net.Start("IonRP_Genetics_Sync")
  net.WriteTable(genetics)
  net.Send(ply)
end

--- Upgrade a genetic type
--- @param ply Player
--- @param gType string
--- @return boolean success
function IonRP.Genetics:Upgrade(ply, gType)
  if not IsValid(ply) then return false end
  
  local genetics = ply.IonRP_Genetics
  if not genetics then return false end
  
  -- Validate genetic type
  local validTypes = {"strength", "intelligence", "dexterity", "influence", "perception"}
  if not table.HasValue(validTypes, gType) then
    return false
  end
  
  -- Check if can upgrade
  if not IonRP.Genetics.CanUpgrade(genetics, gType) then
    ply:ChatPrint("[Genetics] Cannot upgrade " .. gType)
    return false
  end
  
  -- Perform upgrade
  genetics[gType] = genetics[gType] + 1
  genetics.availablePoints = genetics.availablePoints - 1
  
  -- Save and sync
  self:Save(ply, genetics)
  self:SendToClient(ply, genetics)
  
  ply:ChatPrint("[Genetics] Upgraded " .. gType .. " to level " .. genetics[gType])
  
  return true
end

--- Add available points to a player
--- @param ply Player
--- @param amount number
function IonRP.Genetics:AddPoints(ply, amount)
  if not IsValid(ply) then return end
  
  local genetics = ply.IonRP_Genetics
  if not genetics then return end
  
  genetics.availablePoints = genetics.availablePoints + amount
  
  self:Save(ply, genetics)
  self:SendToClient(ply, genetics)
  
  ply:ChatPrint("[Genetics] Received " .. amount .. " genetic point(s)")
end

--- Network receiver for upgrade requests
net.Receive("IonRP_Genetics_Upgrade", function(len, ply)
  local gType = net.ReadString()
  IonRP.Genetics:Upgrade(ply, gType)
end)

--- Auto-save genetics periodically
timer.Create("IonRP_Genetics_AutoSave", 60, 0, function()
  for _, ply in ipairs(player.GetAll()) do
    if IsValid(ply) and ply.IonRP_Genetics then
      IonRP.Genetics:Save(ply, ply.IonRP_Genetics)
    end
  end
end)

print("[IonRP Genetics] Server-side genetics system loaded")
