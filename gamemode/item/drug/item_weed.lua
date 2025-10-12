--- Weed - Final product from harvesting weed plants

ITEM_WEED = ITEM:New("item_weed", "Weed")
ITEM_WEED.description = "Harvested cannabis. Can be sold or used for... purposes."
ITEM_WEED.model = "models/props_lab/bindergreen.mdl"
ITEM_WEED.weight = 0.5
ITEM_WEED.size = { 1, 1 }
ITEM_WEED.stackSize = 100
ITEM_WEED.type = "drug"

--- Optional: Use the weed for effects
--- @param ply Player
--- @return boolean
function ITEM_WEED:SV_Use(ply)
  if not IsValid(ply) then return false end
  
  -- TODO: Add drug effects when effect system exists
  ply:ChatPrint("[IonRP] You consumed some weed... (effects coming soon)")
  
  return true -- Consume the item
end

print("[IonRP Item] Weed loaded: " .. ITEM_WEED.name)
