# 🐋 Docker Setup for IonRP Garry's Mod Server

This setup provides a containerized Garry's Mod dedicated server with your custom IonRP gamemode automatically mounted.

## 📋 Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- At least 4GB of available RAM
- At least 10GB of disk space
- Steam Web API Key (get it from https://steamcommunity.com/dev/apikey)

## 🚀 Quick Start

### 1. Configure Your Steam Token

First, get a Steam Web API Key:
1. Visit https://steamcommunity.com/dev/apikey
2. Register a key for your domain (can be anything)
3. Copy your API key

Create a `.env` file from the example:

```bash
cp .env.example .env
```

Edit `.env` and add your Steam token:
```
STEAM_TOKEN=your_actual_steam_token_here
```

### 2. Build and Start the Server

```bash
# Build the Docker image
docker compose build

# Start the server
docker compose up -d

# View logs
docker compose logs -f
```

The server will:
- Download/update Garry's Mod Dedicated Server (~5GB)
- Start with the IonRP gamemode
- Be accessible on port 27015

### 3. Connect to Your Server

In Garry's Mod:
1. Open the console (press `~`)
2. Type: `connect localhost:27015` (or use your server's IP)

## 🎮 Server Management

### Start/Stop/Restart

```bash
# Start the server
docker compose up -d

# Stop the server
docker compose down

# Restart the server
docker compose restart

# View server logs
docker compose logs -f gmod-server

# Access server console
docker attach ionrp-server
# Press Ctrl+P then Ctrl+Q to detach without stopping
```

### Update the Server

```bash
# Rebuild the image to update Garry's Mod
docker compose build --no-cache

# Restart with the new image
docker compose down
docker compose up -d
```

### Execute Server Commands

```bash
# Run a command in the server console
docker exec ionrp-server rcon_password yourpassword
docker exec ionrp-server rcon changelevel rp_downtown_v4c_v2
```

Or use RCON from your client or a tool like:
- [RCON CLI](https://github.com/gorcon/rcon-cli)
- [mcrcon](https://github.com/Tiiffi/mcrcon)

## ⚙️ Configuration

### Environment Variables

Edit `docker-compose.yml` to change server settings:

```yaml
environment:
  - GMOD_PORT=27015              # Server port
  - GMOD_MAXPLAYERS=32           # Max players
  - GMOD_MAP=rp_downtown_v4c_v2  # Starting map
  - GMOD_GAMEMODE=ionrp          # Gamemode folder name
  - GMOD_HOSTNAME=IonRP Server   # Server name in browser
  - GMOD_STEAMTOKEN=${STEAM_TOKEN}
```

### Server Configuration

Edit `docker/server.cfg` to configure:
- Server name and password
- Game rules and limits
- Voice chat settings
- RCON password (change this!)
- IonRP gamemode settings

### Gamemode Settings

The IonRP gamemode is automatically mounted from your local directory:
```
./  →  /home/steam/gmodserver/garrysmod/gamemodes/ionrp
```

Any changes you make to the gamemode files are immediately available - just restart the server or change the map.

## 📁 File Structure

```
ionrp/
├── docker-compose.yml       # Docker Compose configuration
├── Dockerfile               # Server image definition
├── .env                     # Environment variables (Steam token)
├── .env.example            # Example environment file
├── docker/
│   └── server.cfg          # Server configuration
├── gamemode/               # IonRP gamemode files (mounted)
│   ├── init.lua
│   ├── shared.lua
│   └── cl_init.lua
└── gamemode.txt
```

## 🔧 Advanced Configuration

### Persistent Data Volumes

To persist server data (player data, addons, etc.), uncomment the volume sections in `docker-compose.yml`:

```yaml
volumes:
  - gmod-data:/home/steam/gmodserver/garrysmod/data
  - gmod-addons:/home/steam/gmodserver/garrysmod/addons
  - gmod-logs:/home/steam/gmodserver/garrysmod/logs
```

### Adding Workshop Content

To add Workshop addons, you need to:

1. Create a `workshop.lua` file in your gamemode or server
2. Add workshop IDs using `resource.AddWorkshop()`
3. Or use a collection and add it to the server startup

Example `gamemode/workshop.lua`:
```lua
resource.AddWorkshop("123456789")  -- Replace with actual workshop IDs
```

### Custom Maps

Mount a maps folder:
```yaml
volumes:
  - ./maps:/home/steam/gmodserver/garrysmod/maps:ro
```

### FastDL Setup

For faster content downloads, set up a FastDL server and configure the URL in `docker/server.cfg`:
```
sv_downloadurl "http://your-fastdl-server.com/gmod/"
```

## 🐛 Troubleshooting

### Server not appearing in browser
- Make sure you set a valid `STEAM_TOKEN` in `.env`
- Check that port 27015/UDP is open in your firewall
- Verify `sv_lan 0` in server.cfg

### Can't connect to server
- Check logs: `docker compose logs -f`
- Verify port 27015 is not in use: `sudo netstat -tulpn | grep 27015`
- Make sure firewall allows UDP traffic on port 27015

### Server crashes on startup
- Check logs for errors: `docker compose logs gmod-server`
- Verify gamemode files are valid (no syntax errors)
- Ensure sufficient disk space and memory

### Gamemode changes not taking effect
- Restart the server: `docker compose restart`
- Or change the map in console: `changelevel gm_flatgrass`

### Out of memory
- Increase Docker memory limits in `docker-compose.yml`
- Or adjust your Docker Desktop settings

## 📊 Monitoring

### View Resource Usage

```bash
# Real-time stats
docker stats ionrp-server

# Container details
docker inspect ionrp-server
```

### Health Check

The container includes a health check that monitors the server process:

```bash
# Check health status
docker ps --filter name=ionrp-server
```

## 🔒 Security Notes

1. **Change the RCON password** in `docker/server.cfg`
2. **Don't commit `.env`** to version control (it's in .gitignore)
3. **Use strong passwords** for server and RCON
4. **Keep Steam token private** - it's tied to your Steam account
5. **Update regularly** to get security patches

## 📚 Additional Resources

- [Garry's Mod Wiki](https://wiki.facepunch.com/gmod/)
- [Docker Documentation](https://docs.docker.com/)
- [SteamCMD Documentation](https://developer.valvesoftware.com/wiki/SteamCMD)
- [Facepunch Forums](https://forum.facepunch.com/gmod/)

## 📄 License

This Docker setup is provided as-is. Garry's Mod is owned by Facepunch Studios.
