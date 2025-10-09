--[[
    Vehicle Shop - Server Side
    Handles vehicle purchases and shop interactions
]]--

IonRP.VehicleShop = IonRP.VehicleShop or {}

-- Network strings
util.AddNetworkString("IonRP_VehicleShop_Open")
util.AddNetworkString("IonRP_VehicleShop_Purchase")
util.AddNetworkString("IonRP_VehicleShop_AdminSpawn")

--- Open the vehicle shop for a player
--- @param ply Player The player to open the shop for
function IonRP.VehicleShop:OpenForPlayer(ply)
  if not IsValid(ply) then return end

  net.Start("IonRP_VehicleShop_Open")
  net.Send(ply)
end

-- Handle vehicle purchase
net.Receive("IonRP_VehicleShop_Purchase", function(len, ply)
  if not IsValid(ply) then return end

  local vehicleIdentifier = net.ReadString()

  IonRP.Vehicles:SV_PurchaseVehicle(ply, vehicleIdentifier, function(success, message, vehicleInstance)
    if success then
      ply:ChatPrint(string.format("[IonRP] %s", message))
      ply:ChatPrint("[IonRP] Vehicle added to your garage! Use /mygarage to view it.")
      
      -- Log the purchase
      print(string.format("[IonRP Vehicle Shop] %s purchased %s (ID: %d)", 
        ply:Nick(), vehicleInstance.name, vehicleInstance.databaseId))
    else
      ply:ChatPrint(string.format("[IonRP] Purchase failed: %s", message))
    end
  end)
end)

-- Handle admin spawn
net.Receive("IonRP_VehicleShop_AdminSpawn", function(len, ply)
  if not IsValid(ply) or not ply:IsSuperAdmin() then 
    ply:ChatPrint("[IonRP] You don't have permission to spawn vehicles!")
    return 
  end

  local vehicleIdentifier = net.ReadString()
  local vehicleBase = IonRP.Vehicles.List[vehicleIdentifier]

  if not vehicleBase then
    ply:ChatPrint("[IonRP] Invalid vehicle identifier!")
    return
  end

  local trace = ply:GetEyeTrace()
  local spawnPos = trace.HitPos + Vector(0, 0, 10)
  local spawnAng = Angle(0, ply:EyeAngles().y - 90, 0)

  local vehInstance = vehicleBase:MakeOwnedInstance(ply)
  local vehEnt = vehInstance:SV_Spawn(spawnPos, spawnAng)

  if not vehEnt or not IsValid(vehEnt) then
    ply:ChatPrint("[IonRP] Failed to spawn vehicle.")
    return
  end

  ply:ChatPrint(string.format("[IonRP] Spawned %s (Admin)", vehicleBase.name))
  print(string.format("[IonRP Vehicle Shop] %s spawned %s (Admin)", ply:Nick(), vehicleBase.name))
end)

-- Chat command to open shop
IonRP.Commands.Add("vehicleshop", function(activator, args, rawArgs)
  IonRP.VehicleShop:OpenForPlayer(activator)
end, "Open the vehicle shop")

IonRP.Commands.Add("dealership", function(activator, args, rawArgs)
  IonRP.VehicleShop:OpenForPlayer(activator)
end, "Open the vehicle dealership")

IonRP.Commands.Add("buyvehicle", function(activator, args, rawArgs)
  IonRP.VehicleShop:OpenForPlayer(activator)
end, "Open the vehicle shop")

print("[IonRP Vehicle Shop] Server-side loaded")
