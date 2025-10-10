# IonRP Shop System

A comprehensive shop system with buy/sell functionality, integrated with the inventory and economy systems.

## Features

- **Buy & Sell Items**: Players can buy items from shops or sell items they own
- **Tax System**: Configurable tax rate per shop
- **Bulk Transactions**: Support for buying/selling multiple items at once
- **Modern UI**: Stylized interface matching IonRP's design language
- **3D Item Models**: Interactive item previews with rotation
- **Context Menus**: Right-click for advanced options
- **Inventory Integration**: Checks inventory space and item counts
- **Real-time Money Display**: Shows wallet balance with live updates

## File Structure

```
gamemode/shop/
├── sh_shop.lua              # Shared shop definitions
├── sv_shop.lua              # Server-side transaction handling
├── cl_shop.lua              # Client-side UI
└── shops/
    └── shop_general_store.lua  # Example shop definition
```

## Creating a Shop

Create a new file in `gamemode/shop/shops/`:

```lua
-- Create the shop
local shop = SHOP:New("shop_identifier", "Shop Name", "Shop description here")

-- Set tax rate (0.05 = 5%)
shop:SetTaxRate(0.05)

-- Add items (identifier, buyPrice, sellPrice)
shop:AddItem("item_stick", 50, 25)        -- Buy for $50, sell for $25
shop:AddItem("item_stempack", 100, nil)   -- Can only buy (can't sell to shop)
shop:AddItem("item_gold", nil, 500)       -- Can only sell (shop doesn't sell)

print("[IonRP Shop] Loaded: Shop Name")
```

### Item Price Rules

- **buyPrice**: Price players pay to buy from shop (with tax added)
- **sellPrice**: Price players receive when selling to shop (no tax deduction)
- Set to `nil` to disable buying or selling

## Opening a Shop

### Via Command

```lua
/shop [shop_identifier]
```

Example: `/shop general_store`

### Via Code

```lua
-- Server-side
IonRP.Shop:OpenShop(ply, "general_store")
```

### Listing Shops

```lua
/shops  -- Lists all available shops
```

## Shop Methods

### SHOP:New(identifier, name, description)
Creates a new shop instance.

```lua
local shop = SHOP:New("gun_store", "Gun Store", "Buy weapons and ammo")
```

### SHOP:AddItem(identifier, buyPrice, sellPrice)
Adds an item to the shop.

```lua
shop:AddItem("item_ak47", 5000, 2500)
```

### SHOP:SetTaxRate(rate)
Sets the tax rate (0.0 to 1.0).

```lua
shop:SetTaxRate(0.08) -- 8% tax
```

### SHOP:GetItem(identifier)
Gets a shop item by identifier.

```lua
local shopItem = shop:GetItem("item_ak47")
```

### SHOP:CalculateTaxedPrice(basePrice)
Calculates final price with tax.

```lua
local finalPrice = shop:CalculateTaxedPrice(1000) -- Returns 1050 with 5% tax
```

## UI Features

### Left Click
- Buy 1x item (if available for purchase)

### Right Click
Opens context menu with options:
- **Buy 1x**: Purchase single item
- **Buy Bulk**: Enter custom quantity
- **Sell 1x**: Sell single item (if you own it)
- **Sell Bulk**: Enter custom quantity to sell
- **Sell All**: Sell all items of this type

### Visual Elements
- **3D rotating item models**
- **Animated header with particles**
- **Color-coded prices** (green for money, red for insufficient funds)
- **Hover effects** with glowing borders
- **Real-time wallet balance**
- **Tax rate display**
- **Item tooltips** with descriptions

## Integration

### With Inventory System
- Checks if player has inventory space before purchase
- Verifies item ownership before selling
- Automatically updates inventory after transactions

### With Economy System
- Deducts money from wallet for purchases
- Adds money to wallet for sales
- Tax is automatically calculated and added to buy prices

### With Item System
- Reads item definitions from `IonRP.Items.List`
- Supports all item types (weapons, consumables, misc)
- Uses item models, names, descriptions

## Example Shop Definitions

### General Store
```lua
local shop = SHOP:New("general_store", "General Store", "Buy and sell common items")
shop:SetTaxRate(0.05)
shop:AddItem("item_stick", 50, 25)
shop:AddItem("item_stempack", 100, 50)
shop:AddItem("item_pistol_ammo", 30, 15)
```

### Gun Store
```lua
local shop = SHOP:New("gun_store", "Gun Store", "Firearms and ammunition")
shop:SetTaxRate(0.10) -- Higher tax on weapons
shop:AddItem("item_ak47", 5000, nil)  -- Can't sell back
shop:AddItem("item_pistol", 1500, nil)
shop:AddItem("item_rifle_ammo", 50, 25)
```

### Pawn Shop
```lua
local shop = SHOP:New("pawn_shop", "Pawn Shop", "Sell your unwanted items")
shop:SetTaxRate(0.0) -- No tax
-- Only buying from players, not selling
shop:AddItem("item_stick", nil, 10)
shop:AddItem("item_gold", nil, 1000)
```

## Network Strings

The system uses the following network strings:
- `IonRP_Shop_Open`: Server → Client (opens shop UI)
- `IonRP_Shop_Buy`: Client → Server (buy transaction)
- `IonRP_Shop_Sell`: Client → Server (sell transaction)

## Commands

- `/shop [identifier]`: Open a shop
- `/shops`: List all available shops

## Future Enhancements

Potential additions:
- Shop NPCs with interaction zones
- Stock limits (items can run out)
- Dynamic pricing based on supply/demand
- Shop permissions (VIP-only shops)
- Faction-specific shops
- Trade-in bonuses
- Bulk purchase discounts
