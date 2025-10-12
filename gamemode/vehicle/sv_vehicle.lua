--[[
    Database Schema - Vehicle Ownership
]] --

--- Initialize vehicle ownership tables
function IonRP.Vehicles:InitializeTables()
  print("[IonRP Vehicles] Initializing vehicle ownership tables...")

  local query = IonRP.Database:query([[
    CREATE TABLE IF NOT EXISTS ionrp_owned_vehicles (
      id INT AUTO_INCREMENT PRIMARY KEY,
      steam_id VARCHAR(32) NOT NULL,
      vehicle_identifier VARCHAR(64) NOT NULL,
      upgrades TEXT NOT NULL DEFAULT '{}',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      INDEX idx_steam_id (steam_id),
      INDEX idx_vehicle_identifier (vehicle_identifier),
      INDEX idx_steam_vehicle (steam_id, vehicle_identifier)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  ]])

  function query:onSuccess(data)
    print("[IonRP Vehicles] Vehicle ownership table ready")
  end

  function query:onError(err, sql)
    print("[IonRP Vehicles] ERROR: Failed to create owned vehicles table:")
    print("[IonRP Vehicles] ERROR: " .. err)
    print("[IonRP Vehicles] SQL: " .. sql)
  end

  query:start()
end

--[[
    Vehicle Ownership Functions
]] --

--- Get all vehicles owned by a player
--- @param ply Player The player to get vehicles for
--- @param callback function Callback with signature (vehicles: VEHICLE[])
function IonRP.Vehicles:SV_GetOwnedVehicles(ply, callback)
  if not IsValid(ply) then return end
  local steamID = ply:SteamID64()

  IonRP.Database:PreparedQuery(
    "SELECT * FROM ionrp_owned_vehicles WHERE steam_id = ?",
    { steamID },
    function(data)
      local vehicles = {}
      
      if data and #data > 0 then
        for _, row in ipairs(data) do
          local vehicleBase = IonRP.Vehicles.List[row.vehicle_identifier]
          if vehicleBase then
            -- Create an owned instance with upgrades from database
            local vehInstance = vehicleBase:MakeOwnedInstance(ply, tonumber(row.id))
            
            -- Parse and apply upgrades from JSON
            local success, upgrades = pcall(util.JSONToTable, row.upgrades)
            if success and upgrades then
              vehInstance.Upgrades = upgrades
            end
            
            table.insert(vehicles, vehInstance)
          end
        end
      end
      
      if callback then callback(vehicles) end
    end,
    function(err)
      print("[IonRP Vehicles] Error fetching owned vehicles: " .. err)
      if callback then callback({}) end
    end
  )
end

--- Save a vehicle instance to the database (update if exists, insert if new)
--- @param vehicleInstance VEHICLE The vehicle instance to save
--- @param callback function|nil Optional callback with signature (success: boolean, vehicleId: number|nil)
function IonRP.Vehicles:SV_SaveVehicle(vehicleInstance, callback)
  if not vehicleInstance.owner or not IsValid(vehicleInstance.owner) then
    if callback then callback(false) end
    return
  end

  local steamID = vehicleInstance.owner:SteamID64()
  local upgradesJSON = util.TableToJSON(vehicleInstance.Upgrades)

  if vehicleInstance.databaseId then
    -- Update existing vehicle
    IonRP.Database:PreparedQuery(
      "UPDATE ionrp_owned_vehicles SET upgrades = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
      { upgradesJSON, vehicleInstance.databaseId },
      function(data)
        print(string.format("[IonRP Vehicles] Updated vehicle ID %d for %s", 
          vehicleInstance.databaseId, vehicleInstance.owner:Nick()))
        if callback then callback(true, vehicleInstance.databaseId) end
      end,
      function(err)
        print("[IonRP Vehicles] Error updating vehicle: " .. err)
        if callback then callback(false) end
      end
    )
  else
    -- Insert new vehicle
    IonRP.Database:PreparedQuery(
      "INSERT INTO ionrp_owned_vehicles (steam_id, vehicle_identifier, upgrades) VALUES (?, ?, ?)",
      { steamID, vehicleInstance.identifier, upgradesJSON },
      function(data, query)
        local insertId = query:lastInsert()
        vehicleInstance.databaseId = insertId
        print(string.format("[IonRP Vehicles] Saved new vehicle %s (ID: %d) for %s", 
          vehicleInstance.identifier, insertId, vehicleInstance.owner:Nick()))
        if callback then callback(true, insertId) end
      end,
      function(err)
        print("[IonRP Vehicles] Error saving vehicle: " .. err)
        if callback then callback(false) end
      end
    )
  end
end

--- Purchase a vehicle for a player
--- @param ply Player The player purchasing the vehicle
--- @param vehicleIdentifier string The vehicle identifier
--- @param callback function|nil Optional callback with signature (success: boolean, message: string, vehicleInstance: VEHICLE|nil)
function IonRP.Vehicles:SV_PurchaseVehicle(ply, vehicleIdentifier, callback)
  if not IsValid(ply) then
    if callback then callback(false, "Invalid player") end
    return
  end

  if ply:GetLicenseState("license_driver") ~= "active" then
    if callback then callback(false, "You need a valid driver's license to purchase vehicles") end
    return
  end

  local vehicleBase = IonRP.Vehicles.List[vehicleIdentifier]
  if not vehicleBase then
    if callback then callback(false, "Invalid vehicle identifier") end
    return
  end

  if not vehicleBase.purchasable then
    if callback then callback(false, "This vehicle is not purchasable") end
    return
  end

  -- Check if player has enough money
  local bank = ply:GetBank()
  if bank < vehicleBase.marketValue then
    if callback then callback(false, "Insufficient funds") end
    return
  end

  -- Deduct money
  ply:AddBank(-vehicleBase.marketValue)

  -- Create and save the vehicle instance
  local vehInstance = vehicleBase:MakeOwnedInstance(ply)
  self:SV_SaveVehicle(vehInstance, function(success, vehicleId)
    if success then
      if callback then 
        callback(true, string.format("Purchased %s for %s", 
          vehicleBase.name, IonRP.Util:FormatMoney(vehicleBase.marketValue)), vehInstance)
      end
    else
      -- Refund on failure
      ply:AddBank(vehicleBase.marketValue)
      if callback then callback(false, "Failed to save vehicle to database") end
    end
  end)
end

--- Delete an owned vehicle from the database
--- @param vehicleInstance VEHICLE The vehicle instance to delete
--- @param callback function|nil Optional callback with signature (success: boolean)
function IonRP.Vehicles:SV_DeleteVehicle(vehicleInstance, callback)
  if not vehicleInstance.databaseId then
    if callback then callback(false) end
    return
  end

  IonRP.Database:PreparedQuery(
    "DELETE FROM ionrp_owned_vehicles WHERE id = ?",
    { vehicleInstance.databaseId },
    function(data)
      print(string.format("[IonRP Vehicles] Deleted vehicle ID %d", vehicleInstance.databaseId))
      
      -- Remove from active list if spawned
      if vehicleInstance.entity and IsValid(vehicleInstance.entity) then
        local entIndex = vehicleInstance.entity:EntIndex()
        vehicleInstance.entity:Remove()
        IonRP.Vehicles.Active[entIndex] = nil
      end
      
      if callback then callback(true) end
    end,
    function(err)
      print("[IonRP Vehicles] Error deleting vehicle: " .. err)
      if callback then callback(false) end
    end
  )
end

--- Get a specific owned vehicle by database ID
--- @param ply Player The player who owns the vehicle
--- @param vehicleId number The database ID of the vehicle
--- @param callback fun(vehicleInstance: VEHICLE|nil) Callback with signature (vehicleInstance: VEHICLE|nil)
function IonRP.Vehicles:SV_GetOwnedVehicleById(ply, vehicleId, callback)
  if not IsValid(ply) then return end
  local steamID = ply:SteamID64()

  IonRP.Database:PreparedQuery(
    "SELECT * FROM ionrp_owned_vehicles WHERE id = ? AND steam_id = ? LIMIT 1",
    { vehicleId, steamID },
    function(data)
      if data and #data > 0 then
        local row = data[1]
        local vehicleBase = IonRP.Vehicles.List[row.vehicle_identifier]
        
        if vehicleBase then
          local vehInstance = vehicleBase:MakeOwnedInstance(ply, tonumber(row.id))
          
          -- Parse and apply upgrades from JSON
          local success, upgrades = pcall(util.JSONToTable, row.upgrades)
          if success and upgrades then
            vehInstance.Upgrades = upgrades
          end
          
          if callback then callback(vehInstance) end
          return
        end
      end
      
      if callback then callback(nil) end
    end,
    function(err)
      print("[IonRP Vehicles] Error fetching vehicle by ID: " .. err)
      if callback then callback(nil) end
    end
  )
end

--[[
    Vehicle Entity Management
]] --

--- Defines functions related to vehicle entity
--- @param veh Vehicle The vehicle entity to define
--- @return boolean, string|nil
function IonRP.Vehicles:SV_DefineVehicleEntity(veh)
  if not veh.VehicleInstance then return false, "Not a valid IonRP vehicle entity" end
  local vehInstance = veh.VehicleInstance

  -- When the vehicle is removed, clean up the active list
  local callOnRemoveIdentifier = veh:EntIndex() .. "_" .. vehInstance.identifier .. "_OnRemove"
  veh:CallOnRemove(callOnRemoveIdentifier, function()
    if vehInstance and vehInstance.entity and vehInstance.entity == self then
      IonRP.Vehicles.Active[self:EntIndex()] = nil
      vehInstance.entity = nil
    end

    veh:RemoveCallOnRemove(callOnRemoveIdentifier)
  end)

  return true, nil
end

print("[IonRP Vehicles] Server-side vehicle management loaded")
