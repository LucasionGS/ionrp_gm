--[[
    Rank System
    Server-side rank management and permission checking
]] --

IonRP.Ranks = IonRP.Ranks or {}

-- Network strings
util.AddNetworkString("IonRP_RankUpdated")
util.AddNetworkString("IonRP_SendRankData")

--[[
    Load a player's rank from database
    @param ply Player
    @param callback function(rankId)
]] --
function IonRP.Ranks:LoadPlayerRank(ply, callback)
  local steamID = ply:SteamID64()

  IonRP.Database:PreparedQuery(
    "SELECT rank_id FROM ionrp_player_ranks WHERE steam_id = ? LIMIT 1",
    { steamID },
    function(data)
      local rankId = 0
      if data and #data > 0 then
        rankId = tonumber(data[1].rank_id) or 0
      end

      -- Set the rank on the player
      ply:SetNWInt("IonRP_Rank", rankId)

      local rankData = self:GetRankData(rankId)
      print(string.format("[IonRP] Loaded rank for %s: %s (ID: %d)", ply:Nick(), rankData.name, rankId))

      -- Send rank data to client
      self:SendRankDataToClient(ply)

      if callback then callback(rankId) end
    end,
    function(err)
      print("[IonRP] Error loading rank: " .. err)
      -- Default to User rank
      ply:SetNWInt("IonRP_Rank", 0)
      if callback then callback(0) end
    end
  )
end

--[[
    Set a player's rank
    @param ply Player - Target player
    @param rankId number - New rank ID
    @param admin Player - Admin who changed the rank
    @param reason string - Optional reason
]] --
function IonRP.Ranks:SetPlayerRank(ply, rankId, admin, reason)
  local steamID = ply:SteamID64()
  local adminSteamID = IsValid(admin) and admin:SteamID64() or "CONSOLE"
  local oldRank = ply:GetNWInt("IonRP_Rank", 0)

  -- Validate rank ID
  if not self:GetRankData(rankId) then
    return false, "Invalid rank ID"
  end

  -- Update or insert rank
  IonRP.Database:PreparedQuery(
    [[INSERT INTO ionrp_player_ranks (steam_id, rank_id, granted_by)
          VALUES (?, ?, ?)
          ON DUPLICATE KEY UPDATE rank_id = ?, granted_by = ?, updated_at = CURRENT_TIMESTAMP]],
    { steamID, rankId, adminSteamID, rankId, adminSteamID },
    function(data)
      -- Update player's networked rank
      ply:SetNWInt("IonRP_Rank", rankId)

      local rankData = self:GetRankData(rankId)
      local oldRankData = self:GetRankData(oldRank)

      print(string.format("[IonRP] %s changed %s's rank from %s to %s",
        IsValid(admin) and admin:Nick() or "CONSOLE",
        ply:Nick(),
        oldRankData.name,
        rankData.name))

      -- Log the change
      self:LogRankChange(steamID, oldRank, rankId, adminSteamID, reason)

      -- Notify client
      net.Start("IonRP_RankUpdated")
      net.WriteInt(rankId, 8)
      net.Send(ply)

      -- Send updated rank data
      self:SendRankDataToClient(ply)

      -- Notify all admins
      for _, p in ipairs(player.GetAll()) do
        if p:HasPermission("seeadminchat") then
          p:ChatPrint(string.format("[RANK] %s set %s's rank to %s",
            IsValid(admin) and admin:Nick() or "CONSOLE",
            ply:Nick(),
            rankData.name))
        end
      end
    end,
    function(err)
      print("[IonRP] Error setting rank: " .. err)
    end
  )

  return true
end

--[[
    Log rank change
    @param steamID string
    @param oldRank number
    @param newRank number
    @param changedBy string
    @param reason string
]] --
function IonRP.Ranks:LogRankChange(steamID, oldRank, newRank, changedBy, reason)
  IonRP.Database:PreparedQuery(
    "INSERT INTO ionrp_rank_logs (steam_id, old_rank, new_rank, changed_by, reason) VALUES (?, ?, ?, ?, ?)",
    { steamID, oldRank, newRank, changedBy, reason or "No reason provided" },
    function(data)
      -- Success
    end,
    function(err)
      print("[IonRP] Error logging rank change: " .. err)
    end
  )
end

