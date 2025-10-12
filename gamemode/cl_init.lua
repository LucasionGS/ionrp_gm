--[[
  IonRP - Client Initialization
--]]
IonRP = IonRP or {}
IonRP.Util = IonRP.Util or {}
-- Load shared code
include("shared.lua")

-- Load command system
include("commands/sh_commands.lua")

--[[
  Called when the gamemode is loaded on the client
--]]
function GM:Initialize()
  print("[IonRP] Gamemode initialized on client")
end

-- Hud
include("hud/cl_hud.lua")
-- Interface
include("interface/cl_dialog.lua")
include("interface/cl_bank.lua")
-- Character
include("character/cl_character.lua")
-- Ranks
include("ranks/cl_ranks.lua")
-- Scoreboard
include("scoreboard/cl_scoreboard.lua")
-- Developer Tools
include("developer/cl_model_explorer.lua")
-- Items
include("item/sh_item.lua")
-- Jobs
include("job/sh_job.lua")
-- Vehicles
include("vehicle/sh_vehicle.lua")
include("vehicle/cl_vehicle_interaction.lua")
-- Inventory
include("inventory/cl_inventory.lua")
-- Shop System
include("shop/sh_shop.lua")
include("shop/cl_shop.lua")
-- ATM System
include("atm/sh_atm.lua")
include("atm/cl_atm.lua")
-- Property System
include("property/sh_property.lua")
include("property/cl_property.lua")
include("property/cl_property_shop.lua")
-- NPC System
include("npc/sh_npc.lua")
-- Physgun Restrictions
include("physgun/sh_physgun.lua")
-- Garage System
include("garage/sh_garage.lua")
include("garage/cl_garage.lua")
include("garage/cl_garage_vehicles.lua")
-- License System
include("license/sh_license.lua")
include("license/cl_license.lua")
-- Buddy System
include("buddy/sh_buddy.lua")
include("buddy/cl_buddy.lua")
-- Drug System
include("drug/sh_drug.lua")
include("drug/cl_drug.lua")
-- Load drug definitions
for _, drugFile in ipairs(file.Find("ionrp/gamemode/drug/drugs/*.lua", "LUA")) do
  include("drug/drugs/" .. drugFile)
end
-- IonSys (Admin Panel)
include("ionsys/cl_ionsys.lua")