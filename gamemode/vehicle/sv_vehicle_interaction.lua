--[[
    Vehicle Interaction System - Server
    Handles server-side validation and execution of vehicle interactions
]] --

util.AddNetworkString("IonRP_Vehicle_OpenGate")

--- Handle remote gate opening requests from vehicles
net.Receive("IonRP_Vehicle_OpenGate", function(len, ply)
  local door = net.ReadEntity()

  -- Validation
  if not IsValid(ply) then return end
  if not IsValid(door) then return end

  -- Verify player is in a vehicle
  local vehicle = ply:GetVehicle()
  if not IsValid(vehicle) then
    -- ply:ChatPrint("[Vehicle] You must be in a vehicle to remotely open gates")
    return
  end

  -- Verify door is within range
  local SEARCH_RADIUS = 500
  local distance = vehicle:GetPos():Distance(door:GetPos())
  if distance > SEARCH_RADIUS then
    -- ply:ChatPrint("[Vehicle] Gate is too far away")
    return
  end

  -- Get property data
  local propertyId = door:GetNWInt("PropertyID", 0)
  if propertyId == 0 then
    -- ply:ChatPrint("[Vehicle] This door is not part of a property")
    return
  end

  local property = IonRP.Properties.List[propertyId]
  if not property then
    -- ply:ChatPrint("[Vehicle] Property not found")
    return
  end

  -- Find the door in property's door list
  local propertyDoor = nil
  for _, propDoor in ipairs(property.doors) do
    if propDoor.entity == door then
      propertyDoor = propDoor
      break
    end
  end

  if not propertyDoor then
    -- ply:ChatPrint("[Vehicle] Door not found in property")
    return
  end

  -- Verify it's a gate
  if not propertyDoor.isGate then
    -- ply:ChatPrint("[Vehicle] This door is not a gate")
    return
  end

  -- Check access permissions
  local hasAccess = not propertyDoor.isLocked or
      (property.owner and IsValid(property.owner) and property.owner == ply)

  if not hasAccess then
    -- ply:ChatPrint("[Vehicle] You don't have access to this gate")
    return
  end

  -- Open the gate
  local wasLocked = propertyDoor.isLocked

  if wasLocked then
    door:Fire("Unlock")
  end

  door:Fire("Open")

  -- Auto-close and re-lock after 5 seconds
  timer.Simple(5, function()
    if IsValid(door) then
      door:Fire("Close")

      if wasLocked then
        timer.Simple(1, function()
          if IsValid(door) then
            door:Fire("Lock")
          end
        end)
      end
    end
  end)

  -- Log action
  -- print(string.format("[IonRP Vehicle] %s remotely opened gate at property '%s' (ID: %d)",
  --   ply:Nick(), property.name, property.id))

  -- ply:ChatPrint(string.format("[Vehicle] Opened gate at %s", property.name))
end)

print("[IonRP Vehicle] Server interaction system loaded")
