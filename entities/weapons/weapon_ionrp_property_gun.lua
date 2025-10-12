--[[
    IonRP Property Gun
    Used by developers to create and edit properties on the map
]] --

SWEP.PrintName = "Property Gun"
SWEP.Author = "IonRP"
SWEP.Instructions = "Create and edit properties with ease"
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
-- ply.PropertyGun_EditingProperty (Property instance)
-- ply.PropertyGun_IsNewProperty (boolean)

--- Clear the player's property editing state
--- @param ply Player
local function ClearEditingState(ply)
  ply.PropertyGun_EditingProperty = nil
  ply.PropertyGun_IsNewProperty = nil
end

--- Get the door entity the player is looking at
--- @param ply Player
--- @return Entity|nil
local function GetLookingAtDoor(ply)
  local trace = ply:GetEyeTrace()
  local ent = trace.Entity

  if IsValid(ent) and (
        ent:GetClass() == "prop_door_rotating" or
        ent:GetClass() == "func_door" or
        ent:GetClass() == "func_door_rotating"
      ) then
    return ent
  end

  return nil
end

--- Check if a door is already in the property
--- @param property Property
--- @param doorPos Vector
--- @return boolean
local function IsDoorInProperty(property, doorPos)
  for _, door in ipairs(property.doors) do
    if door.pos:Distance(doorPos) < 10 then
      return true
    end
  end
  return false
end

--- Find a door in the property by position
--- @param property Property
--- @param doorPos Vector
--- @return PropertyDoor|nil
local function FindDoorInProperty(property, doorPos)
  for _, door in ipairs(property.doors) do
    if door.pos:Distance(doorPos) < 10 then
      return door
    end
  end
  return nil
end

