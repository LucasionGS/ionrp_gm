--- Weed Pot - Used to plant weed seeds

ITEM_WEED_POT = ITEM:New("item_weed_pot", "Weed Pot")
ITEM_WEED_POT.description = "A ceramic pot used for planting weed seeds. Place it down and add a seed to start growing."
ITEM_WEED_POT.model = "models/props_c17/pottery06a.mdl"
ITEM_WEED_POT.weight = 2.0
ITEM_WEED_POT.size = { 2, 2 }
ITEM_WEED_POT.stackSize = 10
ITEM_WEED_POT.type = "material"
ITEM_WEED_POT.price = 50

--- Use the pot to spawn a drug entity (requires weed seed)
--- @param ply Player
--- @return boolean
function ITEM_WEED_POT:SV_Use(ply)
  if not IsValid(ply) then return false end
  
  -- Check if player has a weed seed
  local inventory = ply:GetInventory()
  if not inventory then return false end
  
  local hasSeed = false
  for _, slot in pairs(inventory.slots) do
    print("[IonRP Item] Checking inventory slot:", slot)
    if slot.item and slot.item.identifier == "item_weed_seed" and slot.quantity > 0 then
      hasSeed = true
      break
    end
  end
  
  if not hasSeed then
    ply:ChatPrint("[IonRP] You need a weed seed to plant!")
    return false
  end
  
  -- Spawn the weed plant in front of the player
  local trace = util.TraceLine({
    start = ply:EyePos(),
    endpos = ply:EyePos() + ply:GetAimVector() * 100,
    filter = ply
  })
  
  local spawnPos = trace.HitPos + trace.HitNormal * 5
  local spawnAng = ply:EyeAngles()
  spawnAng.pitch = 0
  spawnAng.roll = 0
  
  -- Spawn the drug entity
  local drugEnt = IonRP.Drug:Spawn("drug_weed", spawnPos, spawnAng, true)
  
  if IsValid(drugEnt) then
    -- Remove the seed from inventory
    local seedItem = IonRP.Items.List["item_weed_seed"]
    if seedItem then
      local ownedSeed = seedItem:MakeOwnedInstance(ply)
      IonRP.Inventory:RemoveItem(inventory, ownedSeed, 1)
    end
    
    ply:ChatPrint("[IonRP] You planted a weed seed! Wait for it to grow...")
    return true -- Consume the pot (it's now the drug entity)
  end
  
  return false
end

print("[IonRP Item] Weed Pot loaded: " .. ITEM_WEED_POT.name)
