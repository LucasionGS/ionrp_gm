--[[
    Shopkeeper NPC
    Sells items to players
]]--

local NPC_SHOPKEEPER = NPC:New("npc_shopkeeper", "Shopkeeper")
NPC_SHOPKEEPER.description = "A friendly merchant who sells various items"
NPC_SHOPKEEPER.model = "models/player/group01/male_07.mdl"
NPC_SHOPKEEPER.category = "Commerce"
NPC_SHOPKEEPER.health = 100
NPC_SHOPKEEPER.canBeKilled = true
NPC_SHOPKEEPER.friendly = false

if SERVER then
  --- Called when a player uses the shopkeeper
  --- @param ply Player The player who used the NPC
  function NPC_SHOPKEEPER:OnUse(ply, npcInstance)
    -- Show shop menu options
    
    IonRP.Shop:OpenShop(ply, "general_store")
  end
  
  --- Called when the shopkeeper spawns
  function NPC_SHOPKEEPER:OnSpawn(npcInstance)
    print("[IonRP NPCs] Shopkeeper spawned: " .. npcInstance:GetName())
  end
end
