IonRP.Vehicles = IonRP.Vehicles or {}
--- All registered vehicle types
--- @type table<string, VEHICLE>
IonRP.Vehicles.List = IonRP.Vehicles.List or {}

if SERVER then
  --- Active vehicle instances. Keys are the entity index of the vehicle entity.
  --- @type table<number, VEHICLE>
  IonRP.Vehicles.Active = IonRP.Vehicles.Active or {}
end

--- Active vehicle instances
IonRP.Vehicles.Categories = {
  SUPERCARS = "Supercars",
  OTHER = "Other",
}

--- @class VEHICLE
VEHICLE = {}

VEHICLE.__index = VEHICLE

--- The unique identifier
--- @type string
VEHICLE.identifier = "generic_vehicle"

--- The display name
--- @type string
VEHICLE.name = "<No name>"

--- The model path used for the world model
--- @type string
VEHICLE.model = "models/buggy.mdl"

--- Vehicle script this car utilizes
--- @type string
VEHICLE.script = "scripts/vehicles/jeep.txt"

--- The market value used to determine pricing in shops and upgrades
--- @type number
VEHICLE.marketValue = 10000

--- Whether or not this vehicle can be purchased from shops
--- @type boolean
VEHICLE.purchasable = true

--- Vehicle category. Matches an entry in IonRP.Vehicles.Categories
--- @type string
VEHICLE.category = IonRP.Vehicles.Categories.OTHER

--- The player who owns this vehicle instance
--- @type Player|nil
VEHICLE.owner = nil

--- The physical vehicle entity in the world
--- @type Entity|nil
VEHICLE.entity = nil

--- The database ID for this vehicle instance (if owned)
--- As a player can own multiple of the same vehicle with different configurations,
--- owned vehicles are uniquely identified by this ID.
--- @type number|nil
VEHICLE.databaseId = nil

--[[
  Upgradeable stats
]]--

--- Contains all upgradeable stats for this vehicle.
---
--- This determines how many levels each stat has and what the values are.
--- First entry is always the default for newly acquired vehicles.
--- @class VehicleUpgradeables
VEHICLE.Upgradeable = {}

--- Active levels for this instance of the vehicle.
--- Only applicable to owned vehicles.
---
--- This is stored in the database and will always be `1` on all fields by default.
--- @class VehicleUpgrades
VEHICLE.Upgrades = {}

--- Fuel capacity
VEHICLE.Upgradeable.fuelTank = { 150, 200, 250, 300 }
VEHICLE.Upgrades.fuelTank = 1

--- Engine power
VEHICLE.Upgradeable.engine = { 50, 65, 80 }
VEHICLE.Upgrades.engine = 1

--- Horsepower
VEHICLE.Upgradeable.horsepower = { 50, 65, 80 }
VEHICLE.Upgrades.horsepower = 1

--- Create a new vehicle
--- @param identifier string The unique identifier for the vehicle
--- @param name string The display name of the vehicle
--- @return VEHICLE
function VEHICLE:New(identifier, name)
  local newVehicle = {}
  setmetatable(newVehicle, VEHICLE)
  newVehicle.__index = VEHICLE
  newVehicle.identifier = identifier
  newVehicle.name = name
  newVehicle.Upgrades = table.Copy(self.Upgrades)
  newVehicle.Upgradeable = table.Copy(self.Upgradeable)

  IonRP.Vehicles.List[identifier] = newVehicle
  print("│ [IonRP Vehicles] ├ Registered vehicle: " .. identifier .. " - " .. name)

  return newVehicle
end

--- Create an instance of the vehicle with a player as the owner context.
--- @param owner Player The player who owns this vehicle instance.
--- @param databaseId number|nil The database ID for this vehicle instance (if owned).
--- @return VEHICLE
function VEHICLE:MakeOwnedInstance(owner, databaseId)
  local vehicleInstance = {}
  setmetatable(vehicleInstance, VEHICLE)
  vehicleInstance.__index = VEHICLE
  vehicleInstance.owner = owner
  vehicleInstance.databaseId = databaseId or nil
  vehicleInstance.Upgrades = table.Copy(self.Upgrades)
  vehicleInstance.Upgradeable = table.Copy(self.Upgradeable)
  return vehicleInstance
end

