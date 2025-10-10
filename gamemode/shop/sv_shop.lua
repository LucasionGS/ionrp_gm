--[[
    IonRP Shop System - Server
    Shop transaction handling
]]--

include("sh_shop.lua")

util.AddNetworkString("IonRP_Shop_Open")
util.AddNetworkString("IonRP_Shop_Buy")
util.AddNetworkString("IonRP_Shop_Sell")

--- Open a shop for a player
--- @param ply Player The player
--- @param shopIdentifier string Shop identifier
function IonRP.Shop:OpenShop(ply, shopIdentifier)
  if not IsValid(ply) then return end
  
  local shop = self.Shops[shopIdentifier]
  if not shop then
    print("[IonRP Shop] Unknown shop: " .. shopIdentifier)
    return
  end
  
  -- Send shop data to client
  net.Start("IonRP_Shop_Open")
    net.WriteString(shop.identifier)
    net.WriteString(shop.name)
    net.WriteString(shop.description)
    net.WriteFloat(shop.taxRate)
    net.WriteUInt(#shop.items, 16)
    
    for _, shopItem in ipairs(shop.items) do
      net.WriteString(shopItem.identifier)
      net.WriteBool(shopItem.buyPrice ~= nil)
      if shopItem.buyPrice then
        net.WriteUInt(shopItem.buyPrice, 32)
      end
      net.WriteBool(shopItem.sellPrice ~= nil)
      if shopItem.sellPrice then
        net.WriteUInt(shopItem.sellPrice, 32)
      end
    end
  net.Send(ply)
end

--- Handle buy transaction
net.Receive("IonRP_Shop_Buy", function(len, ply)
  local shopIdentifier = net.ReadString()
  local itemIdentifier = net.ReadString()
  local quantity = net.ReadUInt(16)
  
  local shop = IonRP.Shop.Shops[shopIdentifier]
  if not shop then
    ply:ChatPrint("[IonRP] Invalid shop")
    return
  end
  
  local shopItem = shop:GetItem(itemIdentifier)
  if not shopItem or not shopItem.buyPrice then
    ply:ChatPrint("[IonRP] This item is not for sale")
    return
  end
  
  local itemDef = IonRP.Items.List[itemIdentifier]
  if not itemDef then
    ply:ChatPrint("[IonRP] Invalid item")
    return
  end
  
  -- Calculate total cost with tax
  local totalCost = shop:CalculateTaxedPrice(shopItem.buyPrice) * quantity
  
  -- Check if player has enough money
  if ply:GetWallet() < totalCost then
    ply:ChatPrint("[IonRP] You don't have enough money (Need: $" .. totalCost .. ")")
    return
  end
  
  -- Get player's inventory
  local inv = ply.IonRP_Inventory
  if not inv then
    ply:ChatPrint("[IonRP] Inventory not loaded")
    return
  end
  
  -- Check if inventory can fit the items
  local canFit, reason = inv:CanFitQuantity(itemDef, quantity)
  if not canFit then
    ply:ChatPrint("[IonRP] " .. (reason or "Not enough inventory space"))
    return
  end
  
  -- Deduct money
  ply:SetWallet(ply:GetWallet() - totalCost)
  
  -- Add items to inventory
  local success, slots = inv:AddItem(itemDef, quantity)
  if success then
    -- Save inventory
    IonRP.Inventory:Save(ply)
    
    -- Notify player
    ply:ChatPrint("[IonRP] Purchased " .. quantity .. "x " .. itemDef.name .. " for $" .. totalCost)
    
    -- Play sound
    ply:EmitSound("items/battery_pickup.wav", 75, 100)
  else
    -- Refund if failed
    ply:SetWallet(ply:GetWallet() + totalCost)
    ply:ChatPrint("[IonRP] Failed to add items to inventory")
  end
end)

--- Handle sell transaction
net.Receive("IonRP_Shop_Sell", function(len, ply)
  local shopIdentifier = net.ReadString()
  local itemIdentifier = net.ReadString()
  local quantity = net.ReadUInt(16)
  
  local shop = IonRP.Shop.Shops[shopIdentifier]
  if not shop then
    ply:ChatPrint("[IonRP] Invalid shop")
    return
  end
  
  local shopItem = shop:GetItem(itemIdentifier)
  if not shopItem or not shopItem.sellPrice then
    ply:ChatPrint("[IonRP] This shop doesn't buy this item")
    return
  end
  
  local itemDef = IonRP.Items.List[itemIdentifier]
  if not itemDef then
    ply:ChatPrint("[IonRP] Invalid item")
    return
  end
  
  -- Get player's inventory
  local inv = ply.IonRP_Inventory
  if not inv then
    ply:ChatPrint("[IonRP] Inventory not loaded")
    return
  end
  
  -- Check if player has enough items
  local totalQuantity = inv:CountItem(itemDef)
  if totalQuantity < quantity then
    ply:ChatPrint("[IonRP] You don't have enough " .. itemDef.name .. " (Have: " .. totalQuantity .. ", Need: " .. quantity .. ")")
    return
  end
  
  -- Remove items from inventory
  local removed = inv:RemoveItemByIdentifier(itemDef, quantity)
  if removed < quantity then
    ply:ChatPrint("[IonRP] Failed to remove items from inventory")
    return
  end
  
  -- Calculate total payout (sell price is already after tax reduction)
  local totalPayout = shopItem.sellPrice * quantity
  
  -- Add money
  ply:SetWallet(ply:GetWallet() + totalPayout)
  
  -- Save inventory
  IonRP.Inventory:Save(ply)
  
  -- Notify player
  ply:ChatPrint("[IonRP] Sold " .. quantity .. "x " .. itemDef.name .. " for $" .. totalPayout)
  
  -- Play sound
  ply:EmitSound("items/battery_pickup.wav", 75, 110)
end)

print("[IonRP Shop] Server module loaded")
