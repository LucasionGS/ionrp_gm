--[[
    VIP System - Shared Types
    Common type definitions for VIP ranks
]]--

--- @class VIPRankData
--- @field id number Unique VIP rank identifier
--- @field name string Display name of the VIP rank
--- @field color Color RGB color for the VIP rank
--- @field level number VIP level (higher = better tier)
--- @field description string Description of VIP benefits
--- @field purchasable boolean Whether this VIP can be purchased

--- @class VIPInstance
--- @field rankData VIPRankData The VIP rank data
--- @field owner Player|nil The player who owns this VIP instance
--- @field expiresAt string|nil ISO datetime string when VIP expires (nil = permanent)
--- @field grantedAt string ISO datetime string when VIP was granted
--- @field grantedBy string Steam ID of who granted the VIP
--- @field updatedAt string ISO datetime string when VIP was last updated

-- VIP rank constants (shared between client and server)
--- Silver VIP rank (lowest tier)
--- @type number
VIP_RANK_SILVER = 1

--- Gold VIP rank (mid tier)
--- @type number
VIP_RANK_GOLD = 2

--- Diamond VIP rank (high tier)
--- @type number
VIP_RANK_DIAMOND = 3

--- Prism VIP rank (special tier, non-purchasable)
--- @type number
VIP_RANK_PRISM = 4
