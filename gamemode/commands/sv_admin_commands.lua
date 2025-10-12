--[[
    IonRP admin Commands
    Helper functions for administration commands
]] --

if SERVER then
  -- /goto command
  IonRP.Commands.Add("goto", function(activator, args, rawArgs)
    -- Check arguments
    if #args < 1 then
      activator:ChatPrint("[IonRP] Usage: /goto <player>")
      return
    end

    local targetIdentifier = args[1]
    local target = IonRP.Util:FindPlayer(targetIdentifier)

    if not target or not IsValid(target) then
      activator:ChatPrint("[IonRP] Player not found")
      return
    end

    activator:SetPos(target:GetPos())
    activator:ChatPrint("[IonRP] Teleported to " .. target:Nick())

  end, "Teleport to a player", "goto")

  print("[IonRP] Admin commands loaded")

  -- /bring command
  IonRP.Commands.Add("bring", function(activator, args, rawArgs)
    -- Check arguments
    if #args < 1 then
      activator:ChatPrint("[IonRP] Usage: /bring <player>")
      return
    end

    local targetIdentifier = args[1]
    local target = IonRP.Util:FindPlayer(targetIdentifier)

    if not target or not IsValid(target) then
      activator:ChatPrint("[IonRP] Player not found")
      return
    end

    target:SetPos(activator:GetPos())
    target:ChatPrint("[IonRP] You have been brought to " .. activator:Nick())
  end, "Bring a player to your location", "bring")
  
end
