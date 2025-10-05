--[[
    Character Management System
    Server-side character loading, saving, and creation
]] --

IonRP.Character = IonRP.Character or {}

-- Network strings
util.AddNetworkString("IonRP_RequestCharacterCreation")
util.AddNetworkString("IonRP_CreateCharacter")
util.AddNetworkString("IonRP_CharacterLoaded")

-- Available character models
IonRP.Character.Models = {
  Male = {
    "models/player/Group01/male_01.mdl",
    "models/player/Group01/male_02.mdl",
    "models/player/Group01/male_03.mdl",
    "models/player/Group01/male_04.mdl",
    "models/player/Group01/male_05.mdl",
    "models/player/Group01/male_06.mdl",
    "models/player/Group01/male_07.mdl",
    "models/player/Group01/male_08.mdl",
    "models/player/Group01/male_09.mdl",
  },
  Female = {
    "models/player/Group01/female_01.mdl",
    "models/player/Group01/female_02.mdl",
    "models/player/Group01/female_03.mdl",
    "models/player/Group01/female_04.mdl",
    "models/player/Group01/female_05.mdl",
    "models/player/Group01/female_06.mdl",
  }
}

--[[
    Check if a player has a character
    @param ply Player
    @param callback function(hasCharacter, characterData)
]] --
function IonRP.Character:HasCharacter(ply, callback)
  local steamID = ply:SteamID64()

  IonRP.Database:PreparedQuery(
    "SELECT * FROM ionrp_characters WHERE steam_id = ? LIMIT 1",
    { steamID },
    function(data)
      if data and #data > 0 then
        callback(true, data[1])
      else
        callback(false, nil)
      end
    end,
    function(err)
      print("[IonRP] Error checking character: " .. err)
      callback(false, nil)
    end
  )
end

--[[
    Load a player's character
    @param ply Player
]] --
function IonRP.Character:Load(ply)
  self:HasCharacter(ply, function(hasChar, data)
    if hasChar then
      -- Apply character data to player
      ply:SetNWString("IonRP_FirstName", data.first_name)
      ply:SetNWString("IonRP_LastName", data.last_name)
      ply:SetWallet(tonumber(data.wallet) or 500)
      ply:SetBank(tonumber(data.bank) or 0)
      ply:SetModel(data.model or "models/player/Group01/male_01.mdl")

      print(string.format("[IonRP] Loaded character for %s: %s %s", ply:Nick(), data.first_name, data.last_name))

      -- Notify client that character is loaded
      net.Start("IonRP_CharacterLoaded")
      net.Send(ply)
    else
      -- No character found, request creation
      print("[IonRP] No character found for " .. ply:Nick() .. ", requesting creation")
      net.Start("IonRP_RequestCharacterCreation")
      net.Send(ply)
    end
  end)
end

--[[
    Create a new character for a player
    @param ply Player
    @param firstName string
    @param lastName string
    @param model string
]] --
function IonRP.Character:Create(ply, firstName, lastName, model)
  -- Validate inputs
  if not firstName or firstName == "" or not lastName or lastName == "" then
    return false, "Invalid name"
  end

  -- Sanitize names (only letters and spaces)
  firstName = string.gsub(firstName, "[^%a%s]", "")
  lastName = string.gsub(lastName, "[^%a%s]", "")

  if #firstName < 2 or #lastName < 2 then
    return false, "Names must be at least 2 characters"
  end

  if #firstName > 32 or #lastName > 32 then
    return false, "Names must be less than 32 characters"
  end

  -- Validate model
  local validModel = false
  for _, modelList in pairs(self.Models) do
    for _, validModelPath in ipairs(modelList) do
      if validModelPath == model then
        validModel = true
        break
      end
    end
    if validModel then break end
  end

  if not validModel then
    model = "models/player/Group01/male_01.mdl"
  end

  local steamID = ply:SteamID64()

  -- Insert into database
  IonRP.Database:PreparedQuery(
    "INSERT INTO ionrp_characters (steam_id, first_name, last_name, bank) VALUES (?, ?, ?, ?)",
    { steamID, firstName, lastName, model, IonRP.Bank.Config.StartingBank },
    function(data)
      print(string.format("[IonRP] Created character for %s: %s %s", ply:Nick(), firstName, lastName))

      -- Load the character
      timer.Simple(0.1, function()
        if IsValid(ply) then
          self:Load(ply)
        end
      end)
    end,
    function(err)
      print("[IonRP] Error creating character: " .. err)
    end
  )

  return true
end

--[[
    Save a player's character
    @param ply Player
]] --
function IonRP.Character:Save(ply)
  local steamID = ply:SteamID64()
  local firstName = ply:GetNWString("IonRP_FirstName", "")
  local lastName = ply:GetNWString("IonRP_LastName", "")

  if firstName == "" or lastName == "" then
    return -- No character to save
  end

  IonRP.Database:PreparedQuery(
    "UPDATE ionrp_characters SET wallet = ?, bank = ? WHERE steam_id = ?",
    { ply:GetWallet(), ply:GetBank(), steamID },
    function(data)
      print(string.format("[IonRP] Saved character for %s %s", firstName, lastName))
    end,
    function(err)
      print("[IonRP] Error saving character: " .. err)
    end
  )
end

-- Network handlers
net.Receive("IonRP_CreateCharacter", function(len, ply)
  local firstName = net.ReadString()
  local lastName = net.ReadString()
  local model = net.ReadString()

  IonRP.Character:Create(ply, firstName, lastName, model)
end)

-- Hook into player initialization
hook.Add("PlayerInitialSpawn", "IonRP_LoadCharacter", function(ply)
  -- Wait a bit for player to be fully loaded
  timer.Simple(1, function()
    if IsValid(ply) then
      IonRP.Character:Load(ply)
    end
  end)
end)

-- Save character on disconnect
hook.Add("PlayerDisconnected", "IonRP_SaveCharacter", function(ply)
  IonRP.Character:Save(ply)
end)

-- Auto-save characters every 5 minutes
timer.Create("IonRP_AutoSave", 300, 0, function()
  for _, ply in ipairs(player.GetAll()) do
    IonRP.Character:Save(ply)
  end
  print("[IonRP] Auto-saved all characters")
end)
