--[[
    Banker NPC
    Provides banking services to players
]]--

local NPC_BANKER = NPC:New("npc_banker", "Banker")
NPC_BANKER.description = "A professional banker who manages your finances"
NPC_BANKER.model = "models/player/group01/male_09.mdl"
NPC_BANKER.category = "Commerce"
NPC_BANKER.health = 100
NPC_BANKER.canBeKilled = false
NPC_BANKER.friendly = true

if SERVER then
  --- Called when a player uses the banker
  --- @param ply Player The player who used the NPC
  function NPC_BANKER:OnUse(ply, npcInstance)
    -- IonRP.Bank:OpenMenu(ply)
    IonRP.PropertyShop:OpenForPlayer(ply)
  end
  
  --- Called when the banker spawns
  function NPC_BANKER:OnSpawn(npcInstance)
    print("[IonRP NPCs] Banker spawned: " .. npcInstance:GetName())
  end
end
