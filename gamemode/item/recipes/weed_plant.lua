local recipe = RECIPE:New("weed_plant", "Weed Plant")
recipe.ingredients = {
  [ITEM_WEED_SEED.identifier] = 1,
  [ITEM_WEED_POT.identifier] = 1
}

-- recipe.result = ITEM_WEED.identifier

function recipe:SV_OnCraft(ply)
  -- Spawn the weed plant in front of the player
  local trace = util.TraceLine({
    start = ply:EyePos(),
    endpos = ply:EyePos() + ply:GetAimVector() * 100,
    filter = ply
  })
  
  local spawnPos = trace.HitPos + trace.HitNormal * 5
  local spawnAng = ply:EyeAngles()
  spawnAng.pitch = 0
  spawnAng.roll = 0
  
  -- Spawn the drug entity
  local drugEnt = IonRP.Drug:Spawn("drug_weed", spawnPos, spawnAng)
  
  -- Give the pot item back to the player (not consumed)
  ply:GiveItem(ITEM_WEED_POT.identifier)
  
  return true
end