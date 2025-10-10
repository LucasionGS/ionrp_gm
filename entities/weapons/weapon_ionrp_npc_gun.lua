--[[
    IonRP NPC Gun
    Used by developers to place and edit NPCs on the map
]]--

SWEP.PrintName = "NPC Gun"
SWEP.Author = "IonRP"
SWEP.Instructions = "Place and manage NPCs with ease"
SWEP.Category = "IonRP"

SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModel = "models/weapons/v_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.UseHands = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Slot = 1
SWEP.SlotPos = 0
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

-- Editing state stored on player
-- ply.NPCGun_EditingNPC (NPCInstance)
-- ply.NPCGun_PlacingNPC (NPC type identifier)

--- Clear the player's NPC editing state
--- @param ply Player
local function ClearEditingState(ply)
  ply.NPCGun_EditingNPC = nil
  ply.NPCGun_PlacingNPC = nil
end

--- Get the NPC entity the player is looking at
--- @param ply Player
--- @return Entity|nil, NPCInstance|nil
local function GetLookingAtNPC(ply)
  local trace = ply:GetEyeTrace()
  local ent = trace.Entity

  if IsValid(ent) and ent.IonRP_NPCInstance then
    return ent, ent.IonRP_NPCInstance
  end

  return nil, nil
end

--[[
    PRIMARY ATTACK - Place NPC or interact with existing
]]--
function SWEP:PrimaryAttack()
  if CLIENT then return end

  --- @type Player
  local ply = self:GetOwner()
  
  -- Check if player is placing an NPC
  if ply.NPCGun_PlacingNPC then
    self:PlaceNPC(ply)
    self:SetNextPrimaryFire(CurTime() + 0.3)
    return
  end
  
  -- Check if looking at an NPC to edit
  local npcEnt, npcInstance = GetLookingAtNPC(ply)
  if npcEnt and npcInstance then
    ply.NPCGun_EditingNPC = npcInstance
    self:ShowNPCOptions(ply, npcInstance)
    self:SetNextPrimaryFire(CurTime() + 0.3)
    return
  end
  
  -- Show NPC type selection menu
  self:ShowNPCTypeMenu(ply)
  self:SetNextPrimaryFire(CurTime() + 0.3)
end

--[[
    SECONDARY ATTACK - Delete NPC
]]--
function SWEP:SecondaryAttack()
  if CLIENT then return end

  --- @type Player
  local ply = self:GetOwner()
  
  -- Cancel placing mode
  if ply.NPCGun_PlacingNPC then
    ply.NPCGun_PlacingNPC = nil
    ply:ChatPrint("[IonRP NPC Gun] Cancelled NPC placement")
    self:SetNextSecondaryFire(CurTime() + 0.3)
    return
  end
  
  -- Check if looking at an NPC to delete
  local npcEnt, npcInstance = GetLookingAtNPC(ply)
  if npcEnt and npcInstance then
    self:ConfirmDelete(ply, npcInstance)
    self:SetNextSecondaryFire(CurTime() + 0.3)
    return
  end
  
  ply:ChatPrint("[IonRP NPC Gun] Look at an NPC to delete it")
  self:SetNextSecondaryFire(CurTime() + 0.3)
end

--[[
    RELOAD - Clear state or show help
]]--
function SWEP:Reload()
  if CLIENT then return end

  --- @type Player
  local ply = self:GetOwner()
  
  -- Clear editing state
  if ply.NPCGun_EditingNPC or ply.NPCGun_PlacingNPC then
    ClearEditingState(ply)
    ply:ChatPrint("[IonRP NPC Gun] Cleared editing state")
    return
  end
  
  -- Show help
  ply:ChatPrint("[IonRP NPC Gun] LEFT CLICK - Place/Edit NPC | RIGHT CLICK - Delete NPC")
end

--- Place an NPC at the crosshair position
--- @param ply Player
function SWEP:PlaceNPC(ply)
  if not ply.NPCGun_PlacingNPC then return end
  
  local npcType = IonRP.NPCs.List[ply.NPCGun_PlacingNPC]
  if not npcType then
    ply:ChatPrint("[IonRP NPC Gun] Invalid NPC type!")
    ply.NPCGun_PlacingNPC = nil
    return
  end
  
  -- Get placement position and angles
  local trace = ply:GetEyeTrace()
  local pos = trace.HitPos + trace.HitNormal * 5
  local ang = Angle(0, ply:EyeAngles().y, 0) -- Face the player

  -- Create NPC instance
  local instance = NPC_INSTANCE:New(npcType, pos, ang, nil, nil)


  -- Save to database (will spawn automatically)
  instance:Save(function(success, npcId)
    if success then
      ply:ChatPrint("[IonRP NPC Gun] Placed " .. npcType.name .. " (ID: " .. npcId .. ")")
      ply.NPCGun_PlacingNPC = nil
    else
      ply:ChatPrint("[IonRP NPC Gun] Failed to save NPC!")
    end
  end)
end

