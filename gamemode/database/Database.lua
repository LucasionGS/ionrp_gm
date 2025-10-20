-- https://github.com/FredyH/MySQLOO/releases
-- "gmsv_mysqloo_*.dll" should be put in garrysmod/lua/bin/
require("mysqloo")

-- In case "credentials.lua" exists in the same directory as this file, load it.
-- This is useful for keeping your database credentials out of your public repository.
if file.Exists("ionrp/gamemode/database/credentials.lua", "LUA") then
  print("[IonRP] Found credentials.lua, loading...")
  include("credentials.lua")
end
--[[
    If you want to keep a local copy of your database credentials,
    you can create a file called "credentials.lua" in the same directory as this file.
    It will be excluded from your the repository if using https://github.com/LucasionGS/ionrp
    Copy this code into the file and fill in with your credentials:
    ------------------------------------------------------------
    DB_HOST = "mariadb"
    DB_PORT = 3306
    DB_NAME = "ionrp"
    DB_USER = "ionrp"
    DB_PASSWORD = "ionrp"
    DB_SOCKET = "/var/run/mysqld/mysqld.sock" -- Used for UNIX sockets
    ------------------------------------------------------------
]] --


local hostname = DB_HOST or "mariadb"
local port     = DB_PORT or 3306
local database = DB_NAME or "ionrp"
local username = DB_USER or "ionrp"
local password = DB_PASSWORD or "ionrp"
local socket   = DB_SOCKET or "/var/run/mysqld/mysqld.sock"
--- @type Database
IonRP.Database = mysqloo.connect(hostname, username, password, database, port, socket)

function IonRP.Database:onConnected()
  print("[IonRP] Connected to the MySQL database!")

  -- Initialize database tables
  if IonRP.Database.InitializeTables then
    IonRP.Database:InitializeTables()
  end
end

function IonRP.Database:onConnectionFailed(err)
  print("[IonRP] ERROR: Failed to connect to the MySQL database:")
  print("[IonRP] ERROR: " .. err)
end

IonRP.Database:connect()
