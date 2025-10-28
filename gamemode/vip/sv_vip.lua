--[[
    VIP System
    Server-side VIP management and permission checking
]]--

-- Load shared types
include("sh_vip_types.lua")
AddCSLuaFile("sh_vip_types.lua")

IonRP.VIP = IonRP.VIP or {}

--- @type VIPRankData[]
IonRP.VIP.Ranks = {}

--- Add a VIP rank to the rank list
--- @param id number Unique VIP rank identifier
--- @param name string Display name of the VIP rank
--- @param color Color RGB color for the VIP rank
--- @param level number VIP level (higher = better tier)
--- @param description string Description of VIP benefits
--- @param purchasable boolean Whether this VIP can be purchased
local function AddVIPRank(id, name, color, level, description, purchasable)
  table.insert(IonRP.VIP.Ranks, {
    id = id,
    name = name,
    color = color,
    level = level,
    description = description,
    purchasable = purchasable
  })
end

-- Define VIP ranks (constants are in sh_vip_types.lua)
AddVIPRank(VIP_RANK_SILVER, "Silver VIP", Color(192, 192, 192), 1, "Basic VIP benefits", true)
AddVIPRank(VIP_RANK_GOLD, "Gold VIP", Color(255, 215, 0), 2, "Enhanced VIP benefits", true)
AddVIPRank(VIP_RANK_DIAMOND, "Diamond VIP", Color(185, 242, 255), 3, "Premium VIP benefits", true)
AddVIPRank(VIP_RANK_PRISM, "Prism VIP", Color(255, 105, 180), 4, "Exclusive special VIP (non-purchasable)", false)

--- Get VIP rank data by ID
--- @param vipRankId number The VIP rank ID to look up
--- @return VIPRankData|nil The VIP rank data or nil if not found
function IonRP.VIP:GetVIPRankData(vipRankId)
  for _, rank in ipairs(self.Ranks) do
    if rank.id == vipRankId then
      return rank
    end
  end
  return nil
end

--- Get VIP rank data by name
--- @param vipRankName string The VIP rank name to look up (case-insensitive)
--- @return VIPRankData|nil The VIP rank data or nil if not found
function IonRP.VIP:GetVIPRankByName(vipRankName)
  for _, rank in ipairs(self.Ranks) do
    if string.lower(rank.name) == string.lower(vipRankName) then
      return rank
    end
  end
  return nil
end

-- Network strings
util.AddNetworkString("IonRP_VIPUpdated")
util.AddNetworkString("IonRP_SendVIPData")

--- Load a player's VIP rank from database
--- @param ply Player The player to load VIP for
--- @param callback fun(vipRankId: number, expiresAt: string|nil)|nil Optional callback with the loaded VIP rank ID and expiration
function IonRP.VIP:LoadPlayerVIP(ply, callback)
  local steamID = ply:SteamID64()

  IonRP.Database:PreparedQuery(
    "SELECT vip_rank_id, expires_at FROM ionrp_player_vip WHERE steam_id = ? LIMIT 1",
    { steamID },
    function(data)
      local vipRankId = 0
      local expiresAt = nil
      
      if data and #data > 0 then
        vipRankId = tonumber(data[1].vip_rank_id) or 0
        expiresAt = data[1].expires_at
        
        -- Check if VIP has expired
        if expiresAt and expiresAt ~= "" then
          local expireTime = self:ParseDateTime(expiresAt)
          if expireTime and os.time() >= expireTime then
            -- VIP expired, remove it
            print(string.format("[IonRP VIP] VIP expired for %s, removing...", ply:Nick()))
            self:RemovePlayerVIP(ply)
            vipRankId = 0
            expiresAt = nil
          end
        end
      end

      -- Set the VIP rank on the player
      ply:SetNWInt("IonRP_VIP", vipRankId)
      
      if expiresAt then
        ply:SetNWString("IonRP_VIP_Expires", expiresAt)
      else
        ply:SetNWString("IonRP_VIP_Expires", "")
      end

      if vipRankId > 0 then
        local vipData = self:GetVIPRankData(vipRankId)
        if vipData then
          print(string.format("[IonRP VIP] Loaded VIP for %s: %s (ID: %d)%s",
            ply:Nick(),
            vipData.name,
            vipRankId,
            expiresAt and (" expires at " .. expiresAt) or " (permanent)"
          ))
        end
      end

      -- Send VIP data to client
      self:SendVIPDataToClient(ply)

      if callback then callback(vipRankId, expiresAt) end
    end,
    function(err)
      print("[IonRP VIP] Error loading VIP: " .. err)
      -- Default to no VIP
      ply:SetNWInt("IonRP_VIP", 0)
      ply:SetNWString("IonRP_VIP_Expires", "")
      if callback then callback(0, nil) end
    end
  )
