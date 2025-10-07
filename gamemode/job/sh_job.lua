IonRP.Jobs = IonRP.Jobs or {}

---@type table<string, JOB>
IonRP.Jobs.List = IonRP.Jobs.List or {}


--- @class JOB
JOB = {}

--- @type JOB
JOB.__index = JOB

--- The unique identifier for the job.
--- @type string
JOB.identifier = "generic_job"

--- The display name of the job.
--- @type string
JOB.name = "<No name>"

--- The description of the job.
--- @type string
JOB.description = "<No description>"

--- The salary paid to players in this job assuming 0% taxing (per pay period).
--- @type number
JOB.salary = 0

--- The teams this job is a part of.
--- If empty, the job is considered its own standalone team.
--- @type table<"government"|"police"|"medic">
JOB.teams = {}

--- The maximum number of players allowed in this job.
--- 0 = unlimited
--- @type number
JOB.max = 0

--- The color associated with this job (for UI elements).
--- @type Color
JOB.color = Color(200, 200, 200)

--- The weapons given to players when they take this job.
--- @type table<string>
JOB.weapons = {}

--- The default weapons given to all jobs (e.g. fists, physgun).
--- @type table<string>
JOB.defaultWeapons = {
  "weapon_physcannon",
  "weapon_fists"
}

--- Player models used for this job based on the player's desired appearance.
JOB.playerModels = {
  ["male"] = "models/player/group01/male_01.mdl", -- Fallback male
  ["male_01"] = "models/player/group01/male_01.mdl",
  ["male_02"] = "models/player/group01/male_02.mdl",
  ["male_03"] = "models/player/group01/male_03.mdl",
  ["male_04"] = "models/player/group01/male_04.mdl",
  ["male_05"] = "models/player/group01/male_05.mdl",
  ["male_06"] = "models/player/group01/male_06.mdl",
  ["male_07"] = "models/player/group01/male_07.mdl",
  ["male_08"] = "models/player/group01/male_08.mdl",
  ["male_09"] = "models/player/group01/male_09.mdl",

  ["female"] = "models/player/group01/female_01.mdl", -- Fallback female
  ["female_01"] = "models/player/group01/female_01.mdl",
  ["female_02"] = "models/player/group01/female_02.mdl",
  ["female_03"] = "models/player/group01/female_03.mdl",
  ["female_04"] = "models/player/group01/female_04.mdl",
  ["female_05"] = "models/player/group01/female_05.mdl",
  ["female_06"] = "models/player/group01/female_06.mdl",
}

--- Create a new job
--- @param identifier string The unique identifier for the job
--- @param name string The display name of the job
--- @return JOB
function JOB:New(identifier, name)
  local newJob = {}
  setmetatable(newJob, JOB)
  newJob.__index = JOB
  newJob.identifier = identifier
  newJob.name = name

  IonRP.Jobs.List[identifier] = newJob
  print("│ [IonRP Jobs] ├ Registered job: " .. identifier .. " - " .. name)

  return newJob
end

function JOB:IsInTeam(teamName)
  if not teamName or teamName == "" then return false end
  for _, t in ipairs(self.teams) do
    if t == teamName then
      return true
    end
  end
  return false
end

--- Apply for this job as a player
--- @param ply Player
--- @return boolean, string|nil
function JOB:ApplyForJob(ply)
  if not ply or not IsValid(ply) then return false, "Invalid player" end
  if not self or not self.identifier then return false, "Invalid job" end

  if SERVER then
    ply:SetNWString("IonRP_Job", self.identifier)
    self:Loadout(ply)
    ply:ChatPrint("You are now employed as: " .. self.name)
    return true
  end

  return false, "Not running on server"
end

--- Give the player their job loadout (model, weapons, etc.)
--- @param ply Player
function JOB:Loadout(ply)
  if not ply or not IsValid(ply) then return end

  -- Set player model
  local model = self:GetFullModel(ply)
  ply:SetModel(model)

  -- Give weapons
  for _, defaultWeapon in ipairs(self.defaultWeapons) do
    ply:Give(defaultWeapon)
  end
  for _, weapon in ipairs(self.weapons) do
    ply:Give(weapon)
  end

  print("[IonRP] Player " .. ply:Nick() .. " has been given the loadout for job: " .. self.name)
end

--- Get the full player model path for this job based on the player's desired model
--- @param ply Player
--- @return string
function JOB:GetFullModel(ply)
  local model = self.playerModels[ply:GetDesiredModel()] or self.playerModels["male"]
  return model
end

--- @class Player
local playerMeta = FindMetaTable("Player")

--- Get the player's current job
--- @return JOB|nil, string|nil The job identifier
function playerMeta:GetJob()
  local jobId = self:GetNWString("IonRP_Job", JOB_CITIZEN.identifier)
  return IonRP.Jobs.List[jobId], jobId
end

if SERVER then
  -- Salary interval
  local salaryInterval = 60 -- in seconds

  -- Pay salaries periodically
  timer.Create("IonRP_PaySalaries", salaryInterval, 0, function()
    for _, ply in ipairs(player.GetAll()) do
      if not IsValid(ply) then continue end

      local job = ply:GetJob()
      if not job then continue end

      local salary = job.salary
      if not salary then continue end

      ply:AddBank(salary)
      ply:ChatPrint("You have received your salary: " .. IonRP.Util:FormatMoney(salary))
    end
  end)
end

-- Import weapons
print("┌──────────────┬─────────────────────────────────────────────────────────────────•")
print("│ [IonRP Jobs] │ Loading jobs")
for _, job in ipairs(file.Find("ionrp/gamemode/job/jobs/*.lua", "LUA")) do
  include("jobs/" .. job)
  if SERVER then
    AddCSLuaFile("jobs/" .. job)
  end
end
print("└──────────────┴─────────────────────────────────────────────────────────────────•")