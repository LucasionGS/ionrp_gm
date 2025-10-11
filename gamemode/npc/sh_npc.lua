IonRP.NPCs = IonRP.NPCs or {}

--- Registry of all NPC types
--- @type table<string, NPC>
IonRP.NPCs.List = IonRP.NPCs.List or {}

--- Registry of spawned NPC instances
--- @type table<number, NPCInstance>
IonRP.NPCs.Spawned = IonRP.NPCs.Spawned or {}

--[[
  NPC Base Class
  Defines the structure and behavior for all NPCs
]]--
--- @class NPC
NPC = {}

--- @type NPC
NPC.__index = NPC

--- The unique identifier for the NPC type
--- @type string
NPC.identifier = "generic_npc"

--- The display name of the NPC
--- @type string
NPC.name = "<Unnamed NPC>"

--- The description of the NPC
--- @type string
NPC.description = "<No description>"

--- The default model for the NPC
--- @type string
NPC.model = "models/player/group01/male_01.mdl"

--- The category of the NPC (for organization in spawn menu)
--- @type string
NPC.category = "Other"

--- The health of the NPC
--- @type number
NPC.health = 100

--- Whether the NPC can be killed
--- @type boolean
NPC.canBeKilled = false

--- Time in seconds before the NPC respawns after being killed. 0 = no respawn
--- @type number
NPC.respawn = 30

--- Whether the NPC is friendly (won't be targeted by NPCs/players)
--- @type boolean
NPC.friendly = true

--- Create a new NPC type and register it
--- @param identifier string Unique identifier for the NPC type
--- @param name string Display name for the NPC
--- @return NPC
function NPC:New(identifier, name)
  local newNPC = {}
  setmetatable(newNPC, self)
  self.__index = self
  newNPC.identifier = identifier
  newNPC.name = name

  IonRP.NPCs.List[identifier] = newNPC
  print("│ [IonRP NPCs] ├ Registered NPC: " .. identifier .. " - " .. name)

  return newNPC
end

--[[
  NPC Instance Class
  Represents a spawned NPC in the world
]]--
--- @class NPCInstance
NPC_INSTANCE = {}

--- @type NPCInstance
NPC_INSTANCE.__index = NPC_INSTANCE

--- Database ID of the spawned NPC (nil if not saved yet)
--- @type number|nil
NPC_INSTANCE.id = nil

--- The NPC type this instance is based on
--- @type NPC
NPC_INSTANCE.npcType = nil

--- Custom name for this instance (overrides NPC.name if set)
--- @type string|nil
NPC_INSTANCE.customName = nil

--- Custom model for this instance (overrides NPC.model if set)
--- @type string|nil
NPC_INSTANCE.customModel = nil

--- World position of the NPC
--- @type Vector
NPC_INSTANCE.pos = Vector(0, 0, 0)

--- World angles of the NPC
--- @type Angle
NPC_INSTANCE.ang = Angle(0, 0, 0)

--- The actual NPC entity (nil if not spawned yet)
--- @type NPC|nil
NPC_INSTANCE.entity = nil

--- The map this NPC instance is on
--- @type string
NPC_INSTANCE.mapName = ""

--- Create a new NPC instance
--- @param npcType NPC The NPC type to instantiate
--- @param pos Vector World position
--- @param ang Angle World angles
--- @param customName string|nil Optional custom name
--- @param customModel string|nil Optional custom model
--- @return NPCInstance
function NPC_INSTANCE:New(npcType, pos, ang, customName, customModel)
  local instance = setmetatable({}, NPC_INSTANCE)
  instance.npcType = npcType
  instance.pos = pos
  instance.ang = ang
  instance.customName = customName
  instance.customModel = customModel
  instance.mapName = game.GetMap()
  return instance
end

--- Get the display name for this instance
--- @return string
function NPC_INSTANCE:GetName()
  return self.customName or self.npcType.name
end

--- Get the model for this instance
--- @return string
function NPC_INSTANCE:GetModel()
  return self.customModel or self.npcType.model
end

if SERVER then
  --[[
    Server-side NPC methods
    These can be overridden in specific NPC types
  ]]--

  --- Called when a player uses (presses E on) the NPC
  --- @param ply Player The player who used the NPC
  function NPC:OnUse(ply)
    -- Default behavior: chat message
    ply:ChatPrint("[NPC] " .. self:GetName() .. ": Hello!")
  end

  --- Called when the NPC is spawned
  --- @param npcInstance NPCInstance The instance being spawned
  function NPC:OnSpawn(npcInstance)
    -- Override in specific NPC types for custom behavior
  end

  --- Called when the NPC is removed
  --- @param npcInstance NPCInstance The instance being removed
  function NPC:OnRemove(npcInstance)
    -- Override in specific NPC types for custom behavior
  end

  --- Called when the NPC takes damage
  --- @param npcInstance NPCInstance The instance taking damage
  --- @param dmginfo CTakeDamageInfo Damage info
  function NPC:OnDamage(npcInstance, dmginfo)
    -- Override in specific NPC types for custom behavior
  end

  --- Called when the NPC dies
  --- @param npcInstance NPCInstance The instance that died
  --- @param attacker Entity The entity that killed the NPC
  function NPC:OnDeath(npcInstance, attacker)
    -- Override in specific NPC types for custom behavior
  end
end

if CLIENT then
  --[[
    Client-side NPC methods
  ]]--

  --- Draw additional information above the NPC
  --- @param npcInstance NPCInstance The instance to draw for
  function NPC:DrawInfo(npcInstance)
    -- Override in specific NPC types for custom UI
  end
end

-- Load NPC types
print("┌──────────────┬─────────────────────────────────────────────────────────────────•")
print("│ [IonRP NPCs] │ Loading NPC types")

local npcFiles = file.Find("ionrp/gamemode/npc/npcs/*.lua", "LUA")
if npcFiles then
  for _, npcFile in ipairs(npcFiles) do
    include("npcs/" .. npcFile)
    if SERVER then
      AddCSLuaFile("npcs/" .. npcFile)
    end
  end
end

print("│ [IonRP NPCs] │ Loaded " .. table.Count(IonRP.NPCs.List) .. " NPC types")
print("└──────────────┴─────────────────────────────────────────────────────────────────•")
