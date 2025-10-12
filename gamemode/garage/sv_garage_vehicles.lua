--[[
    Garage Vehicle Integration - Server
    Connects the garage system with vehicle spawning
]]--

util.AddNetworkString("IonRP_Garage_OpenMenu")
util.AddNetworkString("IonRP_Garage_SyncVehicles")
util.AddNetworkString("IonRP_Garage_SpawnVehicle")
util.AddNetworkString("IonRP_Garage_DespawnVehicle")
util.AddNetworkString("IonRP_Garage_SyncNearbyVehicles")

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
  IonRP.Garage:SendNearbyVehiclesToClient(ply)
end)

--- Handle client request to spawn vehicle
net.Receive("IonRP_Garage_SpawnVehicle", function(len, ply)
  local vehicleDbId = net.ReadUInt(32)
  IonRP.Garage:SpawnPlayerVehicleAtGarage(ply, vehicleDbId)
end)

--- Handle client request to despawn vehicle
net.Receive("IonRP_Garage_DespawnVehicle", function(len, ply)
  if not IsValid(ply) then return end
  
  local vehicleEntIndex = net.ReadUInt(16)
  local vehicle = Entity(vehicleEntIndex)
  
  if not IsValid(vehicle) then
    ply:ChatPrint("[Garage] Vehicle not found.")
    return
  end
  
  -- Find the vehicle instance
  local vehicleInstance = nil
  for _, vehInstance in pairs(IonRP.Vehicles.Active) do
    if vehInstance.entity == vehicle then
      vehicleInstance = vehInstance
      break
    end
  end
  
  if not vehicleInstance then
    ply:ChatPrint("[Garage] Vehicle data not found.")
    return
  end
  
  -- Check ownership
  if vehicleInstance.owner ~= ply then
    ply:ChatPrint("[Garage] You don't own this vehicle!")
    return
  end
  
  -- Despawn the vehicle
  local vehicleName = vehicleInstance.name
  IonRP.Vehicles.Active[vehicleInstance.entity:EntIndex()] = nil
  vehicleInstance.entity:Remove()
  
  ply:ChatPrint("[Garage] " .. vehicleName .. " has been returned to your garage.")
  
  print(string.format("[IonRP Garage] %s despawned their %s", ply:Nick(), vehicleName))
  
  -- Refresh the garage menu
  timer.Simple(0.1, function()
    if IsValid(ply) then
      IonRP.Garage:SendOwnedVehiclesToClient(ply)
      IonRP.Garage:SendNearbyVehiclesToClient(ply)
    end
  end)
end)

--- Send nearby owned vehicles to client
--- @param ply Player The player to send data to
function IonRP.Garage:SendNearbyVehiclesToClient(ply)
  if not IsValid(ply) then return end
  
  local nearbyVehicles = {}
  local playerPos = ply:GetPos()
  local maxDistance = 1000
  
  -- Find all vehicles owned by player within range
  for _, vehInstance in pairs(IonRP.Vehicles.Active) do
    if vehInstance.owner == ply and IsValid(vehInstance.entity) then
      local distance = playerPos:Distance(vehInstance.entity:GetPos())
      if distance <= maxDistance then
        table.insert(nearbyVehicles, {
          entIndex = vehInstance.entity:EntIndex(),
          identifier = vehInstance.identifier,
          name = vehInstance.name,
          model = vehInstance.model,
          distance = math.floor(distance),
        })
      end
    end
  end

  PrintTable(nearbyVehicles)

  net.Start("IonRP_Garage_SyncNearbyVehicles")
    net.WriteTable(nearbyVehicles)
  net.Send(ply)
end

--- Command to open garage menu
IonRP.Commands.Add("garage", function(ply)
  -- Send vehicle data first, then tell client to open menu
  IonRP.Garage:SendOwnedVehiclesToClient(ply)
  IonRP.Garage:SendNearbyVehiclesToClient(ply)
  
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
