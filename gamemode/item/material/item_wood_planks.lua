--- Wood Planks - Basic building material

ITEM_WOOD_PLANKS = ITEM:New("item_wood_planks", "Wood Planks")
ITEM_WOOD_PLANKS.description = "Processed wooden planks, ready for construction."
ITEM_WOOD_PLANKS.model = "models/props_debris/wood_board04a.mdl"
ITEM_WOOD_PLANKS.weight = 1.5
ITEM_WOOD_PLANKS.size = { 2, 1 }
ITEM_WOOD_PLANKS.stackSize = 50
ITEM_WOOD_PLANKS.type = "material"

print("[IonRP Item] Wood Planks loaded: " .. ITEM_WOOD_PLANKS.name)
