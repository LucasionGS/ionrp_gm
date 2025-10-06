--[[
    Rank System Schema
    Creates and manages rank-related database tables
]]--

IonRP.Ranks = IonRP.Ranks or {}

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
