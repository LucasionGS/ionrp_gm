JOB_CITIZEN = JOB:New("citizen", "Citizen")
JOB_CITIZEN.color = Color(20, 150, 20)
JOB_CITIZEN.salary = 45

-- We use default weapons because defaultWeapons already suffices for a citizen.
-- JOB_CITIZEN.weapons = {}

-- We use default models already defined in base job.
-- Potentially override a model selector function for styles?
-- JOB_CITIZEN.playerModels

function JOB_CITIZEN:GetFullModel(ply)
  -- Eventually this will be based on player's fashion choices.
  return JOB:GetFullModel(ply)
end