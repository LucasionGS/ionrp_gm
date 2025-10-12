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
  -- Stop growth timer
  timer.Remove("IonRP_Drug_Growth_" .. self:EntIndex())
  
  -- Remove from active list
  IonRP.Drug:RemoveActive(self)
  
  -- Remove plant entity
  if IsValid(self.plant) then
    self.plant:Remove()
  end
end

--- Think loop for custom behavior
function ENT:Think()
  -- Can be overridden in drug definitions
end
