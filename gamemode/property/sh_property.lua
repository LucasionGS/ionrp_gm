IonRP.Properties = IonRP.Properties or {}
--- @type Property[]
IonRP.Properties.List = IonRP.Properties.List or {}

--[[
  Property Door setup
]]--
--- @class PropertyDoor
PROPERTY_DOOR = {}

--- Database ID of the property door (nil if not saved yet)
--- @type number|nil
PROPERTY_DOOR.id = nil

--- @type PropertyDoor
PROPERTY_DOOR.__index = PROPERTY_DOOR

--- @type Property
PROPERTY_DOOR.property = nil

--- World position of the door.
--- This is used to find the door entity.
--- @type Vector
PROPERTY_DOOR.pos = Vector(0, 0, 0)

--- Whether the door will start locked
--- @type boolean
PROPERTY_DOOR.isLocked = false

--- Whether the door is a gate. Gates can be opened from within a car.
--- @type boolean
PROPERTY_DOOR.isGate = false

--- The group the door belongs to for multi-door properties.
--- Grouped doors in the same property will always have the same lock state.
--- @type string|nil
PROPERTY_DOOR.group = nil

--- The actual door entity (nil if not found yet)
--- @type Entity|nil
PROPERTY_DOOR.entity = nil

--- Create a new property door instance
--- @param doorData table The door data (pos, isLocked, isGate, group)
--- @return PropertyDoor # The new property door object
function PROPERTY_DOOR:New(doorData)
    local newDoor = setmetatable({}, PROPERTY_DOOR)
    newDoor.property = property
    newDoor.pos = doorData.pos or Vector(0, 0, 0)
    newDoor.isLocked = doorData.isLocked or false
    newDoor.isGate = doorData.isGate or false
    newDoor.group = doorData.group or nil
    return newDoor
end

--[[
  Property setup
]]--
--- Property is a collection of doors that can be owned by players.
--- @class Property
PROPERTY = {}

--- @type Property
PROPERTY.__index = PROPERTY

--- Database ID of the property (nil if not saved yet)
--- @type number|nil
PROPERTY.id = nil

--- Name of the property
--- @type string
PROPERTY.name = "<Unnamed Property>"

--- The description of the property
--- @type string
PROPERTY.description = "<No description>"

--- The category of the property
--- @type string
PROPERTY.category = "Other"

--- Whether this property is purchasable
--- @type boolean
PROPERTY.purchasable = true

--- The price to purchase the property
--- @type number
PROPERTY.price = 0

--- List of doors (PROPERTY_DOOR) that belong to this property
--- @type table<number, PropertyDoor>
PROPERTY.doors = {}

--- Owner of the property (Player) or nil if unowned
--- @type Player|nil
PROPERTY.owner = nil

--- Create a new property instance
--- @param propertyData table The property data (id, name, description, price)
--- @param doors table<number, PropertyDoor>|table<number, any> List of doors (PROPERTY_DOOR) that belong to this property
--- @return Property # The new property object
function PROPERTY:New(propertyData, doors)
    local newProperty = setmetatable({}, PROPERTY)
    newProperty.id = propertyData.id
    newProperty.name = propertyData.name
    newProperty.description = propertyData.description
    newProperty.category = propertyData.category or "Other"
    newProperty.purchasable = propertyData.purchasable
    newProperty.price = propertyData.price
    newProperty.doors = {} -- Initialize a fresh doors table for this instance
    newProperty.owner = propertyData.owner or nil -- Initialize owner as nil for this instance if none if provided
    for _, doorData in ipairs(doors) do
      if doorData.__index ~= PROPERTY_DOOR then
        doorData = PROPERTY_DOOR:New(doorData)
      end
      table.insert(newProperty.doors, doorData)
      doorData.property = newProperty
    end
    return newProperty
end

if SERVER then
  include("sv_property.lua")
end