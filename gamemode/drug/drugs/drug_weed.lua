--- Weed drug definition for IonRP
--- Growable plant that produces weed items and seeds

DRUG_WEED = DRUG:New("drug_weed", "Weed Plant")

DRUG_WEED.description = "A cannabis plant that grows over time and produces weed when harvested"
DRUG_WEED.baseModel = "models/props_c17/pottery06a.mdl"
DRUG_WEED.plantModel = "models/props/pi_fern.mdl"
DRUG_WEED.growthTime = 300 -- 5 minutes (300 seconds)
DRUG_WEED.glowWhenReady = true
DRUG_WEED.glowColor = Color(20, 200, 0)

-- Item given when picking up non-ready plant
DRUG_WEED.pickupItem = "item_weed_pot"

-- Items given on successful harvest
DRUG_WEED.harvestRewards = {
  ["item_weed"] = 2, -- Give 1-2 weed items (will be randomized in custom harvest)
}

--- Custom harvest logic for weed - gives random seeds
--- @param ent Entity The drug entity
--- @param ply Player The player harvesting
--- @return boolean # Whether harvest was successful
function DRUG_WEED:SV_OnHarvest(ent, ply)
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
  
  -- TODO: Add skill XP when skill system exists
  -- ply:AddSkillXP("weed_expert", 10)
  
  return true
end

print("[IonRP Drug] Weed drug loaded: " .. DRUG_WEED.name)
