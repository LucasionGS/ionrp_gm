--[[
  IonRP - Shared Code
  This file runs on both client and server
--]]

-- Gamemode information
GM.Name = "IonRP"
GM.Author = "Ion"
GM.Email = "N/A"
GM.Website = "N/A"
GM.TeamBased = false

--[[
  Allow or deny noclip
  This will be overridden by the rank system in sv_ranks.lua
--]]
function GM:PlayerNoClip(ply, desiredState)
  -- Fallback if rank system not loaded
  if ply:IsAdmin() then
    return true
  end

  return false
end

--[[
  Shared utility functions
--]]

--- Format money display
function IonRP.Util:FormatMoney(amount)
  -- Format number with commas (e.g., 1000 -> 1,000)
  local formatted = tostring(amount)
  local k
  while true do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    if k == 0 then break end
  end
  return "$" .. formatted
end

function IonRP.Util:FindPlayer(name, fallbackToIDs)
  local players = player.GetAll()
  name = string.lower(name)
  for _, ply in ipairs(players) do
    if string.find(string.lower(ply:Nick()), name, 1, true) then
      return ply
    end
  end

  if fallbackToIDs then
    for _, ply in ipairs(players) do
      if ply:SteamID64() == name then
        return ply
      end
    end

    local id = tonumber(name)
    local ply = id and Player(id) or nil
    if ply and IsValid(ply) and ply:IsPlayer() then
      return ply
    end
  end

  return nil
end

--- Convert a hex color string (e.g., "#RRGGBB" or "RRGGBB") to a Color object
--- @param hex string The hex color string
--- @return Color|nil # The resulting Color object
function IonRP.Util:HexToColor(hex)
  hex = hex:gsub("#", "")
  if #hex ~= 6 then
    return nil
  end

  local r = tonumber(hex:sub(1, 2), 16) or 255
  local g = tonumber(hex:sub(3, 4), 16) or 255
  local b = tonumber(hex:sub(5, 6), 16) or 255

  return Color(r, g, b)
end


---@class Player
local plyMeta = FindMetaTable("Player")
--- Get cash is in the player's wallet
--- @return number
function plyMeta:GetWallet()
  return self:GetNWInt("Wallet", 0)
end

--- Get money is in the player's bank
--- @return number
function plyMeta:GetBank()
  return self:GetNWInt("Bank", 0)
end

if SERVER then
  --- Set cash in the player's wallet
  --- @param amount number
  function plyMeta:SetWallet(amount)
    self:SetNWInt("Wallet", amount)
  end

  --- Add cash to the player's wallet
  --- @param amount number
  function plyMeta:AddWallet(amount)
    local currentMoney = self:GetWallet()
    self:SetWallet(currentMoney + amount)
  end

  --- Set money in the player's bank
  --- @param amount number
  function plyMeta:SetBank(amount)
    self:SetNWInt("Bank", amount)
  end

  --- Add money to the player's bank
  --- @param amount number
  function plyMeta:AddBank(amount)
    local currentMoney = self:GetBank()
    self:SetBank(currentMoney + amount)
  end

  --- Get character's roleplay name
  --- @return string # The full roleplay name or fallback to Nick()
  function plyMeta:GetRPName()
    local firstName = self:GetNWString("IonRP_FirstName", "")
    local lastName = self:GetNWString("IonRP_LastName", "")

    if firstName == "" or lastName == "" then
      return self:Nick()
    end

    return firstName .. " " .. lastName
  end

  function plyMeta:GetFirstName()
    return self:GetNWString("IonRP_FirstName", "Unknown")
  end

  function plyMeta:GetLastName()
    return self:GetNWString("IonRP_LastName", "Unknown")
  end
end
