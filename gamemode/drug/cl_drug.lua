--- Client-side drug system for IonRP

if not CLIENT then return end

IonRP.Drug = IonRP.Drug or {}

--- Get the drug definition from an entity
--- @param ent Entity The drug entity
--- @return Drug|nil
function IonRP.Drug:GetFromEntity(ent)
  if not IsValid(ent) then return nil end
  
  local drugID = ent:GetNWString("IonRP_DrugID", "")
  if drugID == "" then return nil end
  
  return IonRP.Drug.List[drugID]
end

print("[IonRP Drug] Client-side drug system loaded")
