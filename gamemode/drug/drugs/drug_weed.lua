--- Weed drug definition for IonRP
--- Growable plant that produces weed items and seeds

DRUG_WEED = DRUG:New("drug_weed", "Weed Plant")

DRUG_WEED.description = "A cannabis plant that grows over time and produces weed when harvested"
DRUG_WEED.model = "models/props_c17/pottery06a.mdl" -- Pot model

-- Plant-specific properties
DRUG_WEED.customData.plantModel = "models/props/pi_fern.mdl"
DRUG_WEED.customData.growthTime = 300 -- 5 minutes (300 seconds)
DRUG_WEED.customData.glowWhenReady = true
DRUG_WEED.customData.glowColor = Color(20, 200, 0)

--- Initialize weed plant entity
--- @param ent Entity The drug entity
function DRUG_WEED:SV_Initialize(ent)
  -- Call base initialization
  DRUG.SV_Initialize(self, ent)
  
  -- Create plant entity above the pot
  local plant = ents.Create("prop_dynamic")
  plant:SetModel(self.customData.plantModel)
  plant:SetPos(ent:GetPos() + Vector(0, 0, ent:OBBMaxs().z * 0.8))
  plant:SetAngles(ent:GetAngles())
  plant:SetParent(ent)
  plant:Spawn()
  plant:SetModelScale(0) -- Start hidden
  
  ent.plant = plant
  
  -- Start growth process
  self:StartGrowth(ent)
end

--- Start the growth timer for this plant
--- @param ent Entity The drug entity
function DRUG_WEED:StartGrowth(ent)
  self:SetNetworkData(ent, "Ready", false, "Bool")
  self:SetNetworkData(ent, "GrowthStage", 0, "Int")
  
  -- Calculate total stages with randomization (±10%)
  local baseStages = self.customData.growthTime * 10 -- 0.1 second intervals
  local randomVariation = math.random(-baseStages * 0.1, baseStages * 0.1)
  local totalStages = math.floor(baseStages + randomVariation)
  
  ent.totalGrowthStages = totalStages
  
  timer.Create("IonRP_Drug_Growth_" .. ent:EntIndex(), 0.1, 0, function()
    if not IsValid(ent) then return end
    
    local currentStage = self:GetNetworkData(ent, "GrowthStage", "Int", 0)
    
    if currentStage < totalStages then
      self:SetNetworkData(ent, "GrowthStage", currentStage + 1, "Int")
      
      -- Update plant scale
      if IsValid(ent.plant) then
        ent.plant:SetModelScale(currentStage / totalStages)
      end
    else
      -- Growth complete
      timer.Remove("IonRP_Drug_Growth_" .. ent:EntIndex())
      self:SetNetworkData(ent, "Ready", true, "Bool")
      
      -- Make plant glow
      if self.customData.glowWhenReady and IsValid(ent.plant) then
        ent.plant:SetColor(self.customData.glowColor)
        ent.plant:SetRenderMode(RENDERMODE_TRANSALPHA)
      end
    end
  end)
end

--- Handle player use - harvest or pickup
--- @param ent Entity The drug entity
--- @param ply Player The player using
function DRUG_WEED:SV_OnUse(ent, ply)
  local isReady = self:GetNetworkData(ent, "Ready", "Bool", false)
  
  if isReady then
    -- Harvest the plant
    self:Harvest(ent, ply)
  else
    -- Pick up the pot (not ready yet)
    self:Pickup(ent, ply)
  end
end

--- Harvest the weed plant
--- @param ent Entity The drug entity
--- @param ply Player The player harvesting
--- @return boolean # Whether harvest was successful
function DRUG_WEED:Harvest(ent, ply)
  local inv = ply:GetInventory()
  if not inv then return false end
  -- Give weed pot back
  local potItem = IonRP.Items.List["item_weed_pot"]
  if potItem then
    local ownedPot = potItem:MakeOwnedInstance(ply)
    inv:AddItem(ownedPot, 1)
  end
  
  -- Give random weed seeds (0-2)
  local seedCount = math.random(0, 2)
  if seedCount > 0 then
    local seedItem = IonRP.Items.List["item_weed_seed"]
    if seedItem then
      local ownedSeeds = seedItem:MakeOwnedInstance(ply)
      inv:AddItem(ownedSeeds, seedCount)
      ply:ChatPrint("[IonRP] You also got " .. seedCount .. " weed seed(s)!")
    end
  end
  
  -- Give random weed products (1-2)
  local weedCount = math.random(1, 2)
  local weedItem = IonRP.Items.List["item_weed"]
  if weedItem then
    local ownedWeed = weedItem:MakeOwnedInstance(ply)
    inv:AddItem(ownedWeed, weedCount)
  end
  
  ply:ChatPrint("[IonRP] You harvested a " .. self.name .. "!")
  
  -- TODO: Add skill XP when skill system exists
  -- ply:AddSkillXP("weed_expert", 10)
  
  -- Remove entity
  ent:Remove()
  
  return true
end

--- Pick up the weed pot before it's ready
--- @param ent Entity The drug entity
--- @param ply Player The player picking up
function DRUG_WEED:Pickup(ent, ply)
  local inv = ply:GetInventory()
  if not inv then return end
  
  -- Give the pot back
  local potItem = IonRP.Items.List["item_weed_pot"]
  if potItem then
    local ownedPot = potItem:MakeOwnedInstance(ply)
    inv:AddItem(ownedPot, 1)
    ply:ChatPrint("[IonRP] You picked up the weed pot")
  end
  
  ent:Remove()
end

--- Cleanup plant entity when removed
--- @param ent Entity The drug entity
function DRUG_WEED:SV_OnRemove(ent)
  -- Stop growth timer
  timer.Remove("IonRP_Drug_Growth_" .. ent:EntIndex())
  
  -- Remove plant entity
  if IsValid(ent.plant) then
    ent.plant:Remove()
  end
end

--- Get growth progress for UI display
--- @param ent Entity The drug entity
--- @return number # Progress from 0.0 to 1.0
function DRUG_WEED:GetGrowthProgress(ent)
  if not IsValid(ent) then return 0 end
  
  local currentStage = self:GetNetworkData(ent, "GrowthStage", "Int", 0)
  local totalStages = ent.totalGrowthStages or 1
  
  return math.Clamp(currentStage / totalStages, 0, 1)
end

print("[IonRP Drug] Weed drug loaded: " .. DRUG_WEED.name)
