--[[
    IonRP Model Explorer - Server
    Handles model spawning for developers
]] --

-- Network strings
util.AddNetworkString("IonRP_SpawnModel")
util.AddNetworkString("IonRP_GiveWeapon")

-- Handle model spawn requests
net.Receive("IonRP_SpawnModel", function(len, ply)
  -- Check if player is developer
  if not (ply.GetRankName and ply:GetRankName() == "Developer") then
    ply:ChatPrint("[IonRP] Only Developers can spawn models")
    return
  end

  -- Get model data
  local modelPath = net.ReadString()
  local spawnPos = net.ReadVector()
  local spawnAng = net.ReadAngle()

  -- Validate model path
  if not modelPath or modelPath == "" then
    ply:ChatPrint("[IonRP] Invalid model path")
    return
  end

  -- Create the prop
  local prop = ents.Create("prop_physics")

  if not IsValid(prop) then
    ply:ChatPrint("[IonRP] Failed to create prop")
    return
  end

  prop:SetModel(modelPath)
  prop:SetPos(spawnPos)
  prop:SetAngles(spawnAng)
  prop:Spawn()
  prop:Activate()

  -- Set the owner
  prop:SetNWEntity("Owner", ply)

  -- Make it moveable with physgun
  local phys = prop:GetPhysicsObject()
  if IsValid(phys) then
    phys:Wake()
  end

  -- Log the spawn
  print(string.format("[IonRP] %s spawned model: %s", ply:Nick(), modelPath))
end)

-- Handle weapon give requests
net.Receive("IonRP_GiveWeapon", function(len, ply)
  -- Check if player is developer
  if not (ply.GetRankName and ply:GetRankName() == "Developer") then
    ply:ChatPrint("[IonRP] Only Developers can give weapons")
    return
  end

  -- Get weapon class
  local weaponClass = net.ReadString()

  -- Validate weapon class
  if not weaponClass or weaponClass == "" then
    ply:ChatPrint("[IonRP] Invalid weapon class")
    return
  end

  -- Check if weapon exists
  if not weapons.Get(weaponClass) then
    ply:ChatPrint("[IonRP] Weapon class not found: " .. weaponClass)
    return
  end

  -- Give weapon to player
  ply:Give(weaponClass, true)
  ply:SelectWeapon(weaponClass)

  -- Log the action
  print(string.format("[IonRP] %s gave themselves weapon: %s", ply:Nick(), weaponClass))
  ply:ChatPrint("[IonRP] Given weapon: " .. weaponClass)
end)

-- Register /models command
IonRP.Commands.Add("models", function(activator, args, rawArgs)

  -- Send net message to open the model explorer
  net.Start("IonRP_OpenModelExplorer")
  net.Send(activator)
end, "Open the Model Explorer", "developer")

-- Network string to open model explorer
util.AddNetworkString("IonRP_OpenModelExplorer")

print("[IonRP] Model Explorer (Server) loaded")
