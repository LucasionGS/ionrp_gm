# IonRP Gamemode - AI Coding Instructions

## Project Overview
Garry's Mod roleplay gamemode built on GLua with MySQL persistence, modular architecture, and comprehensive type safety via LuaLS annotations.

## Architecture Pattern: Realm-Based Module System

### File Organization
```
gamemode/
├── init.lua          # SERVER: AddCSLuaFile + include server modules
├── cl_init.lua       # CLIENT: include client modules  
├── shared.lua        # SHARED: Runs on both realms
└── feature/
    ├── sv_feature.lua    # Server logic, database, networking
    ├── cl_feature.lua    # Client UI, rendering, net receivers
    └── sh_feature.lua    # Shared types, data structures, utility
```

**Critical**: Files run in different realms. Use `SERVER` and `CLIENT` guards for realm-specific code in shared files. Server must `AddCSLuaFile()` for client files, then `include()` for server files.

**Example from init.lua**:
```lua
AddCSLuaFile("inventory/sh_inventory.lua")  -- Send to client
AddCSLuaFile("inventory/cl_inventory.lua")  -- Send to client
include("inventory/sh_inventory.lua")       -- Run on server
include("inventory/sv_inventory.lua")       -- Run on server
```

## Type System: LuaLS Annotations

**All new code must be strongly typed**. Use `---` comments with LuaLS annotations for IntelliSense.

**Pattern from sh_inventory.lua**:
```lua
--- @class Inventory
--- @field owner Player|nil The player who owns this inventory
--- @field width number The width of the inventory grid
--- @field slots table<string, InventorySlot> Table of slots indexed by "x_y"
INVENTORY = {}

--- Create a new inventory instance
--- @param width number Grid width
--- @param height number Grid height
--- @param maxWeight number|nil Maximum weight capacity (default: 50)
--- @return Inventory
function INVENTORY:New(width, height, maxWeight)
```

**Key rules**:
- Use `@class` for data structures and metatables
- `@field` for class properties with description
- `@param` with type and description for all parameters
- `@return` for return types
- Handle `nil` cases explicitly: `Player|nil`, `number|nil`
- Create `sh_*_types.lua` for shared type definitions across realms

## Database Pattern: MySQLOO with Prepared Queries

**Always use `IonRP.Database:PreparedQuery()` for SQL** - it handles parameterization, error logging, and prevents SQL injection.

**Pattern from sv_inventory.lua**:
```lua
IonRP.Database:PreparedQuery(
  "SELECT * FROM ionrp_inventories WHERE steam_id = ? LIMIT 1",
  { steamID },
  function(data)  -- onSuccess
    if data and #data > 0 then
      -- Handle result
    end
  end,
  function(err, sql)  -- onError (optional)
    print("[Error] " .. err)
  end
)
```

**Schema conventions**:
- Tables: `ionrp_<feature>` (plural)
- Primary key: `id INT AUTO_INCREMENT PRIMARY KEY`
- Foreign keys with `ON DELETE CASCADE`
- Steam IDs: `VARCHAR(32)` with `INDEX idx_steam_id`
- Timestamps: `created_at`, `updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP`
- Engine: `InnoDB`, Charset: `utf8mb4_unicode_ci`

Initialize tables in `<feature>:InitializeTables()` called from `sv_schema.lua`.

## Networking Pattern: Prefixed Network Strings

**Convention**: `util.AddNetworkString("IonRP_<Action>")` or `IonSys_<Action>` for admin features.

**Client-Server flow** (from sv_inventory.lua → cl_inventory.lua):
```lua
-- SERVER: Register and send
util.AddNetworkString("IonRP_SyncInventory")
net.Start("IonRP_SyncInventory")
  net.WriteTable(inventoryData)
net.Send(ply)

-- CLIENT: Receive
net.Receive("IonRP_SyncInventory", function()
  local invData = net.ReadTable()
  -- Update UI
end)
```

Register all network strings at the top of `sv_*.lua` files.

## Permission System

Use `ply:HasPermission("permission_name")` for access control. Permissions defined in `sv_ranks.lua`:

```lua
IonRP.Ranks.Permissions = {
  ["ionsys"] = { minRank = RANK_ADMIN, description = "Access admin panel" },
}
```

**Rank constants** (defined in `sh_ranks_types.lua`):
- `RANK_USER = 1`
- `RANK_MODERATOR = 2`
- `RANK_ADMIN = 3`
- Higher rank = more permissions

Check immunity before actions: `actorRank > targetRank`.

## Item System: Metatable-Based Instances

