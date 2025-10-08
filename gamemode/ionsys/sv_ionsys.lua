--[[
    IonSys - Admin Panel System
    Server-side admin panel handlers
]] --

include("sh_ionsys.lua")

IonRP.IonSys = IonRP.IonSys or {}

-- Network strings
util.AddNetworkString("IonSys_OpenPanel")
util.AddNetworkString("IonSys_RequestData")
util.AddNetworkString("IonSys_SendData")
util.AddNetworkString("IonSys_KickPlayer")
util.AddNetworkString("IonSys_BanPlayer")
util.AddNetworkString("IonSys_GiveItem")
util.AddNetworkString("IonSys_ApplyJob")
util.AddNetworkString("IonSys_SetPlayerRank")

--- Send admin panel data to client
--- @param ply Player The player to send data to
function IonRP.IonSys:SendDataToClient(ply)
  if not IsValid(ply) or not ply:HasPermission("ionsys") then
    return
  end

  -- Collect player data
  local players = {}
  for _, p in ipairs(player.GetAll()) do
    table.insert(players, {
      userid = p:UserID(),
      name = p:Nick(),
      steamid = p:SteamID(),
      steamid64 = p:SteamID64(),
      rank = p:GetRankName(),
      rankColor = p:GetRankColor(),
      ping = p:Ping(),
      health = p:Health(),
      armor = p:Armor()
    })
  end

  -- Collect item data
  local items = {}
  for identifier, item in pairs(IonRP.Items.List) do
    table.insert(items, {
      identifier = identifier,
      name = item.name,
      description = item.description,
      type = item.type,
      weight = item.weight,
      stackSize = item.stackSize
    })
  end

  -- Collect job data
  local jobs = {}
  for identifier, job in pairs(IonRP.Jobs.List) do
    table.insert(jobs, {
      identifier = identifier,
      name = job.name,
      description = job.description,
      salary = job.salary,
      max = job.max,
      color = { r = job.color.r, g = job.color.g, b = job.color.b }
    })
  end

  -- Collect rank data
  local ranks = {}
  for _, rankData in ipairs(IonRP.Ranks.List) do
    table.insert(ranks, {
      id = rankData.id,
      name = rankData.name,
      color = { r = rankData.color.r, g = rankData.color.g, b = rankData.color.b },
      immunity = rankData.immunity
    })
  end

  -- Send data
  net.Start("IonSys_SendData")
  net.WriteTable({
    players = players,
    items = items,
    jobs = jobs,
    ranks = ranks
  })
  net.Send(ply)
end

--- Open admin panel for player
--- @param ply Player The player to open the panel for
function IonRP.IonSys:OpenPanel(ply)
  if not IsValid(ply) or not ply:HasPermission("ionsys") then
    ply:ChatPrint("[IonSys] You don't have permission to access the admin panel!")
    return
  end

  -- Send data first
  self:SendDataToClient(ply)

  -- Tell client to open panel
  net.Start("IonSys_OpenPanel")
  net.Send(ply)
end

-- Network receivers

-- Client requests to open admin panel
net.Receive("IonSys_OpenPanel", function(len, ply)
  IonRP.IonSys:OpenPanel(ply)
end)

-- Client requests fresh data
net.Receive("IonSys_RequestData", function(len, ply)
  if not ply:HasPermission("ionsys") then return end
  IonRP.IonSys:SendDataToClient(ply)
end)

-- Client requests to kick a player
net.Receive("IonSys_KickPlayer", function(len, ply)
  if not ply:HasPermission("kick") then
    ply:ChatPrint("[IonSys] You don't have permission to kick players!")
    return
  end

  local targetUserID = net.ReadUInt(16)
  local reason = net.ReadString()

  -- Find target player
  local target = nil
  for _, p in ipairs(player.GetAll()) do
    if p:UserID() == targetUserID then
      target = p
      break
    end
  end

  if not target or not IsValid(target) then
    ply:ChatPrint("[IonSys] Target player not found!")
    return
  end

  -- Check immunity
  if not ply:HasImmunity(target) then
    ply:ChatPrint("[IonSys] You cannot kick this player (insufficient immunity)!")
    return
  end

  -- Kick the player
  local kickReason = reason ~= "" and reason or "Kicked by admin"
  target:Kick(kickReason)

  -- Log and notify
  print(string.format("[IonSys] %s kicked %s (Reason: %s)", ply:Nick(), target:Nick(), kickReason))

  for _, p in ipairs(player.GetAll()) do
    if p:HasPermission("seeadminchat") then
      p:ChatPrint(string.format("[IonSys] %s kicked %s (Reason: %s)", ply:Nick(), target:Nick(), kickReason))
    end
  end
end)

