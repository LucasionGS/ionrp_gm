--- Weed Seed - Used to grow weed plants

ITEM_WEED_SEED = ITEM:New("item_weed_seed", "Weed Seed")
ITEM_WEED_SEED.description = "A cannabis seed. Use with a pot to grow a weed plant."
ITEM_WEED_SEED.model = "models/props_lab/jar01b.mdl"
ITEM_WEED_SEED.weight = 0.1
ITEM_WEED_SEED.size = { 1, 1 }
ITEM_WEED_SEED.stackSize = 50
ITEM_WEED_SEED.type = "material"

print("[IonRP Item] Weed Seed loaded: " .. ITEM_WEED_SEED.name)
