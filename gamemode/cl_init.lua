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
-- Inventory
include("inventory/cl_inventory.lua")
-- ATM System
include("atm/sh_atm.lua")
include("atm/cl_atm.lua")
-- Property System
include("property/sh_property.lua")
include("property/cl_property.lua")
include("property/cl_property_shop.lua")
-- NPC System
include("npc/sh_npc.lua")
-- IonSys (Admin Panel)
include("ionsys/cl_ionsys.lua")