--- Server-side drug management for IonRP

if not SERVER then return end

IonRP.Drug = IonRP.Drug or {}
IonRP.Drug.Active = IonRP.Drug.Active or {}

--- Spawn a drug entity in the world
--- @param drugID string The drug type ID
--- @param pos Vector Spawn position
--- @param ang Angle|nil Spawn angle
--- @param autoGrow boolean|nil Whether to auto-start growth (default: true)
--- @return Entity|nil # The spawned drug entity
function IonRP.Drug:Spawn(drugID, pos, ang, autoGrow)
  local drug = IonRP.Drug.List[drugID]
  if not drug then
    print("[IonRP Drug] ERROR: Unknown drug ID: " .. drugID)
    return nil
  end
  
  if autoGrow == nil then autoGrow = true end
  
  -- Create entity
  local ent = ents.Create("ionrp_drug_base")
  if not IsValid(ent) then
    print("[IonRP Drug] ERROR: Failed to create ionrp_drug_base entity")
    return nil
  end
  
  ent:SetPos(pos)
  ent:SetAngles(ang or Angle(0, 0, 0))
  ent:SetNWString("IonRP_DrugID", drugID)
  ent:Spawn()
  
  -- Initialize drug-specific logic
  drug:SV_Initialize(ent)
  
  -- Start growth if enabled
  if autoGrow then
    drug:SV_StartGrowth(ent)
  end
  
  -- Track active drug
  IonRP.Drug.Active[ent:EntIndex()] = {
    entity = ent,
    drug = drug,
    drugID = drugID,
    spawnTime = CurTime()
  }
  
  print("[IonRP Drug] Spawned " .. drug.name .. " at " .. tostring(pos))
  
  return ent
end

--- Remove a drug from the active list
--- @param ent Entity The drug entity
function IonRP.Drug:RemoveActive(ent)
  if not IsValid(ent) then return end
  
  local entIndex = ent:EntIndex()
  if IonRP.Drug.Active[entIndex] then
    IonRP.Drug.Active[entIndex] = nil
    print("[IonRP Drug] Removed drug entity " .. entIndex)
  end
end

--- Get the drug definition from an entity
--- @param ent Entity The drug entity
--- @return Drug|nil
function IonRP.Drug:GetFromEntity(ent)
  if not IsValid(ent) then return nil end
  
  local drugID = ent:GetNWString("IonRP_DrugID", "")
  if drugID == "" then return nil end
  
  return IonRP.Drug.List[drugID]
end

--- Get all active drug entities of a specific type
--- @param drugID string The drug type ID
--- @return table<number, Entity> # Array of entities
function IonRP.Drug:GetActiveDrugs(drugID)
  local drugs = {}
  
  for _, data in pairs(IonRP.Drug.Active) do
    if IsValid(data.entity) and data.drugID == drugID then
      table.insert(drugs, data.entity)
    end
  end
  
  return drugs
end

--- Clean up invalid entities from active list
function IonRP.Drug:CleanupActive()
  local removed = 0
  
  for entIndex, data in pairs(IonRP.Drug.Active) do
    if not IsValid(data.entity) then
      IonRP.Drug.Active[entIndex] = nil
      removed = removed + 1
    end
  end
  
  if removed > 0 then
    print("[IonRP Drug] Cleaned up " .. removed .. " invalid drug entities")
  end
end

-- Cleanup timer
timer.Create("IonRP_Drug_Cleanup", 60, 0, function()
  IonRP.Drug:CleanupActive()
end)

print("[IonRP Drug] Server-side drug system loaded")
