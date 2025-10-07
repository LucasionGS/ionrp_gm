IonRP.Character = IonRP.Character or {}

-- Available character models
IonRP.Character.Models = {
  Male = {
    "male_01",
    "male_02",
    "male_03",
    "male_04",
    "male_05",
    "male_06",
    "male_07",
    "male_08",
    "male_09",
  },
  Female = {
    "female_01",
    "female_02",
    "female_03",
    "female_04",
    "female_05",
    "female_06",
  }
}

-- Player meta
---@class Player
local plyMeta = FindMetaTable("Player")

-- Get the desired model for the player
--- @return string
function plyMeta:GetDesiredModel()
  return self:GetNWString("IonRP_DesiredModel", "male_01")
end