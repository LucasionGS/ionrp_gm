--- Simple crafting recipe: Turn sticks into wood planks
local recipe = RECIPE:New("wood_planks", "Wood Planks")
recipe.description = "Craft wood planks from sticks"
recipe.ingredients = {
  [ITEM_STICK.identifier] = 4
}
recipe.result = ITEM_WOOD_PLANKS.identifier
recipe.resultAmount = 1
