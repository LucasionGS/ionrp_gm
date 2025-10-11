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
      model VARCHAR(255) NULL,
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
--- @param model string|nil Optional model path
--- @param callback function|nil Optional callback(success, id)
function IonRP.ATM:SaveATM(pos, ang, model, callback)
  local mapName = game.GetMap()
  
  local query = [[
    INSERT INTO ionrp_atms (map_name, pos_x, pos_y, pos_z, ang_p, ang_y, ang_r, model)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  ]]
  
  IonRP.Database:PreparedQuery(
    query,
    { mapName, pos.x, pos.y, pos.z, ang.p, ang.y, ang.r, model },
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

--- Update an ATM's position, angle, and model in the database
--- @param id number Database ID
--- @param pos Vector New position
--- @param ang Angle New angles
--- @param model string|nil New model path (or nil)
--- @param callback function|nil Optional callback(success)
function IonRP.ATM:UpdateATM(id, pos, ang, model, callback)
  local query = [[
    UPDATE ionrp_atms 
    SET pos_x = ?, pos_y = ?, pos_z = ?, ang_p = ?, ang_y = ?, ang_r = ?, model = ?
    WHERE id = ?
  ]]
  
  IonRP.Database:PreparedQuery(
    query,
    { pos.x, pos.y, pos.z, ang.p, ang.y, ang.r, model, id },
    function()
      print("[IonRP ATM] Updated ATM ID: " .. id .. " at " .. tostring(pos))
      if callback then
        callback(true)
      end
    end,
    function(err)
      print("[IonRP ATM] Failed to update ATM: " .. err)
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
        local model = atmData.model
        
        self:SpawnATM(pos, ang, atmData.id, model)
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
--- @param model string|nil Custom model path (if nil, uses bounding box)
--- @return Entity|nil The spawned ATM entity
function IonRP.ATM:SpawnATM(pos, ang, dbId, model)
  local atm = ents.Create("prop_physics")
  if not IsValid(atm) then
    print("[IonRP ATM] Failed to create ATM entity")
    return nil
  end
  
  -- Use custom model if provided, otherwise use default visual box
  if model and model ~= "" then
    -- Custom model mode
    util.PrecacheModel(model)
    atm:SetModel(model)
    atm:SetPos(pos)
    atm:SetAngles(ang)
  else
    -- Default bounding box mode (invisible)
    atm:SetModel("models/hunter/blocks/cube025x025x025.mdl")
    atm:SetPos(pos)
    atm:SetAngles(ang)
    atm:SetMaterial("models/effects/vol_light001")
    atm:SetColor(Color(100, 200, 255, 50))
    atm:SetRenderMode(RENDERMODE_TRANSALPHA)
    
    -- Set collision bounds for proper USE detection (only for bounding box mode)
    atm:SetCollisionBounds(IonRP.ATM.BoundsMin, IonRP.ATM.BoundsMax)
  end
  
  atm:Spawn()
  
  -- Make it solid but non-movable
  atm:SetMoveType(MOVETYPE_NONE)
  atm:SetSolid(SOLID_VPHYSICS)
  atm:SetCollisionGroup(COLLISION_GROUP_WORLD)
  
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
  
  -- Spawn the ATM entity (without model by default)
  local atm = IonRP.ATM:SpawnATM(pos, ang, nil, nil)
  
  if not IsValid(atm) then
    activator:ChatPrint("[IonRP] Failed to spawn ATM entity!")
    return
  end
  
  -- Save to database
  IonRP.ATM:SaveATM(pos, ang, nil, function(success, id)
    if success and IsValid(atm) then
      if id then
        atm:SetNWInt("ATM_ID", id)
      end
      activator:ChatPrint("[IonRP] ATM placed successfully! (ID: " .. (id or "unknown") .. ")")
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

--- Command: Save ATM's current position and angle
IonRP.Commands.Add("saveatm", function(activator, args, rawArgs)
  if not activator:HasPermission("developer") then
    activator:ChatPrint("[IonRP] You don't have permission to save ATMs!")
    return
  end
  
  local atm = IonRP.ATM:GetLookingAtATM(activator, 150)
  
  if not atm or not IsValid(atm) then
    activator:ChatPrint("[IonRP] You're not looking at an ATM!")
    return
  end
  
  local atmId = atm:GetNWInt("ATM_ID", 0)
  
  if atmId == 0 then
    activator:ChatPrint("[IonRP] This ATM has no database ID! Cannot save.")
    return
  end
  
  -- Get current position, angle, and model
  local pos = atm:GetPos()
  local ang = atm:GetAngles()
  local model = atm:GetModel()
  
  -- Only store model if it's not the default bounding box
  if model == "models/hunter/blocks/cube025x025x025.mdl" then
    model = nil
  end
  
  -- Update in database
  IonRP.ATM:UpdateATM(atmId, pos, ang, model, function(success)
    if success then
      activator:ChatPrint("[IonRP] ATM position saved! (ID: " .. atmId .. ")")
      activator:ChatPrint("[IonRP] Position: " .. tostring(pos))
    else
      activator:ChatPrint("[IonRP] Failed to save ATM position to database!")
    end
  end)
end, "Save the current position/angle of the ATM you're looking at", "developer")

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

--- Command: Set model for ATM you're looking at
IonRP.Commands.Add("atmmodel", function(activator, args, rawArgs)
  if not activator:HasPermission("developer") then
    activator:ChatPrint("[IonRP] You don't have permission to set ATM models!")
    return
  end
  
  local atm = IonRP.ATM:GetLookingAtATM(activator, 150)
  
  if not atm or not IsValid(atm) then
    activator:ChatPrint("[IonRP] You're not looking at an ATM!")
    return
  end
  
  local atmId = atm:GetNWInt("ATM_ID", 0)
  
  if atmId == 0 then
    activator:ChatPrint("[IonRP] This ATM has no database ID! Cannot set model.")
    return
  end
  
  -- Get model path from arguments
  --- @type string|nil
  local modelPath = rawArgs
  
  if not modelPath or modelPath == "" then
    activator:ChatPrint("[IonRP] Usage: /atmmodel <model/path>")
    activator:ChatPrint("[IonRP] Example: /atmmodel models/props_c17/consolebox01a.mdl")
    activator:ChatPrint("[IonRP] Use 'none' to remove model and use bounding box")
    return
  end
  
  -- Handle "none" to remove model
  if modelPath:lower() == "none" then
    modelPath = nil
  elseif modelPath then
    -- Validate model exists
    if not file.Exists(modelPath, "GAME") then
      activator:ChatPrint("[IonRP] Model file not found: " .. modelPath)
      activator:ChatPrint("[IonRP] Make sure the path is correct (e.g., models/props/file.mdl)")
      return
    end
  end
  
  -- Get current position and angle
  local pos = atm:GetPos()
  local ang = atm:GetAngles()
  
  -- Update in database with new model
  IonRP.ATM:UpdateATM(atmId, pos, ang, modelPath, function(success)
    if success then
      -- Remove old ATM
      atm:Remove()
      
      -- Spawn new ATM with new model
      local newAtm = IonRP.ATM:SpawnATM(pos, ang, atmId, modelPath)
      
      if IsValid(newAtm) then
        if modelPath then
          activator:ChatPrint("[IonRP] ATM model updated! (ID: " .. atmId .. ")")
          activator:ChatPrint("[IonRP] Model: " .. modelPath)
        else
          activator:ChatPrint("[IonRP] ATM model removed, using bounding box! (ID: " .. atmId .. ")")
        end
      else
        activator:ChatPrint("[IonRP] Model updated in database but failed to respawn ATM!")
      end
    else
      activator:ChatPrint("[IonRP] Failed to update ATM model in database!")
    end
  end)
end, "Set or remove the model for the ATM you're looking at", "developer")

print("[IonRP ATM] Server module loaded")
