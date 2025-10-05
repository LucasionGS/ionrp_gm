# Rank System

## Overview

IonRP features a comprehensive rank/admin system with permission-based access control. Ranks are stored in the database and persist across server restarts.

## Rank Hierarchy

Ranks are ordered by power/immunity level (ascending):

| ID | Rank | Color | Immunity | Description |
|----|------|-------|----------|-------------|
| 0  | User | Gray | 0 | Default rank for all players |
| 1  | Moderator | Green | 1 | Basic moderation powers |
| 2  | Admin | Blue | 2 | Advanced moderation and server management |
| 3  | Superadmin | Red | 3 | Full server control |
| 4  | Lead Admin | Purple | 4 | Can manage ranks and advanced settings |
| 5  | Developer | Yellow | 5 | Full system access including Lua execution |

## Permissions

### Basic Moderation (Moderator+)
- `kick` - Kick players from the server
- `mute` - Mute players in chat
- `freeze` - Freeze players in place
- `slay` - Kill players
- `bring` - Teleport players to you
- `goto` - Teleport to players
- `spectate` - Spectate players
- `noclip` - Use noclip mode
- `cloak` - Become invisible
- `health` - Modify player health
- `armor` - Modify player armor
- `ignite` - Set players on fire
- `respawn` - Respawn players
- `seejoinleave` - See join/leave messages
- `seeadminchat` - View admin chat

### Advanced Moderation (Admin+)
- `ban` - Ban players from the server
- `unban` - Unban players
- `god` - God mode (invincibility)
- `money` - Give/take money from players
- `cleanup` - Clean up entities/props
- `physgun_players` - Use physgun on players
- `manage_props` - Remove/manage props

### Administrative (Superadmin+)
- `manage_jobs` - Create and manage jobs
- `workshop` - Manage workshop addons

### High Level (Lead Admin+)
- `manage_ranks` - Set player ranks
- `console` - Execute server console commands

### Developer Only
- `lua` - Execute Lua code on the server

## Commands

### Set Player Rank
```
ionrp_setrank <player> <rank> [reason]
```

**Examples:**
```
ionrp_setrank John Moderator
ionrp_setrank John Admin Promoted for good work
ionrp_setrank Player123 2
```

You can use:
- Player name (partial matches work)
- Rank name: User, Moderator, Admin, Superadmin, "Lead Admin", Developer
- Rank ID: 0-5

**Requirements:**
- Must have `manage_ranks` permission (Lead Admin+)
- Cannot modify ranks of players with equal or higher immunity

## Usage in Code

### Server-Side

```lua
-- Check if player has permission
if ply:HasPermission("ban") then
    -- Player can ban
end

-- Check immunity before taking action
if admin:HasImmunity(target) then
    -- Admin can target this player
end

-- Get rank information
local rankName = ply:GetRankName() -- "Admin"
local rankColor = ply:GetRankColor() -- Color(52, 152, 219)
local rankData = ply:GetRankData() -- Full rank table

-- Convenience checks
if ply:IsStaff() then -- Moderator+
if ply:IsRPAdmin() then -- Admin+
if ply:IsRPSuperAdmin() then -- Superadmin+
if ply:IsDeveloper() then -- Developer only

-- Set rank programmatically
IonRP.Ranks:SetPlayerRank(ply, 2, admin, "Promotion")
```

### Client-Side

```lua
-- Get rank information (display only)
local rankName = LocalPlayer():GetRankName()
local rankColor = LocalPlayer():GetRankColor()

-- Check rank level (no permission checking client-side)
if LocalPlayer():IsStaff() then
    -- Show staff UI elements
end
```

## Database Schema

### ionrp_player_ranks
```sql
CREATE TABLE ionrp_player_ranks (
    steam_id VARCHAR(32) PRIMARY KEY,
    rank_id INT NOT NULL DEFAULT 0,
    granted_by VARCHAR(32) DEFAULT NULL,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### ionrp_rank_logs
```sql
CREATE TABLE ionrp_rank_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    steam_id VARCHAR(32) NOT NULL,
    old_rank INT NOT NULL,
    new_rank INT NOT NULL,
    changed_by VARCHAR(32) NOT NULL,
    reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Adding New Permissions

Edit `gamemode/ranks/sv_ranks_schema.lua`:

```lua
IonRP.Ranks.Permissions = {
    ["your_permission"] = {minRank = 2, description = "Description here"},
}
```

Then check in your code:
```lua
if ply:HasPermission("your_permission") then
    -- Do something
end
```

## Display Features

- **HUD**: Shows rank badge next to player name (hidden for User rank)
- **Target ID**: Shows rank when looking at players
- **Chat**: Admin actions are announced to staff with `seeadminchat` permission

## Immunity System

Immunity prevents lower-ranked staff from targeting higher-ranked staff. For example:
- Moderator (immunity 1) cannot kick Admin (immunity 2)
- Admin (immunity 2) cannot ban Superadmin (immunity 3)
- Players with equal immunity can target each other

Always check immunity before administrative actions:
```lua
if not admin:HasImmunity(target) then
    admin:ChatPrint("You cannot target this player!")
    return
end
```
