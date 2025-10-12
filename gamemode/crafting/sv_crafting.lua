--[[
    IonRP Crafting System
    Server-side crafting logic and networking
]]--

include("sh_crafting.lua")

-- Network strings
util.AddNetworkString("IonRP_OpenCrafting")
util.AddNetworkString("IonRP_RequestCraft")
util.AddNetworkString("IonRP_CraftResult")
util.AddNetworkString("IonRP_SyncRecipes")

--- Open crafting menu for player
--- @param ply Player
function IonRP.Crafting.OpenMenu(ply)
  if not IsValid(ply) then return end
  
  -- Send available recipes to client
  local recipes = {}
  for identifier, recipe in pairs(IonRP.Recipes.List) do
    local canCraft, reason = recipe:SV_CanCraft(ply)
    
    table.insert(recipes, {
      identifier = recipe.identifier,
      name = recipe.name,
      description = recipe.description,
      ingredients = recipe.ingredients,
      result = recipe.result,
      resultAmount = recipe.resultAmount,
      requireWaterSource = recipe.requireWaterSource,
      requireHeatSource = recipe.requireHeatSource,
      canCraft = canCraft,
      reason = reason or ""
    })
  end
  
  net.Start("IonRP_SyncRecipes")
    net.WriteTable(recipes)
  net.Send(ply)
  
  -- Tell client to open the UI
  timer.Simple(0.1, function()
    if IsValid(ply) then
      net.Start("IonRP_OpenCrafting")
      net.Send(ply)
    end
  end)
end

--- Handle craft request from client
net.Receive("IonRP_RequestCraft", function(len, ply)
  local recipeIdentifier = net.ReadString()
  
  local recipe = IonRP.Crafting.GetRecipe(recipeIdentifier)
  if not recipe then
    net.Start("IonRP_CraftResult")
      net.WriteBool(false)
      net.WriteString("Invalid recipe")
    net.Send(ply)
    return
  end
  
  local success, reason = recipe:SV_Craft(ply)
  
  net.Start("IonRP_CraftResult")
    net.WriteBool(success)
    net.WriteString(reason or "")
  net.Send(ply)
  
  if success then
    ply:ChatPrint("[IonRP] Crafted: " .. recipe.name)
    
    -- Resync recipes after crafting (ingredients may have changed)
    timer.Simple(0.1, function()
      if IsValid(ply) then
        IonRP.Crafting.OpenMenu(ply)
      end
    end)
  else
    ply:ChatPrint("[IonRP] Failed to craft: " .. (reason or "Unknown error"))
  end
end)

-- Command to open crafting menu
IonRP.Commands.Add("craft", function(activator)
  IonRP.Crafting.OpenMenu(activator)
end, "Open crafting menu")

print("┌──────────────────┬─────────────────────────────────────────────────────────────•")
print("│ [IonRP Crafting] │ Server-side crafting system loaded")
print("└──────────────────┴─────────────────────────────────────────────────────────────•")
