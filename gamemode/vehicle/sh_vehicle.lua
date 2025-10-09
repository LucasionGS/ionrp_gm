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

--- The description
--- @type string
VEHICLE.description = "<No description>"

--- The model path used for the world model
--- @type string
VEHICLE.model = "models/buggy.mdl"

--- Vehicle script this car utilizes
--- @type string
VEHICLE.script = "scripts/vehicles/airboat.txt"

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
]] --

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
VEHICLE.Upgradeable.fuelTank = { 1, 1.5, 2.5, 3 }
VEHICLE.Upgrades.fuelTank = 1

--- Engine power
VEHICLE.Upgradeable.engine = { 1, 1.5, 2 }
VEHICLE.Upgrades.engine = 1

--- Horsepower
VEHICLE.Upgradeable.horsepower = { 1, 1.1, 1.2, 1.4 }
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
  newVehicle.Upgrades = table.Copy(VEHICLE.Upgrades)
  newVehicle.Upgradeable = table.Copy(VEHICLE.Upgradeable)

  IonRP.Vehicles.List[identifier] = newVehicle
  print("│ [IonRP Vehicles] ├ Registered vehicle: " .. identifier .. " - " .. name)

  return newVehicle
end

--- Create a new vehicle from it's existing class name in GMod's vehicle list.
---
--- This will automatically assign the model and script based on the vehicle data.
--- @param vehicleClassName string The class name of the vehicle
--- @param identifier_override string|nil Optional override for the vehicle identifier
--- @return VEHICLE|nil
function VEHICLE:NewFrom(vehicleClassName, identifier_override)
  --[[
    Example:
    ["bmwm613tdm"]:
      ["Author"]          =       TheDanishMaster, Turn 10
      ["Category"]        =       TDM Cars
      ["Class"]           =       prop_vehicle_jeep
      ["Information"]     =       A drivable BMW M6 2013 by TheDanishMaster
      ["KeyValues"]:
        ["vehiclescript"] =       scripts/vehicles/TDMCars/bmwm613.txt
      ["Model"]           =       models/tdmcars/bmw_m6_13.mdl
      ["Name"]            =       BMW M6 2013
  ]] --
  local vehicleData = GetVehicleList()[vehicleClassName]
  if not vehicleData then return nil end

  local newVehicle = self:New(identifier_override or vehicleClassName, vehicleData.Name)
  newVehicle.model = vehicleData.Model
  newVehicle.script = vehicleData.KeyValues.vehiclescript
  newVehicle.description = vehicleData.Information

  return newVehicle
end

local _cachedVehicleList = nil
function GetVehicleList()
  if not _cachedVehicleList then
    _cachedVehicleList = list.Get("Vehicles") or {}
  end
  return _cachedVehicleList
end