if SERVER then
  -- Ensure data paths existing
  if not file.Exists("ionrp", "DATA") then
    file.CreateDir("ionrp")
  end
  if not file.Exists("ionrp/generated_vehicle_scripts", "DATA") then
    file.CreateDir("ionrp/generated_vehicle_scripts")
  end

  --- Spawn an instanced vehicle in the world
  --- @param pos Vector The position to spawn the vehicle at
  --- @param ang Angle The angle to spawn the vehicle with
  --- @return Entity|nil # The spawned vehicle entity, or nil on failure
  function VEHICLE:SV_Spawn(pos, ang)
    if not pos or not ang then return nil end
    if not self.model or self.model == "" then return nil end
    local veh = ents.Create("prop_vehicle_jeep")
    if not IsValid(veh) then return nil end
    veh:SetModel(self.model)
    veh:SetPos(pos)
    veh:SetAngles(ang)

    -- Based on upgrades, we use a generated vehicle script
    veh:SetKeyValue("vehiclescript", self:SV_GetVehicleScript())

    veh:Spawn()
    veh:Activate()
    veh:SetNWString("IonRP_VehicleID", self.identifier)

    self.entity = veh
    IonRP.Vehicles.Active[veh:EntIndex()] = self

    return veh
  end

  function VEHICLE:SV_GetVehicleScriptFilepath()
    local generatedPath = "ionrp/generated_vehicle_scripts/" .. self.databaseId .. ".txt"
    return generatedPath
  end
  
  --- Get or generate the vehicle script path for this vehicle instance
  function VEHICLE:SV_GetVehicleScript()
    -- Check if a generate script exists for this vehicle
    local generatedPath = self:SV_GetVehicleScriptFilepath()
    if not file.Exists(generatedPath, "DATA") then
      self:SV_GenerateVehicleScript()
    end

    return generatedPath
  end

  --- Parse original vehicle script and apply upgrades
  --- This should be called when a vehicles upgrades have changed.
  --- @return string|nil # The path to the generated vehicle script, or nil on failure
  function VEHICLE:SV_GenerateVehicleScript()
    if not self.entity or not IsValid(self.entity) then return end
    if not self.Upgrades or not self.Upgradeable then return end
    local scriptPath = self.script
    if not scriptPath or scriptPath == "" then return end
    local scriptData = file.Read(scriptPath, "GAME")

    print("Generating vehicle script for " .. self.identifier .. " with DB ID " .. tostring(self.databaseId))
    --- @class VehicleParams
    --- @field axles VehicleParamsAxle
    --- @field body VehicleParamsBody
    --- @field engine VehicleParamsEngine
    --- @field steering VehicleParamsSteering
    local data = util.KeyValuesToTablePreserveOrder(scriptData)
    PrintTable(data)
    -- TODO: Test what data i even have to work with and implement
    -- Manipulate the data...

    data.engine.horsepower = data.engine.horsepower * (self.Upgrades.horsepower or 1)

    -- Convert back to string
    local newScript = util.TableToKeyValues(data)
    local path = self:SV_GetVehicleScriptFilepath()
    file.Write(path, newScript)
    -- Reload scripts to apply changes
    RunConsoleCommand("vehicle_flushscript")

    return path
  end

  --- Find the owner of a vehicle by its entity
  --- @param ent Entity The vehicle entity
  --- @return Player|nil - The owner player, or nil if not found
  function VEHICLE:SV_FindOwnerByEntity(ent)
    if not ent or not IsValid(ent) then return nil end
    local vehData = IonRP.Vehicles.Active[ent:EntIndex()]
    if not vehData then return nil end
    return vehData.owner
  end

  function VEHICLE:SV_Lock()
    if not self.entity or not IsValid(self.entity) then return end
    self.entity:Fire("lock", "", 0)
    self.entity:EmitSound("doors/door_locked2.wav", 60, 100)
    self.entity:SetNWBool("lockedState", true)
  end
  
  function VEHICLE:SV_Unlock()
    if not self.entity or not IsValid(self.entity) then return end
    self.entity:Fire("unlock", "", 0)
    self.entity:EmitSound("doors/door_locked1.wav", 60, 100)
    self.entity:SetNWBool("lockedState", false)
  end

  util.AddNetworkString("IonRP_VehicleLockToggle")
  net.Receive("IonRP_VehicleLockToggle", function(len, ply)
    local ent = net.ReadEntity()
    local isLocked = net.ReadBool()
    if not ent or not IsValid(ent) then return end

    local vehData = IonRP.Vehicles.Active[ent:EntIndex()]
    if not vehData then return end
    vehData:ToggleLock(ply, isLocked)
  end)
end


--- Toggle the lock state of the vehicle
--- @param activator Player|nil The player who initiated the lock toggle (for client-side use)
--- @param state boolean|nil If specified, forces the lock state to this value. If nil, toggles the current state.
function VEHICLE:ToggleLock(activator, state)
  if not self.entity or not IsValid(self.entity) then return end

  local isLocked = self.entity:GetNWBool("lockedState", false)
  if state ~= nil then
    isLocked = state
  else
    isLocked = not isLocked
  end

  if CLIENT then
    net.Start("IonRP_VehicleLockToggle")
      net.WriteEntity(self.entity)
      net.WriteBool(isLocked)
    net.Send(activator or LocalPlayer())
  else
    if not ent or not IsValid(ent) then return end

    local vehData = IonRP.Vehicles.Active[ent:EntIndex()]
    if not vehData then return end
    local ply = vehData.owner
    if not ply or not IsValid(ply) then return end
    
    if isLocked then
      vehData:SV_Lock()
      ply:ChatPrint("Vehicle locked.")
    else
      vehData:SV_Unlock()
      ply:ChatPrint("Vehicle unlocked.")
    end
  end
end

-- Import vehicles
print("┌──────────────────┬───────────────────────────────────────────────────────────────•")
print("│ [IonRP Vehicles] │ Loading vehicles")
for _, vehicle in ipairs(file.Find("ionrp/gamemode/vehicle/vehicles/*.lua", "LUA")) do
  include("vehicles/" .. vehicle)
  if SERVER then
    AddCSLuaFile("vehicles/" .. vehicle)
  end
end
print("│ [IonRP Vehicles] │ Loaded " .. tostring(table.Count(IonRP.Vehicles.List)) .. " vehicles")
print("└──────────────────┴───────────────────────────────────────────────────────────────•")
