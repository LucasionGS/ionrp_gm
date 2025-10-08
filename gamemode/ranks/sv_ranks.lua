--[[
    Rank System
    Server-side rank management and permission checking
]] --

-- Load shared types
include("sh_ranks_types.lua")
AddCSLuaFile("sh_ranks_types.lua")

IonRP.Ranks = IonRP.Ranks or {}

--- @type RankData[]
IonRP.Ranks.List = {}

--- Add a rank to the rank list
--- @param id number Unique rank identifier
--- @param name string Display name of the rank
--- @param color Color RGB color for the rank
--- @param immunity number Immunity level
local function AddRank(id, name, color, immunity)
  table.insert(IonRP.Ranks.List, { id = id, name = name, color = color, immunity = immunity })
end
-- Define rank hierarchy (higher number = higher rank)
-- Define ranks (constants are in sh_ranks_types.lua)
AddRank(RANK_USER, "User", Color(200, 200, 200), 0)
AddRank(RANK_MODERATOR, "Moderator", Color(46, 204, 113), 1)
AddRank(RANK_ADMIN, "Admin", Color(52, 152, 219), 2)
AddRank(RANK_SUPERADMIN, "Superadmin", Color(231, 76, 60), 3)
AddRank(RANK_LEAD_ADMIN, "Lead Admin", Color(155, 89, 182), 4)
AddRank(RANK_DEVELOPER, "Developer", Color(241, 196, 15), 5)


--- Permission categories with minimum rank requirements
--- @type table<string, PermissionData>
IonRP.Ranks.Permissions = {
  -- Basic moderation
  ["kick"] = { minRank = RANK_MODERATOR, description = "Kick players" },
  ["ban"] = { minRank = RANK_ADMIN, description = "Ban players" },
  ["unban"] = { minRank = RANK_ADMIN, description = "Unban players" },
  ["mute"] = { minRank = RANK_MODERATOR, description = "Mute players in chat" },
  ["freeze"] = { minRank = RANK_MODERATOR, description = "Freeze players" },
  ["slay"] = { minRank = RANK_MODERATOR, description = "Slay players" },
  ["bring"] = { minRank = RANK_MODERATOR, description = "Bring players to you" },
  ["goto"] = { minRank = RANK_MODERATOR, description = "Go to players" },
  ["spectate"] = { minRank = RANK_MODERATOR, description = "Spectate players" },

  -- Advanced moderation
  ["noclip"] = { minRank = RANK_MODERATOR, description = "Use noclip" },
  ["god"] = { minRank = RANK_ADMIN, description = "God mode" },
  ["cloak"] = { minRank = RANK_MODERATOR, description = "Invisibility" },
  ["health"] = { minRank = RANK_MODERATOR, description = "Set player health" },
  ["armor"] = { minRank = RANK_MODERATOR, description = "Set player armor" },
  ["money"] = { minRank = RANK_ADMIN, description = "Give/take money" },

  -- Server management
  ["cleanup"] = { minRank = RANK_ADMIN, description = "Clean up entities" },
  ["physgun_players"] = { minRank = RANK_ADMIN, description = "Physgun players" },
  ["ignite"] = { minRank = RANK_MODERATOR, description = "Ignite players" },
  ["respawn"] = { minRank = RANK_MODERATOR, description = "Respawn players" },

  -- Administrative
  ["manage_ranks"] = { minRank = RANK_LEAD_ADMIN, description = "Manage player ranks" },
  ["manage_jobs"] = { minRank = RANK_SUPERADMIN, description = "Manage jobs" },
  ["manage_props"] = { minRank = RANK_ADMIN, description = "Remove/manage props" },
  ["seejoinleave"] = { minRank = RANK_MODERATOR, description = "See join/leave messages" },
  ["seeadminchat"] = { minRank = RANK_MODERATOR, description = "See admin chat" },

  -- Developer
  ["lua"] = { minRank = RANK_DEVELOPER, description = "Run Lua code" },
  ["console"] = { minRank = RANK_LEAD_ADMIN, description = "Run server console commands" },
  ["workshop"] = { minRank = RANK_SUPERADMIN, description = "Manage workshop addons" },

  -- Rank management
  ["setrank"] = { minRank = RANK_LEAD_ADMIN, description = "Set player ranks" },

  -- Development
  ["developer"] = { minRank = RANK_DEVELOPER, description = "Access developer tools" },
  ["modelexplorer"] = { minRank = RANK_DEVELOPER, description = "Access Model Explorer" },

  -- Admin Panel
  ["ionsys"] = { minRank = RANK_ADMIN, description = "Access IonSys admin panel" },
}

--- Get rank data by ID
--- @param rankId number The rank ID to look up
--- @return RankData The rank data
function IonRP.Ranks:GetRankData(rankId)
  for _, rank in ipairs(self.List) do
    if rank.id == rankId then
      return rank
    end
  end
  return self.List[1] -- Default to User
