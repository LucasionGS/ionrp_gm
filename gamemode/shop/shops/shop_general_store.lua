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

shop:AddItem(ITEM_STICK, 50, 25)        -- Can buy for $50, sell for $25
shop:AddItem(ITEM_STEMPACK, 100, 50)    -- Medical item
shop:AddItem(ITEM_PISTOL_AMMO, 30, 15)  -- Ammo
shop:AddItem(ITEM_SMG_AMMO, 40, 20)
shop:AddItem(ITEM_RIFLE_AMMO, 50, 25)
shop:AddItem(ITEM_357_AMMO, 60, 30)
shop:AddItem(ITEM_AK47, 6000, 2000)

print("[IonRP Shop] Loaded: General Store")
