--[[
    Admin Commands for Genetics System
]]--

--- Give genetic points to a player
IonRP.Commands.Add("givegenetics", function(activator, args, rawArgs)
  local targetName = args[1]
  local amount = tonumber(args[2]) or 1
  
  if not targetName then
    activator:ChatPrint("[IonSys] Usage: /givegenetics <player> <amount>")
    return
  end
  
  local target = IonRP.Util:FindPlayerByName(targetName)
  
  if not IsValid(target) then
    activator:ChatPrint("[IonSys] Player not found")
    return
  end
  
  if not IonRP.Genetics then
    activator:ChatPrint("[IonSys] Genetics system not loaded")
    return
  end
  
  IonRP.Genetics:AddPoints(target, amount)
  
  activator:ChatPrint(string.format("[IonSys] Gave %d genetic point(s) to %s", amount, target:Nick()))
  
end, "Give genetic points to a player", "genetics.give")

print("[IonRP Genetics] Admin commands loaded")
