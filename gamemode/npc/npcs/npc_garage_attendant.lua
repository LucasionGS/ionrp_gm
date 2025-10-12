--[[
    Garage Attendant NPC
    Opens the garage menu to manage and spawn vehicles
]] --

local NPC_GARAGE_ATTENDANT = NPC:New("npc_garage_attendant", "Garage Attendant")
NPC_GARAGE_ATTENDANT.description = "A helpful attendant who manages the vehicle garage"
NPC_GARAGE_ATTENDANT.model = "models/player/group03/male_06.mdl"
NPC_GARAGE_ATTENDANT.category = "Services"
NPC_GARAGE_ATTENDANT.health = 100
NPC_GARAGE_ATTENDANT.canBeKilled = true
NPC_GARAGE_ATTENDANT.friendly = true

if SERVER then
  --- Called when a player uses the garage attendant
  --- @param ply Player The player who used the NPC
  function NPC_GARAGE_ATTENDANT:OnUse(ply, npcInstance)
    -- Send vehicle data to client
    IonRP.Garage:SendOwnedVehiclesToClient(ply)
    
    -- Open the garage menu after a brief delay to ensure data is synced
    timer.Simple(0.1, function()
      if IsValid(ply) then
        net.Start("IonRP_Garage_OpenMenu")
        net.Send(ply)
      end
    end)
  end

  --- Called when the garage attendant spawns
  function NPC_GARAGE_ATTENDANT:OnSpawn(npcInstance)
    print("[IonRP NPCs] Garage Attendant spawned: " .. npcInstance:GetName())
  end
end
