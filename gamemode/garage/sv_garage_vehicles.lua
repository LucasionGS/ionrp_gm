--[[
    Garage Vehicle Integration - Server
    Connects the garage system with vehicle spawning
]]--

util.AddNetworkString("IonRP_Garage_OpenMenu")
util.AddNetworkString("IonRP_Garage_SyncVehicles")
util.AddNetworkString("IonRP_Garage_SpawnVehicle")

--- Spawn a player's owned vehicle at the nearest available garage spot
--- @param ply Player The player spawning the vehicle
--- @param vehicleDbId number The database ID of the owned vehicle
function IonRP.Garage:SpawnPlayerVehicleAtGarage(ply, vehicleDbId)
  if not IsValid(ply) then return end
  
  -- Get the vehicle instance
  ply:SV_GetOwnedVehicleById(vehicleDbId, function(vehicleInstance)
    if not vehicleInstance then
      ply:ChatPrint("[Garage] Vehicle not found.")
      return
    end
    
    -- Check if already spawned
    -- Get all vehicles currently on the map
    --- @type VEHICLE
    for _, existingVehicle in pairs(IonRP.Vehicles.Active) do
      -- if existingVehicle.databaseId == vehicleDbId then
      --   vehicleInstance = existingVehicle
      --   ply:ChatPrint("[Garage] That vehicle is already spawned!")
      --   return
      -- end
      if existingVehicle.owner == ply then
        ply:ChatPrint("[Garage] You already have a vehicle spawned. Please despawn it first.")
        return
      end
    end
    
    -- Find nearest garage
    local closestGroup, distance = self:FindClosestGroup(ply:GetPos())
    if not closestGroup then
      ply:ChatPrint("[Garage] No garages found on this map.")
      return
    end
    
    -- Check distance (optional: limit to reasonable range)
    if distance and distance > 5000 then
      ply:ChatPrint(string.format("[Garage] Nearest garage (%s) is %.0f units away. Get closer to spawn vehicles.", 
        closestGroup.name, distance))
      return
    end
    
    -- Find available spot
    local availableSpot = self:FindClosestAvailableSpot(closestGroup)
    if not availableSpot then
      ply:ChatPrint(string.format("[Garage] No available parking spots at %s. Try another garage.", 
        closestGroup.name))
      return
    end
    
    -- Spawn the vehicle
    local spawnedVehicle = vehicleInstance:SV_Spawn(availableSpot.pos, Angle(
      availableSpot.ang.p, availableSpot.ang.y + 90, availableSpot.ang.r
    ))

    if not spawnedVehicle or not IsValid(spawnedVehicle) then
      ply:ChatPrint("[Garage] Failed to spawn vehicle.")
      return
    end
    
    -- Success message
    ply:ChatPrint(string.format("[Garage] Spawned %s at %s", vehicleInstance.name, closestGroup.name))
    
    print(string.format("[IonRP Garage] %s spawned their %s (ID: %d) at %s", 
      ply:Nick(), vehicleInstance.name, vehicleDbId, closestGroup.name))
  end)
end

--- Send player's owned vehicles to client for garage menu
--- @param ply Player The player to send data to
function IonRP.Garage:SendOwnedVehiclesToClient(ply)
  if not IsValid(ply) then return end
  
  ply:SV_GetOwnedVehicles(function(vehicles)
    local vehicleData = {}
    
    for _, vehInstance in ipairs(vehicles) do
      table.insert(vehicleData, {
        dbId = vehInstance.databaseId,
        identifier = vehInstance.identifier,
        name = vehInstance.name,
        description = vehInstance.description,
        model = vehInstance.model,
        marketValue = vehInstance.marketValue,
        category = vehInstance.category,
        isSpawned = vehInstance.entity and IsValid(vehInstance.entity),
      })
    end
    
    net.Start("IonRP_Garage_SyncVehicles")
    net.WriteTable(vehicleData)
    net.Send(ply)
  end)
end

--- Handle client request to open garage menu
net.Receive("IonRP_Garage_OpenMenu", function(len, ply)
  IonRP.Garage:SendOwnedVehiclesToClient(ply)
end)

--- Handle client request to spawn vehicle
net.Receive("IonRP_Garage_SpawnVehicle", function(len, ply)
  local vehicleDbId = net.ReadUInt(32)
  IonRP.Garage:SpawnPlayerVehicleAtGarage(ply, vehicleDbId)
end)

--- Command to open garage menu
IonRP.Commands.Add("garage", function(ply)
  -- Send vehicle data first, then tell client to open menu
  IonRP.Garage:SendOwnedVehiclesToClient(ply)
  
  timer.Simple(0.1, function()
    if IsValid(ply) then
      net.Start("IonRP_Garage_OpenMenu")
      net.Send(ply)
    end
  end)
end, "Open your vehicle garage", "developer")

IonRP.Commands.Add("despawncar", function(ply)
  -- Despawn all vehicles owned by this player
  local despawnedCount = 0
  for entIndex, vehInstance in pairs(IonRP.Vehicles.Active) do
    if vehInstance.owner == ply then
      if vehInstance.entity and IsValid(vehInstance.entity) then
        vehInstance.entity:Remove()
      end
      IonRP.Vehicles.Active[entIndex] = nil
      despawnedCount = despawnedCount + 1
    end
  end
  
  if despawnedCount > 0 then
    ply:ChatPrint(string.format("[Garage] Despawned %d vehicle(s).", despawnedCount))
    print(string.format("[IonRP Garage] %s despawned %d vehicle(s).", ply:Nick(), despawnedCount))
  else
    ply:ChatPrint("[Garage] You have no vehicles to despawn.")
  end
end, "Open your vehicle garage", "developer")

print("[IonRP Garage] Vehicle integration loaded (server)")
