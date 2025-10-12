--- Drug system for IonRP
--- Allows creation of growable/craftable drugs with customizable properties

IonRP.Drug = IonRP.Drug or {}
--- @type table<string, Drug>
IonRP.Drug.List = IonRP.Drug.List or {}

--- @class Drug
--- @field id string Unique identifier for the drug
--- @field name string Display name
--- @field description string Drug description
--- @field baseModel string Model for the pot/base entity
--- @field plantModel string Model for the growing plant
--- @field growthTime number Time in seconds for full growth (randomized ±10%)
--- @field harvestRewards table<string, number> Items given on harvest {itemID = amount}
--- @field pickupItem string|nil Item ID to give when picking up non-ready plant
--- @field glowWhenReady boolean Whether to make plant glow when ready
--- @field glowColor Color|nil Color to glow when ready
DRUG = {}
DRUG.__index = DRUG

--- Create a new drug type
--- @param id string Unique drug identifier
--- @param name string Display name
--- @return Drug
function DRUG:New(id, name)
  local drug = setmetatable({}, DRUG)
  
  drug.id = id
  drug.name = name
  drug.description = ""
  drug.baseModel = "models/props_c17/pottery06a.mdl"
  drug.plantModel = "models/props/pi_fern.mdl"
  drug.growthTime = 300 -- 5 minutes default
  drug.harvestRewards = {}
  drug.pickupItem = nil
  drug.glowWhenReady = false
  drug.glowColor = Color(20, 200, 0)
  
  -- Register in global list
  IonRP.Drug.List[id] = drug
  
  return drug
end

--- Called when the drug entity is first spawned (SERVER)
--- Override this for custom initialization logic
--- @param ent Entity The drug entity
function DRUG:SV_Initialize(ent)
  -- Default implementation
  ent:SetModel(self.baseModel)
  ent:PhysicsInit(SOLID_VPHYSICS)
  ent:SetMoveType(MOVETYPE_VPHYSICS)
  ent:SetSolid(SOLID_VPHYSICS)
  ent:SetUseType(SIMPLE_USE)
  
  local phys = ent:GetPhysicsObject()
  if phys and phys:IsValid() then
    phys:Wake()
  end
  
  -- Create plant entity
  local plant = ents.Create("prop_dynamic")
  plant:SetModel(self.plantModel)
  plant:SetPos(ent:GetPos() + Vector(0, 0, ent:OBBMaxs().z * 0.8))
  plant:SetAngles(ent:GetAngles())
  plant:SetParent(ent)
  plant:Spawn()
  plant:SetModelScale(0) -- Start hidden
  
  ent.plant = plant
  ent.drug = self
end

--- Called to start the growth process (SERVER)
--- Override this for custom growth logic
--- @param ent Entity The drug entity
function DRUG:SV_StartGrowth(ent)
  ent:SetNWBool("IonRP_Drug_Ready", false)
  ent:SetNWInt("IonRP_Drug_GrowthStage", 0)
  
  -- Calculate total stages with randomization
  local baseStages = self.growthTime * 10 -- 0.1 second intervals
  local randomVariation = math.random(-baseStages * 0.1, baseStages * 0.1)
  local totalStages = math.floor(baseStages + randomVariation)
  
  ent.totalGrowthStages = totalStages
  
  timer.Create("IonRP_Drug_Growth_" .. ent:EntIndex(), 0.1, 0, function()
    if not IsValid(ent) then return end
    
    local currentStage = ent:GetNWInt("IonRP_Drug_GrowthStage", 0)
    
    if currentStage < totalStages then
      ent:SetNWInt("IonRP_Drug_GrowthStage", currentStage + 1)
      
      -- Update plant scale
      if IsValid(ent.plant) then
        ent.plant:SetModelScale(currentStage / totalStages)
      end
    else
      -- Growth complete
      timer.Remove("IonRP_Drug_Growth_" .. ent:EntIndex())
      ent:SetNWBool("IonRP_Drug_Ready", true)
      
      if self.glowWhenReady and IsValid(ent.plant) then
        ent.plant:SetColor(self.glowColor)
        ent.plant:SetRenderMode(RENDERMODE_TRANSALPHA)
      end
      
      self:SV_OnGrowthComplete(ent)
    end
  end)
end

--- Called when growth is complete (SERVER)
--- Override this for custom completion logic
--- @param ent Entity The drug entity
function DRUG:SV_OnGrowthComplete(ent)
  -- Default: empty, override in drug definitions
end

--- Called when player harvests the drug (SERVER)
--- Override this for custom harvest rewards
--- @param ent Entity The drug entity
--- @param ply Player The player harvesting
--- @return boolean # Whether harvest was successful
function DRUG:SV_OnHarvest(ent, ply)
  -- Give harvest rewards
  for itemID, amount in pairs(self.harvestRewards) do
    local item = IonRP.Items.List[itemID]
    if item then
      local ownedItem = item:MakeOwnedInstance(ply)
      IonRP.Inventory:AddItem(ply:GetInventory(), ownedItem, amount)
    end
  end
  
  -- Give pickup item if configured
  if self.pickupItem then
    local pickupItem = IonRP.Items.List[self.pickupItem]
    if pickupItem then
      local ownedPickupItem = pickupItem:MakeOwnedInstance(ply)
      IonRP.Inventory:AddItem(ply:GetInventory(), ownedPickupItem, 1)
    end
  end
  
  return true
end

--- Called when player uses the drug entity (SERVER)
--- Override this for custom use behavior
--- @param ent Entity The drug entity
--- @param ply Player The player using
function DRUG:SV_OnUse(ent, ply)
  local isReady = ent:GetNWBool("IonRP_Drug_Ready", false)
  
  if isReady then
    -- Harvest
    if self:SV_OnHarvest(ent, ply) then
      ply:ChatPrint("[IonRP] You harvested a " .. self.name .. "!")
      ent:Remove()
    end
  else
    -- Pick up (not ready yet)
    if self.pickupItem then
      local pickupItem = IonRP.Items.List[self.pickupItem]
      if pickupItem then
        local ownedPickupItem = pickupItem:MakeOwnedInstance(ply)
        IonRP.Inventory:AddItem(ply:GetInventory(), ownedPickupItem, 1)
        ply:ChatPrint("[IonRP] You picked up the " .. self.name)
        ent:Remove()
      end
    else
      -- Allow physics pickup
      ent:SetAngles(ply:GetAngles())
      ply:PickupObject(ent)
    end
  end
end

--- Get growth progress (0.0 to 1.0)
--- @param ent Entity The drug entity
--- @return number # Growth progress percentage
function DRUG:GetGrowthProgress(ent)
  if not IsValid(ent) then return 0 end
  
  local currentStage = ent:GetNWInt("IonRP_Drug_GrowthStage", 0)
  local totalStages = ent.totalGrowthStages or 1
  
  return math.Clamp(currentStage / totalStages, 0, 1)
end

--- Check if drug is ready for harvest
--- @param ent Entity The drug entity
--- @return boolean
function DRUG:IsReady(ent)
  if not IsValid(ent) then return false end
  return ent:GetNWBool("IonRP_Drug_Ready", false)
end

print("[IonRP Drug] Shared drug system loaded")
