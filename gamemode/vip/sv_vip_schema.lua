--[[
    VIP System Schema
    Creates and manages VIP-related database tables
]]--

IonRP.VIP = IonRP.VIP or {}

--[[
    Initialize VIP tables
]]--
function IonRP.VIP:InitializeTables()
    print("[IonRP] Initializing VIP tables...")
    
    -- Create player VIP table
    local query = IonRP.Database:query([[
        CREATE TABLE IF NOT EXISTS ionrp_player_vip (
            steam_id VARCHAR(32) PRIMARY KEY,
            vip_rank_id INT NOT NULL DEFAULT 0,
            granted_by VARCHAR(32) DEFAULT NULL,
            expires_at DATETIME NULL,
            granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_vip_rank (vip_rank_id),
            INDEX idx_expires (expires_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
    
    function query:onSuccess(data)
        print("[IonRP] Player VIP table ready")
    end
    
    function query:onError(err, sql)
        print("[IonRP] ERROR: Failed to create player VIP table:")
        print("[IonRP] ERROR: " .. err)
    end
    
    query:start()
    
    -- Create VIP logs table
    local logQuery = IonRP.Database:query([[
        CREATE TABLE IF NOT EXISTS ionrp_vip_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            steam_id VARCHAR(32) NOT NULL,
            old_vip_rank INT NOT NULL,
            new_vip_rank INT NOT NULL,
            changed_by VARCHAR(32) NOT NULL,
            reason TEXT,
            expires_at DATETIME NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_steam_id (steam_id),
            INDEX idx_changed_by (changed_by)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
    
    function logQuery:onSuccess(data)
        print("[IonRP] VIP logs table ready")
    end
    
    function logQuery:onError(err, sql)
        print("[IonRP] ERROR: Failed to create VIP logs table:")
        print("[IonRP] ERROR: " .. err)
    end
    
    logQuery:start()
end