**Define items** in `gamemode/item/<category>/item_<name>.lua`:
```lua
ITEM_AK47 = ITEM:New("item_ak47", "AK-47")
ITEM_AK47.description = "A popular assault rifle..."
ITEM_AK47.model = "models/weapons/w_rif_ak47.mdl"
ITEM_AK47.weight = 3.47
ITEM_AK47.size = { 3, 1 }  -- Width, Height in grid units
ITEM_AK47.stackSize = 1
ITEM_AK47.type = "weapon"
ITEM_AK47.weaponClass = "weapon_ak47"

-- Optional: Custom behavior
function ITEM_AK47:SV_Use()
  -- Custom server logic
  return true  -- Consume item
end
```

**Access items**: `IonRP.Items.List["item_ak47"]`  
**Player context**: `item:MakeOwnedInstance(ply)` sets `item.owner`

## Command System

**Register commands** in `commands/sv_<feature>_commands.lua`:
```lua
IonRP.Commands.Add("giveitem", function(activator, args, rawArgs)
  -- Command logic
  activator:ChatPrint("[IonRP] Result message")
end, "Give item to player", "inventory.give")
```

**Parameters**:
- `activator`: Player who ran command
- `args`: Table of arguments split by spaces
- `rawArgs`: Full argument string
- `permission`: Optional permission check (uses `HasPermission()`)

Users run with `/giveitem arg1 arg2`.

## UI Conventions: Custom Paint with Color Scheme

**Derma panels** use `Paint` override for custom rendering. Standard color palette in `cl_*.lua`:

```lua
Colors = {
  Background = Color(25, 25, 35, 250),     -- Dark blue-gray
  Header = Color(45, 35, 60, 255),         -- Purple-gray
  SlotBackground = Color(35, 35, 45, 200), -- Darker slots
  SlotHover = Color(55, 50, 70, 230),      -- Lighter on hover
  Accent = Color(120, 100, 255, 255),      -- Purple accent
  AccentCyan = Color(100, 200, 255, 255),  -- Cyan accent
  Text = Color(255, 255, 255, 255),        -- White text
  TextMuted = Color(160, 160, 175, 255),   -- Dimmed text
}
```

**Use `draw.RoundedBox()`** for modern UI:
```lua
function panel:Paint(w, h)
  draw.RoundedBox(6, 0, 0, w, h, Colors.Background)
end
```

## Development Workflow

### Running the Server
Docker-based setup (see `docker-compose.yml`):
```bash
docker-compose up -d    # Start MariaDB + Garry's Mod server
docker-compose logs -f  # View logs
```

### Database Access
```bash
docker exec -it ionrp-mariadb mysql -u ionrp -p ionrp
# Password: ionrp (from credentials.lua)
```

### Testing Changes
- Edit Lua files (auto-loaded via `include()` chain)
- Reload gamemode: `changelevel <current_map>` in server console
- For inventory/UI: Test with `/giveitem` admin command
- Check console for `[IonRP]` prefixed error messages

### Debugging
- Use `print("[Feature] Debug message")` for server logs
- Client logs: `F8` console in GMod client
- MySQL errors logged with query SQL for debugging
- Network traffic: `net_graph 1` in client console

## Common Patterns

**Player metatable extensions** (shared.lua):
```lua
local plyMeta = FindMetaTable("Player")
function plyMeta:GetWallet()
  return self:GetNWInt("Wallet", 0)
end
```

**Networked variables**: Use `SetNWInt/String/Bool` on server, `GetNW*` on both realms.

**Auto-save timers** (sv_inventory.lua):
```lua
timer.Create("IonRP_SaveInventory_" .. ply:SteamID64(), 30, 0, function()
  if IsValid(ply) then
    IonRP.Inventory:Save(inventory, ply)
  end
end)
```

**Grid-based positioning**: Inventory uses `"x_y"` string keys for slots, e.g., `slots["5_3"]`.

## Important Notes

- **No README.md files in features** - Use inline comments for documentation
- **Flexible rank IDs**: `SetPlayerRank()` accepts both `2` and `"Admin"` (case-insensitive)
- **Item stacking**: Respects `stackSize` limit, splits stacks if quantity exceeds
- **Weight validation**: Check `inventory:CanFitItem()` before adding items
- **Immunity system**: Prevent lower ranks from affecting higher ranks
- **MySQLOO library**: `gmsv_mysqloo_linux.dll` in `lua/bin/` (required for database)

## File Naming Conventions
- `sh_<feature>.lua` - Shared code
- `sv_<feature>.lua` - Server-only code
- `cl_<feature>.lua` - Client-only code
- `sh_<feature>_types.lua` - Shared type definitions
- `sv_<feature>_commands.lua` - Server commands for feature
- `item_<name>.lua` - Item definitions

When adding new features, follow this modular structure and ensure proper realm separation, type annotations, and integration into `init.lua`/`cl_init.lua`.