--[[
    PRIMARY ATTACK - Add door to property
]] --
function SWEP:PrimaryAttack()
  if CLIENT then return end

  --- @type Player
  local ply = self:GetOwner()

  -- Check if editing a property
  if not ply.PropertyGun_EditingProperty then
    ply:ChatPrint("[IonRP] Press RELOAD to start creating a property first!")
    return
  end

  -- Get door entity
  local door = GetLookingAtDoor(ply)
  if not door then
    ply:ChatPrint("[IonRP] You must be looking at a door!")
    return
  end

  local doorPos = door:GetPos()
  local property = ply.PropertyGun_EditingProperty

  -- Check if door already added
  if IsDoorInProperty(property, doorPos) then
    ply:ChatPrint("[IonRP] This door is already added to the property!")
    return
  end

  -- Add door to property
  local doorObj = PROPERTY_DOOR:New({
    pos = doorPos,
    isLocked = false,
    isGate = false,
    group = nil
  })
  doorObj.property = property
  table.insert(property.doors, doorObj)

  ply:ChatPrint("[IonRP] Added door to property! (" .. #property.doors .. " total doors)")

  self:SetNextPrimaryFire(CurTime() + 0.2)
end

--[[
    SECONDARY ATTACK - Edit door or property settings
]] --
function SWEP:SecondaryAttack()
  if CLIENT then return end

  --- @type Player
  local ply = self:GetOwner()

  -- Check if editing a property
  if not ply.PropertyGun_EditingProperty then
    ply:ChatPrint("[IonRP] Press RELOAD to start creating a property first!")
    return
  end

  local property = ply.PropertyGun_EditingProperty
  local door = GetLookingAtDoor(ply)

  -- If looking at a door that's in the property, show door options
  if door then
    local doorPos = door:GetPos()
    local doorObj = FindDoorInProperty(property, doorPos)

    if doorObj then
      self:ShowDoorOptions(ply, property, doorObj)
      self:SetNextSecondaryFire(CurTime() + 0.3)
      return
    end
  end

  -- Otherwise show property options
  self:ShowPropertyOptions(ply, property)
  self:SetNextSecondaryFire(CurTime() + 0.3)
end

--[[
    RELOAD - Start/End property creation
]] --
function SWEP:Reload()
  if CLIENT then return end

  --- @type Player
  local ply = self:GetOwner()

  -- If already editing, show finish options
  if ply.PropertyGun_EditingProperty then
    self:ShowFinishOptions(ply)
    return
  end

  -- Check if looking at an existing property door to edit
  local door = GetLookingAtDoor(ply)
  if door then
    local doorPos = door:GetPos()
    
    -- First try to get property from door's networked variable
    local propertyId = door:GetNWInt("PropertyID", 0)
    if propertyId > 0 and IonRP.Properties.List[propertyId] then
      local property = IonRP.Properties.List[propertyId]
      ply.PropertyGun_EditingProperty = property
      ply.PropertyGun_IsNewProperty = false
      ply:ChatPrint("[IonRP] Started editing property: " .. property.name)
      ply:ChatPrint("[IonRP] Use LEFT CLICK to add/remove doors, RIGHT CLICK for settings")
      return
    end
    
    -- Fallback: Search through all properties for this door position
    for id, property in pairs(IonRP.Properties.List) do
      for _, doorObj in ipairs(property.doors) do
        if doorPos:DistToSqr(doorObj.pos) < 100 then -- Within ~10 units
          ply.PropertyGun_EditingProperty = property
          ply.PropertyGun_IsNewProperty = false
          ply:ChatPrint("[IonRP] Started editing property: " .. property.name)
          ply:ChatPrint("[IonRP] Use LEFT CLICK to add/remove doors, RIGHT CLICK for settings")
          return
        end
      end
    end
  end

  -- Start new property
  self:StartNewProperty(ply)
end

--[[
    Start creating a new property
]] --
function SWEP:StartNewProperty(ply)
  if CLIENT then return end

  IonRP.Dialog:RequestString(ply, "Property Name", "Enter the name for this property:", "", function(name)
    if not name or name == "" then
      ply:ChatPrint("[IonRP] Property name cannot be empty!")
      return
    end

    -- Create new property instance
    local property = PROPERTY:New({
      name = name,
      description = "No description",
      category = "Other",
      purchasable = true,
      price = 10000
    }, {})

    ply.PropertyGun_EditingProperty = property
    ply.PropertyGun_IsNewProperty = true

    ply:ChatPrint("[IonRP] Started creating property: " .. name)
    ply:ChatPrint("[IonRP] Use LEFT CLICK to add doors")
  end)
end

--- Show property options menu
--- @param ply Player
--- @
function SWEP:ShowPropertyOptions(ply, property)
  if CLIENT then return end

  local options = {
    {
      text = "Property: " .. property.name,
      isLabel = true
    },
    {
      text = "Change Name",
      callback = function()
        IonRP.Dialog:RequestString(ply, "Property Name", "Enter new name:", property.name, function(name)
          if name and name ~= "" then
            property.name = name
            ply:ChatPrint("[IonRP] Changed name to: " .. name)
          end
        end)
      end
    },
    {
      text = "Change Description",
      callback = function()
        IonRP.Dialog:RequestString(ply, "Description", "Enter description:", property.description, function(desc)
          if desc then
            property.description = desc
            ply:ChatPrint("[IonRP] Updated description")
          end
        end)
      end
    },
    {
      text = "Change Category",
      callback = function()
        IonRP.Dialog:RequestString(ply, "Category", "Enter category:", property.category, function(cat)
          if cat and cat ~= "" then
            property.category = cat
            ply:ChatPrint("[IonRP] Changed category to: " .. cat)
          end
        end)
      end
    },
    {
      text = "Set Price: $" .. property.price,
      callback = function()
        IonRP.Dialog:RequestString(ply, "Price", "Enter price:", tostring(property.price), function(priceStr)
          local price = tonumber(priceStr)
          if price and price >= 0 then
            property.price = price
            ply:ChatPrint("[IonRP] Set price to: $" .. price)
          else
            ply:ChatPrint("[IonRP] Invalid price!")
          end
        end)
      end
    },
    {
      text = "Toggle Purchasable: " .. (property.purchasable and "YES" or "NO"),
      callback = function()
        property.purchasable = not property.purchasable
        ply:ChatPrint("[IonRP] Purchasable: " .. (property.purchasable and "YES" or "NO"))
        -- Reopen the menu to show updated value
        timer.Simple(0.1, function()
          if IsValid(ply) then
            self:ShowPropertyOptions(ply, property)
          end
        end)
      end
    },
    {
      text = property.cameraPos and "Update Camera Position" or "Set Camera Position",
      callback = function()
        -- Get player's current view position and angle
        -- local trace = ply:GetEyeTrace()
        -- local cameraPos = trace.HitPos + trace.HitNormal * 5 -- Slightly offset from wall
        local cameraPos = ply:GetShootPos()
        local cameraAng = ply:EyeAngles()
        
        property.cameraPos = cameraPos
        property.cameraAng = cameraAng
        
        ply:ChatPrint("[IonRP] Set camera position for property preview!")
        ply:ChatPrint("[IonRP] Position: " .. tostring(cameraPos))
        ply:ChatPrint("[IonRP] Angle: " .. tostring(cameraAng))
        
        -- Reopen menu to show updated option text
        timer.Simple(0.1, function()
          if IsValid(ply) then
            self:ShowPropertyOptions(ply, property)
          end
        end)
      end
    },
    {
      text = property.cameraPos and "Clear Camera Position" or "<No Camera Set>",
      callback = property.cameraPos and function()
        property.cameraPos = nil
        property.cameraAng = nil
        ply:ChatPrint("[IonRP] Cleared camera position")
        
        -- Reopen menu
        timer.Simple(0.1, function()
          if IsValid(ply) then
            self:ShowPropertyOptions(ply, property)
          end
        end)
      end or nil
    },
    {
      text = "Done",
      callback = function() end
    }
  }

  IonRP.Dialog:ShowOptions(ply, "Property Settings", options)
end

--[[
    Show door options menu
]] --
function SWEP:ShowDoorOptions(ply, property, doorObj)
  if CLIENT then return end

  local options = {
    {
      text = "Door Settings",
      isLabel = true
    },
    {
      text = "Toggle Locked (" .. tostring(doorObj.isLocked) .. ")",
      callback = function()
        doorObj.isLocked = not doorObj.isLocked
        ply:ChatPrint("[IonRP] Door locked: " .. tostring(doorObj.isLocked))
      end
    },
    {
      text = "Toggle Gate (" .. tostring(doorObj.isGate) .. ")",
      callback = function()
        doorObj.isGate = not doorObj.isGate
        ply:ChatPrint("[IonRP] Door is gate: " .. tostring(doorObj.isGate))
      end
    },
    {
      text = "Set Group: " .. (doorObj.group or "None"),
      callback = function()
        IonRP.Dialog:RequestString(ply, "Door Group", "Enter group name (empty for none):", doorObj.group or "",
          function(group)
            if group == "" then
              doorObj.group = nil
              ply:ChatPrint("[IonRP] Cleared door group")
            else
              doorObj.group = group
              if group == nil then
                ply:ChatPrint("[IonRP] Set door group to nil")
              else
                ply:ChatPrint("[IonRP] Set door group to: " .. group)
              end
            end
          end)
      end
    },
    {
      text = "Remove Door",
      callback = function()
        for i, door in ipairs(property.doors) do
          if door == doorObj then
            table.remove(property.doors, i)
            ply:ChatPrint("[IonRP] Removed door from property")
            break
          end
        end
      end
    },
    {
      text = "Cancel",
      callback = function() end
    }
  }

  IonRP.Dialog:ShowOptions(ply, "Door Settings", options)
end

--[[
    Show finish/save options
]] --
function SWEP:ShowFinishOptions(ply)
  if CLIENT then return end

  --- @type Property
  local property = ply.PropertyGun_EditingProperty
  local isNew = ply.PropertyGun_IsNewProperty

  local options = {
    {
      text = "Property: " .. property.name,
      isLabel = true
    },
    {
      text = "Doors: " .. #property.doors,
      isLabel = true
    },
    {
      text = isNew and "Save New Property" or "Update Property",
      callback = function()
        if #property.doors == 0 then
          ply:ChatPrint("[IonRP] Cannot save property with no doors!")
          return
        end

        property:Save(function(success, propId)
          if success then
            ply:ChatPrint("[IonRP] Property saved successfully! (ID: " .. property.id .. ")")
            ClearEditingState(ply)
          else
            ply:ChatPrint("[IonRP] Failed to save property!")
          end
        end)
      end
    },
    {
      text = "Continue Editing",
      callback = function()
        ply:ChatPrint("[IonRP] Continuing property editing...")
      end
    },
    {
      text = "Cancel (Discard Changes)",
      callback = function()
        ClearEditingState(ply)
        ply:ChatPrint("[IonRP] Cancelled property editing")
      end
    }
  }

  IonRP.Dialog:ShowOptions(ply, "Finish Property", options)
end

--[[
    HUD Drawing (CLIENT)
]] --
if CLIENT then
  function SWEP:DrawHUD()
    local ply = LocalPlayer()
    local scrW, scrH = ScrW(), ScrH()

    -- Instructions
    local instructions = {
      "LEFT CLICK - Add Door",
      "RIGHT CLICK - Edit Door/Property",
      "RELOAD - Start/Finish Property"
    }

    local yOffset = 20
    for _, text in ipairs(instructions) do
      draw.SimpleText(text, "DermaDefault", scrW - 20, yOffset, Color(255, 255, 255, 230), TEXT_ALIGN_RIGHT,
        TEXT_ALIGN_TOP)
      yOffset = yOffset + 20
    end

    -- Show editing status
    if ply.PropertyGun_EditingProperty then
      local property = ply.PropertyGun_EditingProperty
      draw.SimpleText("Editing: " .. property.name, "DermaDefaultBold", scrW / 2, scrH - 80, Color(100, 200, 255),
        TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
      draw.SimpleText("Doors: " .. #property.doors, "DermaDefault", scrW / 2, scrH - 60, Color(255, 255, 255),
        TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
      
      -- Show camera status
      if property.cameraPos then
        draw.SimpleText("Camera: SET ✓", "DermaDefault", scrW / 2, scrH - 40, Color(100, 255, 100),
          TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
      else
        draw.SimpleText("Camera: Not Set", "DermaDefault", scrW / 2, scrH - 40, Color(255, 200, 100),
          TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
      end
    else
      draw.SimpleText("Press RELOAD to start", "DermaDefault", scrW / 2, scrH - 60, Color(255, 200, 100),
        TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end

    -- Highlight door being looked at
    local trace = ply:GetEyeTrace()
    local ent = trace.Entity

    if IsValid(ent) and (
          ent:GetClass() == "prop_door_rotating" or
          ent:GetClass() == "func_door" or
          ent:GetClass() == "func_door_rotating"
        ) then
      local color = Color(255, 255, 255)

      -- Change color if door is in current property
      if ply.PropertyGun_EditingProperty then
        local doorPos = ent:GetPos()
        local inProperty = false

        for _, door in ipairs(ply.PropertyGun_EditingProperty.doors) do
          if door.pos:Distance(doorPos) < 10 then
            inProperty = true
            break
          end
        end

        if inProperty then
          color = Color(100, 255, 100) -- Green if in property
        else
          color = Color(100, 200, 255) -- Blue if not in property
        end
      end

      halo.Add({ ent }, color, 2, 2, 2, true, true)
    end
    
    -- Draw camera preview frame (showing what the camera will see)
    if ply.PropertyGun_EditingProperty then
      local frameSize = 300
      local frameX = scrW - frameSize - 40
      local frameY = 100
      local borderSize = 4
      
      -- Draw frame border
      surface.SetDrawColor(100, 200, 255, 200)
      surface.DrawRect(frameX - borderSize, frameY - borderSize, frameSize + borderSize * 2, frameSize + borderSize * 2)
      
      -- Draw inner black box
      surface.SetDrawColor(0, 0, 0, 230)
      surface.DrawRect(frameX, frameY, frameSize, frameSize)
      
      -- Draw preview label
      draw.SimpleText("CAMERA PREVIEW", "DermaDefaultBold", frameX + frameSize / 2, frameY - 20, 
        Color(100, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
      
      -- Draw crosshair in center of preview
      local centerX = frameX + frameSize / 2
      local centerY = frameY + frameSize / 2
      surface.SetDrawColor(100, 200, 255, 180)
      surface.DrawLine(centerX - 10, centerY, centerX + 10, centerY)
      surface.DrawLine(centerX, centerY - 10, centerX, centerY + 10)
      
      -- Draw hint text
      draw.SimpleText("Right-click > Set Camera Position", "DermaDefault", frameX + frameSize / 2, frameY + frameSize + 10,
        Color(255, 255, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
  end
end

--[[
    Cleanup when weapon is holstered
]]--
function SWEP:Holster()
  -- Don't clear state on holster - let player resume editing when they re-equip
  return true
end

--[[
    Cleanup when weapon is removed/dropped
]]--
function SWEP:OnRemove()
  if SERVER then
    local ply = self:GetOwner()
    if IsValid(ply) then
      -- Optionally: Clear editing state when weapon is removed
      -- ClearEditingState(ply)
      -- For now, keep the state so players can continue editing after picking it back up
    end
  end
end

print("[IonRP] Property Gun loaded")
