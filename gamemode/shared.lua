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

  --- Get all licenses owned by the player
  --- @return table<string, LicenseInstance> # Table of license instances keyed by identifier
  function plyMeta:GetLicenses()
    return self.IonRP_Licenses or {}
  end

  --- Check if player has a specific license (regardless of state)
  --- @param licenseIdentifier string The license identifier
  --- @return boolean # True if player owns the license
  function plyMeta:HasLicense(licenseIdentifier)
    return self.IonRP_Licenses and self.IonRP_Licenses[licenseIdentifier] ~= nil
  end

  --- Get the state of a specific license
  --- @param licenseIdentifier string The license identifier
  --- @return "active"|"suspended"|nil # License state or nil if not owned
  function plyMeta:GetLicenseState(licenseIdentifier)
    if not self.IonRP_Licenses or not self.IonRP_Licenses[licenseIdentifier] then
      return nil
    end
    return self.IonRP_Licenses[licenseIdentifier].state
  end

  --- Check if player has an active and valid license
  --- @param licenseIdentifier string The license identifier
  --- @return boolean # True if license is active and valid
  function plyMeta:HasValidLicense(licenseIdentifier)
    if not self.IonRP_Licenses or not self.IonRP_Licenses[licenseIdentifier] then
      return false
    end
    
    local licenseType = IonRP.Licenses.List[licenseIdentifier]
    if not licenseType then return false end
    
    return LICENSE:IsValid(self.IonRP_Licenses[licenseIdentifier])
  end

  util.AddNetworkString("Player_Send_Notification")
  --- Send a notification to a player
  --- @param text string The notification text
  --- @param duration number|nil The duration in seconds
  --- @param type number|nil The notification type (NOTIFY_GENERIC, NOTIFY_ERROR, etc.)
  function plyMeta:Notify(text, duration, type)
    net.Start("Player_Send_Notification")
      net.WriteString(text)
      net.WriteFloat(duration or 3)
      net.WriteInt(type or 0, 32)
    net.Send(self)
  end
else
  function plyMeta:Notify(text, duration, type)
    notification.AddLegacy(text, type or 0, duration or 3)
    if type == NOTIFY_ERROR then
      surface.PlaySound("buttons/button10.wav")
    else
      surface.PlaySound("buttons/lightswitch2.wav")
    end
  end

  net.Receive("Player_Send_Notification", function()
    local text = net.ReadString()
    local duration = net.ReadFloat()
    local type = net.ReadInt(32)

    local ply = LocalPlayer()

    if not IsValid(ply) then
      ErrorNoHalt("Invalid player.")
      return
    end

    if not ply.Notify then return end

    ply:Notify(text, duration, type)
  end)
end
