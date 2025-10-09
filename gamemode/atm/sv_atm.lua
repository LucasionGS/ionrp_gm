--[[
    ATM System - Server
    Handles ATM spawning, persistence, and interaction
]]--

util.AddNetworkString("IonRP_ATM_SyncPositions")

--- Initialize the ATM database table
function IonRP.ATM:InitializeTables()
  local query = [[
    CREATE TABLE IF NOT EXISTS ionrp_atms (
      id INT AUTO_INCREMENT PRIMARY KEY,
      map_name VARCHAR(64) NOT NULL,
      pos_x FLOAT NOT NULL,
      pos_y FLOAT NOT NULL,
      pos_z FLOAT NOT NULL,
      ang_p FLOAT NOT NULL,
      ang_y FLOAT NOT NULL,
      ang_r FLOAT NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      INDEX idx_map_name (map_name)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  ]]

  IonRP.Database:PreparedQuery(query, {}, function()
    print("[IonRP ATM] Database table initialized")
    
    -- Load ATMs for current map after table is ready
    timer.Simple(0.5, function()
      IonRP.ATM:LoadATMsForMap()
    end)
  end, function(err)
    print("[IonRP ATM] Failed to initialize table: " .. err)
  end)
end

--- Save an ATM position to the database
--- @param pos Vector Position
--- @param ang Angle Angles
--- @param callback function|nil Optional callback(success, id)
function IonRP.ATM:SaveATM(pos, ang, callback)
  local mapName = game.GetMap()
  
  local query = [[
    INSERT INTO ionrp_atms (map_name, pos_x, pos_y, pos_z, ang_p, ang_y, ang_r)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  ]]
  
  IonRP.Database:PreparedQuery(
    query,
    { mapName, pos.x, pos.y, pos.z, ang.p, ang.y, ang.r },
    function(data, query)
      local insertId = query:lastInsert()
      print("[IonRP ATM] Saved ATM at " .. tostring(pos) .. " with ID: " .. insertId)
      
      if callback then
        callback(true, insertId)
      end
    end,
    function(err)
      print("[IonRP ATM] Failed to save ATM: " .. err)
      if callback then
        callback(false)
      end
    end
  )
end

--- Delete an ATM from the database
--- @param id number Database ID
--- @param callback function|nil Optional callback(success)
function IonRP.ATM:DeleteATM(id, callback)
  local query = "DELETE FROM ionrp_atms WHERE id = ?"
  
  IonRP.Database:PreparedQuery(
    query,
    { id },
    function()
      print("[IonRP ATM] Deleted ATM ID: " .. id)
      if callback then
        callback(true)
      end
    end,
    function(err)
      print("[IonRP ATM] Failed to delete ATM: " .. err)
      if callback then
        callback(false)
      end
    end
  )
end

--- Load all ATMs for the current map
function IonRP.ATM:LoadATMsForMap()
  local mapName = game.GetMap()
  
  local query = "SELECT * FROM ionrp_atms WHERE map_name = ?"
  
  IonRP.Database:PreparedQuery(
    query,
    { mapName },
    function(data)
      if not data or #data == 0 then
        print("[IonRP ATM] No ATMs found for map: " .. mapName)
        return
      end
      
      print("[IonRP ATM] Loading " .. #data .. " ATMs for map: " .. mapName)
      
      -- Clear existing ATMs
      self:RemoveAllATMs()
      
      -- Spawn each ATM
      for _, atmData in ipairs(data) do
        local pos = Vector(atmData.pos_x, atmData.pos_y, atmData.pos_z)
        local ang = Angle(atmData.ang_p, atmData.ang_y, atmData.ang_r)
        
        self:SpawnATM(pos, ang, atmData.id)
      end
      
      print("[IonRP ATM] Spawned " .. #data .. " ATMs")
    end,
    function(err)
      print("[IonRP ATM] Failed to load ATMs: " .. err)
    end
  )
end

--- Spawn an ATM entity at the given position
--- @param pos Vector Position
--- @param ang Angle Angles
--- @param dbId number|nil Database ID (if loading from DB)
--- @return Entity|nil The spawned ATM entity
function IonRP.ATM:SpawnATM(pos, ang, dbId)
  local atm = ents.Create("prop_physics")
  if not IsValid(atm) then
    print("[IonRP ATM] Failed to create ATM entity")
    return nil
  end
  
  atm:SetModel("models/hunter/blocks/cube025x025x025.mdl")
  atm:SetPos(pos)
  atm:SetAngles(ang)
  atm:SetMaterial("models/effects/vol_light001")
  atm:SetColor(Color(100, 200, 255, 50))
  atm:SetRenderMode(RENDERMODE_TRANSALPHA)
  atm:Spawn()
  
  -- Make it solid but non-movable
  atm:SetMoveType(MOVETYPE_NONE)
  atm:SetSolid(SOLID_VPHYSICS)
  atm:SetCollisionGroup(COLLISION_GROUP_WORLD)
  
  -- Set collision bounds for proper USE detection
  atm:SetCollisionBounds(IonRP.ATM.BoundsMin, IonRP.ATM.BoundsMax)
  
  -- Enable USE on entire entity
  atm:SetUseType(SIMPLE_USE)
  
  -- Store metadata
  atm:SetNWString("EntityType", IonRP.ATM.EntityClass)
  atm:SetNWInt("ATM_ID", dbId or 0)
  
  -- Prevent physics interactions
  local phys = atm:GetPhysicsObject()
  if IsValid(phys) then
    phys:EnableMotion(false)
    phys:EnableCollisions(true)
  end
  
  -- Store reference
  IonRP.ATM.Entities[atm:EntIndex()] = atm
  
  return atm
end

--- Remove all ATM entities from the map
function IonRP.ATM:RemoveAllATMs()
  for _, atm in pairs(IonRP.ATM.Entities) do
    if IsValid(atm) then
      atm:Remove()
    end
  end
  
  IonRP.ATM.Entities = {}
end

--- Get the ATM entity a player is looking at (within range)
--- @param ply Player The player
--- @param maxDist number Maximum distance (default 100)
--- @return Entity|nil The ATM entity or nil
function IonRP.ATM:GetLookingAtATM(ply, maxDist)
  maxDist = maxDist or 100
  
  local trace = ply:GetEyeTrace()
  local ent = trace.Entity
  
  if IsValid(ent) and ent:GetNWString("EntityType") == IonRP.ATM.EntityClass then
    if trace.HitPos:Distance(ply:GetPos()) <= maxDist then
      return ent
    end
  end
  
  return nil
end

--- Hook: Player presses USE on ATM
hook.Add("PlayerUse", "IonRP_ATM_Use", function(ply, ent)
  if not IsValid(ent) then return end
  if ent:GetNWString("EntityType") ~= IonRP.ATM.EntityClass then return end

  IonRP.Bank:OpenMenu(ply)

  return false -- Prevent default USE behavior
end)

--- Hook: Check for players looking at ATM zones (more reliable than entity USE)
hook.Add("KeyPress", "IonRP_ATM_KeyPress", function(ply, key)
  if key ~= IN_USE then return end
  
  -- Check if player is looking at any ATM zone
  local trace = ply:GetEyeTrace()
  local hitPos = trace.HitPos
  local maxDist = 100
  
  -- Check distance first
  if hitPos:Distance(ply:EyePos()) > maxDist then return end
  
  -- Check all ATM entities to see if trace hit is within their bounding box
  for _, atm in pairs(IonRP.ATM.Entities) do
    if IsValid(atm) then
      local atmPos = atm:GetPos()
      local atmAng = atm:GetAngles()
      local mins = IonRP.ATM.BoundsMin
      local maxs = IonRP.ATM.BoundsMax
      
      -- Transform hit position to local space
      local localPos = WorldToLocal(hitPos, Angle(0, 0, 0), atmPos, atmAng)
      
      -- Check if within bounds
      if localPos.x >= mins.x and localPos.x <= maxs.x and
         localPos.y >= mins.y and localPos.y <= maxs.y and
         localPos.z >= mins.z and localPos.z <= maxs.z then
        
        -- Hit the ATM zone!
        IonRP.Bank:OpenMenu(ply)
        return
      end
    end
  end
end)

--- Hook: Initialize on map load
hook.Add("InitPostEntity", "IonRP_ATM_LoadMap", function()
  timer.Simple(1, function()
    IonRP.ATM:LoadATMsForMap()
  end)
end)

--- Command: Place ATM at player position
IonRP.Commands.Add("placeatm", function(activator, args, rawArgs)
  if not activator:HasPermission("developer") then
    activator:ChatPrint("[IonRP] You don't have permission to place ATMs!")
    return
  end
  
  local trace = activator:GetEyeTrace()
  local pos = trace.HitPos
  local ang = activator:EyeAngles()
  ang.p = 0 -- Keep it level
  ang.r = 0
  
  -- Spawn the ATM entity
  local atm = IonRP.ATM:SpawnATM(pos, ang)
  
  if not IsValid(atm) then
    activator:ChatPrint("[IonRP] Failed to spawn ATM entity!")
    return
  end
  
  -- Save to database
  IonRP.ATM:SaveATM(pos, ang, function(success, id)
    if success and IsValid(atm) then
      atm:SetNWInt("ATM_ID", id)
      activator:ChatPrint("[IonRP] ATM placed successfully! (ID: " .. id .. ")")
    else
      activator:ChatPrint("[IonRP] ATM spawned but failed to save to database!")
    end
  end)
end, "Place an ATM at your crosshair position", "developer")

--- Command: Remove ATM you're looking at
IonRP.Commands.Add("removeatm", function(activator, args, rawArgs)
  if not activator:HasPermission("developer") then
    activator:ChatPrint("[IonRP] You don't have permission to remove ATMs!")
    return
  end
  
  local atm = IonRP.ATM:GetLookingAtATM(activator, 150)
  
  if not atm or not IsValid(atm) then
    activator:ChatPrint("[IonRP] You're not looking at an ATM!")
    return
  end
  
  local atmId = atm:GetNWInt("ATM_ID", 0)
  
  if atmId > 0 then
    -- Delete from database
    IonRP.ATM:DeleteATM(atmId, function(success)
      if success then
        activator:ChatPrint("[IonRP] ATM removed from database!")
      else
        activator:ChatPrint("[IonRP] Failed to remove ATM from database!")
      end
    end)
  end
  
  -- Remove entity
  if IsValid(atm) then
    IonRP.ATM.Entities[atm:EntIndex()] = nil
    atm:Remove()
  end
  
  activator:ChatPrint("[IonRP] ATM entity removed!")
end, "Remove the ATM you're looking at", "developer")

--- Command: List all ATMs on current map
IonRP.Commands.Add("listatms", function(activator, args, rawArgs)
  if not activator:HasPermission("developer") then
    activator:ChatPrint("[IonRP] You don't have permission to list ATMs!")
    return
  end
  
  local count = 0
  for _, atm in pairs(IonRP.ATM.Entities) do
    if IsValid(atm) then
      count = count + 1
    end
  end
  
  activator:ChatPrint("[IonRP] ATMs on map: " .. count)
  
  for idx, atm in pairs(IonRP.ATM.Entities) do
    if IsValid(atm) then
      local id = atm:GetNWInt("ATM_ID")
      local pos = atm:GetPos()
      activator:ChatPrint(string.format("  [%d] ID: %d at %s", idx, id, tostring(pos)))
    end
  end
end, "List all ATMs on the current map", "developer")

print("[IonRP ATM] Server module loaded")
