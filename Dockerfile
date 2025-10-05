FROM cm2network/steamcmd:root

LABEL maintainer="ion"
LABEL description="Garry's Mod Dedicated Server"

# Install dependencies
RUN apt-get update && apt-get install -y \
    lib32gcc-s1 \
    lib32stdc++6 \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create steam user and directories
RUN useradd -m -d /home/steam steam || true

# Set up directories
RUN mkdir -p /home/steam/gmodserver \
    && chown -R steam:steam /home/steam/gmodserver

# Switch to steam user
USER steam
WORKDIR /home/steam

# Install/Update Garry's Mod Dedicated Server
# App ID: 4020 (Garry's Mod Dedicated Server)
RUN /home/steam/steamcmd/steamcmd.sh \
    +force_install_dir /home/steam/gmodserver \
    +login anonymous \
    +app_update 4020 validate \
    +quit

COPY lib/gmsv_mysqloo_linux.dll /home/steam/gmodserver/garrysmod/lua/bin/gmsv_mysqloo_linux.dll

# Set working directory to the server
WORKDIR /home/steam/gmodserver

# Expose ports
# 27015 - Game server port (UDP)
# 27015 - RCON port (TCP)
EXPOSE 27015/udp 27015/tcp

# Create entrypoint script
USER root
RUN echo '#!/bin/bash\n\
cd /home/steam/gmodserver\n\
./srcds_run \
    -game garrysmod \
    -console \
    -systemtest \
    +ip 0.0.0.0 \
    -port ${GMOD_PORT:-27015} \
    +maxplayers ${GMOD_MAXPLAYERS:-16} \
    +map ${GMOD_MAP:-gm_flatgrass} \
    +gamemode ${GMOD_GAMEMODE:-sandbox} \
    +hostname "${GMOD_HOSTNAME:-IonRP Server}" \
    +host_workshop_collection 2522269170 \
    +sv_setsteamaccount "${GMOD_STEAMTOKEN:-}" \
    "$@"' > /home/steam/start.sh \
    && chmod +x /home/steam/start.sh \
    && chown steam:steam /home/steam/start.sh

USER steam

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s \
    CMD pgrep srcds_linux || exit 1

ENTRYPOINT ["/home/steam/start.sh"]
