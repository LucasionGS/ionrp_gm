--- Drug system for IonRP
--- Generic system for creating complex drug production processes
--- Can be used for plants, labs, processing stations, etc.

IonRP.Drug = IonRP.Drug or {}
--- @type table<string, Drug>
IonRP.Drug.List = IonRP.Drug.List or {}

--- @class Drug
--- @field id string Unique identifier for the drug
--- @field name string Display name
--- @field description string Drug description
--- @field model string Default model for the entity
--- @field customData table Custom data storage for drug-specific properties
DRUG = {}
DRUG.__index = DRUG

--- Create a new drug type
--- @param id string Unique drug identifier
--- @param name string Display name
--- @return Drug
function DRUG:New(id, name)
  local drug = setmetatable({}, DRUG)
  
  drug.id = id
  drug.name = name
  drug.description = ""
  drug.model = "models/props_c17/pottery06a.mdl"
  drug.customData = {} -- For drug-specific properties
  
  -- Register in global list
  IonRP.Drug.List[id] = drug
  
  return drug
end

--- Called when the drug entity is first spawned (SERVER)
--- MUST be overridden in drug definitions for custom setup
--- @param ent Entity The drug entity
function DRUG:SV_Initialize(ent)
  -- Default minimal implementation
  ent:SetModel(self.model)
  ent:PhysicsInit(SOLID_VPHYSICS)
  ent:SetMoveType(MOVETYPE_VPHYSICS)
  ent:SetSolid(SOLID_VPHYSICS)
  ent:SetUseType(SIMPLE_USE)
  
  local phys = ent:GetPhysicsObject()
  if phys and phys:IsValid() then
    phys:Wake()
  end
  
  -- Store reference to drug definition
  ent.drug = self
end

--- Called when player uses the drug entity (SERVER)
--- MUST be overridden in drug definitions for custom behavior
--- @param ent Entity The drug entity
--- @param ply Player The player using
function DRUG:SV_OnUse(ent, ply)
  -- Default: do nothing - override in specific drug definitions
  ply:ChatPrint("[IonRP] This drug entity has no use behavior defined")
end

--- Called when entity is removed (SERVER)
--- Override this to clean up custom timers, child entities, etc.
--- @param ent Entity The drug entity
function DRUG:SV_OnRemove(ent)
  -- Default: empty - override in drug definitions
end

--- Called every think tick (SERVER)
--- Override this for continuous processing logic
--- @param ent Entity The drug entity
function DRUG:SV_Think(ent)
  -- Default: empty - override in drug definitions
end

--- Helper: Set custom network data
--- @param ent Entity The drug entity
--- @param key string Data key
--- @param value any Value to set
--- @param varType string Type: "Int", "Float", "Bool", "String", "Vector", "Angle"
function DRUG:SetNetworkData(ent, key, value, varType)
  if not IsValid(ent) then return end
  local fullKey = "IonRP_Drug_" .. key
  
  if varType == "Int" then
    ent:SetNWInt(fullKey, value)
  elseif varType == "Float" then
    ent:SetNWFloat(fullKey, value)
  elseif varType == "Bool" then
    ent:SetNWBool(fullKey, value)
  elseif varType == "String" then
    ent:SetNWString(fullKey, value)
  elseif varType == "Vector" then
    ent:SetNWVector(fullKey, value)
  elseif varType == "Angle" then
    ent:SetNWAngle(fullKey, value)
  end
end

--- Helper: Get custom network data
--- @param ent Entity The drug entity
--- @param key string Data key
--- @param varType string Type: "Int", "Float", "Bool", "String", "Vector", "Angle"
--- @param default any Default value if not set
--- @return any
function DRUG:GetNetworkData(ent, key, varType, default)
  if not IsValid(ent) then return default end
  local fullKey = "IonRP_Drug_" .. key
  
  if varType == "Int" then
    return ent:GetNWInt(fullKey, default or 0)
  elseif varType == "Float" then
    return ent:GetNWFloat(fullKey, default or 0.0)
  elseif varType == "Bool" then
    return ent:GetNWBool(fullKey, default or false)
  elseif varType == "String" then
    return ent:GetNWString(fullKey, default or "")
  elseif varType == "Vector" then
    return ent:GetNWVector(fullKey, default or Vector())
  elseif varType == "Angle" then
    return ent:GetNWAngle(fullKey, default or Angle())
  end
  
  return default
end

print("[IonRP Drug] Shared drug system loaded")
