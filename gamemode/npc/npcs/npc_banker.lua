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
    local wallet = ply:GetWallet()
    local bank = ply:GetBank()
    
    -- Show banking menu options
    local options = {
      {
        text = "Banker - " .. npcInstance:GetName(),
        isLabel = true
      },
      {
        text = "Wallet: " .. IonRP.Util:FormatMoney(wallet),
        isLabel = true
      },
      {
        text = "Bank: " .. IonRP.Util:FormatMoney(bank),
        isLabel = true
      },
      {
        text = "Deposit Money",
        callback = function()
          IonRP.Dialog:RequestString(ply, "Deposit", "How much would you like to deposit?", "", function(amountStr)
            local amount = tonumber(amountStr)
            if amount and amount > 0 then
              if wallet >= amount then
                ply:SetWallet(wallet - amount)
                ply:SetBank(bank + amount)
                ply:ChatPrint("[Banker] Deposited " .. IonRP.Util:FormatMoney(amount) .. " to your bank account.")
              else
                ply:ChatPrint("[Banker] You don't have that much cash!")
              end
            else
              ply:ChatPrint("[Banker] Invalid amount!")
            end
          end)
        end
      },
      {
        text = "Withdraw Money",
        callback = function()
          IonRP.Dialog:RequestString(ply, "Withdraw", "How much would you like to withdraw?", "", function(amountStr)
            local amount = tonumber(amountStr)
            if amount and amount > 0 then
              if bank >= amount then
                ply:SetBank(bank - amount)
                ply:SetWallet(wallet + amount)
                ply:ChatPrint("[Banker] Withdrew " .. IonRP.Util:FormatMoney(amount) .. " from your bank account.")
              else
                ply:ChatPrint("[Banker] Insufficient funds in your bank account!")
              end
            else
              ply:ChatPrint("[Banker] Invalid amount!")
            end
          end)
        end
      },
      {
        text = "Check Balance",
        callback = function()
          ply:ChatPrint("[Banker] Wallet: " .. IonRP.Util:FormatMoney(ply:GetWallet()))
          ply:ChatPrint("[Banker] Bank: " .. IonRP.Util:FormatMoney(ply:GetBank()))
        end
      },
      {
        text = "Close",
        callback = function()
          ply:ChatPrint("[Banker] Have a nice day!")
        end
      }
    }
    
    IonRP.Dialog:OptionList(ply, "Banker", options)
  end
  
  --- Called when the banker spawns
  function NPC_BANKER:OnSpawn(npcInstance)
    print("[IonRP NPCs] Banker spawned: " .. npcInstance:GetName())
  end
end
