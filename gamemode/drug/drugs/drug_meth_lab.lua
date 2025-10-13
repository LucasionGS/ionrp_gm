--- Meth Lab drug definition for IonRP
--- Complex multi-stage production requiring ingredients and interaction

DRUG_METH_LAB = DRUG:New("drug_meth_lab", "Meth Lab")

DRUG_METH_LAB.description = "A portable meth cooking station. Requires chemicals and careful monitoring."
DRUG_METH_LAB.model = "models/props_c17/FurnitureStove001a.mdl"

-- Meth lab specific properties
DRUG_METH_LAB.customData.cookTime = 120 -- 2 minutes per batch
DRUG_METH_LAB.customData.requiredIngredients = {
  ["item_chemical_a"] = 2,  -- Placeholder items
  ["item_chemical_b"] = 1,
}
DRUG_METH_LAB.customData.explosionChance = 0.05 -- 5% chance to explode if neglected
DRUG_METH_LAB.customData.outputItem = "item_meth" -- Placeholder
DRUG_METH_LAB.customData.outputAmount = 3

--- Initialize meth lab entity
--- @param ent Entity The drug entity
function DRUG_METH_LAB:SV_Initialize(ent)
  -- Call base initialization
  DRUG.SV_Initialize(self, ent)
  
  -- Set initial state
  self:SetNetworkData(ent, "State", "idle", "String") -- States: idle, cooking, ready
  self:SetNetworkData(ent, "CookProgress", 0, "Float") -- 0.0 to 1.0
  self:SetNetworkData(ent, "Temperature", 0, "Int") -- 0 to 100
  
  -- Add glow effect
  local glow = ents.Create("env_sprite")
  glow:SetKeyValue("model", "sprites/redglow1.vmt")
  glow:SetKeyValue("scale", "0.2")
  glow:SetKeyValue("rendermode", "5")
  glow:SetKeyValue("rendercolor", "255 50 0")
  glow:SetPos(ent:GetPos() + Vector(0, 0, 20))
  glow:SetParent(ent)
  glow:Spawn()
  glow:Activate()
  
  ent.glowSprite = glow
end

--- Handle player use - different actions based on state
--- @param ent Entity The drug entity
--- @param ply Player The player using
function DRUG_METH_LAB:SV_OnUse(ent, ply)
  local state = self:GetNetworkData(ent, "State", "String", "idle")
  
  if state == "idle" then
    -- Try to start cooking
    self:TryStartCooking(ent, ply)
  elseif state == "cooking" then
    -- Show progress
    local progress = self:GetNetworkData(ent, "CookProgress", "Float", 0)
    ply:ChatPrint(string.format("[IonRP] Meth lab is cooking... %.0f%% complete", progress * 100))
  elseif state == "ready" then
    -- Collect the product
    self:CollectProduct(ent, ply)
  end
end

