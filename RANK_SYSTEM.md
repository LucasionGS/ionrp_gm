# IonRP Rank System - Complete Implementation

## 🎯 Overview

A complete rank/admin system has been implemented with database persistence, permission management, and immunity levels.

## ✅ What Was Created

### Database Tables
1. **ionrp_player_ranks** - Stores player rank assignments
2. **ionrp_rank_logs** - Logs all rank changes for auditing

### Server Files
- `gamemode/ranks/sv_ranks_schema.lua` - Rank definitions and database schema
- `gamemode/ranks/sv_ranks.lua` - Server-side rank management and commands

### Client Files
- `gamemode/ranks/cl_ranks.lua` - Client-side rank display and data

### Documentation
- `gamemode/ranks/README.md` - Complete usage guide

## 📊 Rank Hierarchy

| ID | Rank | Color | Immunity | Key Permissions |
|----|------|-------|----------|----------------|
| 0 | User | Gray | 0 | None (default player) |
| 1 | Moderator | Green | 1 | kick, freeze, noclip, spectate |
| 2 | Admin | Blue | 2 | ban, god, money, cleanup |
| 3 | Superadmin | Red | 3 | manage_jobs, workshop |
| 4 | Lead Admin | Purple | 4 | manage_ranks, console |
| 5 | Developer | Yellow | 5 | lua (full access) |

## 🔧 Commands

### Set Player Rank (Console or Chat)
```
ionrp_setrank <player> <rank> [reason]
```

**Examples:**
```
ionrp_setrank Ion Developer
ionrp_setrank John Moderator Good helper
ionrp_setrank Player123 2
```

**To promote yourself (first time setup):**
1. Open server console
2. Type: `ionrp_setrank YourName Developer`
3. Your rank will be saved to the database

## 🎨 Visual Features

### HUD Integration
- **Bottom left HUD**: Shows rank badge for staff (hidden for User rank)
- **Target ID**: Shows rank when looking at other players
- Rank name displayed in rank's color

### Example Display
```
[Developer] John Doe
Health: 100 █████████
Armor: 100  █████████
Cash: $500
```

## 🔐 Permission System

### Check Permissions in Code
```lua
-- Server-side
if ply:HasPermission("ban") then
    -- Player can ban
end

if admin:HasImmunity(target) then
    -- Can target this player
end

-- Convenience checks
if ply:IsStaff() then -- Moderator+
if ply:IsRPAdmin() then -- Admin+
if ply:IsRPSuperAdmin() then -- Superadmin+
if ply:IsDeveloper() then -- Developer
```

### Available Permissions
See the full list in `gamemode/ranks/README.md`

Major categories:
- **Basic Moderation**: kick, mute, freeze, noclip, teleport
- **Advanced**: ban, god, money manipulation
- **Administrative**: manage_jobs, manage_props
- **High Level**: manage_ranks, console commands
- **Developer**: lua execution

## 🔄 Integration Points

### Automatic Integration
✅ HUD shows ranks automatically
✅ Target ID shows ranks
✅ Noclip now uses permission system
✅ Database auto-creates tables
✅ Ranks load on player join
✅ Ranks sync to clients

### Files Modified
- `gamemode/init.lua` - Added rank includes
- `gamemode/cl_init.lua` - Added client rank include
- `gamemode/database/sv_schema.lua` - Added rank table initialization
- `gamemode/hud/cl_hud.lua` - Added rank display
- `gamemode/shared.lua` - Updated noclip comment

## 📝 Usage Examples

### Setting Up First Admin
1. Start server
2. Join server
3. Open server console
4. Run: `ionrp_setrank YourSteamName Developer`
5. You now have full access!

### Promoting a Player
1. As Lead Admin or higher: `ionrp_setrank PlayerName Moderator`
2. Player will see notification
3. All staff see the promotion in chat
4. Change is logged to database

### Checking Permissions
```lua
-- Before kicking a player
if not admin:HasPermission("kick") then
    admin:ChatPrint("No permission!")
    return
end

if not admin:HasImmunity(target) then
    admin:ChatPrint("Cannot kick this player!")
    return
end

-- Kick the player
target:Kick("Kicked by admin")
```

### Adding Custom Permissions
Edit `sv_ranks_schema.lua`:
```lua
IonRP.Ranks.Permissions = {
    ["custom_action"] = {minRank = 2, description = "Do custom thing"},
}
```

Then use:
```lua
if ply:HasPermission("custom_action") then
    -- Execute action
end
```

## 🔍 Player Meta Functions

### Server-Side
```lua
ply:GetRank() -- Returns rank ID (0-5)
ply:GetRankName() -- Returns "Admin"
ply:GetRankColor() -- Returns Color(52, 152, 219)
ply:GetRankData() -- Returns full rank table
ply:HasPermission("ban") -- Check permission
ply:HasImmunity(target) -- Check immunity
ply:IsStaff() -- Moderator+
ply:IsRPAdmin() -- Admin+
ply:IsRPSuperAdmin() -- Superadmin+
ply:IsDeveloper() -- Developer only
```

### Client-Side
```lua
LocalPlayer():GetRank()
LocalPlayer():GetRankName()
LocalPlayer():GetRankColor()
LocalPlayer():IsStaff()
-- etc. (display only, no permission checks)
```

## 🗄️ Database Storage

Ranks are automatically:
- ✅ Loaded when player joins
- ✅ Saved when rank changes
- ✅ Persisted across server restarts
- ✅ Logged with audit trail

## 🚀 Next Steps

The rank system is fully functional and ready to use! You can now:

1. **Set your own rank** to Developer
2. **Create staff team** by promoting players
3. **Add custom permissions** for new features
4. **Check permissions** before admin actions
5. **Use immunity system** to protect higher staff

All rank changes are logged and persisted to the MariaDB database.
