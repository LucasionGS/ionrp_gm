--[[
    Physgun Restrictions System - Server
    
    Implements physgun pickup restrictions:
    - Devmode users can pick up everything
    - Non-devmode users can only pick up whitelisted models
    - Static props and important entities are protected
]]--

if not SERVER then return end

--- Hook: Control physgun pickup
--- Returns false to allow pickup, true to deny
hook.Add("PhysgunPickup", "IonRP_Physgun_Restrictions", function(ply, ent)
  if not IsValid(ply) or not IsValid(ent) then return false end
  
  -- Allow devmode users to pick up anything
  if ply:IsDevMode() then
    return true -- Allow pickup
  end
  
  -- Get entity class and model
  local entClass = ent:GetClass()
  local entModel = ent:GetModel()
  
  -- Always block pickup of certain entity types
  local blockedClasses = {
    ["prop_door_rotating"] = true,
    ["func_door"] = true,
    ["func_door_rotating"] = true,
    ["player"] = true,
    ["npc_*"] = true, -- Block all NPCs
  }
  
  -- Check if class is blocked
  if blockedClasses[entClass] then
    -- ply:ChatPrint("[IonRP] You cannot pick up this entity!")
    return false -- Deny pickup
  end
  
  -- Check if it's an NPC (wildcard check)
  if string.StartsWith(entClass, "npc_") then
    -- ply:ChatPrint("[IonRP] You cannot pick up NPCs!")
    return false -- Deny pickup
  end
  
  -- Check for IonRP specific entities
  local ionrpEntityType = ent:GetNWString("EntityType", "")
  if ionrpEntityType ~= "" then
    -- These are IonRP system entities (ATMs, properties, etc.)
    -- ply:ChatPrint("[IonRP] This entity is protected! Use devmode to move it.")
    return false -- Deny pickup
  end
  
  -- Check if entity is a prop
  if entClass == "prop_physics" or entClass == "prop_physics_multiplayer" then
    -- Check if model is whitelisted
    if entModel and IonRP.Physgun:IsModelWhitelisted(entModel) then
      return true -- Allow pickup
    else
      -- Not whitelisted, deny pickup
      -- ply:ChatPrint("[IonRP] This prop is not whitelisted! Use devmode to move it.")
      return false -- Deny pickup
    end
  end
  
  -- For all other entities, block by default unless devmode
  return false -- Deny pickup
end)

--- Hook: Control physgun drop (optional - can add restrictions here too)
hook.Add("PhysgunDrop", "IonRP_Physgun_Drop", function(ply, ent)
  -- Currently no restrictions on dropping
  -- Could add freeze/unfreeze restrictions here if needed
end)

--- Hook: Prevent physgun damage to props
hook.Add("OnPhysgunFreeze", "IonRP_Physgun_Freeze", function(weapon, phys, ent, ply)
  -- Allow freezing if player can pick it up
  -- The PhysgunPickup hook already handles permissions
  return false
end)

--- Command: Add model to whitelist
IonRP.Commands.Add("physgun_whitelist_add", function(activator, args, rawArgs)
  if not activator:HasPermission("developer") then
    activator:ChatPrint("[IonRP] You don't have permission to modify the physgun whitelist!")
    return
  end
  
  local model = rawArgs
  
  if not model or model == "" then
    activator:ChatPrint("[IonRP] Usage: /physgun_whitelist_add <model/path>")
    activator:ChatPrint("[IonRP] Example: /physgun_whitelist_add models/props_c17/chair_office01a.mdl")
    return
  end
  
  -- Validate model exists
  if not file.Exists(model, "GAME") then
    activator:ChatPrint("[IonRP] Model file not found: " .. model)
    return
  end
  
  IonRP.Physgun:AddWhitelistedModel(model)
  activator:ChatPrint("[IonRP] Added model to physgun whitelist: " .. model)
end, "Add a model to the physgun whitelist", "developer")

--- Command: Remove model from whitelist
IonRP.Commands.Add("physgun_whitelist_remove", function(activator, args, rawArgs)
  if not activator:HasPermission("developer") then
    activator:ChatPrint("[IonRP] You don't have permission to modify the physgun whitelist!")
    return
  end
  
  local model = rawArgs
  
  if not model or model == "" then
    activator:ChatPrint("[IonRP] Usage: /physgun_whitelist_remove <model/path>")
    return
  end
  
  IonRP.Physgun:RemoveWhitelistedModel(model)
  activator:ChatPrint("[IonRP] Removed model from physgun whitelist: " .. model)
end, "Remove a model from the physgun whitelist", "developer")

--- Command: List whitelisted models
IonRP.Commands.Add("physgun_whitelist_list", function(activator, args, rawArgs)
  if not activator:HasPermission("developer") then
    activator:ChatPrint("[IonRP] You don't have permission to view the physgun whitelist!")
    return
  end
  
  local models = IonRP.Physgun:GetWhitelistedModels()
  local count = 0
  
  activator:ChatPrint("[IonRP] Physgun Whitelisted Models:")
  
  for model, _ in pairs(models) do
    count = count + 1
    activator:ChatPrint("  " .. count .. ". " .. model)
  end
  
  if count == 0 then
    activator:ChatPrint("  No models whitelisted")
  end
end, "List all physgun whitelisted models", "developer")

--- Command: Check if looking at entity is whitelisted
IonRP.Commands.Add("physgun_check", function(activator, args, rawArgs)
  local trace = activator:GetEyeTrace()
  local ent = trace.Entity
  
  if not IsValid(ent) then
    activator:ChatPrint("[IonRP] You're not looking at an entity!")
    return
  end
  
  local model = ent:GetModel()
  local class = ent:GetClass()
  local ionrpType = ent:GetNWString("EntityType", "")
  
  activator:ChatPrint("[IonRP] Entity Info:")
  activator:ChatPrint("  Class: " .. class)
  activator:ChatPrint("  Model: " .. (model or "None"))
  
  if ionrpType ~= "" then
    activator:ChatPrint("  IonRP Type: " .. ionrpType)
  end
  
  if model and IonRP.Physgun:IsModelWhitelisted(model) then
    activator:ChatPrint("  Status: WHITELISTED (anyone can pick up)")
  else
    activator:ChatPrint("  Status: RESTRICTED (devmode required)")
  end
  
  if activator:IsDevMode() then
    activator:ChatPrint("  Your Status: DEVMODE ENABLED (can pick up)")
  else
    activator:ChatPrint("  Your Status: DEVMODE DISABLED (limited pickup)")
  end
end, "Check if the entity you're looking at is whitelisted for physgun", nil)

print("[IonRP Physgun] Server module loaded")
