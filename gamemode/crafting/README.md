# IonRP Crafting System

A comprehensive crafting system for the IonRP gamemode that allows players to combine items from their inventory to create new items.

## Features

- **Recipe-Based Crafting**: Define recipes with required ingredients and resulting items
- **Environmental Requirements**: Recipes can require water sources or heat sources nearby
- **Visual UI**: Modern, intuitive crafting interface matching the IonRP inventory style
- **Real-time Updates**: Shows available ingredients and craftable recipes dynamically
- **Permission System**: Can be extended with permission-based recipe access

## Usage

### For Players

1. **Open Crafting Menu**: Press `F2` or type `/craft` in chat
2. **Browse Recipes**: Scroll through available recipes (craftable recipes shown first)
3. **Check Requirements**: Each recipe shows:
   - Required ingredients with current vs. needed amounts
   - Environmental requirements (water/heat sources)
   - Result item and quantity
4. **Craft Items**: Click the "CRAFT" button on available recipes

### For Developers

#### Creating a Recipe

Create a new file in `gamemode/item/recipes/` with the recipe definition:

```lua
--- Example recipe file: gamemode/item/recipes/my_recipe.lua

local recipe = RECIPE:New("unique_identifier", "Recipe Display Name")

-- Set recipe properties
recipe.description = "A brief description of what this recipe creates"
recipe.ingredients = {
  [ITEM_INGREDIENT_1.identifier] = 2,  -- Needs 2 of ingredient 1
  [ITEM_INGREDIENT_2.identifier] = 1,  -- Needs 1 of ingredient 2
}
recipe.result = ITEM_RESULT.identifier
recipe.resultAmount = 1  -- How many result items to give

-- Optional: Environmental requirements
recipe.requireWaterSource = false  -- Must be near water
recipe.requireHeatSource = false   -- Must be near heat source

-- Optional: Custom crafting logic
function recipe:SV_OnCraft(ply)
  -- Custom logic here
  -- Return true to give the result item, false to prevent it
  return true
end
```

#### Recipe Class Reference

**Core Properties:**
- `identifier` (string): Unique ID for the recipe
- `name` (string): Display name shown in UI
- `description` (string): Brief description of the recipe
- `ingredients` (table): Table of item identifiers -> required quantities
- `result` (string): Item identifier of the crafted result
- `resultAmount` (number): How many result items to give (default: 1)
- `requireWaterSource` (boolean): Must be near water to craft
- `requireHeatSource` (boolean): Must be near heat source to craft

**Methods:**
- `RECIPE:SV_CanCraft(ply)`: Check if player can craft this recipe
- `RECIPE:SV_Craft(ply)`: Execute the crafting (consumes ingredients, gives result)
- `RECIPE:SV_OnCraft(ply)`: Optional callback after successful craft

## File Structure

```
gamemode/
├── crafting/
│   ├── sh_crafting.lua      # Shared utilities and helper functions
│   ├── sv_crafting.lua      # Server-side crafting logic and networking
│   └── cl_crafting.lua      # Client-side UI and rendering
├── environment/
│   └── sh_environment.lua   # Environmental detection (water/heat sources)
└── item/
    └── recipes/
        ├── weed_plant.lua   # Example: Weed growing recipe
        └── wood_planks.lua  # Example: Simple crafting recipe
```

## Network Messages

- `IonRP_OpenCrafting`: Server -> Client - Opens crafting UI
- `IonRP_SyncRecipes`: Server -> Client - Syncs all recipes with craftability status
- `IonRP_RequestCraft`: Client -> Server - Request to craft a recipe
- `IonRP_CraftResult`: Server -> Client - Result of crafting attempt

## Environmental Detection

The system includes environmental detection for special crafting requirements:

### Water Sources
Detected by:
- Being underwater
- Being near water surface (within 100 units)
- Custom water entities (extendable)

### Heat Sources
Detected by:
- Fire entities (`env_fire`)
- Drug production entities (heaters)
- Custom heat source entities (extendable)

Extend detection in `gamemode/environment/sh_environment.lua`.

## UI Customization

Colors and styling are defined in `cl_crafting.lua`:

```lua
IonRP.CraftingUI.Config = {
  RecipeWidth = 300,
  RecipeHeight = 120,
  Colors = {
    Background = Color(25, 25, 35, 250),
    RecipeBackground = Color(35, 35, 45, 220),
    -- ... more colors
  }
}
```

## Integration with Inventory

The crafting system integrates seamlessly with the IonRP inventory system:
- Checks player inventory for ingredients
- Consumes items from inventory when crafting
- Adds result items to inventory
- Updates UI in real-time

## Commands

- `/craft` - Opens the crafting menu

## Future Enhancements

Potential improvements for the crafting system:
- Crafting stations/workbenches for specific recipe types
- Skill-based crafting with experience requirements
- Crafting time with progress bars
- Recipe discovery/unlocking system
- Crafting quality levels (random success rates)
- Batch crafting (craft multiple at once)
- Recipe categories/filtering in UI
