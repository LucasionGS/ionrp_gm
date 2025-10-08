--[[
    Rank System - Client
    Client-side rank display and data
]] --

-- Load shared types
include("sh_ranks_types.lua")

IonRP.Ranks = IonRP.Ranks or {}

--- @type RankData[]
IonRP.Ranks.List = IonRP.Ranks.List or {}

-- Network receivers
net.Receive("IonRP_RankUpdated", function()
  local rankId = net.ReadInt(8)

  if not IsValid(LocalPlayer()) then return end
  LocalPlayer():SetNWInt("IonRP_Rank", rankId)

  local rankData = IonRP.Ranks:GetRankData(rankId)
  if rankData then
    chat.AddText(
      Color(46, 204, 113), "[IonRP] ",
      Color(255, 255, 255), "Your rank has been updated to ",
      rankData.color, rankData.name
    )
  end
end)

net.Receive("IonRP_SendRankData", function()
  -- Receive all ranks
  local numRanks = net.ReadUInt(8)
  IonRP.Ranks.List = {}

  for i = 1, numRanks do
    local id = net.ReadUInt(8)
    local name = net.ReadString()
    local color = net.ReadColor()
    local immunity = net.ReadUInt(8)

    table.insert(IonRP.Ranks.List, {
      id = id,
      name = name,
      color = color,
      immunity = immunity
    })
  end

  -- Receive player's current rank
  local myRank = net.ReadUInt(8)

  if not IsValid(LocalPlayer()) then return end
  LocalPlayer():SetNWInt("IonRP_Rank", myRank)

  print("[IonRP] Received rank data from server")
end)

--- Get rank data by ID
--- @param rankId number The rank ID to look up
--- @return RankData The rank data (defaults to User if not found)
function IonRP.Ranks:GetRankData(rankId)
  for _, rank in ipairs(self.List) do
    if rank.id == rankId then
      return rank
    end
  end
  -- Default to User
  return { id = 0, name = "User", color = Color(200, 200, 200), immunity = 0 }
end

-- Player meta functions (client-side)
--- @class Player
local ply = FindMetaTable("Player")

--- Get player's rank ID
--- @return number The rank ID (0 = User, 1 = Moderator, etc.)
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
  local data = self:GetRankData()
  return data and data.name or "User"
end

--- Get player's rank color
--- @return Color The RGB color associated with the rank
function ply:GetRankColor()
  local data = self:GetRankData()
  return data and data.color or Color(200, 200, 200)
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
