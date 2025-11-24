--[[
    VIP System - Shared
    Shared VIP data structures and helper functions
]]--

-- Load shared types
if SERVER then
  include("sh_vip_types.lua")
  AddCSLuaFile("sh_vip_types.lua")
else
  include("sh_vip_types.lua")
end

IonRP.VIP = IonRP.VIP or {}

--- @type VIPRankData[]
IonRP.VIP.Ranks = IonRP.VIP.Ranks or {}

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
