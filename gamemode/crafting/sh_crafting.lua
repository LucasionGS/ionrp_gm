--[[
    IonRP Crafting System
    Shared crafting utilities
]]--

IonRP.Crafting = IonRP.Crafting or {}

--- Get a recipe by identifier
--- @param identifier string
--- @return RECIPE|nil
function IonRP.Crafting.GetRecipe(identifier)
  return IonRP.Recipes.List[identifier]
end

--- Get all available recipes
--- @return table<string, RECIPE>
function IonRP.Crafting.GetAllRecipes()
  return IonRP.Recipes.List
end

--- Get recipes that a player can currently craft
--- @param ply Player
--- @return table<string, RECIPE>
function IonRP.Crafting.GetCraftableRecipes(ply)
  local craftable = {}
  
  for identifier, recipe in pairs(IonRP.Recipes.List) do
    local canCraft, _ = recipe:SV_CanCraft(ply)
    if canCraft then
      craftable[identifier] = recipe
    end
  end
  
  return craftable
end

--- Create a simple IonRP.Items.Get function if it doesn't exist
--- @param identifier string
--- @return ITEM|nil
function IonRP.Items.Get(identifier)
  return IonRP.Items.List[identifier]
end
