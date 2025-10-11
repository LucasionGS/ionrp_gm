--[[
    Physgun Restrictions System - Shared
    
    Controls what entities can be picked up with the physgun.
    - Only players with devmode enabled can move all props
    - Whitelisted models can be moved by anyone
    - All other props/entities are restricted
    
    Features:
    - Model whitelist for freely movable props
    - Devmode bypass for developers
    - Prevents movement of static/important entities
]]--

IonRP.Physgun = IonRP.Physgun or {}

--- List of prop models that anyone can move with the physgun
--- Add models here that should be freely movable by all players
--- @type table<string, boolean>
IonRP.Physgun.WhitelistedModels = {
  -- Example props
  ["models/props_c17/furniturechair001a.mdl"] = true,
  ["models/props_c17/furnituretable001a.mdl"] = true,
  ["models/props_c17/furnituretable002a.mdl"] = true,
  ["models/props_interiors/furniture_chair01a.mdl"] = true,
  ["models/props_interiors/furniture_desk01a.mdl"] = true,
  
  -- Barrels and crates (common movable objects)
  ["models/props_c17/oildrum001.mdl"] = true,
  ["models/props_c17/oildrum001_explosive.mdl"] = true,
  ["models/props_junk/wood_crate001a.mdl"] = true,
  ["models/props_junk/wood_crate002a.mdl"] = true,
  
  -- Add more models as needed
}

--- Check if a model is whitelisted for physgun pickup
--- @param model string The model path
--- @return boolean # True if the model is whitelisted
function IonRP.Physgun:IsModelWhitelisted(model)
  if not model then return false end
  return self.WhitelistedModels[model] == true
end

--- Add a model to the whitelist
--- @param model string The model path
function IonRP.Physgun:AddWhitelistedModel(model)
  if not model then return end
  self.WhitelistedModels[model] = true
  print("[IonRP Physgun] Added whitelisted model: " .. model)
end

--- Remove a model from the whitelist
--- @param model string The model path
function IonRP.Physgun:RemoveWhitelistedModel(model)
  if not model then return end
  self.WhitelistedModels[model] = nil
  print("[IonRP Physgun] Removed whitelisted model: " .. model)
end

--- Get list of all whitelisted models
--- @return table<string, boolean> # Table of whitelisted models
function IonRP.Physgun:GetWhitelistedModels()
  return self.WhitelistedModels
end

print("[IonRP Physgun] Shared module loaded")
