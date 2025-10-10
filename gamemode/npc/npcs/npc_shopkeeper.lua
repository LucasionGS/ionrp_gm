--[[
    Shopkeeper NPC
    Sells items to players
]]--

local NPC_SHOPKEEPER = NPC:New("npc_shopkeeper", "Shopkeeper")
NPC_SHOPKEEPER.description = "A friendly merchant who sells various items"
NPC_SHOPKEEPER.model = "models/player/group01/male_07.mdl"
NPC_SHOPKEEPER.category = "Commerce"
NPC_SHOPKEEPER.health = 100
NPC_SHOPKEEPER.canBeKilled = false
NPC_SHOPKEEPER.friendly = true

if SERVER then
  --- Called when a player uses the shopkeeper
  --- @param ply Player The player who used the NPC
  function NPC_SHOPKEEPER:OnUse(ply, npcInstance)
    -- Show shop menu options
    local options = {
      {
        text = "Shopkeeper - " .. npcInstance:GetName(),
        isLabel = true
      },
      {
        text = "Buy AK-47 ($5,000)",
        callback = function()
          local price = 5000
          if ply:GetBank() >= price then
            ply:SetBank(ply:GetBank() - price)
            
            -- Give item
            local item = IonRP.Items.List["item_ak47"]
            if item then
              local inventory = ply:GetInventory()
              if inventory then
                inventory:AddItem(item, 1)
                ply:ChatPrint("[Shopkeeper] Here's your AK-47! Stay safe out there.")
              end
            end
          else
            ply:ChatPrint("[Shopkeeper] You don't have enough money for that!")
          end
        end
      },
      {
        text = "Buy Rifle Ammo ($250)",
        callback = function()
          local price = 250
          if ply:GetBank() >= price then
            ply:SetBank(ply:GetBank() - price)
            
            -- Give item
            local item = IonRP.Items.List["item_rifle_ammo"]
            if item then
              local inventory = ply:GetInventory()
              if inventory then
                inventory:AddItem(item, 1)
                ply:ChatPrint("[Shopkeeper] Enjoy your ammunition!")
              end
            end
          else
            ply:ChatPrint("[Shopkeeper] You don't have enough money for that!")
          end
        end
      },
      {
        text = "Nevermind",
        callback = function()
          ply:ChatPrint("[Shopkeeper] Come back anytime!")
        end
      }
    }
    
    IonRP.Dialog:ShowOptions(ply, "Shopkeeper", options)
  end
  
  --- Called when the shopkeeper spawns
  function NPC_SHOPKEEPER:OnSpawn(npcInstance)
    print("[IonRP NPCs] Shopkeeper spawned: " .. npcInstance:GetName())
  end
end
