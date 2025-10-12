--[[
    NPC System - Server
    Handles NPC persistence, spawning, and interactions
]] --

util.AddNetworkString("IonRP_NPC_Sync")
util.AddNetworkString("IonRP_NPC_Remove")

--- Initialize the NPC database tables
function IonRP.NPCs:InitializeTables()
  local query = [[
    CREATE TABLE IF NOT EXISTS ionrp_npcs (
      id INT AUTO_INCREMENT PRIMARY KEY,
      npc_identifier VARCHAR(64) NOT NULL,
      map_name VARCHAR(64) NOT NULL,
      custom_name VARCHAR(128) NULL,
      custom_model VARCHAR(255) NULL,
      pos_x FLOAT NOT NULL,
      pos_y FLOAT NOT NULL,
      pos_z FLOAT NOT NULL,
      ang_pitch FLOAT NOT NULL DEFAULT 0,
      ang_yaw FLOAT NOT NULL DEFAULT 0,
      ang_roll FLOAT NOT NULL DEFAULT 0,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      INDEX idx_map_name (map_name),
      INDEX idx_npc_identifier (npc_identifier)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  ]]

  IonRP.Database:PreparedQuery(query, {}, function()
    print("[IonRP NPCs] NPC table initialized")

    -- Load NPCs for current map after table is ready
    timer.Simple(0.5, function()
      IonRP.NPCs:LoadNPCsForMap()
    end)
  end, function(err)
    print("[IonRP NPCs] Failed to initialize NPC table: " .. err)
  end)
end

--- Save an NPC instance to the database
--- @param callback function|nil Optional callback(success, npcId)
function NPC_INSTANCE:Save(callback)
  if self.id then
    -- Update existing NPC
    self:Update(callback)
    return
  end

  -- Insert new NPC
  local query = [[
    INSERT INTO ionrp_npcs (npc_identifier, map_name, custom_name, custom_model, pos_x, pos_y, pos_z, ang_pitch, ang_yaw, ang_roll)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ]]


  IonRP.Database:PreparedQuery(
    query,
    {
      self.npcType.identifier,
      self.mapName,
      self.customName or nil,
      self.customModel or nil,
      self.pos.x,
      self.pos.y,
      self.pos.z,
      self.ang.p,
      self.ang.y,
      self.ang.r
    },
    function(data, query)
      local npcId = query:lastInsert()
      self.id = npcId

      print("[IonRP NPCs] Saved NPC '" .. self:GetName() .. "' with ID: " .. npcId)

      -- Register in spawned list
      IonRP.NPCs.Spawned[npcId] = self

      -- Spawn the entity
      self:SV_Spawn()

      -- Sync to all clients
      IonRP.NPCs:SyncNPCToClients(self)

      if callback then
        callback(true, npcId)
      end
    end,
    function(err, sql)
      print("[IonRP NPCs] Failed to save NPC: " .. err)
      print("[IonRP NPCs] SQL: " .. sql)
      print("[IonRP NPCs] Parameters: ", self.npcType.identifier, self.mapName, self.customName, self.customModel,
        self.pos.x, self.pos.y, self.pos.z, self.ang.p, self.ang.y, self.ang.r)
      -- print("[IonRP NPCs] Parameters: \n",
      --   "self.npcType.identifier = \n\t"..self.npcType.identifier,
      --   "self.mapName = \n\t"..self.mapName,
      --   "self.customName = \n\t"..(self.customName or "nil"),
      --   "self.customModel = \n\t"..(self.customModel or "nil"),
      --   "self.pos.x = \n\t"..self.pos.x,
      --   "self.pos.y = \n\t"..self.pos.y,
      --   "self.pos.z = \n\t"..self.pos.z,
      --   "self.ang.p = \n\t"..self.ang.p,
      --   "self.ang.y = \n\t"..self.ang.y,
      --   "self.ang.r = \n\t"..self.ang.r
      -- )
      if callback then
        callback(false)
      end
    end
  )
end

--- Update an existing NPC in the database
--- @param callback function|nil Optional callback(success)
function NPC_INSTANCE:Update(callback)
  if not self.id then
    print("[IonRP NPCs] Cannot update NPC without ID")
    if callback then callback(false) end
    return
  end

  local query = [[
    UPDATE ionrp_npcs
    SET custom_name = ?, custom_model = ?, pos_x = ?, pos_y = ?, pos_z = ?, ang_pitch = ?, ang_yaw = ?, ang_roll = ?
    WHERE id = ?
  ]]

  IonRP.Database:PreparedQuery(
    query,
    {
      self.customName,
      self.customModel,
      self.pos.x,
      self.pos.y,
      self.pos.z,
      self.ang.p,
      self.ang.y,
      self.ang.r,
      self.id
    },
    function()
      print("[IonRP NPCs] Updated NPC ID: " .. self.id)

      -- Respawn the entity with new data
      if IsValid(self.entity) then
        self.entity:Remove()
      end
      self:SV_Spawn()

      -- Sync to all clients
      IonRP.NPCs:SyncNPCToClients(self)

      if callback then
        callback(true)
      end
    end,
    function(err)
      print("[IonRP NPCs] Failed to update NPC: " .. err)
      if callback then
        callback(false)
      end
    end
  )
end

--- Delete an NPC instance from the database
--- @param callback function|nil Optional callback(success)
function NPC_INSTANCE:Delete(callback)
  if not self.id then
    print("[IonRP NPCs] Cannot delete NPC without ID")
    if callback then callback(false) end
    return
  end

  local query = "DELETE FROM ionrp_npcs WHERE id = ?"

  IonRP.Database:PreparedQuery(
    query,
    { self.id },
    function()
      print("[IonRP NPCs] Deleted NPC ID: " .. self.id)

      -- Remove entity
      if IsValid(self.entity) then
        self.entity:Remove()
      end

      -- Remove from spawned list
      IonRP.NPCs.Spawned[self.id] = nil

      -- Notify clients to remove
      net.Start("IonRP_NPC_Remove")
      net.WriteInt(self.id, 32)
      net.Broadcast()

      if callback then
        callback(true)
      end
    end,
    function(err)
      print("[IonRP NPCs] Failed to delete NPC: " .. err)
      if callback then
        callback(false)
      end
    end
  )
end

--- Spawn the NPC entity in the world
function NPC_INSTANCE:SV_Spawn()
  -- Remove old entity if exists
  if IsValid(self.entity) then
    self.entity:Remove()
  end

  -- Create NPC entity
  --- @type NPC
  local npc = ents.Create("npc_citizen")
  if not IsValid(npc) then
    print("[IonRP NPCs] Failed to create NPC entity")
    return
  end

  npc:SetPos(self.pos)
  npc:SetAngles(self.ang)
  npc:SetModel(self:GetModel())
  npc:Spawn()
  npc:Activate()

  -- Configure NPC
  npc:SetHealth(self.npcType.health)
  npc:SetMaxHealth(self.npcType.health)

  if not self.npcType.canBeKilled then
    npc:SetHealth(999999)
    npc:SetMaxHealth(999999)
  end

  if self.npcType.friendly then
    npc:AddRelationship("player D_LI 99")
  end

  -- Configure NPC to stay in place using AI
  npc:SetHullType(HULL_HUMAN)
  npc:SetHullSizeNormal()
  npc:SetSolid(SOLID_BBOX)

  -- Enable basic movement capabilities so pathfinding works
  npc:CapabilitiesClear()
  npc:CapabilitiesAdd(CAP_MOVE_GROUND)
  npc:CapabilitiesAdd(CAP_ANIMATEDFACE)
  npc:CapabilitiesAdd(CAP_TURN_HEAD)

  -- No spammy
  npc:SetUseType(SIMPLE_USE)

  -- Store the home position for pathfinding back
  npc.IonRP_HomePos = self.pos
  npc.IonRP_HomeAng = self.ang

  -- Store reference to instance
  npc.IonRP_NPCInstance = self
  self.entity = npc

  -- Store NPC ID for networking
  npc:SetNWInt("IonRP_NPCID", self.id or 0)
  npc:SetNWString("IonRP_NPCName", self:GetName())
  npc:SetNWString("IonRP_NPCType", self.npcType.name)

  -- Call OnSpawn callback
  if self.npcType.OnSpawn then
    self.npcType.OnSpawn(self.npcType, self)
  end

  print("[IonRP NPCs] Spawned NPC '" .. self:GetName() .. "' at " .. tostring(self.pos))
end

--- Remove all spawned NPCs and clear the spawned list
function IonRP.NPCs:RemoveAllSpawned()
  local count = 0
  for id, npcInstance in pairs(self.Spawned) do
    if IsValid(npcInstance.entity) then
      npcInstance.entity:Remove()
    end
    count = count + 1
  end

  -- Clear the spawned list
  self.Spawned = {}

  if count > 0 then
    print("[IonRP NPCs] Removed " .. count .. " spawned NPCs")
  end
end

--- Load all NPCs for the current map
function IonRP.NPCs:LoadNPCsForMap()
  -- Remove any existing spawned NPCs first to prevent duplicates
  self:RemoveAllSpawned()

  local mapName = game.GetMap()

  local query = "SELECT * FROM ionrp_npcs WHERE map_name = ?"

  IonRP.Database:PreparedQuery(
    query,
    { mapName },
    function(data)
      if not data or #data == 0 then
        print("[IonRP NPCs] No NPCs found for map: " .. mapName)
        return
      end

      print("[IonRP NPCs] Loading " .. #data .. " NPCs for map: " .. mapName)

      for _, npcData in ipairs(data) do
        self:LoadNPC(npcData)
      end
    end,
    function(err)
      print("[IonRP NPCs] Failed to load NPCs: " .. err)
    end
  )
end

--- Load a single NPC from database data
--- @param npcData table NPC data from database
function IonRP.NPCs:LoadNPC(npcData)
  -- Get NPC type
  local npcType = self.List[npcData.npc_identifier]
  if not npcType then
    print("[IonRP NPCs] Unknown NPC type: " .. npcData.npc_identifier)
    return
  end

  -- Create instance
  local instance = NPC_INSTANCE:New(
    npcType,
    Vector(npcData.pos_x, npcData.pos_y, npcData.pos_z),
    Angle(npcData.ang_pitch, npcData.ang_yaw, npcData.ang_roll),
    npcData.custom_name,
    npcData.custom_model
  )
  instance.id = npcData.id
  instance.mapName = npcData.map_name

  -- Register in spawned list
  self.Spawned[instance.id] = instance

  -- Spawn the entity
  instance:SV_Spawn()

  print("[IonRP NPCs] Loaded NPC: " .. instance:GetName() .. " (ID: " .. instance.id .. ")")
end

--- Sync an NPC to all clients
--- @param npcInstance NPCInstance The NPC to sync
function IonRP.NPCs:SyncNPCToClients(npcInstance)
  local npcData = {
    id = npcInstance.id,
    identifier = npcInstance.npcType.identifier,
    customName = npcInstance.customName,
    customModel = npcInstance.customModel,
    pos = npcInstance.pos,
    ang = npcInstance.ang
  }

  net.Start("IonRP_NPC_Sync")
  net.WriteTable(npcData)
  net.Broadcast()
end

--- Sync all NPCs to a player (on join)
--- @param ply Player The player to sync to
function IonRP.NPCs:SyncAllToPlayer(ply)
  for id, npcInstance in pairs(self.Spawned) do
    local npcData = {
      id = npcInstance.id,
      identifier = npcInstance.npcType.identifier,
      customName = npcInstance.customName,
      customModel = npcInstance.customModel,
      pos = npcInstance.pos,
      ang = npcInstance.ang
    }

    net.Start("IonRP_NPC_Sync")
    net.WriteTable(npcData)
    net.Send(ply)
  end
end

--- Player Index -> Time of last click
--- @type table<number, boolean>
local playerHoldingE = {}
--- Hook: Handle player USE key on NPCs
hook.Add("PlayerUse", "IonRP_NPCs_HandleUse", function(ply, ent)
  if not IsValid(ent) or not ent.IonRP_NPCInstance then return end

  -- Simple debounce to prevent spamming
  timer.Create("IonRP_NPCs_Debounce_" .. ply:UserID(), 0.1, 1, function()
    if IsValid(ply) then
      playerHoldingE[ply:UserID()] = nil
    end
  end)
  if playerHoldingE[ply:UserID()] then return false end
  playerHoldingE[ply:UserID()] = true

  local npcInstance = ent.IonRP_NPCInstance
  local npcType = npcInstance.npcType

  -- Call OnUse callback
  if npcType.OnUse then
    npcType.OnUse(npcType, ply, npcInstance)
  end

  return false -- Allow default use behavior
end)

--- Hook: Handle NPC damage
hook.Add("EntityTakeDamage", "IonRP_NPCs_HandleDamage", function(target, dmginfo)
  if not IsValid(target) or not target.IonRP_NPCInstance then return end

  local npcInstance = target.IonRP_NPCInstance
  local npcType = npcInstance.npcType

  -- Call OnDamage callback
  if npcType.OnDamage then
    npcType.OnDamage(npcType, npcInstance, dmginfo)
  end

  -- Prevent death if canBeKilled is false
  if not npcType.canBeKilled then
    dmginfo:ScaleDamage(0)
    target:SetHealth(target:GetMaxHealth())
  end
end)

--- Hook: Handle NPC death
hook.Add("OnNPCKilled", "IonRP_NPCs_HandleDeath", function(npc, attacker, inflictor)
  if not IsValid(npc) or not npc.IonRP_NPCInstance then return end

  --- @type NPCInstance
  local npcInstance = npc.IonRP_NPCInstance
  local npcType = npcInstance.npcType

  -- Call OnDeath callback
  if npcType.OnDeath then
    npcType.OnDeath(npcType, npcInstance, attacker)
  end

  -- Respawn after a delay if can't be killed
  if npcType.respawn ~= nil and npcType.respawn > 0 then
    timer.Simple(npcType.respawn, function()
      if npcInstance and npcInstance.id then
        npcInstance:SV_Spawn()
      end
    end)
  end
end)

--- Hook: Initialize on map load
hook.Add("InitPostEntity", "IonRP_NPCs_LoadMap", function()
  timer.Simple(1, function()
    IonRP.NPCs:LoadNPCsForMap()
  end)
end)

--- Hook: Sync all NPCs to player when they join
hook.Add("PlayerInitialSpawn", "IonRP_NPCs_SyncToPlayer", function(ply)
  timer.Simple(2, function()
    if IsValid(ply) then
      IonRP.NPCs:SyncAllToPlayer(ply)
    end
  end)
end)

--- Hook: Make NPCs constantly return to their home position
hook.Add("Think", "IonRP_NPCs_ReturnHome", function()
  for id, npcInstance in pairs(IonRP.NPCs.Spawned) do
    --- @type NPC
    local npc = npcInstance.entity
    if npc and IsValid(npc) and npc.IonRP_HomePos then
      local homePos = npc.IonRP_HomePos
      local currentPos = npc:GetPos()
      local distance = currentPos:Distance(homePos)

      -- If NPC is more than 50 units away from home, make it walk back
      if distance > 50 then
        -- Set destination to home position
        npc:SetLastPosition(homePos)
        npc:SetSchedule(SCHED_FORCED_GO_RUN)
        -- If NPC is close to home but not exactly there, snap it back
      elseif distance > 5 then
        npc:SetLastPosition(homePos)
        npc:SetSchedule(SCHED_FORCED_GO)
        -- If NPC is at home, make it face the right direction and idle
      else
        npc:SetPos(homePos)
        npc:SetAngles(npc.IonRP_HomeAng)
        -- if npc:GetSchedule() ~= SCHED_IDLE_STAND then
        --   npc:SetSchedule(SCHED_IDLE_STAND)
        -- end
      end
    end
  end
end)

print("[IonRP NPCs] Server module loaded")

-- Command to give NPC gun
IonRP.Commands.Add("npc_gun", function(ply)
  ply:Give("weapon_ionrp_npc_gun")
end, "Give yourself the NPC management gun", "developer")
