IonRP.Licenses = IonRP.Licenses or {}

---@type table<string, LICENSE>
IonRP.Licenses.List = IonRP.Licenses.List or {}

--- @class LICENSE
LICENSE = {}

--- @type LICENSE
LICENSE.__index = LICENSE

--- The unique identifier for the license type.
--- @type string
LICENSE.identifier = "generic_license"

--- The display name of the license.
--- @type string
LICENSE.name = "<No name>"

--- The description of what this license permits.
--- @type string
LICENSE.description = "<No description>"

--- The icon material path for the license.
--- @type string
LICENSE.icon = "icon16/page_white_text.png"

--- The color theme for this license type (used in UI).
--- @type Color
LICENSE.color = Color(100, 150, 255)

--- @class LicenseInstance
--- @field licenseType LICENSE The license type definition
--- @field owner Player|nil The player who owns this license instance
--- @field state "active"|"suspended" The current state of the license
--- @field reason string|nil The reason for suspension (if suspended)
--- @field activateOn string|nil ISO datetime string when license becomes active
--- @field grantedAt string ISO datetime string when license was granted
--- @field updatedAt string ISO datetime string when license was last updated

--- Create a new license type and register it. Properties can be assigned to the returned object.
--- @param identifier string Identifier that uniquely distinguishes the license.
--- @param name string Name of the license.
--- @return LICENSE
function LICENSE:New(identifier, name)
  local newLicense = {}
  setmetatable(newLicense, self)
  self.__index = self
  newLicense.identifier = identifier
  newLicense.name = name

  IonRP.Licenses.List[identifier] = newLicense
  print("│ [IonRP Licenses] ├ Registered license: " .. identifier .. " - " .. name)

  return newLicense
end

--- Create an instance of the license with a player as the owner context.
--- @param owner Player The player who owns this license instance.
--- @param state "active"|"suspended"|nil The state of the license (default: "active")
--- @param reason string|nil The reason for suspension (if suspended)
--- @param activateOn string|nil ISO datetime when license becomes active
--- @param grantedAt string|nil ISO datetime when license was granted
--- @param updatedAt string|nil ISO datetime when license was last updated
--- @return LicenseInstance
function LICENSE:MakeOwnedInstance(owner, state, reason, activateOn, grantedAt, updatedAt)
  local licenseInstance = {
    licenseType = self,
    owner = owner,
    state = state or "active",
    reason = reason,
    activateOn = activateOn,
    grantedAt = grantedAt or os.date("!%Y-%m-%d %H:%M:%S"),
    updatedAt = updatedAt or os.date("!%Y-%m-%d %H:%M:%S")
  }
  
  return licenseInstance
end

--- Check if a license instance is currently valid (active and not waiting for activation)
--- @param licenseInstance LicenseInstance The license instance to check
--- @return boolean
function LICENSE:IsValid(licenseInstance)
  if not licenseInstance or licenseInstance.state ~= "active" then
    return false
  end
  
  -- Check if license has a future activation date
  if licenseInstance.activateOn then
    local activateTime = self:ParseDateTime(licenseInstance.activateOn)
    if activateTime and os.time() < activateTime then
      return false -- Not yet activated
    end
  end
  
  return true
end

--- Parse ISO datetime string to Unix timestamp
--- @param dateTimeStr string ISO datetime string (YYYY-MM-DD HH:MM:SS)
--- @return number|nil Unix timestamp or nil if parsing failed
function LICENSE:ParseDateTime(dateTimeStr)
  if not dateTimeStr then return nil end
  
  local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)"
  local year, month, day, hour, min, sec = dateTimeStr:match(pattern)
  
  if not year then return nil end
  
  return os.time({
    year = tonumber(year),
    month = tonumber(month),
    day = tonumber(day),
    hour = tonumber(hour),
    min = tonumber(min),
    sec = tonumber(sec)
  })
end

-- Import license definitions
print("┌────────────────────┬─────────────────────────────────────────────────────────────•")
print("│ [IonRP Licenses]   │ Loading License Types")
print("│ [IonRP Licenses]   │ Loading license definitions...")
for _, licenseFile in ipairs(file.Find("ionrp/gamemode/license/licenses/*.lua", "LUA")) do
  include("licenses/" .. licenseFile)
  if SERVER then
    AddCSLuaFile("licenses/" .. licenseFile)
  end
end
print("└────────────────────┴─────────────────────────────────────────────────────────────•")
