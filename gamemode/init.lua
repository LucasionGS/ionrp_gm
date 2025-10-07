--[[
  IonRP - Server Initialization
--]]
IonRP = IonRP or {}
IonRP.Util = IonRP.Util or {}
-- Send client files to players
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
-- Commands
AddCSLuaFile("commands/sh_commands.lua")
-- Hud
AddCSLuaFile("hud/cl_hud.lua")
-- Interface
AddCSLuaFile("interface/cl_dialog.lua")
AddCSLuaFile("interface/cl_bank.lua")
-- Character
AddCSLuaFile("character/cl_character.lua")
-- Ranks
AddCSLuaFile("ranks/cl_ranks.lua")
-- Scoreboard
AddCSLuaFile("scoreboard/cl_scoreboard.lua")
-- Developer Tools
AddCSLuaFile("developer/cl_model_explorer.lua")
-- Items
AddCSLuaFile("item/sh_item.lua")
-- Jobs
AddCSLuaFile("job/sh_job.lua")
-- Inventory
AddCSLuaFile("inventory/sh_inventory.lua")
AddCSLuaFile("inventory/cl_inventory.lua")
-- IonSys (Admin Panel)
AddCSLuaFile("ionsys/sh_ionsys.lua")
AddCSLuaFile("ionsys/cl_ionsys.lua")

-- Load shared code
include("shared.lua")

-- Load command system
include("commands/sh_commands.lua")

-- Load database
include("database/Database.lua")
include("ranks/sv_ranks_schema.lua")
include("database/sv_schema.lua")

-- Load server modules
include("interface/sv_dialog.lua")
include("interface/sv_bank.lua")
include("ranks/sv_ranks.lua")
include("character/sv_character.lua")
include("developer/sv_model_explorer.lua")

-- Load commands
include("commands/sv_rank_commands.lua")
include("commands/sv_inventory_commands.lua")

-- Items
include("item/sh_item.lua")

-- Jobs
include("job/sh_job.lua")

-- Inventory
include("inventory/sv_inventory.lua")

-- IonSys (Admin Panel)
include("ionsys/sv_ionsys.lua")

function GM:Initialize()
  self.BaseClass.Initialize(self)

  print("[IonRP] Gamemode initialized on server")
end

--[[
  Called when a player first spawns
--]]
function GM:PlayerInitialSpawn(ply)
  -- Set up player on first spawn
  print("[IonRP] Player " .. ply:Nick() .. " has joined the server")
end

-- function GM:PlayerSpawn(ply)
--   self.BaseClass.PlayerSpawn(self, ply)
-- end

--[[
  Initialize the player and their job.
--]]
function GM:PlayerLoadout(ply)
  -- Set player model (required to prevent crashes)
  local job = ply:GetJob()
  if job then
    job:Loadout(ply)
  else
    JOB_CITIZEN:Loadout(ply)
  end

  print("[IonRP] Player " .. ply:Nick() .. " has spawned")

  -- Return true to prevent default weapon loadout
  return true
end

--[[
  Called when a player dies
--]]
function GM:PlayerDeath(victim, inflictor, attacker)
  -- Handle player death
  print("[IonRP] Player " .. victim:Nick() .. " has died")
end
