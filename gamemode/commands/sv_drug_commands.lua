--- Admin commands for drug system

--- Spawn a drug entity
IonRP.Commands.Add("spawndrug", function(activator, args, rawArgs)
  if not args[1] then
    activator:ChatPrint("[IonRP] Usage: /spawndrug <drug_id>")
    activator:ChatPrint("[IonRP] Available drugs:")
    for drugID, drug in pairs(IonRP.Drug.List) do
      activator:ChatPrint("  - " .. drugID .. " (" .. drug.name .. ")")
    end
    return
  end
  
  local drugID = args[1]
  local drug = IonRP.Drug.List[drugID]
  
  if not drug then
    activator:ChatPrint("[IonRP] Unknown drug: " .. drugID)
    return
  end
  
  -- Spawn in front of player
  local trace = util.TraceLine({
    start = activator:EyePos(),
    endpos = activator:EyePos() + activator:GetAimVector() * 100,
    filter = activator
  })
  
  local spawnPos = trace.HitPos + trace.HitNormal * 10
  local spawnAng = activator:EyeAngles()
  spawnAng.pitch = 0
  spawnAng.roll = 0
  
  local ent = IonRP.Drug:Spawn(drugID, spawnPos, spawnAng, true)
  
  if IsValid(ent) then
    activator:ChatPrint("[IonRP] Spawned " .. drug.name)
  else
    activator:ChatPrint("[IonRP] Failed to spawn drug entity")
  end
end, "Spawn a drug entity for testing", "admin.spawndrug")

print("[IonRP Commands] Drug commands loaded")