end

--- Get rank data by name
--- @param rankName string The rank name to look up (case-insensitive)
--- @return RankData|nil rank The rank data or nil if not found
function IonRP.Ranks:GetRankByName(rankName)
  for _, rank in ipairs(self.List) do
    if string.lower(rank.name) == string.lower(rankName) then
      return rank
    end
  end
  return nil
end

--- Check if a rank has a specific permission
--- @param rankId number The rank ID to check
--- @param permission string The permission to check
--- @return boolean True if the rank has the permission
function IonRP.Ranks:HasPermission(rankId, permission)
  local perm = self.Permissions[permission]
  if not perm then return false end

  return rankId >= perm.minRank
end

--- Get all permissions for a rank
--- @param rankId number The rank ID to get permissions for
--- @return table<number, {name: string, description: string}> List of permissions with their descriptions
function IonRP.Ranks:GetRankPermissions(rankId)
  local perms = {}

  for permName, permData in pairs(self.Permissions) do
    if rankId >= permData.minRank then
      table.insert(perms, {
        name = permName,
        description = permData.description
      })
    end
  end

  return perms
end

-- Network strings
util.AddNetworkString("IonRP_RankUpdated")
util.AddNetworkString("IonRP_SendRankData")

--- Load a player's rank from database
--- @param ply Player The player to load rank for
--- @param callback fun(rankId: number)|nil Optional callback with the loaded rank ID
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

--- Set a player's rank
--- @param ply Player Target player to set rank for
--- @param rankId number|string New rank ID or rank name to assign
--- @param admin Player|nil Admin who changed the rank (nil for console)
--- @param reason string|nil Optional reason for the rank change
--- @return boolean success True if rank was set successfully
--- @return string|nil error Error message if failed
function IonRP.Ranks:SetPlayerRank(ply, rankId, admin, reason)
  local steamID = ply:SteamID64()
  local adminSteamID = admin and IsValid(admin) and admin:SteamID64() or "CONSOLE"
  local oldRank = ply:GetNWInt("IonRP_Rank", 0)

  -- Resolve rank name to ID if string is provided
  if type(rankId) == "string" then
    local rankData = self:GetRankByName(rankId)
    if not rankData then
      return false, "Invalid rank name: " .. rankId
    end
    rankId = rankData.id
  end

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
        admin and IsValid(admin) and admin:Nick() or "CONSOLE",
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
            admin and IsValid(admin) and admin:Nick() or "CONSOLE",
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

--- Log rank change to database
--- @param steamID string The Steam ID of the player whose rank changed
--- @param oldRank number The previous rank ID
--- @param newRank number The new rank ID
--- @param changedBy string Steam ID of who made the change (or "CONSOLE")
--- @param reason string|nil Reason for the change
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

--- Send rank data to client
--- @param ply Player The player to send rank data to
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
---@class Player
local ply = FindMetaTable("Player")

--- Get player's rank ID
--- @return number - The rank ID (0 = User, 1 = Moderator, etc.)
function ply:GetRank()
  return self:GetNWInt("IonRP_Rank", 0)
end

--- Get player's rank data
--- @return RankData The full rank data including name, color, and immunity
function ply:GetRankData()
  return IonRP.Ranks:GetRankData(self:GetRank())
end

--- Get player's rank name
--- @return string The display name of the player's rank
function ply:GetRankName()
  return self:GetRankData().name
end

--- Get player's rank color
--- @return Color The RGB color associated with the rank
function ply:GetRankColor()
  return self:GetRankData().color
end

--- Check if player has a specific permission
--- @param permission string The permission name to check (e.g., "noclip", "kick", "ban")
--- @return boolean True if the player has the permission
function ply:HasPermission(permission)
  return IonRP.Ranks:HasPermission(self:GetRank(), permission)
end

--- Check if player has higher or equal immunity than target
--- @param target Player The target player to check immunity against
--- @return boolean True if this player has immunity over the target
function ply:HasImmunity(target)
  if not IsValid(target) then return true end

  local myRank = self:GetRankData()
  local targetRank = target:GetRankData()

  return myRank.immunity >= targetRank.immunity
end

--- Check if player is staff (Moderator or above)
--- @return boolean True if the player is staff rank or higher
function ply:IsStaff()
  return self:GetRank() >= 1
end

--- Check if player is admin (Admin or above)
--- @return boolean True if the player is admin rank or higher
function ply:IsRPAdmin()
  return self:GetRank() >= 2
end

--- Check if player is superadmin (Superadmin or above)
--- @return boolean True if the player is superadmin rank or higher
function ply:IsRPSuperAdmin()
  return self:GetRank() >= 3
end

--- Check if player is developer
--- @return boolean True if the player is developer rank
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
  --- @type string
  local targetName = args[1]
  --- @type Player|nil
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

  if not target or not IsValid(target) then
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