end

--- Set a player's VIP rank
--- @param ply Player Target player to set VIP for
--- @param vipRankId number|string New VIP rank ID or rank name to assign (0 to remove VIP)
--- @param admin Player|nil Admin who changed the VIP (nil for console)
--- @param expiresAt string|nil ISO datetime when VIP expires (nil = permanent)
--- @param reason string|nil Optional reason for the VIP change
--- @return boolean success True if VIP was set successfully
--- @return string|nil error Error message if failed
function IonRP.VIP:SetPlayerVIP(ply, vipRankId, admin, expiresAt, reason)
  local steamID = ply:SteamID64()
  local adminSteamID = admin and IsValid(admin) and admin:SteamID64() or "CONSOLE"
  local oldVIP = ply:GetNWInt("IonRP_VIP", 0)

  -- Resolve VIP rank name to ID if string is provided
  if type(vipRankId) == "string" then
    local vipData = self:GetVIPRankByName(vipRankId)
    if not vipData then
      return false, "Invalid VIP rank name: " .. vipRankId
    end
    vipRankId = vipData.id
  end

  -- Validate VIP rank ID
  if vipRankId ~= 0 and not self:GetVIPRankData(vipRankId) then
    return false, "Invalid VIP rank ID"
  end

  -- Format expires_at for SQL
  local expiresSQL = "NULL"
  if expiresAt then
    expiresSQL = "'" .. expiresAt .. "'"
  end

  -- Remove VIP if rank is 0
  if vipRankId == 0 then
    return self:RemovePlayerVIP(ply, admin, reason)
  end

  -- Update or insert VIP
  IonRP.Database:PreparedQuery(
    [[INSERT INTO ionrp_player_vip (steam_id, vip_rank_id, granted_by, expires_at)
          VALUES (?, ?, ?, ]] .. expiresSQL .. [[)
          ON DUPLICATE KEY UPDATE vip_rank_id = ?, granted_by = ?, expires_at = ]] .. expiresSQL .. [[, updated_at = CURRENT_TIMESTAMP]],
    { steamID, vipRankId, adminSteamID, vipRankId, adminSteamID },
    function(data)
      -- Update player's networked VIP
      ply:SetNWInt("IonRP_VIP", vipRankId)
      
      if expiresAt then
        ply:SetNWString("IonRP_VIP_Expires", expiresAt)
      else
        ply:SetNWString("IonRP_VIP_Expires", "")
      end

      local vipData = self:GetVIPRankData(vipRankId)
      local oldVIPData = self:GetVIPRankData(oldVIP)

      print(string.format("[IonRP VIP] %s changed %s's VIP from %s to %s%s",
        admin and IsValid(admin) and admin:Nick() or "CONSOLE",
        ply:Nick(),
        oldVIPData and oldVIPData.name or "None",
        vipData.name,
        expiresAt and (" (expires " .. expiresAt .. ")") or " (permanent)"
      ))

      -- Log the change
      self:LogVIPChange(steamID, oldVIP, vipRankId, adminSteamID, expiresAt, reason)

      -- Notify client
      net.Start("IonRP_VIPUpdated")
      net.WriteInt(vipRankId, 8)
      if expiresAt then
        net.WriteString(expiresAt)
      else
        net.WriteString("")
      end
      net.Send(ply)

      -- Send updated VIP data
      self:SendVIPDataToClient(ply)

      -- Notify all admins with manage_vip permission
      for _, p in ipairs(player.GetAll()) do
        if p:HasPermission("manage_vip") then
          p:ChatPrint(string.format("[VIP] %s set %s's VIP to %s%s",
            admin and IsValid(admin) and admin:Nick() or "CONSOLE",
            ply:Nick(),
            vipData.name,
            expiresAt and (" until " .. expiresAt) or ""
          ))
        end
      end
    end,
    function(err)
      print("[IonRP VIP] Error setting VIP: " .. err)
    end
  )

  return true
end

