--[[
    Database Schema
    Creates and manages database tables
]] --

IonRP.Database = IonRP.Database or {}

--[[
    Initialize all database tables
]] --
function IonRP.Database:InitializeTables()
  print("[IonRP] Initializing database tables...")

  -- Initialize rank tables if available
  if IonRP.Ranks and IonRP.Ranks.InitializeTables then
    IonRP.Ranks:InitializeTables()
  end

  -- Initialize inventory tables if available
  if IonRP.Inventory and IonRP.Inventory.InitializeTables then
    IonRP.Inventory:InitializeTables()
  end

  -- Initialize vehicle tables if available
  if IonRP.Vehicles and IonRP.Vehicles.InitializeTables then
    IonRP.Vehicles:InitializeTables()
  end

  -- Create characters table
  local query = self:query([[
        CREATE TABLE IF NOT EXISTS ionrp_characters (
            id INT AUTO_INCREMENT PRIMARY KEY,
            steam_id VARCHAR(32) NOT NULL,
            first_name VARCHAR(32) NOT NULL,
            last_name VARCHAR(32) NOT NULL,
            wallet INT NOT NULL DEFAULT 500,
            bank INT NOT NULL DEFAULT 0,
            model VARCHAR(128) NOT NULL DEFAULT 'models/player/Group01/male_01.mdl',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY unique_steamid (steam_id),
            INDEX idx_steam_id (steam_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

  function query:onSuccess(data)
    print("[IonRP] Characters table ready")
  end

  function query:onError(err, sql)
    print("[IonRP] ERROR: Failed to create characters table:")
    print("[IonRP] ERROR: " .. err)
    print("[IonRP] SQL: " .. sql)
  end

  query:start()
end

--- Execute a prepared query safely
--- @param sql string - SQL query with ? placeholders
--- @param params table - Parameters to bind
--- @param onSuccess function - Callback on success
--- @param onError function - Callback on error
function IonRP.Database:PreparedQuery(sql, params, onSuccess, onError)
  local query = self:prepare(sql)

  if not query then
    if onError then
      onError("Failed to prepare query")
    end
    return
  end

  -- Bind parameters
  if params then
    for i, param in ipairs(params) do
      query:setString(i, tostring(param))
    end
  end

  function query:onSuccess(data)
    if onSuccess then onSuccess(data) end
  end

  function query:onError(err, sql)
    print("[IonRP] Query Error: " .. err)
    if onError then onError(err, sql) end
  end

  query:start()
  return query
end