--- Create an instance of the vehicle with a player as the owner context.
--- @param owner Player The player who owns this vehicle instance.
--- @param databaseId number|nil The database ID for this vehicle instance (if owned).
--- @return VEHICLE
function VEHICLE:MakeOwnedInstance(owner, databaseId)
  local vehicleInstance = table.Copy(self)
  setmetatable(vehicleInstance, self)
  vehicleInstance.__index = self
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
    --- @class Vehicle
    local veh = ents.Create("prop_vehicle_jeep")
    if not IsValid(veh) then return nil end
    veh:SetModel(self.model)
    veh:SetPos(pos)
    veh:SetAngles(ang)

    -- Based on upgrades, we use a generated vehicle script
    veh:SetKeyValue("vehiclescript", "scripts/vehicles/" .. self:SV_GetVehicleScript())
    -- veh:SetKeyValue("vehiclescript", "scripts/vehicles/car.txt")
    -- veh:SetKeyValue("vehiclescript", self.script)
    veh:Spawn()
    veh:Activate()
    veh:SetNWString("IonRP_VehicleID", self.identifier)
    veh.VehicleInstance = self

    IonRP.Vehicles:SV_DefineVehicleEntity(veh)

    self.entity = veh
    IonRP.Vehicles.Active[veh:EntIndex()] = self

    return veh
  end

  --- For KeyvaluesToTablePreserveOrder converted tables back to string
  --- Their format follows "1" {
  ---   "Key" "KEY"
  ---   "Value" "VALUE"
  --- }
  --- @param tbl table The table to convert
  --- @param rootName string The root name for the keyvalues (e.g. "root")
  function TablePreservedOrderToKeyValues(tbl, rootName)
    local lines = {}
    for k, v in ipairs(tbl) do
      local key = v["Key"]
      local value = v["Value"]

      if type(value) == "table" then
        table.insert(lines, TablePreservedOrderToKeyValues(value, key))
      else
        table.insert(lines, string.format('\t"%s" "%s"', key, value))
      end
    end
    return "\"" .. rootName .. "\"\n{\n" .. table.concat(lines, "\n") .. "\n}"
  end

  --- Set a value in a KeyvaluesToTablePreserveOrder converted table by its key path
  --- @param tbl table The table to modify
  --- @param keyPath string The dot-separated key path (e.g. "engine.horsepower")
  --- @param value any The value to set
  --- @return table # The modified table
  function SetKeyValueTable(tbl, keyPath, value)
    local keys = string.Explode(".", keyPath)
    local current = tbl
    for i = 1, #keys do
      local key = keys[i]
      for _, entry in ipairs(current) do
        if entry["Key"] == key then
          if i == #keys then
            entry["Value"] = value
            return tbl
          end
          current = entry["Value"]
          break
        end
      end
    end

    return tbl
  end

  --- Get a value in a KeyvaluesToTablePreserveOrder converted table by its key path
  --- @param tbl table The table to search
  --- @param keyPath string The dot-separated key path (e.g. "engine.horsepower")
  --- @return number|string|nil
  function GetKeyValueTable(tbl, keyPath)
    -- PrintTable(tbl)
    -- print(keyPath)
    local keys = string.Explode(".", keyPath)
    local current = tbl
    for i = 1, #keys do
      local key = keys[i]
      local foundLayer = false
      for _, entry in ipairs(current) do
        if entry["Key"] == key then
          -- print("Found:", entry["Key"], " " .. tostring(i) .. " out of " .. tostring(#keys))
          -- PrintTable(entry["Value"])
          current = entry["Value"]

          -- if type(current) ~= "table" then
          --   return current
          -- end

          foundLayer = true
          break
        end
      end
      if not foundLayer then
        print("Key not found:", key)
        -- PrintTable(current)
        return nil
      end
    end
    --- @type number|string|nil
    return current
  end

  function VEHICLE:SV_GetVehicleScriptFilepath()
    -- Generate a unique hash based on the upgrade combination
    local upgradeHash = util.TableToJSON({ -- Only use upgrades that affect the script file
      self.Upgrades.engine,
      self.Upgrades.horsepower
    })
    upgradeHash = util.SHA256(upgradeHash)

    local generatedPath = string.format("ionrp/generated_vehicle_scripts/%s_%s.txt", self.identifier, upgradeHash)
    return generatedPath
  end

  --- Get or generate the vehicle script path for this vehicle instance
  function VEHICLE:SV_GetVehicleScript()
    -- Check if a generate script exists for this vehicle
    local generatedPath = self:SV_GetVehicleScriptFilepath()
    if not file.Exists(generatedPath, "DATA") then
      print("No generated vehicle script found for " .. self.identifier .. ", generating new one.")
      self:SV_GenerateVehicleScript()
    else
      print("Using existing generated vehicle script for " .. self.identifier)
    end
    -- self:SV_GenerateVehicleScript()

    return generatedPath
  end

  --- Parse original vehicle script and apply upgrades
  --- This should be called when a vehicles upgrades have changed.
  --- @return string|nil # The path to the generated vehicle script, or nil on failure
  function VEHICLE:SV_GenerateVehicleScript()
    if not self.Upgrades or not self.Upgradeable then return end
    if not self.script or self.script == "" then return end

    print("Generating vehicle script for " .. self.identifier)
    local data = file.Read(self.script, "GAME")
    local toTable = util.KeyValuesToTablePreserveOrder("root" .. "\n{\n" .. data .. "\n}")
    local items = table.GetKeys(toTable)

    --- @param upgradeable string
    --- @return number|string
    local function getLevel(upgradeable)
      return self.Upgradeable[upgradeable][self.Upgrades[upgradeable] or 1] or self.Upgradeable[upgradeable][1]
    end

    -- Manipulate the data...
    local horsepower = GetKeyValueTable(toTable, "vehicle.engine.horsepower")
    SetKeyValueTable(toTable, "vehicle.engine.horsepower", horsepower * getLevel("horsepower"))
    
    -- local maxreversespeed = GetKeyValueTable(toTable, "vehicle.engine.maxreversespeed")
    -- SetKeyValueTable(toTable, "vehicle.engine.maxreversespeed", maxreversespeed * getLevel("engine"))

    -- local power = GetKeyValueTable(toTable, "vehicle.engine.power")
    -- SetKeyValueTable(toTable, "vehicle.engine.power", power * getLevel("engine"))

    -- Convert back to string
    local newData = ""
    for _, k in ipairs(items) do
      local v = toTable[k]
      newData = newData .. TablePreservedOrderToKeyValues(v["Value"], v["Key"]) .. "\n\n"
    end
    
    local path = self:SV_GetVehicleScriptFilepath()
    file.Write(path, newData)
    -- Reload scripts to apply changes
    -- RunConsoleCommand("vehicle_flushscript")

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

IonRP.Commands.Add("listvehicles", function(ply, args, rawArgs)
  for id, veh in pairs(IonRP.Vehicles.List) do
    if IsValid(ply) then
      ply:ChatPrint(string.format("%s - %s (Model: %s, Price: $%d)", id, veh.name, veh.model, veh.marketValue))
    else
      print(string.format("%s - %s (Model: %s, Price: $%d)", id, veh.name, veh.model, veh.marketValue))
    end
  end
end, "List all registered vehicles", "developer")

IonRP.Commands.Add("listvehiclescripts", function(ply, args, rawArgs)
  -- Recursively find all vehicle scripts
  local function findScriptsRecursive(basePath, relativePath)
    local results = {}
    local files, dirs = file.Find(basePath .. "/*", "GAME")

    -- Add all .txt files in current directory
    for _, fileName in ipairs(files) do
      if string.EndsWith(fileName, ".txt") then
        local fullPath = relativePath .. fileName
        table.insert(results, fullPath)
      end
    end

    -- Recursively search subdirectories
    for _, dirName in ipairs(dirs) do
      local subResults = findScriptsRecursive(basePath .. "/" .. dirName, relativePath .. dirName .. "/")
      for _, path in ipairs(subResults) do
        table.insert(results, path)
      end
    end

    return results
  end

  local allScripts = findScriptsRecursive("scripts/vehicles", "")

  for _, scriptPath in ipairs(allScripts) do
    if IsValid(ply) then
      ply:ChatPrint(string.format("Found vehicle script: %s", scriptPath))
    else
      print(string.format("Found vehicle script: %s", scriptPath))
    end
  end

  if IsValid(ply) then
    ply:ChatPrint(string.format("Total scripts found: %d", #allScripts))
  else
    print(string.format("Total scripts found: %d", #allScripts))
  end
end, "List all registered vehicle scripts", "developer")

-- Spawn car at eye trace
IonRP.Commands.Add("spawncar", function(ply, args, rawArgs)
  local vehicleId = args[1]
  if not vehicleId or vehicleId == "" then
    ply:ChatPrint("[IonRP] Usage: /spawncar <vehicle_id>")
    return
  end

  local vehData = IonRP.Vehicles.List[vehicleId]
  if not vehData then
    ply:ChatPrint("[IonRP] Vehicle ID not found: " .. vehicleId)
    return
  end

  PrintTable(vehData)

  local trace = ply:GetEyeTrace()
  local spawnPos = trace.HitPos + Vector(0, 0, 10)
  local spawnAng = Angle(0, ply:EyeAngles().y - 90, 0)

  local vehInstance = vehData:MakeOwnedInstance(ply)
  local vehEnt = vehInstance:SV_Spawn(spawnPos, spawnAng)
  if not vehEnt or not IsValid(vehEnt) then
    ply:ChatPrint("[IonRP] Failed to spawn vehicle.")
    return
  end

  ply:ChatPrint(string.format("[IonRP] Spawned vehicle: %s", vehData.name))
end, "Spawn a vehicle by ID", "developer")

IonRP.Commands.Add("allvehicles", function(ply, args, rawArgs)
  local data = GetVehicleList()

  for className, veh in pairs(data) do
    local str = string.format("%s - %s (\n  Model: %s\n  Script: %s\n)", className, veh.Name, veh.Model,
      veh.KeyValues.vehiclescript)
    if IsValid(ply) then
      ply:ChatPrint(str)
    else
      print(str)
    end
  end
end, "List all vehicles", "developer")

if SERVER then
  include("sv_vehicle.lua")
end
