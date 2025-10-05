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
  Team Setup
--]]
function GM:CreateTeams()
  TEAM_CITIZEN = 1
  TEAM_POLICE = 2
  TEAM_MEDIC = 3

  team.SetUp(TEAM_CITIZEN, "Citizen", Color(100, 100, 100))
  team.SetUp(TEAM_POLICE, "Police Officer", Color(0, 0, 255))
  team.SetUp(TEAM_MEDIC, "Medic", Color(255, 0, 0))
end

--[[
  Allow or deny noclip
--]]
function GM:PlayerNoClip(ply, desiredState)
  -- Only allow admins to noclip
  if ply:IsAdmin() then
    return true
  end

  return false
end

--[[
  Shared utility functions
--]]

-- Format money display
function GM:FormatMoney(amount)
  -- Format number with commas (e.g., 1000 -> 1,000)
  local formatted = tostring(amount)
  local k
  while true do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    if k == 0 then break end
  end
  return "$" .. formatted
end

---@class Player
local plyMeta = FindMetaTable("Player")
-- Get cash is in the player's wallet
function plyMeta:GetWallet()
  return self:GetNWInt("Wallet", 0)
end

-- Get money is in the player's bank
function plyMeta:GetBank()
  return self:GetNWInt("Bank", 0)
end

if SERVER then
  -- Set cash in the player's wallet
  function plyMeta:SetWallet(amount)
    self:SetNWInt("Wallet", amount)
  end

  -- Add cash to the player's wallet
  function plyMeta:AddWallet(amount)
    local currentMoney = self:GetWallet()
    self:SetWallet(currentMoney + amount)
  end

  -- Set money in the player's bank
  function plyMeta:SetBank(amount)
    self:SetNWInt("Bank", amount)
  end

  -- Add money to the player's bank
  function plyMeta:AddBank(amount)
    local currentMoney = self:GetBank()
    self:SetBank(currentMoney + amount)
  end

  -- Get character's roleplay name (server-side)
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
