--[[
    ATM System - Shared
    Manages ATM placement and interaction zones
    
    Features:
    - Invisible, solid interaction boxes that players can press E on
    - Opens the bank interface when used
    - Persistent database storage (per-map)
    - Visual indicators for developers (wireframe boxes)
    - Easy placement with commands
    
    Commands (requires "developer" permission):
    - /placeatm - Place ATM at crosshair position
    - /removeatm - Remove ATM you're looking at
    - /listatms - List all ATMs on current map
    
    ATMs are automatically loaded when the map starts.
]]--

IonRP.ATM = IonRP.ATM or {}

--- All spawned ATM entities on the map
--- @type table<number, Entity>
IonRP.ATM.Entities = IonRP.ATM.Entities or {}

--- ATM entity class name
IonRP.ATM.EntityClass = "ionrp_atm"

--- ATM collision bounds (size of interaction box)
IonRP.ATM.BoundsMin = Vector(-20, -20, 0)
IonRP.ATM.BoundsMax = Vector(20, 20, 60)

--- @class ATMData
--- @field id number Database ID
--- @field map string Map name
--- @field pos Vector Position
--- @field ang Angle Angles
--- @field created_at string|nil Creation timestamp

print("[IonRP ATM] Shared module loaded")