--- Remove a player's VIP rank
--- @param ply Player Target player to remove VIP from
--- @param admin Player|nil Admin who removed the VIP (nil for console)
--- @param reason string|nil Optional reason for VIP removal
--- @return boolean success True if VIP was removed successfully
--- @return string|nil error Error message if failed
function IonRP.VIP:RemovePlayerVIP(ply, admin, reason)
  local steamID = ply:SteamID64()
  local adminSteamID = admin and IsValid(admin) and admin:SteamID64() or "CONSOLE"
  local oldVIP = ply:GetNWInt("IonRP_VIP", 0)

  IonRP.Database:PreparedQuery(
    "DELETE FROM ionrp_player_vip WHERE steam_id = ?",
    { steamID },
    function(data)
      -- Update player's networked VIP
      ply:SetNWInt("IonRP_VIP", 0)
      ply:SetNWString("IonRP_VIP_Expires", "")

      local oldVIPData = self:GetVIPRankData(oldVIP)

      print(string.format("[IonRP VIP] %s removed %s's VIP (%s)",
        admin and IsValid(admin) and admin:Nick() or "CONSOLE",
        ply:Nick(),
        oldVIPData and oldVIPData.name or "None"
      ))

      -- Log the change
      self:LogVIPChange(steamID, oldVIP, 0, adminSteamID, nil, reason)

      -- Notify client
      net.Start("IonRP_VIPUpdated")
      net.WriteInt(0, 8)
      net.WriteString("")
      net.Send(ply)

      -- Send updated VIP data
      self:SendVIPDataToClient(ply)

      -- Notify all admins with manage_vip permission
      for _, p in ipairs(player.GetAll()) do
        if p:HasPermission("manage_vip") then
          p:ChatPrint(string.format("[VIP] %s removed %s's VIP",
            admin and IsValid(admin) and admin:Nick() or "CONSOLE",
            ply:Nick()
          ))
        end
      end
    end,
    function(err)
      print("[IonRP VIP] Error removing VIP: " .. err)
    end
  )

  return true
end

--- Log VIP change to database
--- @param steamID string The Steam ID of the player whose VIP changed
--- @param oldVIP number The previous VIP rank ID
--- @param newVIP number The new VIP rank ID
--- @param changedBy string Steam ID of who made the change (or "CONSOLE")
--- @param expiresAt string|nil ISO datetime when VIP expires
--- @param reason string|nil Reason for the change
function IonRP.VIP:LogVIPChange(steamID, oldVIP, newVIP, changedBy, expiresAt, reason)
  local expiresSQL = "NULL"
  if expiresAt then
    expiresSQL = "'" .. expiresAt .. "'"
  end
  
  IonRP.Database:PreparedQuery(
    "INSERT INTO ionrp_vip_logs (steam_id, old_vip_rank, new_vip_rank, changed_by, expires_at, reason) VALUES (?, ?, ?, ?, " .. expiresSQL .. ", ?)",
    { steamID, oldVIP, newVIP, changedBy, reason or "No reason provided" },
    function(data)
      -- Success
    end,
    function(err)
      print("[IonRP VIP] Error logging VIP change: " .. err)
    end
  )
end

--- Send VIP data to client
--- @param ply Player The player to send VIP data to
function IonRP.VIP:SendVIPDataToClient(ply)
  if not IsValid(ply) then return end

  net.Start("IonRP_SendVIPData")
  -- Send all VIP ranks
  net.WriteUInt(#self.Ranks, 8)
  for _, rank in ipairs(self.Ranks) do
    net.WriteUInt(rank.id, 8)
    net.WriteString(rank.name)
    net.WriteColor(rank.color)
    net.WriteUInt(rank.level, 8)
    net.WriteString(rank.description)
    net.WriteBool(rank.purchasable)
  end

  -- Send player's current VIP
  net.WriteUInt(ply:GetNWInt("IonRP_VIP", 0), 8)
  net.WriteString(ply:GetNWString("IonRP_VIP_Expires", ""))
  net.Send(ply)
end

--- Parse ISO datetime string to Unix timestamp
--- @param dateTimeStr string ISO datetime string (YYYY-MM-DD HH:MM:SS)
--- @return number|nil Unix timestamp or nil if parsing failed
function IonRP.VIP:ParseDateTime(dateTimeStr)
  if not dateTimeStr or dateTimeStr == "" then return nil end

  local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)"
  local year, month, day, hour, min, sec = dateTimeStr:match(pattern)

  if not year then return nil end

  return os.time({
    year = tonumber(year),
    month = tonumber(month),
    day = tonumber(day),
    hour = tonumber(hour),
    min = tonumber(min),
    sec = tonumber(sec)
  })
