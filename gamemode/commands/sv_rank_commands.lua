--[[
    IonRP Rank Commands
    Command implementations for rank management
]] --

if SERVER then
  -- /setrank command
  IonRP.Commands.Add("setrank", function(activator, args, rawArgs)
    -- Check arguments
    if #args < 2 then
      activator:ChatPrint("[IonRP] Usage: /setrank <player> <rank>")
      activator:ChatPrint("[IonRP] Available ranks: User, Moderator, Admin, Superadmin, Lead Admin, Developer")
      return
    end

    local targetIdentifier = args[1]
    local rankName = table.concat(args, " ", 2) -- Join remaining args for rank name

    -- Find target player
    local target = IonRP.Ranks.FindPlayer(targetIdentifier)

    if not target then
      activator:ChatPrint("[IonRP] Player not found: " .. targetIdentifier)
      return
    end

    -- Set the rank
    IonRP.Ranks.SetPlayerRank(target, rankName, activator)
  end, "Set a player's rank", "setrank")

  -- /ranks command - List all ranks
  IonRP.Commands.Add("ranks", function(activator, args, rawArgs)
    activator:ChatPrint("========== IonRP Ranks ==========")

    for id, rankData in pairs(IonRP.Ranks.List) do
      local color = rankData.color
      activator:ChatPrint(string.format("  [%d] %s", id, rankData.name))
    end

    activator:ChatPrint("=================================")
  end, "List all available ranks")

  print("[IonRP] Rank commands loaded")
end
