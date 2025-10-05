--[[
    Rank System Schema
    Creates and manages rank-related database tables
]]--

IonRP.Ranks = IonRP.Ranks or {}

-- Define rank hierarchy (higher number = higher rank)
IonRP.Ranks.List = {
    {id = 0, name = "User", color = Color(200, 200, 200), immunity = 0},
    {id = 1, name = "Moderator", color = Color(46, 204, 113), immunity = 1},
    {id = 2, name = "Admin", color = Color(52, 152, 219), immunity = 2},
    {id = 3, name = "Superadmin", color = Color(231, 76, 60), immunity = 3},
    {id = 4, name = "Lead Admin", color = Color(155, 89, 182), immunity = 4},
    {id = 5, name = "Developer", color = Color(241, 196, 15), immunity = 5},
}

-- Permission categories
IonRP.Ranks.Permissions = {
    -- Basic moderation
    ["kick"] = {minRank = 1, description = "Kick players"},
    ["ban"] = {minRank = 2, description = "Ban players"},
    ["unban"] = {minRank = 2, description = "Unban players"},
    ["mute"] = {minRank = 1, description = "Mute players in chat"},
    ["freeze"] = {minRank = 1, description = "Freeze players"},
    ["slay"] = {minRank = 1, description = "Slay players"},
    ["bring"] = {minRank = 1, description = "Bring players to you"},
    ["goto"] = {minRank = 1, description = "Go to players"},
    ["spectate"] = {minRank = 1, description = "Spectate players"},
    
    -- Advanced moderation
    ["noclip"] = {minRank = 1, description = "Use noclip"},
    ["god"] = {minRank = 2, description = "God mode"},
    ["cloak"] = {minRank = 1, description = "Invisibility"},
    ["health"] = {minRank = 1, description = "Set player health"},
    ["armor"] = {minRank = 1, description = "Set player armor"},
    ["money"] = {minRank = 2, description = "Give/take money"},
    
    -- Server management
    ["cleanup"] = {minRank = 2, description = "Clean up entities"},
    ["physgun_players"] = {minRank = 2, description = "Physgun players"},
    ["ignite"] = {minRank = 1, description = "Ignite players"},
    ["respawn"] = {minRank = 1, description = "Respawn players"},
    
    -- Administrative
    ["manage_ranks"] = {minRank = 4, description = "Manage player ranks"},
    ["manage_jobs"] = {minRank = 3, description = "Manage jobs"},
    ["manage_props"] = {minRank = 2, description = "Remove/manage props"},
    ["seejoinleave"] = {minRank = 1, description = "See join/leave messages"},
    ["seeadminchat"] = {minRank = 1, description = "See admin chat"},
    
    -- Developer
    ["lua"] = {minRank = 5, description = "Run Lua code"},
    ["console"] = {minRank = 4, description = "Run server console commands"},
    ["workshop"] = {minRank = 3, description = "Manage workshop addons"},
}

--[[
    Initialize rank tables
]]--
function IonRP.Ranks:InitializeTables()
    print("[IonRP] Initializing ranks tables...")
    
    -- Create player ranks table
    local query = IonRP.Database:query([[
        CREATE TABLE IF NOT EXISTS ionrp_player_ranks (
            steam_id VARCHAR(32) PRIMARY KEY,
            rank_id INT NOT NULL DEFAULT 0,
            granted_by VARCHAR(32) DEFAULT NULL,
            granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_rank (rank_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
    
    function query:onSuccess(data)
        print("[IonRP] Player ranks table ready")
    end
    
    function query:onError(err, sql)
        print("[IonRP] ERROR: Failed to create player ranks table:")
        print("[IonRP] ERROR: " .. err)
    end
    
    query:start()
    
    -- Create rank logs table
    local logQuery = IonRP.Database:query([[
        CREATE TABLE IF NOT EXISTS ionrp_rank_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            steam_id VARCHAR(32) NOT NULL,
            old_rank INT NOT NULL,
            new_rank INT NOT NULL,
            changed_by VARCHAR(32) NOT NULL,
            reason TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_steam_id (steam_id),
            INDEX idx_changed_by (changed_by)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
    
    function logQuery:onSuccess(data)
        print("[IonRP] Rank logs table ready")
    end
    
    function logQuery:onError(err, sql)
        print("[IonRP] ERROR: Failed to create rank logs table:")
        print("[IonRP] ERROR: " .. err)
    end
    
    logQuery:start()
end

--[[
    Get rank data by ID
    @param rankId number
    @return table Rank data
]]--
function IonRP.Ranks:GetRankData(rankId)
    for _, rank in ipairs(self.List) do
        if rank.id == rankId then
            return rank
        end
    end
    return self.List[1] -- Default to User
end

--[[
    Get rank data by name
    @param rankName string
    @return table Rank data
]]--
function IonRP.Ranks:GetRankByName(rankName)
    for _, rank in ipairs(self.List) do
        if string.lower(rank.name) == string.lower(rankName) then
            return rank
        end
    end
    return nil
end

--[[
    Check if a rank has a specific permission
    @param rankId number
    @param permission string
    @return boolean
]]--
function IonRP.Ranks:HasPermission(rankId, permission)
    local perm = self.Permissions[permission]
    if not perm then return false end
    
    return rankId >= perm.minRank
end

--[[
    Get all permissions for a rank
    @param rankId number
    @return table List of permissions
]]--
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
