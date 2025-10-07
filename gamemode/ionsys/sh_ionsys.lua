--[[
    IonSys - Admin Panel System
    Shared type definitions
]] --

IonRP.IonSys = IonRP.IonSys or {}

--- @class IonSys_PlayerData
--- @field userid number The player's UserID
--- @field name string The player's name
--- @field steamid string The player's SteamID
--- @field steamid64 string The player's SteamID64
--- @field rank string The player's rank name
--- @field rankColor Color The player's rank color
--- @field ping number The player's ping
--- @field health number The player's current health
--- @field armor number The player's current armor

--- @class IonSys_ItemData
--- @field identifier string The item's unique identifier
--- @field name string The item's display name
--- @field description string The item's description
--- @field type string The item type ("weapon", "consumable", "misc")
--- @field weight number The item's weight in KG
--- @field stackSize number Maximum stack size for this item

--- @class IonSys_PanelData
--- @field players IonSys_PlayerData[] List of all players
--- @field items IonSys_ItemData[] List of all items
