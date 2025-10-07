--[[
  IonRP - Server Initialization
--]]
IonRP = IonRP or {}
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

-- Items
include("item/sh_item.lua")

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

--[[
  Called when a player spawns
--]]
function GM:PlayerSpawn(ply)
  -- Reset player state
  self.BaseClass.PlayerSpawn(self, ply)

  -- Set player model (required to prevent crashes)
  ply:SetModel("models/player/group01/male_01.mdl")

  -- Give default weapons
  ply:Give("weapon_pistol")
  ply:Give("weapon_physcannon")

  -- local startingMoney = GetConVar("ionrp_starting_money"):GetInt()
  -- ply:SetWallet(startingMoney)

  print("[IonRP] Player " .. ply:Nick() .. " has spawned")
end

--[[
  Called to give players their weapons
--]]
function GM:PlayerLoadout(ply)
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
