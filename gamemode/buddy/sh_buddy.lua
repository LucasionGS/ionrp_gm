--[[
  Buddy System - Shared
  Allows players to add friends who can access their properties/vehicles
]]--

IonRP.Buddy = IonRP.Buddy or {}

--- @class BuddyRelationship
--- @field id number Database ID of the relationship
--- @field ownerSteamID string Steam ID of the player who added the buddy
--- @field buddySteamID string Steam ID of the buddy player
--- @field createdAt string ISO datetime when buddy was added

--- Check if a player is buddies with another player
--- @param ply Player The player to check
--- @param targetPly Player The target player to check buddy status with
--- @return boolean True if they are buddies
function IonRP.Buddy:AreBuddies(ply, targetPly)
  if not IsValid(ply) or not IsValid(targetPly) then return false end
  if ply == targetPly then return false end
  
  local buddies = ply.IonRP_Buddies
  if not buddies then return false end
  
  local targetSteamID = targetPly:SteamID64()
  return buddies[targetSteamID] ~= nil
end

--- Check if a buddy has a specific permission
--- @param ply Player The player who owns the buddy list
--- @param targetPly Player The buddy to check
--- @param permission string The permission to check ("vehicles" or "properties")
--- @return boolean True if permission is granted
function IonRP.Buddy:HasPermission(ply, targetPly, permission)
  if not IsValid(ply) or not IsValid(targetPly) then return false end
  if ply == targetPly then return false end
  
  local buddies = ply.IonRP_Buddies
  if not buddies then return false end
  
  local targetSteamID = targetPly:SteamID64()
  local buddyData = buddies[targetSteamID]
  
  if not buddyData then return false end
  
  -- buddyData is now a table with permissions
  if type(buddyData) == "table" and buddyData[permission] ~= nil then
    return buddyData[permission] == true
  end
  
  -- Legacy support: if buddyData is just 'true', grant all permissions
  return buddyData == true
end

--- Get a player's buddy list
--- @param ply Player The player to get buddies for
--- @return table<string, table> Table of steam IDs mapped to permissions
function IonRP.Buddy:GetBuddies(ply)
  if not IsValid(ply) then return {} end
  return ply.IonRP_Buddies or {}
end

print("[IonRP Buddy] Shared buddy system loaded")
