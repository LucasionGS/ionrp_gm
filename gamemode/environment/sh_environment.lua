--[[
    IonRP Environment System
    Shared utilities for detecting environmental conditions
]]--

IonRP.Environment = IonRP.Environment or {}

if SERVER then
  --- Check if a position is near a water source
  --- @param pos Vector Position to check
  --- @param range number|nil Maximum range to check (default: 100)
  --- @return boolean
  function IonRP.Environment.IsNearWaterSource(pos, range)
    range = range or 100
    
    -- Check if position is underwater
    local contents = util.PointContents(pos)
    if bit.band(contents, CONTENTS_WATER) ~= 0 then
      return true
    end
    
    -- TODO: Could also check for water entities, sinks, etc.
    -- For now, just check if underwater or near water surface
    local traceDown = util.TraceLine({
      start = pos,
      endpos = pos - Vector(0, 0, range),
      mask = MASK_WATER
    })
    
    if traceDown.Hit and util.PointContents(traceDown.HitPos) == CONTENTS_WATER then
      return true
    end
    
    return false
  end
  
  --- Check if a position is near a heat source
  --- @param pos Vector Position to check
  --- @param range number|nil Maximum range to check (default: 150)
  --- @return boolean
  function IonRP.Environment.IsNearHeatSource(pos, range)
    range = range or 150
    
    -- Find all entities near the position
    local nearbyEnts = ents.FindInSphere(pos, range)
    
    for _, ent in ipairs(nearbyEnts) do
      if not IsValid(ent) then continue end
      
      local class = ent:GetClass()
      
      -- Check for common heat source entities
      if class == "env_fire" or 
         class == "point_spotlight" or
         string.find(class, "fire") or
         string.find(class, "flame") or
         string.find(class, "stove") or
         string.find(class, "oven") then
        return true
      end
      
      -- Check for drug production entities (they often have heat)
      if string.StartsWith(class, "ionrp_drug_") then
        return true
      end
    end
    
    -- TODO: Could also check for specific map entities, props with "stove" in model, etc.
    
    return false
  end
end

print("┌────────────────────┬───────────────────────────────────────────────────────────•")
print("│ [IonRP Environment] │ Environment detection system loaded")
print("└────────────────────┴───────────────────────────────────────────────────────────•")
