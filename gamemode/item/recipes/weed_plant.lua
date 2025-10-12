local recipe = RECIPE:New("weed_plant", "Weed Plant")
recipe.ingredients = {
  [ITEM_WEED_SEED.identifier] = 1,
  [ITEM_WEED_POT.identifier] = 1
}

recipe.result = ITEM_WEED.identifier