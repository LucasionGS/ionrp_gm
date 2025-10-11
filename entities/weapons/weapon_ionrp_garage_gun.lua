AddCSLuaFile()

--[[
    IonRP Garage Gun
    Used by developers to create and manage garage groups and parking spots
]]--

SWEP.PrintName = "Garage Gun"
SWEP.Author = "IonRP"
SWEP.Instructions = "Create and manage garage groups and parking spots"
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

-- Editing state stored on player:
-- ply.GarageGun_EditingGroup (GarageGroup)
-- ply.GarageGun_PlacingSpot (boolean)

if SERVER then
  --- Clear the player's garage editing state
  --- @param ply Player
  local function ClearEditingState(ply)
    ply.GarageGun_EditingGroup = nil
    ply.GarageGun_PlacingSpot = nil
  end
  
  --- Get the garage entity (anchor or spot) the player is looking at
  --- @param ply Player
  --- @return Entity|nil, string|nil entityType
  local function GetLookingAtGarageEntity(ply)
    local trace = ply:GetEyeTrace()
    local ent = trace.Entity
    
    if IsValid(ent) then
      local entType = ent:GetNWString("EntityType", "")
      if entType == IonRP.Garage.AnchorClass or entType == IonRP.Garage.SpotClass then
        return ent, entType
      end
    end
    
    return nil, nil
  end
  
  --[[
      PRIMARY ATTACK - Place spot or interact with existing
  ]]--
  function SWEP:PrimaryAttack()
    if CLIENT then return end
    
    --- @type Player
    local ply = self:GetOwner()
    
    -- If placing spot, create it
    if ply.GarageGun_PlacingSpot and ply.GarageGun_EditingGroup then
      self:PlaceSpot(ply)
      self:SetNextPrimaryFire(CurTime() + 0.3)
      return
    end
    
    -- Check if looking at existing anchor or spot
    local ent, entType = GetLookingAtGarageEntity(ply)
    if ent then
      if entType == IonRP.Garage.AnchorClass then
        -- Edit garage group
        local groupId = ent:GetNWInt("GarageGroupID", 0)
        local group = IonRP.Garage:GetGroupByID(groupId)
        if group then
          ply.GarageGun_EditingGroup = group
          ply.GarageGun_PlacingSpot = nil
          ply:ChatPrint("[IonRP Garage Gun] Started editing garage: " .. group.name)
          self:ShowGroupOptions(ply, group)
        end
      elseif entType == IonRP.Garage.SpotClass then
        -- Edit parking spot
        self:ShowSpotOptions(ply, ent)
      end
      self:SetNextPrimaryFire(CurTime() + 0.3)
      return
    end
    
    ply:ChatPrint("[IonRP Garage Gun] Look at a garage anchor or spot to edit, or RELOAD to create/manage")
    self:SetNextPrimaryFire(CurTime() + 0.3)
  end
  
  --[[
      SECONDARY ATTACK - Delete spot
  ]]--
  function SWEP:SecondaryAttack()
    if CLIENT then return end
    
    --- @type Player
    local ply = self:GetOwner()
    
    -- Cancel spot placement
    if ply.GarageGun_PlacingSpot then
      ply.GarageGun_PlacingSpot = nil
      ply:ChatPrint("[IonRP Garage Gun] Cancelled spot placement")
      self:SetNextSecondaryFire(CurTime() + 0.3)
      return
    end
    
    -- Check if looking at a spot to delete
    local ent, entType = GetLookingAtGarageEntity(ply)
    if ent and entType == IonRP.Garage.SpotClass then
      self:ConfirmDeleteSpot(ply, ent)
      self:SetNextSecondaryFire(CurTime() + 0.3)
      return
    end
    
    ply:ChatPrint("[IonRP Garage Gun] Look at a parking spot to delete it")
    self:SetNextSecondaryFire(CurTime() + 0.3)
  end
  
  --[[
      RELOAD - Start/finish group creation or show options
  ]]--
  function SWEP:Reload()
    if CLIENT then return end
    
    --- @type Player
    local ply = self:GetOwner()
    
    -- If editing a group, show finish options
    if ply.GarageGun_EditingGroup then
      self:ShowFinishOptions(ply)
      return
    end
    
    -- Check if looking at an existing anchor to edit
    local ent, entType = GetLookingAtGarageEntity(ply)
    if ent and entType == IonRP.Garage.AnchorClass then
      local groupId = ent:GetNWInt("GarageGroupID", 0)
      local group = IonRP.Garage:GetGroupByID(groupId)
      if group then
        ply.GarageGun_EditingGroup = group
        ply.GarageGun_PlacingSpot = nil
        ply:ChatPrint("[IonRP Garage Gun] Started editing garage: " .. group.name)
        self:ShowGroupOptions(ply, group)
      end
      return
    end
    
    -- Start creating a new garage group
    self:StartNewGroup(ply)
  end
  
  --[[
      Helper Functions
  ]]--
  
  --- Start creating a new garage group
  --- @param ply Player
  function SWEP:StartNewGroup(ply)
    local trace = ply:GetEyeTrace()
    local anchor = trace.HitPos
    
    IonRP.Dialog:RequestString(ply, "Garage Name", "Enter name for the garage:", "", function(name)
      if not name or name == "" then
        ply:ChatPrint("[IonRP Garage Gun] Name cannot be empty!")
        return
      end
      
      -- Create the group
      local identifier = string.lower(name):gsub("%s+", "_"):gsub("[^%w_]", "")
      local group = GARAGE_GROUP:New(identifier, name, anchor)
      
      -- Save to database
      IonRP.Garage:SaveGroup(group, function(success, groupId)
        if success then
          ply.GarageGun_EditingGroup = group
          ply.GarageGun_PlacingSpot = nil
          
          -- Spawn anchor entity
          IonRP.Garage:SpawnAnchorEntity(group)
          
          ply:ChatPrint("[IonRP Garage Gun] Created garage: " .. name)
          ply:ChatPrint("[IonRP Garage Gun] Now place parking spots with LEFT CLICK")
          ply.GarageGun_PlacingSpot = true
        else
          ply:ChatPrint("[IonRP Garage Gun] Failed to create garage!")
        end
      end)
    end)
  end
  
  --- Place a parking spot
  --- @param ply Player
  function SWEP:PlaceSpot(ply)
    local group = ply.GarageGun_EditingGroup
    if not group then return end
    
    local trace = ply:GetEyeTrace()
    local pos = trace.HitPos
    local ang = Angle(0, ply:EyeAngles().y, 0) -- Face player direction, level
    
    -- Create spot
    local spot = GARAGE_SPOT:New(pos, ang)
    group:AddSpot(spot)
    
    -- Save to database
    IonRP.Garage:SaveSpot(spot, function(success, spotId)
      if success then
        -- Spawn visual entity
        IonRP.Garage:SpawnSpotEntity(spot)
        ply:ChatPrint("[IonRP Garage Gun] Placed parking spot #" .. #group.spots)
      else
        ply:ChatPrint("[IonRP Garage Gun] Failed to save parking spot!")
        group:RemoveSpot(spot)
      end
    end)
  end
  
  --- Show group management options
  --- @param ply Player
  --- @param group GarageGroup
  function SWEP:ShowGroupOptions(ply, group)
    local options = {
      {
        text = "Garage: " .. group.name,
        isLabel = true
      },
      {
        text = "Spots: " .. #group.spots,
        isLabel = true
      },
      {
        text = "Change Name",
        callback = function()
          IonRP.Dialog:RequestString(ply, "Garage Name", "Enter new name:", group.name, function(name)
            if name and name ~= "" then
              group.name = name
              IonRP.Garage:UpdateGroup(group, function(success)
                if success then
                  ply:ChatPrint("[IonRP Garage Gun] Updated garage name")
                  
                  -- Update anchor entity
                  for _, ent in pairs(IonRP.Garage.Entities) do
                    if IsValid(ent) and ent:GetNWInt("GarageGroupID") == group.id then
                      ent:SetNWString("GarageName", name)
                      break
                    end
                  end
                else
                  ply:ChatPrint("[IonRP Garage Gun] Failed to update garage!")
                end
              end)
            end
          end)
        end
      },
      {
        text = "Move Anchor to Crosshair",
        callback = function()
          local trace = ply:GetEyeTrace()
          group.anchor = trace.HitPos
          
          IonRP.Garage:UpdateGroup(group, function(success)
            if success then
              ply:ChatPrint("[IonRP Garage Gun] Moved anchor point")
              
              -- Update anchor entity position
              for _, ent in pairs(IonRP.Garage.Entities) do
                if IsValid(ent) and ent:GetNWInt("GarageGroupID") == group.id and 
                   ent:GetNWString("EntityType") == IonRP.Garage.AnchorClass then
                  ent:SetPos(group.anchor)
                  break
                end
              end
            else
              ply:ChatPrint("[IonRP Garage Gun] Failed to update anchor!")
            end
          end)
        end
      },
      {
        text = "Start Placing Spots",
        callback = function()
          ply.GarageGun_PlacingSpot = true
          ply:ChatPrint("[IonRP Garage Gun] LEFT CLICK to place spots, RIGHT CLICK to cancel")
        end
      },
      {
        text = "Delete Garage",
        callback = function()
          self:ConfirmDeleteGroup(ply, group)
        end
      }
    }
    
    IonRP.Dialog:ShowOptions(ply, "Garage Settings", options)
  end
  
  --- Show parking spot options
  --- @param ply Player
  --- @param spotEnt Entity
  function SWEP:ShowSpotOptions(ply, spotEnt)
    local spotId = spotEnt:GetNWInt("GarageSpotID", 0)
    local groupId = spotEnt:GetNWInt("GarageGroupID", 0)
    local group = IonRP.Garage:GetGroupByID(groupId)
    
    if not group then return end
    
    -- Find the spot object
    local spot = nil
    for _, s in ipairs(group.spots) do
      if s.id == spotId then
        spot = s
        break
      end
    end
    
    if not spot then return end
    
    local options = {
      {
        text = "Parking Spot",
        isLabel = true
      },
      {
        text = "Group: " .. group.name,
        isLabel = true
      },
      {
        text = "Move to Crosshair",
        callback = function()
          local trace = ply:GetEyeTrace()
          spot.pos = trace.HitPos
          spot.ang = Angle(0, ply:EyeAngles().y, 0)
          
          IonRP.Garage:UpdateSpot(spot, function(success)
            if success then
              spotEnt:SetPos(spot.pos)
              spotEnt:SetAngles(spot.ang)
              ply:ChatPrint("[IonRP Garage Gun] Moved parking spot")
            else
              ply:ChatPrint("[IonRP Garage Gun] Failed to update spot!")
            end
          end)
        end
      },
      {
        text = "Delete Spot",
        callback = function()
          self:ConfirmDeleteSpot(ply, spotEnt)
        end
      }
    }
    
    IonRP.Dialog:ShowOptions(ply, "Parking Spot Settings", options)
  end
  
  --- Show finish/save options
  --- @param ply Player
  function SWEP:ShowFinishOptions(ply)
    local group = ply.GarageGun_EditingGroup
    if not group then return end
    
    local options = {
      {
        text = "Editing: " .. group.name,
        isLabel = true
      },
      {
        text = "Spots: " .. #group.spots,
        isLabel = true
      },
      {
        text = "Place More Spots",
        callback = function()
          ply.GarageGun_PlacingSpot = true
          ply:ChatPrint("[IonRP Garage Gun] LEFT CLICK to place spots")
        end
      },
      {
        text = "Finish Editing",
        callback = function()
          ClearEditingState(ply)
          ply:ChatPrint("[IonRP Garage Gun] Finished editing " .. group.name)
        end
      }
    }
    
    IonRP.Dialog:ShowOptions(ply, "Garage Management", options)
  end
  
  --- Confirm delete spot
  --- @param ply Player
  --- @param spotEnt Entity
  function SWEP:ConfirmDeleteSpot(ply, spotEnt)
    local spotId = spotEnt:GetNWInt("GarageSpotID", 0)
    local groupId = spotEnt:GetNWInt("GarageGroupID", 0)
    local group = IonRP.Garage:GetGroupByID(groupId)
    
    if not group or spotId == 0 then return end
    
    -- Find and remove spot
    for i, spot in ipairs(group.spots) do
      if spot.id == spotId then
        IonRP.Garage:DeleteSpot(spotId, function(success)
          if success then
            table.remove(group.spots, i)
            spotEnt:Remove()
            ply:ChatPrint("[IonRP Garage Gun] Deleted parking spot")
          else
            ply:ChatPrint("[IonRP Garage Gun] Failed to delete spot!")
          end
        end)
        break
      end
    end
  end
  
  --- Confirm delete group
  --- @param ply Player
  --- @param group GarageGroup
  function SWEP:ConfirmDeleteGroup(ply, group)
    if not group.id then return end
    
    IonRP.Dialog:ShowDialog(ply, {
      title = "Delete Garage?",
      message = "Are you sure you want to delete '" .. group.name .. "' and all its " .. #group.spots .. " parking spots?",
      buttons = {
        {
          text = "Delete",
          callback = function()
            IonRP.Garage:DeleteGroup(group.id, function(success)
              if success then
                -- Remove all entities
                for _, ent in pairs(IonRP.Garage.Entities) do
                  if IsValid(ent) and ent:GetNWInt("GarageGroupID") == group.id then
                    ent:Remove()
                  end
                end
                
                ClearEditingState(ply)
                ply:ChatPrint("[IonRP Garage Gun] Deleted garage: " .. group.name)
              else
                ply:ChatPrint("[IonRP Garage Gun] Failed to delete garage!")
              end
            end)
          end,
          color = Color(200, 50, 50)
        },
        {
          text = "Cancel",
          callback = function()
            ply:ChatPrint("[IonRP Garage Gun] Cancelled")
          end
        }
      }
    })
  end
end

if CLIENT then
  --[[
      Client-side HUD
  ]]--
  
  function SWEP:DrawHUD()
    local ply = LocalPlayer()
    local scrW, scrH = ScrW(), ScrH()
    
    -- Show placement mode indicator
    if ply.GarageGun_PlacingSpot then
      draw.SimpleText("Placing Parking Spots - LEFT CLICK to place, RIGHT CLICK to cancel", 
        "DermaDefault", scrW / 2, scrH - 100, Color(100, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    elseif ply.GarageGun_EditingGroup then
      local group = ply.GarageGun_EditingGroup
      draw.SimpleText("Editing Garage: " .. group.name .. " (" .. #group.spots .. " spots)", 
        "DermaDefault", scrW / 2, scrH - 100, Color(100, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
  end
end

--- Holster the weapon
function SWEP:Holster()
  if SERVER then
    local ply = self:GetOwner()
    -- Don't clear state on holster, keep editing session
  end
  return true
end

--- When the weapon is removed
function SWEP:OnRemove()
  if SERVER then
    local ply = self:GetOwner()
    if IsValid(ply) then
      -- Clear editing state when weapon is removed
      ply.GarageGun_EditingGroup = nil
      ply.GarageGun_PlacingSpot = nil
    end
  end
end
