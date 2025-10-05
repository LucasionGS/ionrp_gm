# IonRP - Garry's Mod Roleplay Gamemode

A custom roleplay gamemode for Garry's Mod, created following the Facepunch wiki guidelines.

## Installation

1. Copy this folder to your Garry's Mod installation:
   ```
   garrysmod/gamemodes/ionrp/
   ```

2. Ensure the folder structure looks like this:
   ```
   garrysmod/gamemodes/ionrp/
   ├── gamemode.txt
   ├── gamemode/
   │   ├── init.lua
   │   ├── shared.lua
   │   └── cl_init.lua
   └── (optional) icon24.png, logo.png, backgrounds/
   ```

3. Start your server with the gamemode:
   - In your server.cfg: `gamemode ionrp`
   - Or via command line: `+gamemode ionrp`

## Folder Structure

- **gamemode.txt** - Gamemode configuration (title, category, settings)
- **gamemode/** - Core gamemode code
  - **init.lua** - Server-side code
  - **shared.lua** - Code that runs on both client and server
  - **cl_init.lua** - Client-side code
- **icon24.png** - Gamemode icon (24x24 px)
- **logo.png** - Menu logo (288x128 px recommended)
- **backgrounds/** - Optional menu background images (.jpg)
- **content/** - Optional gamemode-specific content (maps, models, sounds)

## Features

### Basic Roleplay System
- Money system (starting amount configurable)
- Team/job system (Citizen, Police, Medic)
- Custom HUD showing player money
- Player spawning with default loadout

### Server Configuration
The following convars are available (set in server.cfg or game menu):
- `ionrp_maxplayers` - Maximum number of players (default: 32)
- `ionrp_friendly_fire` - Enable/disable friendly fire (default: 0)
- `ionrp_starting_money` - Starting money for new players (default: 500)

## Development

### Adding New Jobs/Teams
Edit `gamemode/shared.lua` and add your teams in the `GM:CreateTeams()` function:

```lua
TEAM_NEWJOB = 4
team.SetUp( TEAM_NEWJOB, "Job Name", Color( 255, 255, 255 ) )
```

### Adding Server-Side Features
Add code to `gamemode/init.lua` - this runs on the server only.

### Adding Client-Side Features
Add code to `gamemode/cl_init.lua` - this runs on the client only (UI, HUD, etc.).

### Adding Shared Features
Add code to `gamemode/shared.lua` - this runs on both client and server.

## Deriving from Other Gamemodes

If you want to base your gamemode on Sandbox or another gamemode, add this to `shared.lua`:

```lua
DeriveGamemode( "sandbox" )
```

## Common Errors

- **Error loading gamemode: info.Valid** - Your gamemode.txt file is invalid
- **Error loading gamemode: !IsValidGamemode** - Missing init.lua or cl_init.lua
- **Game crashes on death** - No playermodel assigned (fixed in init.lua)

## Resources

- [Facepunch Gamemode Creation Wiki](https://wiki.facepunch.com/gmod/Gamemode_Creation)
- [Garry's Mod Wiki](https://wiki.facepunch.com/gmod/)
- [Lua Programming Guide](https://wiki.facepunch.com/gmod/Lua_Basics)

## License

This is a starter template - customize it as you wish!
