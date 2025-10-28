--[[
    IonRP VIP Commands
    Command implementations for VIP management
]]--

if SERVER then
  -- Helper function to parse duration strings (e.g., "30d", "1m", "2w")
  local function ParseDuration(durationStr)
    if not durationStr or durationStr == "" then
      return nil -- Permanent
    end
    
    local num = tonumber(durationStr:match("^(%d+)"))
    local unit = durationStr:match("(%a+)$")
    
    if not num or not unit then
      return nil, "Invalid duration format. Use format like: 30d, 1m, 2w"
    end
    
    local seconds = 0
    unit = string.lower(unit)
    
    if unit == "d" or unit == "day" or unit == "days" then
      seconds = num * 86400
    elseif unit == "w" or unit == "week" or unit == "weeks" then
      seconds = num * 604800
    elseif unit == "m" or unit == "month" or unit == "months" then
      seconds = num * 2592000 -- 30 days
    elseif unit == "y" or unit == "year" or unit == "years" then
      seconds = num * 31536000
    elseif unit == "h" or unit == "hour" or unit == "hours" then
      seconds = num * 3600
    else
      return nil, "Invalid time unit. Use: d (days), w (weeks), m (months), y (years), h (hours)"
    end
    
    local expiresAt = os.date("!%Y-%m-%d %H:%M:%S", os.time() + seconds)
    return expiresAt
  end

  -- /setvip command
  IonRP.Commands.Add("setvip", function(activator, args, rawArgs)
    -- Check arguments
    if #args < 2 then
      activator:ChatPrint("[IonRP VIP] Usage: /setvip <player> <vip_rank> [duration]")
      activator:ChatPrint("[IonRP VIP] Available VIP ranks: Silver, Gold, Diamond, Prism")
      activator:ChatPrint("[IonRP VIP] Duration examples: 30d (30 days), 1m (1 month), 2w (2 weeks)")
      activator:ChatPrint("[IonRP VIP] Leave duration empty for permanent VIP")
      return
    end

    local targetIdentifier = args[1]
    local vipRankName = args[2]
    local duration = args[3]

    -- Find target player
    local target = IonRP.Util:FindPlayer(targetIdentifier, true)

    if not target then
      activator:ChatPrint("[IonRP VIP] Player not found: " .. targetIdentifier)
      return
    end

    -- Validate VIP rank
    local vipRank = IonRP.VIP:GetVIPRankByName(vipRankName)
    
    if not vipRank then
      -- Try by ID
      local vipRankId = tonumber(vipRankName)
      if vipRankId then
        vipRank = IonRP.VIP:GetVIPRankData(vipRankId)
      end
    end

    if not vipRank then
      activator:ChatPrint("[IonRP VIP] Invalid VIP rank! Available ranks: Silver, Gold, Diamond, Prism")
      return
    end

    -- Check if trying to give Prism VIP
    if vipRank.id == VIP_RANK_PRISM and not vipRank.purchasable then
      -- Only allow if user has manage_vip permission
      if not activator:HasPermission("manage_vip") then
        activator:ChatPrint("[IonRP VIP] Prism VIP can only be granted by Lead Admin or higher!")
        return
      end
    end

    -- Parse duration
    local expiresAt = nil
    if duration then
      local err
      expiresAt, err = ParseDuration(duration)
      if not expiresAt then
        activator:ChatPrint("[IonRP VIP] " .. err)
        return
      end
    end

    -- Set the VIP
    local success, err = IonRP.VIP:SetPlayerVIP(target, vipRank.id, activator, expiresAt, "Granted via command")
    
    if success then
      activator:ChatPrint(string.format("[IonRP VIP] Set %s's VIP to %s%s",
        target:Nick(),
        vipRank.name,
        expiresAt and (" until " .. expiresAt) or " (permanent)"
      ))
    else
      activator:ChatPrint("[IonRP VIP] Error: " .. (err or "Unknown error"))
    end
  end, "Set a player's VIP rank", "manage_vip")

  -- /removevip command
  IonRP.Commands.Add("removevip", function(activator, args, rawArgs)
    -- Check arguments
    if #args < 1 then
      activator:ChatPrint("[IonRP VIP] Usage: /removevip <player>")
      return
    end

    local targetIdentifier = args[1]

    -- Find target player
    local target = IonRP.Util:FindPlayer(targetIdentifier, true)

    if not target then
      activator:ChatPrint("[IonRP VIP] Player not found: " .. targetIdentifier)
      return
    end

    -- Remove the VIP
    local success, err = IonRP.VIP:RemovePlayerVIP(target, activator, "Removed via command")
    
    if success then
      activator:ChatPrint(string.format("[IonRP VIP] Removed VIP from %s", target:Nick()))
    else
      activator:ChatPrint("[IonRP VIP] Error: " .. (err or "Unknown error"))
    end
  end, "Remove a player's VIP rank", "manage_vip")

  -- /vipranks command - List all VIP ranks
  IonRP.Commands.Add("vipranks", function(activator, args, rawArgs)
    activator:ChatPrint("========== IonRP VIP Ranks ==========")

    for _, vipData in ipairs(IonRP.VIP.Ranks) do
      activator:ChatPrint(string.format("  [%d] %s - %s%s",
        vipData.id,
        vipData.name,
        vipData.description,
        not vipData.purchasable and " (Not purchasable)" or ""
      ))
    end

    activator:ChatPrint("=====================================")
  end, "List all available VIP ranks")

  -- /checkvip command - Check a player's VIP status
  IonRP.Commands.Add("checkvip", function(activator, args, rawArgs)
    local target = activator
    
    -- Check if a target was specified
    if #args >= 1 then
      local targetIdentifier = args[1]
      target = IonRP.Util:FindPlayer(targetIdentifier, true)
      
      if not target then
        activator:ChatPrint("[IonRP VIP] Player not found: " .. targetIdentifier)
        return
      end
    end

    local vipRank = target:GetVIPRank()
    
    if vipRank == 0 then
      activator:ChatPrint(string.format("[IonRP VIP] %s does not have VIP", target:Nick()))
    else
      local vipData = target:GetVIPRankData()
      local expiresAt = target:GetVIPExpiration()
      
      activator:ChatPrint(string.format("[IonRP VIP] %s has %s VIP%s",
        target:Nick(),
        vipData.name,
        expiresAt and (" (expires " .. expiresAt .. ")") or " (permanent)"
      ))
    end
  end, "Check a player's VIP status")

  print("[IonRP VIP] VIP commands loaded")
end