end

--- Check expired VIPs and remove them
function IonRP.VIP:CheckExpiredVIPs()
  local query = "SELECT steam_id FROM ionrp_player_vip WHERE expires_at IS NOT NULL AND expires_at <= NOW()"

  IonRP.Database:PreparedQuery(query, {}, function(data)
    if data and #data > 0 then
      print(string.format("[IonRP VIP] Found %d expired VIP(s), removing...", #data))
      
      for _, row in ipairs(data) do
        -- Find the player if online
        for _, ply in ipairs(player.GetAll()) do
          if ply:SteamID64() == row.steam_id then
            self:RemovePlayerVIP(ply, nil, "VIP expired")
            break
          end
        end
      end
      
      -- Remove expired VIPs from database (in case player is offline)
      IonRP.Database:PreparedQuery(
        "DELETE FROM ionrp_player_vip WHERE expires_at IS NOT NULL AND expires_at <= NOW()",
        {},
        function()
          print("[IonRP VIP] Cleaned up expired VIPs from database")
        end
      )
    end
  end, function(err)
    print("[IonRP VIP] Error checking expired VIPs: " .. err)
  end)
end

--- Initialize auto-expiration timer (runs every 5 minutes)
timer.Create("IonRP_VIP_CheckExpiration", 300, 0, function()
  IonRP.VIP:CheckExpiredVIPs()
end)

-- Player meta functions
---@class Player
local ply = FindMetaTable("Player")

--- Get player's VIP rank ID
--- @return number The VIP rank ID (0 = no VIP)
function ply:GetVIPRank()
  return self:GetNWInt("IonRP_VIP", 0)
end

--- Get player's VIP rank data
--- @return VIPRankData|nil The full VIP rank data or nil if no VIP
function ply:GetVIPRankData()
  local vipRank = self:GetVIPRank()
  if vipRank == 0 then return nil end
  return IonRP.VIP:GetVIPRankData(vipRank)
end

--- Get player's VIP rank name
--- @return string|nil The display name of the player's VIP rank or nil if no VIP
function ply:GetVIPRankName()
  local vipData = self:GetVIPRankData()
  if not vipData then return nil end
  return vipData.name
end

--- Get player's VIP rank color
--- @return Color|nil The RGB color associated with the VIP rank or nil if no VIP
function ply:GetVIPRankColor()
  local vipData = self:GetVIPRankData()
  if not vipData then return nil end
  return vipData.color
end

--- Check if player has VIP (any tier)
--- @return boolean True if the player has any VIP rank
function ply:HasVIP()
  return self:GetVIPRank() > 0
end

--- Check if player has a specific VIP rank or higher
--- @param vipRankId number|string The VIP rank ID or name to check
--- @return boolean True if the player has the specified VIP rank or higher
function ply:HasVIPRank(vipRankId)
  local playerVIPRank = self:GetVIPRank()
  if playerVIPRank == 0 then return false end

  -- Resolve VIP rank name to ID if string is provided
  if type(vipRankId) == "string" then
    local vipData = IonRP.VIP:GetVIPRankByName(vipRankId)
    if not vipData then return false end
    vipRankId = vipData.id
  end

  local playerVIPData = IonRP.VIP:GetVIPRankData(playerVIPRank)
  local requiredVIPData = IonRP.VIP:GetVIPRankData(vipRankId)
  
  if not playerVIPData or not requiredVIPData then return false end

  return playerVIPData.level >= requiredVIPData.level
end

--- Get VIP expiration datetime
--- @return string|nil ISO datetime string when VIP expires or nil if permanent
function ply:GetVIPExpiration()
  local expiresAt = self:GetNWString("IonRP_VIP_Expires", "")
  if expiresAt == "" then return nil end
  return expiresAt
end

--- Check if VIP is expired or about to expire
--- @return boolean True if VIP has expired
function ply:IsVIPExpired()
  local expiresAt = self:GetVIPExpiration()
  if not expiresAt then return false end -- Permanent VIP never expires

  local expireTime = IonRP.VIP:ParseDateTime(expiresAt)
  if not expireTime then return false end

  return os.time() >= expireTime
end

-- Hook into player initialization
hook.Add("PlayerInitialSpawn", "IonRP_LoadVIP", function(ply)
  timer.Simple(0.5, function()
    if IsValid(ply) then
      IonRP.VIP:LoadPlayerVIP(ply)
    end
  end)
end)
