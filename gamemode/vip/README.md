# VIP System

The VIP system is a separate ranking system from administrative ranks. It allows players to have VIP status that can be purchased or granted by administrators. VIP ranks are expirable and can be set to expire after a certain duration.

## VIP Ranks

The VIP system has 4 tiers, from lowest to highest:

1. **Silver VIP** - Basic VIP benefits (Purchasable)
2. **Gold VIP** - Enhanced VIP benefits (Purchasable)
3. **Diamond VIP** - Premium VIP benefits (Purchasable)
4. **Prism VIP** - Exclusive special VIP, non-purchasable, can only be granted by Lead Admin or higher

## Commands

### `/setvip <player> <vip_rank> [duration]`
Set a player's VIP rank. Requires `manage_vip` permission (Lead Admin or higher).

**Examples:**
- `/setvip John Silver` - Give permanent Silver VIP to John
- `/setvip John Gold 30d` - Give Gold VIP to John for 30 days
- `/setvip John Diamond 1m` - Give Diamond VIP to John for 1 month
- `/setvip John Prism` - Give permanent Prism VIP to John (special rank)

**Duration formats:**
- `d` or `days` - Days
- `w` or `weeks` - Weeks
- `m` or `months` - Months (30 days)
- `y` or `years` - Years
- `h` or `hours` - Hours

### `/removevip <player>`
Remove a player's VIP rank. Requires `manage_vip` permission.

**Example:**
- `/removevip John` - Remove John's VIP status

### `/vipranks`
List all available VIP ranks and their descriptions.

### `/checkvip [player]`
Check a player's VIP status. If no player is specified, checks your own VIP status.

**Examples:**
- `/checkvip` - Check your own VIP
- `/checkvip John` - Check John's VIP status

## Player Meta Methods

The VIP system adds several methods to the Player meta table:

### Server-side Methods

- `ply:GetVIPRank()` - Returns the player's VIP rank ID (0 if no VIP)
- `ply:GetVIPRankData()` - Returns the full VIP rank data table or nil
- `ply:GetVIPRankName()` - Returns the VIP rank name or nil
- `ply:GetVIPRankColor()` - Returns the VIP rank color or nil
- `ply:HasVIP()` - Returns true if player has any VIP rank
- `ply:HasVIPRank(vipRankId)` - Returns true if player has the specified VIP rank or higher (accepts ID or name)
- `ply:GetVIPExpiration()` - Returns ISO datetime string when VIP expires or nil if permanent
- `ply:IsVIPExpired()` - Returns true if VIP has expired

### Example Usage

```lua
-- Check if player has VIP
if ply:HasVIP() then
  print(ply:Nick() .. " has VIP!")
end

-- Check if player has Gold VIP or higher
if ply:HasVIPRank(VIP_RANK_GOLD) then
  print(ply:Nick() .. " has Gold VIP or better!")
end

-- Check by name
if ply:HasVIPRank("Diamond") then
  print(ply:Nick() .. " has Diamond VIP or better!")
end

-- Get VIP details
local vipData = ply:GetVIPRankData()
if vipData then
  print("Player has " .. vipData.name .. " VIP")
  print("Description: " .. vipData.description)
end

-- Check expiration
local expiresAt = ply:GetVIPExpiration()
if expiresAt then
  print("VIP expires at: " .. expiresAt)
else
  print("VIP is permanent")
end
```

## Database Tables

### `ionrp_player_vip`
Stores player VIP ranks with expiration dates.

**Columns:**
- `steam_id` (VARCHAR 32, PRIMARY KEY) - Player's Steam ID
- `vip_rank_id` (INT) - VIP rank ID
- `granted_by` (VARCHAR 32) - Steam ID of who granted the VIP
- `expires_at` (DATETIME, NULL) - When VIP expires (NULL = permanent)
- `granted_at` (TIMESTAMP) - When VIP was granted
- `updated_at` (TIMESTAMP) - Last update time

### `ionrp_vip_logs`
Logs all VIP rank changes.

**Columns:**
- `id` (INT, AUTO_INCREMENT, PRIMARY KEY)
- `steam_id` (VARCHAR 32) - Player's Steam ID
- `old_vip_rank` (INT) - Previous VIP rank ID
- `new_vip_rank` (INT) - New VIP rank ID
- `changed_by` (VARCHAR 32) - Who made the change
- `reason` (TEXT) - Reason for change
- `expires_at` (DATETIME, NULL) - Expiration date
- `created_at` (TIMESTAMP) - When the change was made

## Automatic Expiration

The VIP system automatically checks for expired VIPs every 5 minutes and removes them. When a player with an expired VIP joins the server, their VIP is immediately removed.

## Permissions

The `manage_vip` permission is required to use VIP management commands. By default, this is only available to Lead Admin rank and higher.

Prism VIP can only be granted by users with the `manage_vip` permission, as it's a special non-purchasable rank.
