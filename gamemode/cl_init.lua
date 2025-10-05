--[[
  IonRP - Client Initialization
--]]
IonRP = IonRP or {}
-- Load shared code
include("shared.lua")

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
