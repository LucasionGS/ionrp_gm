--[[
    Vehicle Interaction System - Client
    Handles in-vehicle interactions like remote gate opening
]] --

--- Remote gate opening
--- When player presses G in a vehicle, opens nearby gates if they have access
hook.Add("PlayerButtonDown", "IonRP_Vehicle_RemoteGateOpen", function(ply, key)
  if key ~= KEY_G then return end

  -- Check if player is in a vehicle
  local vehicle = ply:GetVehicle()
  if not IsValid(vehicle) then return end

  -- Configuration
  local SEARCH_RADIUS = 500 -- Units to search for gates

  -- Get vehicle position
  local vehPos = vehicle:GetPos()

  -- Find all entities in radius
  local nearbyEnts = ents.FindInSphere(vehPos, SEARCH_RADIUS)

  -- Filter to only door entities and sort by distance
  local doors = {}
  for _, ent in ipairs(nearbyEnts) do
    if IsValid(ent) and (ent:GetClass() == "prop_door_rotating" or
          ent:GetClass() == "func_door" or
          ent:GetClass() == "func_door_rotating") then
      table.insert(doors, ent)
    end
  end

  -- Sort by distance from vehicle
  table.sort(doors, function(a, b)
    return a:GetPos():DistToSqr(vehPos) < b:GetPos():DistToSqr(vehPos)
  end)

  -- Find first accessible gate
  for _, door in ipairs(doors) do
    local propertyId = door:GetNWInt("PropertyID", 0)

    -- Skip if not a property door
    if propertyId == 0 then continue end

    -- Get property data
    local property = IonRP.Properties.List[propertyId]
    if not property then continue end

    -- Find the door in property's door list
    --- @type PropertyDoor|nil
    local propertyDoor = nil
    for _, propDoor in ipairs(property.doors) do
      if propDoor.pos:Distance(door:GetPos()) < 50 then
        propertyDoor = propDoor
        break
      end
    end

    -- Skip if not a gate
    if not propertyDoor or not propertyDoor.isGate then continue end

    -- Check access: door must be unlocked OR player must own the property
    local hasAccess = not propertyDoor.isLocked or
        (property.owner and IsValid(property.owner) and property.owner == ply)

    --- @type PropertyDoor[]
    local allTargetedDoors = {}
    if propertyDoor.group ~= nil then
      for _, groupedDoor in ipairs(property.doors) do
        if groupedDoor.group == propertyDoor.group then
          table.insert(allTargetedDoors, groupedDoor)
        end
      end
    end

    if hasAccess then
      for _, door in ipairs(allTargetedDoors) do
        local ent = door.entity
        if not ent or not IsValid(ent) then continue end
        -- Send request to server to open gate
        net.Start("IonRP_Vehicle_OpenGate")
        net.WriteEntity(ent)
        net.SendToServer()

        -- Visual feedback
        -- chat.AddText(Color(100, 200, 255), "[Vehicle] ", Color(255, 255, 255),
        --   "Opening gate at " .. property.name)

        -- Only open the closest accessible gate
      end
      break
    end
  end
end)

print("[IonRP Vehicle] Client interaction system loaded")