--[[
    Send rank data to client
    @param ply Player
]] --
function IonRP.Ranks:SendRankDataToClient(ply)
  net.Start("IonRP_SendRankData")
  -- Send all ranks
  net.WriteUInt(#self.List, 8)
  for _, rank in ipairs(self.List) do
    net.WriteUInt(rank.id, 8)
    net.WriteString(rank.name)
    net.WriteColor(rank.color)
    net.WriteUInt(rank.immunity, 8)
  end

  -- Send player's current rank
  net.WriteUInt(ply:GetNWInt("IonRP_Rank", 0), 8)
  net.Send(ply)
end

-- Player meta functions
local ply = FindMetaTable("Player")

--[[
    Get player's rank ID
    @return number
]] --
function ply:GetRank()
  return self:GetNWInt("IonRP_Rank", 0)
end

--[[
    Get player's rank data
    @return table
]] --
function ply:GetRankData()
  return IonRP.Ranks:GetRankData(self:GetRank())
end

--[[
    Get player's rank name
    @return string
]] --
function ply:GetRankName()
  return self:GetRankData().name
end

--[[
    Get player's rank color
    @return Color
]] --
function ply:GetRankColor()
  return self:GetRankData().color
end

--[[
    Check if player has a specific permission
    @param permission string
    @return boolean
]] --
function ply:HasPermission(permission)
  return IonRP.Ranks:HasPermission(self:GetRank(), permission)
end

--[[
    Check if player has higher or equal immunity than target
    @param target Player
    @return boolean
]] --
function ply:HasImmunity(target)
  if not IsValid(target) then return true end

  local myRank = self:GetRankData()
  local targetRank = target:GetRankData()

  return myRank.immunity >= targetRank.immunity
end

--[[
    Check if player is staff (Moderator or above)
    @return boolean
]] --
function ply:IsStaff()
  return self:GetRank() >= 1
end

--[[
    Check if player is admin (Admin or above)
    @return boolean
]] --
function ply:IsRPAdmin()
  return self:GetRank() >= 2
end

--[[
    Check if player is superadmin (Superadmin or above)
    @return boolean
]] --
function ply:IsRPSuperAdmin()
  return self:GetRank() >= 3
end

--[[
    Check if player is developer
    @return boolean
]] --
function ply:IsDeveloper()
  return self:GetRank() >= 5
end

-- Hook into player initialization
hook.Add("PlayerInitialSpawn", "IonRP_LoadRank", function(ply)
  timer.Simple(0.5, function()
    if IsValid(ply) then
      IonRP.Ranks:LoadPlayerRank(ply)
    end
  end)
end)

-- Console command to set ranks
concommand.Add("ionrp_setrank", function(ply, cmd, args)
  -- Check if player has permission (or is console)
  if IsValid(ply) and not ply:HasPermission("manage_ranks") then
    ply:ChatPrint("[IonRP] You don't have permission to manage ranks!")
    return
  end

  if #args < 2 then
    local msg = "[IonRP] Usage: ionrp_setrank <player> <rank>"
    if IsValid(ply) then
      ply:ChatPrint(msg)
    else
      print(msg)
    end
    return
  end

  -- Find target player
  local targetName = args[1]
  local target = nil

  for _, p in ipairs(player.GetAll()) do
    -- Check by name (partial match)
    if string.find(string.lower(p:Nick()), string.lower(targetName), 1, true) then
      target = p
      break
    end
    -- Check by exact UserID
    if tostring(p:UserID()) == targetName then
      target = p
      break
    end
    -- Check by SteamID
    if p:SteamID() == targetName or p:SteamID64() == targetName then
      target = p
      break
    end
  end

  if not IsValid(target) then
    local msg = "[IonRP] Player not found! Available players:"
    if IsValid(ply) then
      ply:ChatPrint(msg)
      for _, p in ipairs(player.GetAll()) do
        ply:ChatPrint("  - " .. p:Nick() .. " (ID: " .. p:UserID() .. ")")
      end
    else
      print(msg)
      for _, p in ipairs(player.GetAll()) do
        print("  - " .. p:Nick() .. " (ID: " .. p:UserID() .. ")")
      end
    end
    return
  end

  -- Find rank
  local rankName = args[2]
  local rank = IonRP.Ranks:GetRankByName(rankName)

  if not rank then
    -- Try by ID
    local rankId = tonumber(rankName)
    if rankId then
      rank = IonRP.Ranks:GetRankData(rankId)
    end
  end

  if not rank then
    local msg = "[IonRP] Invalid rank! Available ranks: User, Moderator, Admin, Superadmin, Lead Admin, Developer"
    if IsValid(ply) then
      ply:ChatPrint(msg)
    else
      print(msg)
    end
    return
  end

  -- Check immunity
  if IsValid(ply) and not ply:HasImmunity(target) then
    ply:ChatPrint("[IonRP] You cannot modify this player's rank!")
    return
  end

  -- Get reason (optional)
  local reason = table.concat(args, " ", 3)

  -- Set the rank
  IonRP.Ranks:SetPlayerRank(target, rank.id, ply, reason)
end)

-- Override default noclip to use permission system
hook.Add("PlayerNoClip", "IonRP_NoClip", function(ply, desiredState)
  return ply:HasPermission("noclip")
end)
