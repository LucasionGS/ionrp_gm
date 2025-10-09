--- Defines functions related to vehicle entity
--- @param veh Vehicle The vehicle entity to define
--- @return boolean, string|nil
function IonRP.Vehicles:SV_DefineVehicleEntity(veh)
  if not veh.VehicleInstance then return false, "Not a valid IonRP vehicle entity" end
  local vehInstance = veh.VehicleInstance

  -- When the vehicle is removed, clean up the active list
  local callOnRemoveIdentifier = veh:EntIndex() .. "_" .. vehInstance.identifier .. "_OnRemove"
  veh:CallOnRemove(callOnRemoveIdentifier, function()
    if vehInstance and vehInstance.entity and vehInstance.entity == self then
      IonRP.Vehicles.Active[self:EntIndex()] = nil
      vehInstance.entity = nil
    end

    veh:RemoveCallOnRemove(callOnRemoveIdentifier)
  end)

  return true, nil
end
