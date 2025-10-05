# Character System

## Database Setup

The gamemode uses MariaDB for persistent character storage. Characters include:

- **Name**: First name and last name
- **Money**: Wallet (cash on hand) and Bank balance
- **Model**: Character appearance model

## Configuration

### Option 1: Using credentials.lua (Recommended)

Create `gamemode/database/credentials.lua`:

```lua
MYSQL_HOSTNAME = "mariadb"
MYSQL_USERNAME = "ionrp"
MYSQL_PASSWORD = "ionrp"
MYSQL_DATABASE = "ionrp"
MYSQL_SOCKET = "/var/run/mysqld/mysqld.sock"
MYSQL_PORT = 3306
```

This file is ignored by git and won't be committed to your repository.

### Option 2: Environment Variables

Set the following variables in your `.env` file (copy from `.env.example`):

- `MYSQL_ROOT_PASSWORD`
- `MYSQL_PASSWORD`

## Docker Setup

1. Start the database:

```bash
docker compose up mariadb -d
```

2. Start the game server:

```bash
docker compose up gmod-server
```

The database will automatically create the `ionrp_characters` table on first
connection.

## Features

### Character Creation

- New players are prompted to create a character on first join
- Choose first name, last name, gender, and model
- Starting money: $500 in wallet, $0 in bank

### Character Loading

- Existing players automatically load their character
- Character data is saved:
  - Every 5 minutes (auto-save)
  - When player disconnects
  - Can be manually saved via `IonRP.Character:Save(ply)`

### Character Data Access

**Server-side:**

```lua
local name = ply:GetRPName()        -- "John Doe"
local firstName = ply:GetFirstName() -- "John"
local lastName = ply:GetLastName()   -- "Doe"
```

**Client-side:**

```lua
local name = LocalPlayer():GetRPName()
local firstName = LocalPlayer():GetFirstName()
local lastName = LocalPlayer():GetLastName()
```

## Database Schema

```sql
CREATE TABLE ionrp_characters (
    id INT AUTO_INCREMENT PRIMARY KEY,
    steam_id VARCHAR(32) NOT NULL,
    first_name VARCHAR(32) NOT NULL,
    last_name VARCHAR(32) NOT NULL,
    wallet INT NOT NULL DEFAULT 500,
    bank INT NOT NULL DEFAULT 0,
    model VARCHAR(128) NOT NULL DEFAULT 'models/player/Group01/male_01.mdl',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_steamid (steam_id),
    INDEX idx_steam_id (steam_id)
);
```

## Requirements

- MySQLOO addon (gmsv_mysqloo_*.dll in garrysmod/lua/bin/)
  - Download: https://github.com/FredyH/MySQLOO/releases
  - Place in: `garrysmod/addons/mysqloo/` or `garrysmod/lua/bin/`
