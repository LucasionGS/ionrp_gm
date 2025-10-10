--[[
    Shop Commands
    Commands for opening and managing shops
]]--

-- Open a shop
IonRP.Commands.Add("shop", function(ply, args)
  local shopId = args[1] or "general_store"
  
  if not IonRP.Shop.Shops[shopId] then
    ply:ChatPrint("[IonRP] Unknown shop: " .. shopId)
    ply:ChatPrint("[IonRP] Available shops: " .. table.concat(table.GetKeys(IonRP.Shop.Shops), ", "))
    return
  end
  
  IonRP.Shop:OpenShop(ply, shopId)
end, "Open a shop", nil)

-- List available shops
IonRP.Commands.Add("shops", function(ply)
  ply:ChatPrint("[IonRP] Available shops:")
  for id, shop in pairs(IonRP.Shop.Shops) do
    ply:ChatPrint("  - " .. id .. ": " .. shop.name)
  end
end, "List available shops", nil)

print("[IonRP Shop] Commands loaded")
