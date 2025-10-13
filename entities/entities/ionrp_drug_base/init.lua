AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

--- Initialize the drug entity
function ENT:Initialize()
  local drugID = self:GetNWString("IonRP_DrugID", "")
  local drug = IonRP.Drug.List[drugID]
  
  if drug then
    drug:SV_Initialize(self)
  else
    print("[IonRP Drug] ERROR: No drug definition found for " .. drugID)
  end
end

--- Handle player use
function ENT:Use(activator, caller)
  if not IsValid(caller) or not caller:IsPlayer() then return end
  
  local drug = IonRP.Drug:GetFromEntity(self)
  if not drug then return end
  
  drug:SV_OnUse(self, caller)
end

--- Cleanup on removal
function ENT:OnRemove()
  -- Call drug-specific cleanup
  local drug = IonRP.Drug:GetFromEntity(self)
  if drug then
    drug:SV_OnRemove(self)
  end
  
  -- Remove from active list
  IonRP.Drug:RemoveActive(self)
end

--- Think loop for custom behavior
function ENT:Think()
  local drug = IonRP.Drug:GetFromEntity(self)
  if drug then
    drug:SV_Think(self)
  end
  
  self:NextThink(CurTime() + 0.1)
  return true
end
