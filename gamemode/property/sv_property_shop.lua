--[[
    Property Shop - Server Side
    Handles property purchases and shop interactions
]]--

IonRP.PropertyShop = IonRP.PropertyShop or {}

-- Network strings
util.AddNetworkString("IonRP_PropertyShop_Open")
util.AddNetworkString("IonRP_PropertyShop_Purchase")
util.AddNetworkString("IonRP_PropertyShop_Sell")

--- Open the property shop for a player
--- @param ply Player The player to open the shop for
function IonRP.PropertyShop:OpenForPlayer(ply)
  if not IsValid(ply) then return end

  net.Start("IonRP_PropertyShop_Open")
  net.Send(ply)
end

-- Handle property purchase
net.Receive("IonRP_PropertyShop_Purchase", function(len, ply)
  if not IsValid(ply) then return end

  local propertyId = net.ReadInt(32)

  IonRP.Properties:SV_PurchaseProperty(ply, propertyId, function(success, message)
    if success then
      ply:ChatPrint(string.format("[IonRP] %s", message))
      ply:ChatPrint("[IonRP] Property purchased! You now own this property.")
      
      -- Log the purchase
      print(string.format("[IonRP Property Shop] %s purchased property ID %d", 
        ply:Nick(), propertyId))
    else
      ply:ChatPrint(string.format("[IonRP] Purchase failed: %s", message))
    end
  end)
end)

-- Handle property sale
net.Receive("IonRP_PropertyShop_Sell", function(len, ply)
  if not IsValid(ply) then return end

  local propertyId = net.ReadInt(32)

  IonRP.Properties:SV_SellProperty(ply, propertyId, function(success, message)
    if success then
      ply:ChatPrint(string.format("[IonRP] %s", message))
      ply:ChatPrint("[IonRP] Property sold successfully!")
      
      -- Log the sale
      print(string.format("[IonRP Property Shop] %s sold property ID %d", 
        ply:Nick(), propertyId))
    else
      ply:ChatPrint(string.format("[IonRP] Sale failed: %s", message))
    end
  end)
end)

-- Chat commands to open shop
IonRP.Commands.Add("propertyshop", function(activator, args, rawArgs)
  IonRP.PropertyShop:OpenForPlayer(activator)
end, "Open the property shop", "developer")

print("[IonRP Property Shop] Server-side loaded")
