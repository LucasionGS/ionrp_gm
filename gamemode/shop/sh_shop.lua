--[[
    IonRP Shop System - Shared
    Shop definitions and data structures
]]--

IonRP.Shop = IonRP.Shop or {}
IonRP.Shop.Shops = IonRP.Shop.Shops or {}

--- @class ShopItem
--- @field identifier string Item identifier
--- @field buyPrice number|nil Buy price (nil = can't buy)
--- @field sellPrice number|nil Sell price (nil = can't sell)

--- @class Shop
--- @field identifier string Unique shop identifier
--- @field name string Display name
--- @field description string Shop description
--- @field items ShopItem[] List of items in shop
--- @field taxRate number Tax rate (0.0 to 1.0, e.g., 0.05 = 5%)
SHOP = {}
SHOP.__index = SHOP

--- Create a new shop
--- @param identifier string Unique identifier
--- @param name string Display name
--- @param description string Shop description
--- @return Shop
function SHOP:New(identifier, name, description)
  local shop = setmetatable({}, SHOP)
  shop.identifier = identifier
  shop.name = name or "Shop"
  shop.description = description or ""
  shop.items = {}
  shop.taxRate = 0.05 -- Default 5% tax
  
  -- Register shop
  IonRP.Shop.Shops[identifier] = shop
  
  return shop
end

--- Add an item to the shop
--- @param identifier string Item identifier
--- @param buyPrice number|nil Buy price (nil = can't buy from shop)
--- @param sellPrice number|nil Sell price (nil = can't sell to shop)
--- @return Shop
function SHOP:AddItem(identifier, buyPrice, sellPrice)
  table.insert(self.items, {
    identifier = identifier,
    buyPrice = buyPrice,
    sellPrice = sellPrice
  })
  return self
end

--- Set tax rate for shop
--- @param rate number Tax rate (0.0 to 1.0)
--- @return Shop
function SHOP:SetTaxRate(rate)
  self.taxRate = rate
  return self
end

--- Get an item from shop by identifier
--- @param identifier string Item identifier
--- @return ShopItem|nil
function SHOP:GetItem(identifier)
  for _, shopItem in ipairs(self.items) do
    if shopItem.identifier == identifier then
      return shopItem
    end
  end
  return nil
end

--- Calculate final price with tax
--- @param basePrice number Base price before tax
--- @return number Final price with tax
function SHOP:CalculateTaxedPrice(basePrice)
  return math.floor(basePrice + (basePrice * self.taxRate))
end

print("[IonRP Shop] Shared module loaded")