--[[
    Show NPC type selection menu
]]--
function SWEP:ShowNPCTypeMenu(ply)
  -- Build category list
  local categories = {}
  for identifier, npcType in pairs(IonRP.NPCs.List) do
    local cat = npcType.category or "Other"
    if not categories[cat] then
      categories[cat] = {}
    end
    table.insert(categories[cat], npcType)
  end
  
  local options = {
    {
      text = "Select NPC Type to Place",
      isLabel = true
    }
  }
  
  -- Add NPCs by category
  for category, npcs in SortedPairs(categories) do
    table.insert(options, {
      text = "--- " .. category .. " ---",
      isLabel = true
    })
    
    table.sort(npcs, function(a, b) return a.name < b.name end)
    
    for _, npcType in ipairs(npcs) do
      table.insert(options, {
        text = npcType.name,
        callback = function()
          ply.NPCGun_PlacingNPC = npcType.identifier
          ply:ChatPrint("[IonRP NPC Gun] Placing " .. npcType.name .. ". LEFT CLICK to place, RIGHT CLICK to cancel")
        end
      })
    end
  end
  
  IonRP.Dialog:ShowOptions(ply, "NPC Gun - Select Type", options)
end


--- Show NPC options menu
--- @param ply Player
--- @param npcInstance NPCInstance
function SWEP:ShowNPCOptions(ply, npcInstance)
  local options = {
    {
      text = "NPC: " .. npcInstance:GetName(),
      isLabel = true
    },
    {
      text = "Change Name",
      callback = function()
        IonRP.Dialog:RequestString(ply, "NPC Name", "Enter new name (leave empty for default):", npcInstance.customName or "", function(name)
          if name == "" then
            npcInstance.customName = nil
          else
            npcInstance.customName = name
          end
          npcInstance:Update(function(success)
            if success then
              ply:ChatPrint("[IonRP NPC Gun] Updated NPC name")
            else
              ply:ChatPrint("[IonRP NPC Gun] Failed to update NPC!")
            end
          end)
        end)
      end
    },
    {
      text = "Change Model",
      callback = function()
        IonRP.Dialog:RequestString(ply, "NPC Model", "Enter model path (leave empty for default):", npcInstance.customModel or "", function(model)
          if model == "" then
            npcInstance.customModel = nil
          else
            npcInstance.customModel = model
          end
          npcInstance:Update(function(success)
            if success then
              ply:ChatPrint("[IonRP NPC Gun] Updated NPC model")
            else
              ply:ChatPrint("[IonRP NPC Gun] Failed to update NPC!")
            end
          end)
        end)
      end
    },
    {
      text = "Move to Crosshair",
      callback = function()
        local trace = ply:GetEyeTrace()
        local newPos = trace.HitPos + trace.HitNormal * 5
        
        npcInstance.pos = newPos
        npcInstance.ang = Angle(0, ply:EyeAngles().y, 0)
        
        npcInstance:Update(function(success)
          if success then
            ply:ChatPrint("[IonRP NPC Gun] Moved NPC to new position")
          else
            ply:ChatPrint("[IonRP NPC Gun] Failed to update NPC!")
          end
        end)
      end
    },
    {
      text = "Rotate NPC",
      callback = function()
        IonRP.Dialog:RequestString(ply, "NPC Rotation", "Enter yaw angle (0-360):", tostring(npcInstance.ang.y), function(angleStr)
          local angle = tonumber(angleStr)
          if angle then
            npcInstance.ang = Angle(0, angle, 0)
            npcInstance:Update(function(success)
              if success then
                ply:ChatPrint("[IonRP NPC Gun] Rotated NPC to " .. angle .. " degrees")
              else
                ply:ChatPrint("[IonRP NPC Gun] Failed to update NPC!")
              end
            end)
          else
            ply:ChatPrint("[IonRP NPC Gun] Invalid angle!")
          end
        end)
      end
    },
    {
      text = "Delete NPC",
      callback = function()
        self:ConfirmDelete(ply, npcInstance)
      end
    }
  }
  
  IonRP.Dialog:OptionList(ply, "NPC Gun - Edit NPC", options)
end

--- Confirm NPC deletion
--- @param ply Player
--- @param npcInstance NPCInstance
function SWEP:ConfirmDelete(ply, npcInstance)
  local options = {
    {
      text = "Delete NPC: " .. npcInstance:GetName() .. "?",
      isLabel = true
    },
    {
      text = "Yes, Delete",
      callback = function()
        npcInstance:Delete(function(success)
          if success then
            ply:ChatPrint("[IonRP NPC Gun] Deleted NPC")
          else
            ply:ChatPrint("[IonRP NPC Gun] Failed to delete NPC!")
          end
        end)
      end
    },
    {
      text = "Cancel",
      callback = function()
        ply:ChatPrint("[IonRP NPC Gun] Cancelled deletion")
      end
    }
  }
  
  IonRP.Dialog:OptionList(ply, "NPC Gun - Confirm Delete", options)
end

--- Draw crosshair with placement preview
function SWEP:DrawHUD()
  local ply = LocalPlayer()
  
  if ply.NPCGun_PlacingNPC then
    draw.SimpleText("Placing NPC - LEFT CLICK to place, RIGHT CLICK to cancel", "DermaDefault", ScrW() / 2, ScrH() - 100, Color(100, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end
end

--- Holster the weapon
function SWEP:Holster()
  if SERVER then
    --- @type Player
    local ply = self:GetOwner()
    ClearEditingState(ply)
  end
  return true
end

--- When the weapon is removed
function SWEP:OnRemove()
  if SERVER then
    --- @type Player
    local ply = self:GetOwner()
    if IsValid(ply) then
      ClearEditingState(ply)
    end
  end
end
