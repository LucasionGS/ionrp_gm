# IonRP Gamemode - AI Coding Instructions

## Project Overview
Garry's Mod roleplay gamemode built on GLua (Lua 5.1) with MySQL persistence, modular architecture, and comprehensive type safety via LuaLS annotations. Features inventory, vehicle garage, property ownership, license/permit system, drug production, buddy permissions, NPC interactions, and admin tools.

## Architecture Pattern: Realm-Based Module System

### File Organization & Loading Order
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

**Critical**: GLua has **three execution realms** - files run on different contexts:
- `init.lua` (SERVER): Runs only on server, must `AddCSLuaFile()` for client-side files
- `cl_init.lua` (CLIENT): Runs only on client, receives files via `AddCSLuaFile()`
- `shared.lua` (SHARED): Runs on both, use `if SERVER then` / `if CLIENT then` guards

**Loading pattern from init.lua**:
```lua
AddCSLuaFile("inventory/sh_inventory.lua")  -- Send to client
AddCSLuaFile("inventory/cl_inventory.lua")  -- Send to client
include("inventory/sh_inventory.lua")       -- Run on server
include("inventory/sv_inventory.lua")       -- Run on server
```

**New features require**: 
1. Add `AddCSLuaFile()` calls to `init.lua` for shared/client files
2. Add `include()` calls to `init.lua` for server files  
3. Add `include()` calls to `cl_init.lua` for client files
4. Add `include()` calls to `shared.lua` if truly shared

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

### Running the Server (Docker)
Full Docker setup with MariaDB and GMod server (see `docker-compose.yml`):
```bash
docker compose up -d              # Start both services in background
docker compose attach gmod-server # Attach to view server console
docker compose logs -f            # View logs from all services
docker compose restart gmod-server # Restart after gamemode changes
```

**Environment variables** (`.env` or `docker-compose.yml`):
- `STEAM_TOKEN` - Required for server browser listing (get from steamcommunity.com/dev/apikey)
- `GMOD_MAP` - Current: `rp_riverden_v1a` (default spawn map)
- `GMOD_HOSTNAME` - Server name in browser

### Database Access
MySQL credentials in `gamemode/database/credentials.lua` (gitignored):
```bash
docker exec -it ionrp-mariadb mysql -u ionrp -p ionrp
# Password: ionrp (default)
```

**Schema management**: All tables created via `IonRP.Database:InitializeTables()` in `sv_schema.lua`

### Testing Changes
1. **Edit Lua files** - Hot-reload via `include()` chain (some changes require restart)
2. **Reload gamemode**: `changelevel rp_riverden_v1a` in server console (full restart)
3. **Test commands**: Use `/giveitem`, `/setrank`, `/tp` (requires admin rank)
4. **Check inventory**: Press `F1` (default keybind) to open inventory UI
5. **Admin panel**: Press `F4` to open IonSys admin tools

### Debugging
- **Server logs**: `print("[Feature] Message")` - visible in docker attach console
- **Client logs**: `F8` console in GMod client, look for Lua errors
- **Database errors**: Logged with full SQL query when `PreparedQuery()` fails
- **Network debugging**: `net_graph 1` in client console shows packet traffic
- **Entity inspector**: Developer mode enabled - use `cl_model_explorer.lua` for 3D model testing

### Common Issues
- **Realm mismatch**: Calling server function on client crashes - check `if SERVER then` guards
- **Missing AddCSLuaFile**: Client can't access file - add to `init.lua`
- **Database connection**: Requires MySQLOO binary (`gmsv_mysqloo_linux.dll` in `garrysmod/lua/bin/`)
- **Inventory not syncing**: Check network string registration and `net.Receive()` handlers

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

**Hook overrides** (gamemode files):
```lua
function GM:PlayerLoadout(ply)
  -- Custom loadout logic
  return true  -- Prevent default weapon loadout
end
```

**Entity ownership**: Properties, vehicles, NPCs track owner via `entity.owner` (Player object or SteamID64).

## System Integration Patterns

### Adding a New Feature Module
1. **Create files**: `sh_feature.lua`, `sv_feature.lua`, `cl_feature.lua` in `gamemode/feature/`
2. **Register in init.lua**:
   ```lua
   AddCSLuaFile("feature/sh_feature.lua")
   AddCSLuaFile("feature/cl_feature.lua")
   include("feature/sh_feature.lua")
   include("feature/sv_feature.lua")
   ```
3. **Register in cl_init.lua**:
   ```lua
   include("feature/cl_feature.lua")
   ```
4. **Create namespace**: `IonRP.Feature = IonRP.Feature or {}`
5. **Add database tables**: Create `InitializeTables()` function, call from `sv_schema.lua`
6. **Add commands**: Create `sv_feature_commands.lua`, include in `init.lua`

### Custom Entities (SENT)
- Base entity: `entities/entities/ionrp_drug_base/` (shared.lua, init.lua, cl_init.lua)
- Set `ENT.Type = "anim"`, `ENT.Base = "base_gmodentity"`
- Use `ENT.Spawnable = false` for base classes

### Custom Weapons (SWEP)
- Single-file: `entities/weapons/weapon_ionrp_keys.lua` with `AddCSLuaFile()` at top
- Set `SWEP.Spawnable = true` for player access
- Use `if SERVER then` / `if CLIENT then` for realm-specific code
- Example: `weapon_ionrp_keys.lua` - interacts with property system via netmessages

## Important Notes

- **No README.md in features** - Exception: `shop/README.md` for complex system documentation
- **Flexible rank IDs**: `SetPlayerRank()` accepts both `2` and `"Admin"` (case-insensitive)
- **Item stacking**: Respects `stackSize` limit, splits stacks if quantity exceeds
- **Weight validation**: Check `inventory:CanFitItem()` before adding items
- **Immunity system**: Prevent lower ranks from affecting higher ranks via `actorRank > targetRank`
- **MySQLOO library**: `gmsv_mysqloo_linux.dll` in `lua/bin/` (included in Docker image)
- **Entity validity**: Always check `IsValid(entity)` before accessing entity methods
- **Player disconnection**: Clean up timers with player-specific IDs to prevent leaks

## File Naming Conventions
- `sh_<feature>.lua` - Shared code (runs on both realms)
- `sv_<feature>.lua` - Server-only code
- `cl_<feature>.lua` - Client-only code
- `sh_<feature>_types.lua` - Shared type definitions (LuaLS annotations)
- `sv_<feature>_commands.lua` - Server commands for feature
- `item_<name>.lua` - Item definitions (in `gamemode/item/<category>/`)
- `<entity>_<name>.lua` - Job, NPC, license, drug, vehicle definitions

When adding new features, follow this modular structure and ensure proper realm separation, type annotations, and integration into `init.lua`/`cl_init.lua`.
