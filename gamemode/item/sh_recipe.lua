IonRP.Recipes = IonRP.Recipes or {}

---@type table<string, RECIPE>
IonRP.Recipes.List = IonRP.Recipes.List or {}

--- Recipe class
--- @class RECIPE
RECIPE = {}

--- @type RECIPE
RECIPE.__index = RECIPE

--- The unique identifier for the recipe.
--- @type string
RECIPE.identifier = "generic_recipe"

--- The display name of the recipe.
--- @type string
RECIPE.name = "<No name>"

--- The description of the recipe.
--- @type string
RECIPE.description = "<No description>"

--- The ingredients required for the recipe.
--- @type table<string, number>
RECIPE.ingredients = {}

--- Whether the recipe requires a water source to craft.
--- @type boolean
RECIPE.requireWaterSource = false

--- Whether the recipe requires a heat source to craft.
--- @type boolean
RECIPE.requireHeatSource = false

--- The result of the recipe. This is the identifier of the item produced. (ITEM.identifier)
--- @type string
RECIPE.result = nil

--- The amount of the result item produced by the recipe.
--- @type number
RECIPE.resultAmount = 1

--- Check if a player can craft this recipe.
--- @param ply Player
--- @return boolean, string|nil - True if can craft, false and reason if cannot
function RECIPE:SV_CanCraft(ply)
  if self.requireWaterSource and not IonRP.Environment.IsNearWaterSource(ply:GetPos()) then
    return false, "You need to be near a water source to craft this."
  end

  if self.requireHeatSource and not IonRP.Environment.IsNearHeatSource(ply:GetPos()) then
    return false, "You need to be near a heat source to craft this."
  end

  for ingredient, amount in pairs(self.ingredients) do
    if not ply:HasItem(ingredient, amount) then
      local item = IonRP.Items.Get(ingredient)
      local itemName = item and item.name or ingredient
      return false, "You need " .. amount .. "x " .. itemName .. " to craft this."
    end
  end

  return true
end

--- Craft the recipe for the player, consuming ingredients and adding the result.
--- @param ply Player
--- @return boolean, string|nil - True if crafted, false and reason if failed
function RECIPE:SV_Craft(ply)
  local canCraft, reason = self:SV_CanCraft(ply)
  if not canCraft then
    return false, reason
  end

  for ingredient, amount in pairs(self.ingredients) do
    ply:TakeItem(ingredient, amount)
  end

  if self.result and self:SV_OnCraft(ply) then
    ply:GiveItem(self.result, self.resultAmount)
  end
  return true
end

--- Optional callback after crafting the item.
--- @param ply Player The player who crafted the item.
--- @return boolean # True if the result item should be given, false to prevent it.
function RECIPE:SV_OnCraft(ply)
  -- Optional callback after crafting
  return true
end

--- Create a new recipe and register it.
--- @param identifier string Unique identifier for the recipe.
--- @param name string Display name of the recipe.
--- @return RECIPE
function RECIPE:New(identifier, name)
  local newRecipe = {}
  setmetatable(newRecipe, self)
  self.__index = self
  newRecipe.identifier = identifier
  newRecipe.name = name
  IonRP.Recipes.List[identifier] = newRecipe
  return newRecipe
end

-- Load all recipe definitions
print("┌─────────────────┬──────────────────────────────────────────────────────────────•")
print("│ [IonRP Recipes] │ Loading recipes...")
for _, recipe in ipairs(file.Find("ionrp/gamemode/item/recipes/*.lua", "LUA")) do
  include("recipes/" .. recipe)
  if SERVER then
    AddCSLuaFile("recipes/" .. recipe)
  end
end
print("└─────────────────┴──────────────────────────────────────────────────────────────•")