--- Try to start cooking process
--- @param ent Entity The drug entity
--- @param ply Player The player
function DRUG_METH_LAB:TryStartCooking(ent, ply)
  local inv = ply:GetInventory()
  if not inv then 
    ply:ChatPrint("[IonRP] You don't have an inventory!")
    return 
  end
  
  -- Check for ingredients (example - these items don't exist yet)
  -- In a real implementation, you'd check for actual chemical items
  ply:ChatPrint("[IonRP] Meth lab cooking feature not fully implemented yet.")
  ply:ChatPrint("[IonRP] This would require chemical items and a multi-stage process.")
  
  -- Example of how it would work:
  -- for itemID, amount in pairs(self.customData.requiredIngredients) do
  --   if not ply:HasItem(itemID, amount) then
  --     ply:ChatPrint("[IonRP] You need " .. amount .. "x " .. itemID)
  --     return
  --   end
  -- end
  
  -- Consume ingredients and start cooking
  -- self:StartCooking(ent, ply)
end

--- Start the cooking process
--- @param ent Entity The drug entity
--- @param ply Player The player who started it
function DRUG_METH_LAB:StartCooking(ent, ply)
  self:SetNetworkData(ent, "State", "cooking", "String")
  self:SetNetworkData(ent, "CookProgress", 0, "Float")
  
  ent.cookingPlayer = ply -- Track who's cooking
  
  ply:ChatPrint("[IonRP] Meth lab started cooking! Don't leave it unattended...")
  
  -- Start cooking timer
  timer.Create("IonRP_MethLab_Cook_" .. ent:EntIndex(), 1, self.customData.cookTime, function()
    if not IsValid(ent) then return end
    
    local progress = self:GetNetworkData(ent, "CookProgress", "Float", 0)
    progress = progress + (1 / self.customData.cookTime)
    
    self:SetNetworkData(ent, "CookProgress", progress, "Float")
    
    -- Random temperature fluctuation
    local temp = math.random(80, 100)
    self:SetNetworkData(ent, "Temperature", temp, "Int")
    
    -- Check for explosion (random chance if player is too far)
    if IsValid(ent.cookingPlayer) then
      local dist = ent:GetPos():Distance(ent.cookingPlayer:GetPos())
      if dist > 500 and math.random() < self.customData.explosionChance then
        self:Explode(ent)
        return
      end
    end
    
    -- Check if done
    if progress >= 1.0 then
      timer.Remove("IonRP_MethLab_Cook_" .. ent:EntIndex())
      self:SetNetworkData(ent, "State", "ready", "String")
      
      if IsValid(ent.cookingPlayer) then
        ent.cookingPlayer:ChatPrint("[IonRP] Meth lab finished cooking! Collect your product.")
      end
    end
  end)
end

--- Explode the meth lab
--- @param ent Entity The drug entity
function DRUG_METH_LAB:Explode(ent)
  local pos = ent:GetPos()
  
  -- Create explosion effect
  local effectdata = EffectData()
  effectdata:SetOrigin(pos)
  util.Effect("Explosion", effectdata)
  
  -- Deal damage
  util.BlastDamage(ent, ent, pos, 200, 100)
  
  -- Notify nearby players
  for _, ply in ipairs(player.GetAll()) do
    if ply:GetPos():Distance(pos) < 1000 then
      ply:ChatPrint("[IonRP] A meth lab exploded nearby!")
    end
  end
  
  -- Remove entity
  ent:Remove()
end

--- Collect the finished product
--- @param ent Entity The drug entity
--- @param ply Player The player collecting
function DRUG_METH_LAB:CollectProduct(ent, ply)
  local inv = ply:GetInventory()
  if not inv then return end
  
  -- This would give the meth item when it exists
  ply:ChatPrint("[IonRP] You collected the meth (item not implemented yet)")
  
  -- Reset to idle state for next cook
  self:SetNetworkData(ent, "State", "idle", "String")
  self:SetNetworkData(ent, "CookProgress", 0, "Float")
  
  -- Example of how it would work:
  -- local methItem = IonRP.Items.List[self.customData.outputItem]
  -- if methItem then
  --   inv:AddItem(methItem:MakeOwnedInstance(ply), self.customData.outputAmount)
  -- end
end

--- Think function - monitor temperature, show effects
--- @param ent Entity The drug entity
function DRUG_METH_LAB:SV_Think(ent)
  local state = self:GetNetworkData(ent, "State", "String", "idle")
  
  if state == "cooking" then
    -- Update glow based on temperature
    local temp = self:GetNetworkData(ent, "Temperature", "Int", 0)
    
    if IsValid(ent.glowSprite) then
      -- Scale glow intensity with temperature
      local scale = 0.1 + (temp / 100) * 0.3
      ent.glowSprite:SetKeyValue("scale", tostring(scale))
    end
  end
end

--- Cleanup on removal
--- @param ent Entity The drug entity
function DRUG_METH_LAB:SV_OnRemove(ent)
  -- Stop cooking timer
  timer.Remove("IonRP_MethLab_Cook_" .. ent:EntIndex())
  
  -- Remove glow sprite
  if IsValid(ent.glowSprite) then
    ent.glowSprite:Remove()
  end
end

print("[IonRP Drug] Meth Lab drug loaded: " .. DRUG_METH_LAB.name .. " (example)")
