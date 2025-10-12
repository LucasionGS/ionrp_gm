AddCSLuaFile()

---
--- IonRP Keys SWEP
--- Used to lock/unlock property doors and vehicles
---

SWEP.PrintName = "Keys"
SWEP.Author = "IonRP"
SWEP.Instructions = "Left click to lock | Right click to unlock"
SWEP.Category = "IonRP"

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.ViewModel = "models/swep_keys_ced/v_swepkeys_ced.mdl"
SWEP.WorldModel = ""
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

--- Network strings for sounds
if SERVER then
  util.AddNetworkString("IonRP_Keys_PlaySound")
end

function SWEP:Initialize()
  self:SetHoldType("normal")
end

--- Check if a player can access a property door
--- @param ply Player The player to check
--- @param property Property The property to check access for
--- @return boolean
local function CanAccessPropertyDoor(ply, property)
  if not property then return false end
  
  --- Check if player owns the property
  if property.owner == ply then
    return true
  end
  
  --- Check if owner is buddy/friend with property permission
  if IsValid(property.owner) and property.owner:HasBuddyPermission(ply, "properties") then
    return true
  end
  
  --- TODO: Check if property has job restrictions (future feature)
  --- if property.jobs then
  ---   for _, jobId in ipairs(property.jobs) do
  ---     if ply:GetJob() == jobId then
  ---       return true
  ---     end
  ---   end
  --- end
  
  return false
end

--- Find property by door entity
--- @param doorEnt Entity The door entity to find property for
--- @return Property|nil property The property if found
--- @return PropertyDoor|nil door The door object if found
local function FindPropertyByDoor(doorEnt)
  if not IsValid(doorEnt) then return nil end
  
  local propertyId = doorEnt:GetNWInt("PropertyID", 0)
  if propertyId > 0 then
    return IonRP.Properties.List[propertyId]
  end
  
  --- Fallback: Search by position
  local doorPos = doorEnt:GetPos()
  for id, property in pairs(IonRP.Properties.List) do
    for _, door in ipairs(property.doors) do
      if doorPos:DistToSqr(door.pos) < 100 then --- Within ~10 units
        return property, door
      end
    end
  end
  
  return nil
end

--- Lock/unlock action
--- @param swep SWEP The weapon entity
--- @param lock boolean True to lock, false to unlock
local function Action(swep, lock)
  if CLIENT then return end
  
  --- @type Player
  local ply = swep:GetOwner()
  if not IsValid(ply) then return end
  
  local trace = ply:GetEyeTrace()
  local ent = trace.Entity
  
  if trace.HitWorld or not IsValid(ent) then return end
  
  local distance = ply:GetPos():Distance(ent:GetPos())
  
  --- Check if it's a door
  local entClass = ent:GetClass()
  if entClass == "prop_door_rotating" or entClass == "func_door" or entClass == "func_door_rotating" then
    if distance > 150 then return end
    
    --- Find property
    local property, doorObj = FindPropertyByDoor(ent)
    
    if not property then
      -- ply:ChatPrint("[IonRP] This door doesn't belong to any property")
      return
    end
    
    --- Check access
    if not CanAccessPropertyDoor(ply, property) then
      ent:EmitSound("doors/door_locked2.wav")
      -- ply:ChatPrint("[IonRP] You don't have access to this property")
      return
    end
    
    --- Find the door object in the property
    local doorPos = ent:GetPos()
    local targetDoor = nil
    for _, door in ipairs(property.doors) do
      if doorPos:DistToSqr(door.pos) < 100 then
        targetDoor = door
        break
      end
    end
    
    if not targetDoor then return end
    
    --- Get all doors in the same group
    local doorsToToggle = {}
    if targetDoor.group and targetDoor.group ~= "" then
      --- Lock/unlock all doors in the same group
      for _, door in ipairs(property.doors) do
        if door.group == targetDoor.group then
          table.insert(doorsToToggle, door)
        end
      end
    else
      --- Just this door
      table.insert(doorsToToggle, targetDoor)
    end
    
    --- Toggle all doors in group
    local soundPlayed = false
    for _, door in ipairs(doorsToToggle) do
      local priorState = door.isLocked
      door:SetLocked(lock)
      
      --- Play sound once per group
      if not soundPlayed and priorState ~= lock then
        if lock then
          net.Start("IonRP_Keys_PlaySound")
            net.WriteString("doors/door_latch1.wav")
          net.Send(ply)
        else
          net.Start("IonRP_Keys_PlaySound")
            net.WriteString("doors/door_latch3.wav")
          net.Send(ply)
        end
        soundPlayed = true
      end
    end
    
    --- Notify player
    -- if #doorsToToggle > 1 then
    --   ply:ChatPrint("[IonRP] " .. #doorsToToggle .. " doors " .. (lock and "locked" or "unlocked"))
    -- else
    --   ply:ChatPrint("[IonRP] Door " .. (lock and "locked" or "unlocked"))
    -- end
    
    return
  end
  
  --- Check if it's a vehicle
  if ent:IsVehicle() then
    --- Allow interaction from further away for vehicles
    if distance > 500 then return end
    
    --- Get vehicle data from Active table
    local vehicleData = IonRP.Vehicles.Active[ent:EntIndex()]
    if not vehicleData then return end
    
    --- Check if player owns the vehicle or is a buddy with vehicle permission
    local canAccess = vehicleData.owner == ply
    if not canAccess and IsValid(vehicleData.owner) then
      canAccess = vehicleData.owner:HasBuddyPermission(ply, "vehicles")
    end
    
    if not canAccess then
      -- ply:ChatPrint("[IonRP] You don't have access to this vehicle")
      ent:EmitSound("doors/door_locked2.wav")
      return
    end
    
    --- Get current lock state
    local wasLocked = ent:GetNWBool("lockedState", false)
    
    --- Lock/unlock the vehicle
    if lock and not wasLocked then
      vehicleData:SV_Lock()
    elseif not lock and wasLocked then
      vehicleData:SV_Unlock()
    end
    
    --- Play sound if state changed
    if wasLocked ~= lock then
      if distance > 125 then
        --- Play sound from far away
        net.Start("IonRP_Keys_PlaySound")
          net.WriteString("buttons/button9.wav") --- Car beep sound
        net.Send(ply)
      end
      
      -- ply:ChatPrint("[IonRP] Vehicle " .. (lock and "locked" or "unlocked"))
    end
    
    return
  end
end

function SWEP:PrimaryAttack()
  Action(self, true) --- Lock
  self:SetNextPrimaryFire(CurTime() + 0.5)
end

function SWEP:SecondaryAttack()
  Action(self, false) --- Unlock
  self:SetNextSecondaryFire(CurTime() + 0.5)
end

--- Client-side sound playback
if CLIENT then
  net.Receive("IonRP_Keys_PlaySound", function()
    local soundPath = net.ReadString()
    surface.PlaySound(soundPath)
  end)
end

print("[IonRP] Keys SWEP loaded")
