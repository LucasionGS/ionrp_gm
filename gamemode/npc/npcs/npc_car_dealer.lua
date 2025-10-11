--[[
    Car Dealer NPC
    Sells vehicles to players
]] --

local NPC_CAR_DEALER = NPC:New("npc_car_dealer", "Car Dealer")
NPC_CAR_DEALER.description = "A professional car dealer who can help you find your dream vehicle"
NPC_CAR_DEALER.model = "models/player/group01/male_04.mdl"
NPC_CAR_DEALER.category = "Commerce"
NPC_CAR_DEALER.health = 100
NPC_CAR_DEALER.canBeKilled = true
NPC_CAR_DEALER.friendly = true

if SERVER then
  --- Called when a player uses the car dealer
  --- @param ply Player The player who used the NPC
  function NPC_CAR_DEALER:OnUse(ply, npcInstance)
    -- Open the vehicle shop
    IonRP.VehicleShop:OpenForPlayer(ply)
  end

  --- Called when the car dealer spawns
  function NPC_CAR_DEALER:OnSpawn(npcInstance)
    print("[IonRP NPCs] Car Dealer spawned: " .. npcInstance:GetName())
  end
end
