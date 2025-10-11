--[[
    Garage System - Shared
    Manages garage groups and parking spots for vehicle spawning
    
    Features:
    - Named garage groups with anchor points
    - Multiple parking spots per group
    - Find closest garage to player
    - Per-map persistence
    - Visual indicators for developers
]]--

IonRP.Garage = IonRP.Garage or {}

--- All garage groups on the current map
--- @type table<number, GarageGroup>
IonRP.Garage.Groups = IonRP.Garage.Groups or {}

--- All spawned garage entities (for cleanup)
--- @type table<number, Entity>
IonRP.Garage.Entities = IonRP.Garage.Entities or {}

--[[
    Garage Group Class
    Represents a collection of parking spots with a named location
]]--
--- @class GarageGroup
--- @field id number|nil Database ID
--- @field identifier string Unique identifier (e.g., "downtown_garage")
--- @field name string Display name (e.g., "Downtown Parking Garage")
--- @field anchor Vector Anchor point for distance calculations
--- @field spots GarageSpot[] Array of parking spots
GARAGE_GROUP = {}
GARAGE_GROUP.__index = GARAGE_GROUP

--- Create a new garage group
--- @param identifier string Unique identifier
--- @param name string Display name
--- @param anchor Vector Anchor position
--- @return GarageGroup
function GARAGE_GROUP:New(identifier, name, anchor)
  local group = setmetatable({}, GARAGE_GROUP)
  group.id = nil
  group.identifier = identifier or ("garage_" .. os.time())
  group.name = name or "Unnamed Garage"
  group.anchor = anchor or Vector(0, 0, 0)
  group.spots = {}
  
  return group
end

--- Add a parking spot to the group
--- @param spot GarageSpot The spot to add
function GARAGE_GROUP:AddSpot(spot)
  table.insert(self.spots, spot)
  spot.group = self
end

--- Remove a parking spot from the group
--- @param spot GarageSpot The spot to remove
--- @return boolean success True if removed
function GARAGE_GROUP:RemoveSpot(spot)
  for i, s in ipairs(self.spots) do
    if s == spot then
      table.remove(self.spots, i)
      spot.group = nil
      return true
    end
  end
  return false
end

--- Get the number of parking spots in this group
--- @return number count Number of spots
function GARAGE_GROUP:GetSpotCount()
  return #self.spots
end

--- Get distance from a position to this garage's anchor
--- @param pos Vector Position to check from
--- @return number distance Distance in units
function GARAGE_GROUP:GetDistanceFrom(pos)
  return pos:Distance(self.anchor)
end

--[[
    Garage Spot Class
    Represents a single parking spot on the ground
]]--
--- @class GarageSpot
--- @field id number|nil Database ID
--- @field pos Vector World position
--- @field ang Angle World angles
--- @field group GarageGroup|nil Parent garage group
GARAGE_SPOT = {}
GARAGE_SPOT.__index = GARAGE_SPOT

--- Create a new parking spot
--- @param pos Vector Position
--- @param ang Angle Angles
--- @return GarageSpot
function GARAGE_SPOT:New(pos, ang)
  local spot = setmetatable({}, GARAGE_SPOT)
  spot.id = nil
  spot.pos = pos or Vector(0, 0, 0)
  spot.ang = ang or Angle(0, 0, 0)
  spot.group = nil
  
  return spot
end

--- Check if this spot is occupied by a vehicle
--- @return boolean occupied True if a vehicle is near this spot
function GARAGE_SPOT:IsOccupied()
  if CLIENT then return false end
  
  -- Check for vehicles near this spot (within 100 units)
  local nearbyEnts = ents.FindInSphere(self.pos, 100)
  for _, ent in ipairs(nearbyEnts) do
    if IsValid(ent) and ent:IsVehicle() then
      return true
    end
  end
  
  return false
end

--[[
    Utility Functions
]]--

--- Find the closest garage group to a position
--- @param pos Vector Position to check from
--- @return GarageGroup|nil group The closest garage group
--- @return number|nil distance Distance to the closest garage
function IonRP.Garage:FindClosestGroup(pos)
  local closestGroup = nil
  local closestDist = math.huge
  
  for _, group in pairs(self.Groups) do
    local dist = group:GetDistanceFrom(pos)
    if dist < closestDist then
      closestDist = dist
      closestGroup = group
    end
  end
  
  if closestGroup then
    return closestGroup, closestDist
  end
  
  return nil, nil
end

--- Find the closest available (unoccupied) spot in a garage group
--- @param group GarageGroup The garage group to search
--- @return GarageSpot|nil spot The closest available spot
function IonRP.Garage:FindClosestAvailableSpot(group)
  if not group then return nil end
  
  for _, spot in ipairs(group.spots) do
    if not spot:IsOccupied() then
      return spot
    end
  end
  
  return nil -- All spots occupied
end

--- Get a garage group by ID
--- @param id number Database ID
--- @return GarageGroup|nil group The garage group
function IonRP.Garage:GetGroupByID(id)
  return self.Groups[id]
end

--- Get a garage group by identifier
--- @param identifier string Unique identifier
--- @return GarageGroup|nil group The garage group
function IonRP.Garage:GetGroupByIdentifier(identifier)
  for _, group in pairs(self.Groups) do
    if group.identifier == identifier then
      return group
    end
  end
  return nil
end

print("[IonRP Garage] Shared module loaded")