-- Client requests to ban a player
net.Receive("IonSys_BanPlayer", function(len, ply)
  if not ply:HasPermission("ban") then
    ply:ChatPrint("[IonSys] You don't have permission to ban players!")
    return
  end

  local targetUserID = net.ReadUInt(16)
  local duration = net.ReadUInt(32)   -- Duration in minutes (0 = permanent)
  local reason = net.ReadString()

  -- Find target player
  --- @type Player
  local target = nil
  for _, p in ipairs(player.GetAll()) do
    if p:UserID() == targetUserID then
      target = p
      break
    end
  end

  if not IsValid(target) then
    ply:ChatPrint("[IonSys] Target player not found!")
    return
  end

  -- Check immunity
  if not ply:HasImmunity(target) then
    ply:ChatPrint("[IonSys] You cannot ban this player (insufficient immunity)!")
    return
  end

  local banReason = reason ~= "" and reason or "Banned by admin"
  local durationText = duration == 0 and "Permanent" or (duration .. " minutes")

  -- Log the ban
  print(string.format("[IonSys] %s banned %s for %s (Reason: %s)",
    ply:Nick(), target:Nick(), durationText, banReason))

  -- Notify admins
  for _, p in ipairs(player.GetAll()) do
    if p:HasPermission("seeadminchat") then
      p:ChatPrint(string.format("[IonSys] %s banned %s for %s (Reason: %s)",
        ply:Nick(), target:Nick(), durationText, banReason))
    end
  end

  -- Ban the player using ULX-style ban if available, otherwise kick with message
  if duration == 0 then
    target:Kick("BANNED: " .. banReason .. " (Permanent)")
  else
    target:Kick("BANNED: " .. banReason .. " (Duration: " .. duration .. " minutes)")
  end

  -- TODO: Implement proper ban system with database storage
  -- For now, this just kicks with a ban message
end)

-- Client requests to give themselves an item
net.Receive("IonSys_GiveItem", function(len, ply)
  if not ply:HasPermission("ionsys") then
    ply:ChatPrint("[IonSys] You don't have permission to give items!")
    return
  end

  local itemIdentifier = net.ReadString()
  local quantity = net.ReadUInt(16)

  -- Validate item
  local item = IonRP.Items.List[itemIdentifier]
  if not item then
    ply:ChatPrint("[IonSys] Invalid item identifier!")
    return
  end

  -- Give the item
  local success, err = ply:GiveItem(itemIdentifier, quantity)

  if success then
    ply:ChatPrint(string.format("[IonSys] Gave yourself %dx %s", quantity, item.name))
    print(string.format("[IonSys] %s gave themselves %dx %s", ply:Nick(), quantity, item.name))
  else
    ply:ChatPrint("[IonSys] Failed to give item: " .. (err or "unknown error"))
  end
end)

-- Client requests to apply for a job
net.Receive("IonSys_ApplyJob", function(len, ply)
  if not ply:HasPermission("ionsys") then
    ply:ChatPrint("[IonSys] You don't have permission to change jobs!")
    return
  end

  local jobIdentifier = net.ReadString()

  -- Validate job
  local job = IonRP.Jobs.List[jobIdentifier]
  if not job then
    ply:ChatPrint("[IonSys] Invalid job identifier!")
    return
  end

  -- Apply for the job
  local success, err = job:ApplyForJob(ply)

  if err then
    ply:ChatPrint("[IonSys] Failed to apply for job: " .. err)
  else
    print(string.format("[IonSys] %s changed their job to %s", ply:Nick(), job.name))
  end
end)

-- Client requests to set a player's rank
net.Receive("IonSys_SetPlayerRank", function(len, ply)
  if not ply:HasPermission("setrank") then
    ply:ChatPrint("[IonSys] You don't have permission to set player ranks!")
    return
  end

  local targetUserID = net.ReadUInt(16)
  local newRankId = net.ReadUInt(8)
  local reason = net.ReadString()

  -- Find the target player
  --- @type Player
  local target = nil
  for _, p in ipairs(player.GetAll()) do
    if p:UserID() == targetUserID then
      target = p
      break
    end
  end

  if not target or not IsValid(target) then
    ply:ChatPrint("[IonSys] Target player not found!")
    return
  end

  -- Check immunity (admin can't change rank of someone with equal or higher rank)
  local adminRank = ply:GetRankData()
  local targetRank = target:GetRankData()
  local newRank = IonRP.Ranks:GetRankData(newRankId)

  if not newRank then
    ply:ChatPrint("[IonSys] Invalid rank!")
    return
  end

  if targetRank and targetRank.immunity >= adminRank.immunity then
    ply:ChatPrint("[IonSys] You cannot change the rank of someone with equal or higher immunity!")
    return
  end

  if newRank.immunity >= adminRank.immunity then
    ply:ChatPrint("[IonSys] You cannot set a rank equal to or higher than your own!")
    return
  end

  -- Set the rank
  local success, err = IonRP.Ranks:SetPlayerRank(target, newRankId, ply, reason)

  if success == false then
    ply:ChatPrint("[IonSys] Failed to set rank: " .. (err or "unknown error"))
  else
    ply:ChatPrint(string.format("[IonSys] Set %s's rank to %s", target:Nick(), newRank.name))
    target:ChatPrint(string.format("Your rank has been changed to %s by %s", newRank.name, ply:Nick()))
    
    -- Refresh admin panel data for all admins with panel open
    for _, admin in ipairs(player.GetAll()) do
      if admin:HasPermission("ionsys") then
        IonRP.IonSys:SendDataToClient(admin)
      end
    end
  end
end)

-- Console command to open admin panel
concommand.Add("ionsys", function(ply)
  if not IsValid(ply) then return end
  IonRP.IonSys:OpenPanel(ply)
end)

-- Register chat command
IonRP.Commands.Add("admin", function(activator, args, rawArgs)
  IonRP.IonSys:OpenPanel(activator)
end, "Open the IonSys admin panel", "ionsys")

IonRP.Commands.Add("ionsys", function(activator, args, rawArgs)
  IonRP.IonSys:OpenPanel(activator)
end, "Open the IonSys admin panel", "ionsys")

print("[IonSys] Server-side admin panel loaded")
