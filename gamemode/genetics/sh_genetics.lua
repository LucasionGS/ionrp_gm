--[[
    IonRP Genetics System - Shared
    Character progression system with 5 genetic attributes
]]--

IonRP.Genetics = IonRP.Genetics or {}

--- Genetic types
IonRP.Genetics.Types = {
  STRENGTH = "strength",
  INTELLIGENCE = "intelligence",
  DEXTERITY = "dexterity",
  INFLUENCE = "influence",
  PERCEPTION = "perception"
}

--- Genetic configuration
IonRP.Genetics.Config = {
  MAX_LEVEL = 5,
  MIN_LEVEL = 0,
  
  -- Display information for each genetic type
  Info = {
    strength = {
      name = "Strength",
      description = "Increases physical power and carrying capacity",
      color = Color(200, 80, 60, 255),
      icon = "💪" -- Can be replaced with material path
    },
    intelligence = {
      name = "Intelligence",
      description = "Improves crafting efficiency and hacking abilities",
      color = Color(100, 150, 255, 255),
      icon = "🧠"
    },
    dexterity = {
      name = "Dexterity",
      description = "Enhances movement speed and lockpicking skills",
      color = Color(255, 140, 60, 255),
      icon = "⚡"
    },
    influence = {
      name = "Influence",
      description = "Affects purchase prices from meat vendors",
      color = Color(255, 200, 80, 255),
      icon = "💰"
    },
    perception = {
      name = "Perception",
      description = "Improves awareness and detection range",
      color = Color(80, 200, 150, 255),
      icon = "👁️"
    }
  }
}

--- @class GeneticsData
--- @field strength number
--- @field intelligence number
--- @field dexterity number
--- @field influence number
--- @field perception number
--- @field availablePoints number

--- Create new genetics data structure
--- @return GeneticsData
function IonRP.Genetics.New()
  return {
    strength = 0,
    intelligence = 0,
    dexterity = 0,
    influence = 0,
    perception = 0,
    availablePoints = 0
  }
end

--- Validate genetics data
--- @param data GeneticsData
--- @return boolean
function IonRP.Genetics.Validate(data)
  if not data then return false end
  
  local types = {"strength", "intelligence", "dexterity", "influence", "perception"}
  
  for _, gType in ipairs(types) do
    local level = data[gType]
    if not level or level < IonRP.Genetics.Config.MIN_LEVEL or level > IonRP.Genetics.Config.MAX_LEVEL then
      return false
    end
  end
  
  if not data.availablePoints or data.availablePoints < 0 then
    return false
  end
  
  return true
end

--- Get total points spent
--- @param data GeneticsData
--- @return number
function IonRP.Genetics.GetTotalSpent(data)
  return (data.strength or 0) + (data.intelligence or 0) + (data.dexterity or 0) + 
         (data.influence or 0) + (data.perception or 0)
end

--- Check if can upgrade a genetic type
--- @param data GeneticsData
--- @param gType string
--- @return boolean
function IonRP.Genetics.CanUpgrade(data, gType)
  if not data or not gType then return false end
  if data.availablePoints <= 0 then return false end
  
  local currentLevel = data[gType] or 0
  return currentLevel < IonRP.Genetics.Config.MAX_LEVEL
end

print("[IonRP Genetics] Shared genetics system loaded")
