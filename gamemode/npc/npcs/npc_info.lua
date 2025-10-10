--[[
    Information NPC
    Provides help and information to new players
]]--

local NPC_INFO = NPC:New("npc_info", "Information Guide")
NPC_INFO.description = "A helpful guide who can answer your questions"
NPC_INFO.model = "models/player/group01/female_01.mdl"
NPC_INFO.category = "Utility"
NPC_INFO.health = 100
NPC_INFO.canBeKilled = false
NPC_INFO.friendly = true

if SERVER then
  --- Called when a player uses the information NPC
  --- @param ply Player The player who used the NPC
  function NPC_INFO:OnUse(ply, npcInstance)
    local options = {
      {
        text = "Information Guide - " .. npcInstance:GetName(),
        isLabel = true
      },
      {
        text = "What is IonRP?",
        callback = function()
          ply:ChatPrint("[Info] IonRP is a roleplay gamemode for Garry's Mod!")
          ply:ChatPrint("[Info] You can buy properties, vehicles, and interact with NPCs.")
        end
      },
      {
        text = "How do I earn money?",
        callback = function()
          ply:ChatPrint("[Info] You can earn money by completing quests, getting a job,")
          ply:ChatPrint("[Info] or trading with other players. Use /help for commands!")
        end
      },
      {
        text = "Where's the vehicle shop?",
        callback = function()
          ply:ChatPrint("[Info] Use the /vehicleshop or /dealership command to browse vehicles!")
        end
      },
      {
        text = "Where's the property shop?",
        callback = function()
          ply:ChatPrint("[Info] Use the /propertyshop or /realestate command to buy properties!")
        end
      },
      {
        text = "What commands are available?",
        callback = function()
          ply:ChatPrint("[Info] Type /help in chat to see all available commands.")
          ply:ChatPrint("[Info] Some useful ones: /inventory, /atm, /mygarage")
        end
      },
      {
        text = "Thank you!",
        callback = function()
          ply:ChatPrint("[Info] You're welcome! Come back if you need more help.")
        end
      }
    }
    
    IonRP.Dialog:ShowOptions(ply, "Information Guide", options)
  end
  
  --- Called when the info NPC spawns
  function NPC_INFO:OnSpawn(npcInstance)
    print("[IonRP NPCs] Information Guide spawned: " .. npcInstance:GetName())
  end
end
