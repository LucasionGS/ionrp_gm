--[[
    Example Shop: General Store
    A basic shop selling common items
]]--

-- Create the general store shop
local shop = SHOP:New("general_store", "General Store", "Buy and sell common items")
shop:SetTaxRate(0.05) -- 5% tax

-- Add items (identifier, buyPrice, sellPrice)
-- You can set buyPrice to nil to make it unsellable
-- You can set sellPrice to nil to make it unbuyable from players

shop:AddItem("item_stick", 50, 25)        -- Can buy for $50, sell for $25
shop:AddItem("item_stempack", 100, 50)    -- Medical item
shop:AddItem("item_pistol_ammo", 30, 15)  -- Ammo
shop:AddItem("item_smg_ammo", 40, 20)
shop:AddItem("item_rifle_ammo", 50, 25)
shop:AddItem("item_357_ammo", 60, 30)

print("[IonRP Shop] Loaded: General Store")
