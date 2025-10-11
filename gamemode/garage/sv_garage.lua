--[[
    Garage System - Server
    Handles garage persistence, spawning, and management
]]--

util.AddNetworkString("IonRP_Garage_Sync")
util.AddNetworkString("IonRP_Garage_Remove")

--- Visual entity class names
IonRP.Garage.AnchorClass = "ionrp_garage_anchor"
IonRP.Garage.SpotClass = "ionrp_garage_spot"

--- Initialize garage database tables
function IonRP.Garage:InitializeTables()
  -- Garage groups table
  local groupQuery = [[
    CREATE TABLE IF NOT EXISTS ionrp_garage_groups (
      id INT AUTO_INCREMENT PRIMARY KEY,
      map_name VARCHAR(64) NOT NULL,
      identifier VARCHAR(64) NOT NULL,
      name VARCHAR(128) NOT NULL,
      anchor_x FLOAT NOT NULL,
      anchor_y FLOAT NOT NULL,
      anchor_z FLOAT NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      INDEX idx_map_name (map_name),
      UNIQUE KEY unique_map_identifier (map_name, identifier)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  ]]
  
  IonRP.Database:PreparedQuery(groupQuery, {}, function()
    print("[IonRP Garage] Garage groups table initialized")
    
    -- Parking spots table
    local spotQuery = [[
      CREATE TABLE IF NOT EXISTS ionrp_garage_spots (
        id INT AUTO_INCREMENT PRIMARY KEY,
        group_id INT NOT NULL,
        pos_x FLOAT NOT NULL,
        pos_y FLOAT NOT NULL,
        pos_z FLOAT NOT NULL,
        ang_pitch FLOAT NOT NULL DEFAULT 0,
        ang_yaw FLOAT NOT NULL DEFAULT 0,
        ang_roll FLOAT NOT NULL DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_group_id (group_id),
        FOREIGN KEY (group_id) REFERENCES ionrp_garage_groups(id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    
    IonRP.Database:PreparedQuery(spotQuery, {}, function()
      print("[IonRP Garage] Garage spots table initialized")
      
      -- Load garages after tables are ready
      timer.Simple(0.5, function()
        IonRP.Garage:LoadGaragesForMap()
      end)
    end, function(err)
      print("[IonRP Garage] Failed to initialize garage spots table: " .. err)
    end)
  end, function(err)
    print("[IonRP Garage] Failed to initialize garage groups table: " .. err)
  end)
end

--[[
    Garage Group Database Operations
]]--

--- Save a new garage group to the database
--- @param group GarageGroup The garage group to save
--- @param callback function|nil Optional callback(success, groupId)
function IonRP.Garage:SaveGroup(group, callback)
  local mapName = game.GetMap()
  
  local query = [[
    INSERT INTO ionrp_garage_groups (map_name, identifier, name, anchor_x, anchor_y, anchor_z)
    VALUES (?, ?, ?, ?, ?, ?)
  ]]
  
  IonRP.Database:PreparedQuery(
    query,
    { mapName, group.identifier, group.name, group.anchor.x, group.anchor.y, group.anchor.z },
    function(data, queryObj)
      local insertId = queryObj:lastInsert()
      group.id = insertId
      self.Groups[insertId] = group
      
      print("[IonRP Garage] Saved garage group: " .. group.name .. " (ID: " .. insertId .. ")")
      
      if callback then
        callback(true, insertId)
      end
    end,
    function(err)
      print("[IonRP Garage] Failed to save garage group: " .. err)
      if callback then
        callback(false)
      end
    end
  )
end

--- Update an existing garage group
--- @param group GarageGroup The garage group to update
--- @param callback function|nil Optional callback(success)
function IonRP.Garage:UpdateGroup(group, callback)
  if not group.id then
    print("[IonRP Garage] Cannot update group without ID")
    if callback then callback(false) end
    return
  end
  
  local query = [[
    UPDATE ionrp_garage_groups
    SET identifier = ?, name = ?, anchor_x = ?, anchor_y = ?, anchor_z = ?
    WHERE id = ?
  ]]
  
  IonRP.Database:PreparedQuery(
    query,
    { group.identifier, group.name, group.anchor.x, group.anchor.y, group.anchor.z, group.id },
    function()
      print("[IonRP Garage] Updated garage group: " .. group.name .. " (ID: " .. group.id .. ")")
      if callback then
        callback(true)
      end
    end,
    function(err)
      print("[IonRP Garage] Failed to update garage group: " .. err)
      if callback then
        callback(false)
      end
    end
  )
end

--- Delete a garage group and all its spots
--- @param groupId number The group ID to delete
--- @param callback function|nil Optional callback(success)
function IonRP.Garage:DeleteGroup(groupId, callback)
  local query = "DELETE FROM ionrp_garage_groups WHERE id = ?"
  
  IonRP.Database:PreparedQuery(
    query,
    { groupId },
    function()
      self.Groups[groupId] = nil
      print("[IonRP Garage] Deleted garage group ID: " .. groupId)
      if callback then
        callback(true)
      end
    end,
    function(err)
      print("[IonRP Garage] Failed to delete garage group: " .. err)
      if callback then
        callback(false)
      end
    end
  )
end

--[[
    Parking Spot Database Operations
]]--

--- Save a parking spot to the database
--- @param spot GarageSpot The spot to save
--- @param callback function|nil Optional callback(success, spotId)
function IonRP.Garage:SaveSpot(spot, callback)
  if not spot.group or not spot.group.id then
    print("[IonRP Garage] Cannot save spot without parent group ID")
    if callback then callback(false) end
    return
  end
  
  local query = [[
    INSERT INTO ionrp_garage_spots (group_id, pos_x, pos_y, pos_z, ang_pitch, ang_yaw, ang_roll)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  ]]
  
  IonRP.Database:PreparedQuery(
    query,
    { spot.group.id, spot.pos.x, spot.pos.y, spot.pos.z, spot.ang.p, spot.ang.y, spot.ang.r },
    function(data, queryObj)
      local insertId = queryObj:lastInsert()
      spot.id = insertId
      
      print("[IonRP Garage] Saved parking spot (ID: " .. insertId .. ") to group: " .. spot.group.name)
      
      if callback then
        callback(true, insertId)
      end
    end,
    function(err)
      print("[IonRP Garage] Failed to save parking spot: " .. err)
      if callback then
        callback(false)
      end
    end
  )
end

--- Update a parking spot's position and angles
--- @param spot GarageSpot The spot to update
--- @param callback function|nil Optional callback(success)
function IonRP.Garage:UpdateSpot(spot, callback)
  if not spot.id then
    print("[IonRP Garage] Cannot update spot without ID")
    if callback then callback(false) end
    return
  end
  
  local query = [[
    UPDATE ionrp_garage_spots
    SET pos_x = ?, pos_y = ?, pos_z = ?, ang_pitch = ?, ang_yaw = ?, ang_roll = ?
    WHERE id = ?
  ]]
  
  IonRP.Database:PreparedQuery(
    query,
    { spot.pos.x, spot.pos.y, spot.pos.z, spot.ang.p, spot.ang.y, spot.ang.r, spot.id },
    function()
      print("[IonRP Garage] Updated parking spot ID: " .. spot.id)
      if callback then
        callback(true)
      end
    end,
    function(err)
      print("[IonRP Garage] Failed to update parking spot: " .. err)
      if callback then
        callback(false)
      end
    end
  )
end

--- Delete a parking spot
--- @param spotId number The spot ID to delete
--- @param callback function|nil Optional callback(success)
function IonRP.Garage:DeleteSpot(spotId, callback)
  local query = "DELETE FROM ionrp_garage_spots WHERE id = ?"
  
  IonRP.Database:PreparedQuery(
    query,
    { spotId },
    function()
      print("[IonRP Garage] Deleted parking spot ID: " .. spotId)
      if callback then
        callback(true)
      end
    end,
    function(err)
      print("[IonRP Garage] Failed to delete parking spot: " .. err)
      if callback then
        callback(false)
      end
    end
  )
end

--[[
    Loading and Spawning
]]--

--- Load all garage groups and spots for the current map
function IonRP.Garage:LoadGaragesForMap()
  local mapName = game.GetMap()
  
  local query = "SELECT * FROM ionrp_garage_groups WHERE map_name = ?"
  
  IonRP.Database:PreparedQuery(
    query,
    { mapName },
    function(groupData)
      if not groupData or #groupData == 0 then
        print("[IonRP Garage] No garage groups found for map: " .. mapName)
        return
      end
      
      print("[IonRP Garage] Loading " .. #groupData .. " garage groups for map: " .. mapName)
      
      -- Clear existing
      self:RemoveAllGarages()
      
      -- Load each group
      for _, groupRow in ipairs(groupData) do
        local group = GARAGE_GROUP:New(
          groupRow.identifier,
          groupRow.name,
          Vector(groupRow.anchor_x, groupRow.anchor_y, groupRow.anchor_z)
        )
        group.id = groupRow.id
        self.Groups[groupRow.id] = group
        
        -- Spawn anchor entity
        self:SpawnAnchorEntity(group)
        
        -- Load spots for this group
        self:LoadSpotsForGroup(group)
      end
      
      print("[IonRP Garage] Loaded " .. #groupData .. " garage groups")
    end,
    function(err)
      print("[IonRP Garage] Failed to load garage groups: " .. err)
    end
  )
end

--- Load all parking spots for a garage group
--- @param group GarageGroup The garage group
function IonRP.Garage:LoadSpotsForGroup(group)
  if not group.id then return end
  
  local query = "SELECT * FROM ionrp_garage_spots WHERE group_id = ?"
  
  IonRP.Database:PreparedQuery(
    query,
    { group.id },
    function(spotData)
      if not spotData or #spotData == 0 then
        return
      end
      
      for _, spotRow in ipairs(spotData) do
        local spot = GARAGE_SPOT:New(
          Vector(spotRow.pos_x, spotRow.pos_y, spotRow.pos_z),
          Angle(spotRow.ang_pitch, spotRow.ang_yaw, spotRow.ang_roll)
        )
        spot.id = spotRow.id
        group:AddSpot(spot)
        
        -- Spawn spot entity
        self:SpawnSpotEntity(spot)
      end
      
      print("[IonRP Garage] Loaded " .. #spotData .. " parking spots for: " .. group.name)
    end,
    function(err)
      print("[IonRP Garage] Failed to load parking spots: " .. err)
    end
  )
end

--[[
    Visual Entity Spawning (for development/admin use)
]]--

--- Spawn an anchor entity for a garage group
--- @param group GarageGroup The garage group
--- @return Entity|nil anchor The spawned anchor entity
function IonRP.Garage:SpawnAnchorEntity(group)
  local anchor = ents.Create("prop_physics")
  if not IsValid(anchor) then return nil end
  
  anchor:SetModel("models/hunter/blocks/cube025x025x025.mdl")
  anchor:SetPos(group.anchor)
  anchor:SetAngles(Angle(0, 0, 0))
  anchor:SetMaterial("models/shiny")
  anchor:SetColor(Color(255, 200, 0, 255)) -- Gold color for anchor
  anchor:SetRenderMode(RENDERMODE_TRANSALPHA)
  anchor:Spawn()
  
  anchor:SetMoveType(MOVETYPE_NONE)
  anchor:SetSolid(SOLID_VPHYSICS)
  anchor:SetCollisionGroup(COLLISION_GROUP_WORLD)
  
  -- Store metadata
  anchor:SetNWString("EntityType", self.AnchorClass)
  anchor:SetNWInt("GarageGroupID", group.id or 0)
  anchor:SetNWString("GarageName", group.name)
  anchor:SetNWBool("IonRP_DevModeOnly", true) -- Mark as devmode-only entity
  
  local phys = anchor:GetPhysicsObject()
  if IsValid(phys) then
    phys:EnableMotion(false)
  end
  
  self.Entities[anchor:EntIndex()] = anchor
  
  return anchor
end

--- Spawn a spot entity for a parking spot
--- @param spot GarageSpot The parking spot
--- @return Entity|nil spotEnt The spawned spot entity
function IonRP.Garage:SpawnSpotEntity(spot)
  local spotEnt = ents.Create("prop_physics")
  if not IsValid(spotEnt) then return nil end
  
  -- Use a flat marker on the ground
  spotEnt:SetModel("models/hunter/plates/plate1x1.mdl")
  spotEnt:SetPos(spot.pos)
  spotEnt:SetAngles(spot.ang)
  spotEnt:SetMaterial("models/wireframe")
  spotEnt:SetColor(Color(0, 255, 100, 200)) -- Green color for spots
  spotEnt:SetRenderMode(RENDERMODE_TRANSALPHA)
  spotEnt:Spawn()
  
  spotEnt:SetMoveType(MOVETYPE_NONE)
  spotEnt:SetSolid(SOLID_VPHYSICS)
  spotEnt:SetCollisionGroup(COLLISION_GROUP_WORLD)
  
  -- Store metadata
  spotEnt:SetNWString("EntityType", self.SpotClass)
  spotEnt:SetNWInt("GarageSpotID", spot.id or 0)
  if spot.group then
    spotEnt:SetNWInt("GarageGroupID", spot.group.id or 0)
  end
  spotEnt:SetNWBool("IonRP_DevModeOnly", true) -- Mark as devmode-only entity
  
  local phys = spotEnt:GetPhysicsObject()
  if IsValid(phys) then
    phys:EnableMotion(false)
  end
  
  self.Entities[spotEnt:EntIndex()] = spotEnt
  
  return spotEnt
end

--- Remove all garage entities from the map
function IonRP.Garage:RemoveAllGarages()
  for _, ent in pairs(self.Entities) do
    if IsValid(ent) then
      ent:Remove()
    end
  end
  
  self.Entities = {}
  self.Groups = {}
end

--[[
    Hooks
]]--

--- Initialize on map load
hook.Add("InitPostEntity", "IonRP_Garage_LoadMap", function()
  timer.Simple(1, function()
    IonRP.Garage:LoadGaragesForMap()
  end)
end)

--- Control entity visibility based on devmode
--- Only transmit garage visual entities to players with devmode enabled
hook.Add("SetupPlayerVisibility", "IonRP_Garage_DevModeVisibility", function(ply, viewEntity)
  if not IsValid(ply) then return end
  
  -- If player is in devmode, add all garage entities to their PVS
  if ply:IsDevMode() then
    for _, ent in pairs(IonRP.Garage.Entities) do
      if IsValid(ent) and ent:GetNWBool("IonRP_DevModeOnly", false) then
        AddOriginToPVS(ent:GetPos())
      end
    end
  end
end)

--- Prevent non-devmode players from using garage entities
hook.Add("PlayerUse", "IonRP_Garage_DevModeUse", function(ply, ent)
  if not IsValid(ent) then return end
  
  -- Check if it's a garage entity
  if ent:GetNWBool("IonRP_DevModeOnly", false) then
    -- Only allow devmode players to interact
    if not ply:IsDevMode() then
      return false
    end
  end
end)

print("[IonRP Garage] Server module loaded")

-- Command to give garage gun
IonRP.Commands.Add("garage_gun", function(ply)
  ply:Give("weapon_ionrp_garage_gun")
end, "Give yourself the garage management gun", "developer")