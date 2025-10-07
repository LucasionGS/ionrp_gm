--[[
    Rank System - Shared Types
    Common type definitions for ranks
]]--

--- @class RankData
--- @field id number Unique rank identifier
--- @field name string Display name of the rank
--- @field color Color RGB color for the rank
--- @field immunity number Immunity level (higher can't be targeted by lower)

--- @class PermissionData
--- @field minRank number Minimum rank ID required for this permission
--- @field description string Description of what this permission allows

-- Rank constants (shared between client and server)
--- User rank (default)
--- @type number
RANK_USER = 0

--- Moderator rank (basic moderation permissions)
--- @type number
RANK_MODERATOR = 1

--- Admin rank (advanced moderation permissions)
--- @type number
RANK_ADMIN = 2

--- Superadmin rank (high-level administration)
--- @type number
RANK_SUPERADMIN = 3

--- Lead Admin rank (rank management)
--- @type number
RANK_LEAD_ADMIN = 4

--- Developer rank (full server access)
--- @type number
RANK_DEVELOPER = 5
