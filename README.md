# IonRP - Garry's Mod Roleplay Gamemode

A custom roleplay gamemode for Garry's Mod built from scratch, based on ideas and concepts from PERP.

The gamemode itself is called IonRP. AtomRP will remain as the community and server name. IonRP can be thought of as the backend of AtomRP.

## Development setup

1. Install Docker CE on your machine (Desktop or CLI). Follow the instructions for your operating system [here](https://docs.docker.com/get-docker/).

2. Clone the repository:
   ```bash
   # git clone https://github.com/LucasionGS/ionrp_gm.git # HTTPS
   git clone git@github.com:LucasionGS/ionrp_gm.git ionrp # SSH
   cd ionrp
   ```

3. Use Docker Compose to build and run the development environment:
   ```bash
   docker compose up --build -d
   ```
   This will launch a Garry's Mod server with the IonRP gamemode installed, along with a MariaDB database, and phpMyAdmin for database management.

4. Access the Garry's Mod server:
   - Server IP: `localhost:27015`
   - Command to connect: `connect localhost:27015`

5. Recommended way to view logs and restart the server
   - After the `docker compose up -d` has been run, you can attach the server using:
     ```bash
     docker compose attach gmod-server
     ```
     This will allow you to see the server console output directly and interact with it.
   - To restart the server, you can simply press Ctrl+C to stop it, and then run `docker compose attach gmod-server` again to reattach. It will restart automatically.

6. Give yourself Developer privileges in-game:
   - Open the server console with the attach method above and type this after you joined the server:
     ```
     ionrp_setrank <your_name> developer
     ```

7. Stopping the development environment:
   ```bash
   docker compose down
   ```

## Resources

- [Facepunch Gamemode Creation Wiki](https://wiki.facepunch.com/gmod/Gamemode_Creation)
- [Garry's Mod Wiki](https://wiki.facepunch.com/gmod/)
- [Lua Programming Guide](https://wiki.facepunch.com/gmod/Lua_Basics)
