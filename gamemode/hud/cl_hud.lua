--[[
  GM:HUDPaint
  Called every frame to draw the HUD
--]]
function GM:HUDPaint()
  self:HUDDrawTargetID()
  self:HUDDrawPickupHistory()
  self:DrawIonRPHUD()
end

--[[
  Draw HUD
  Shows player info in bottom left corner
--]]
function GM:DrawIonRPHUD()
  local ply = LocalPlayer()
  if not IsValid(ply) or not ply:Alive() then return end

  -- HUD Configuration
  local padding = 20
  local barWidth = 300
  local barHeight = 25
  local spacing = 8
  local cornerRadius = 6

  -- Position (bottom left)
  local x = padding
  local y = ScrH() - padding

  -- Colors
  local bgColor = Color(30, 30, 30, 220)
  local borderColor = Color(60, 60, 60, 255)
  local healthColor = Color(231, 76, 60)
  local armorColor = Color(52, 152, 219)
  local moneyColor = Color(46, 204, 113)
  local textColor = Color(255, 255, 255)
  local barBgColor = Color(20, 20, 20, 180)

  -- Get player data
  local health = math.max(0, ply:Health())
  local maxHealth = ply:GetMaxHealth() or 100
  local armor = math.max(0, ply:Armor())
  local maxArmor = 100
  local money = ply:GetWallet()
  local name = ply.GetRPName and ply:GetRPName() or ply:Nick()

  -- Calculate dimensions
  local totalHeight = 60 + barHeight * 3 + spacing * 2

  -- Main background panel
  y = y - totalHeight
  draw.RoundedBox(cornerRadius, x, y, barWidth, totalHeight, bgColor)
  draw.RoundedBox(cornerRadius, x, y, barWidth, totalHeight, Color(borderColor.r, borderColor.g, borderColor.b, 100))

  -- Player name
  draw.SimpleText(name, "DermaLarge", x + barWidth / 2, y + 10, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

  local barY = y + 45

  -- Health bar
  draw.RoundedBox(cornerRadius, x + 10, barY, barWidth - 20, barHeight, barBgColor)
  local healthPercent = math.Clamp(health / maxHealth, 0, 1)
  if healthPercent > 0 then
    draw.RoundedBox(cornerRadius, x + 10, barY, (barWidth - 20) * healthPercent, barHeight, healthColor)
  end
  draw.SimpleText("Health: " .. health, "DermaDefault", x + barWidth / 2, barY + barHeight / 2, textColor,
    TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

  barY = barY + barHeight + spacing

  -- Armor bar
  draw.RoundedBox(cornerRadius, x + 10, barY, barWidth - 20, barHeight, barBgColor)
  local armorPercent = math.Clamp(armor / maxArmor, 0, 1)
  if armorPercent > 0 then
    draw.RoundedBox(cornerRadius, x + 10, barY, (barWidth - 20) * armorPercent, barHeight, armorColor)
  end
  draw.SimpleText("Armor: " .. armor, "DermaDefault", x + barWidth / 2, barY + barHeight / 2, textColor,
    TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

  barY = barY + barHeight + spacing

  -- Money bar (no fill, just display)
  draw.RoundedBox(cornerRadius, x + 10, barY, barWidth - 20, barHeight, barBgColor)
  draw.RoundedBox(cornerRadius, x + 10, barY, barWidth - 20, barHeight,
  Color(moneyColor.r, moneyColor.g, moneyColor.b, 60))
  local moneyText = self:FormatMoney(money)
  draw.SimpleText("Cash: " .. moneyText, "DermaDefault", x + barWidth / 2, barY + barHeight / 2, moneyColor,
    TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  
  -- Ammo display (if weapon is equipped)
  local weapon = ply:GetActiveWeapon()
  if IsValid(weapon) and weapon.GetPrintName then
    local clip = weapon:Clip1()
    local ammoType = weapon:GetPrimaryAmmoType()
    local reserveAmmo = ply:GetAmmoCount(ammoType)
    
    -- Only show if weapon uses ammo
    if clip >= 0 or reserveAmmo > 0 then
      -- Position on bottom right
      local ammoX = ScrW() - barWidth - padding
      local ammoY = ScrH() - padding - barHeight * 2 - spacing
      local ammoBarWidth = barWidth * 0.6 -- Smaller width for ammo display
      
      -- Background panel
      draw.RoundedBox(cornerRadius, ammoX, ammoY, ammoBarWidth, barHeight * 2 + spacing, bgColor)
      
      -- Weapon name
      local weaponName = weapon:GetPrintName() or weapon:GetClass()
      draw.SimpleText(weaponName, "DermaDefault", ammoX + ammoBarWidth / 2, ammoY + 8, textColor, 
        TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
      
      -- Ammo display
      local ammoY2 = ammoY + barHeight + spacing - 5
      local ammoColor = Color(255, 193, 7) -- Orange/yellow for ammo
      
      if clip >= 0 then
        -- Weapon uses clips
        local clipText = string.format("%d / %d", clip, reserveAmmo)
        draw.SimpleText(clipText, "DermaLarge", ammoX + ammoBarWidth / 2, ammoY2, ammoColor,
          TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
      else
        -- Weapon doesn't use clips (like RPG, Crossbow)
        draw.SimpleText(tostring(reserveAmmo), "DermaLarge", ammoX + ammoBarWidth / 2, ammoY2, ammoColor,
          TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
      end
    end
  end
end

--[[
  Return false to hide default HUD elements
--]]
function GM:HUDShouldDraw(name)
  -- Hide default health/ammo HUD since we have our own
  local hideElements = {
    ["CHudHealth"] = true,
    ["CHudBattery"] = true,
    ["CHudAmmo"] = true,
    ["CHudSecondaryAmmo"] = true,
    ["CHudDamageIndicator"] = false, -- Keep damage indicator
  }

  if hideElements[name] then
    return false
  end

  return true
end

--[[
  Draw information about the entity the player is looking at
--]]
function GM:HUDDrawTargetID()
  local ply = LocalPlayer()
  local trace = ply:GetEyeTrace()

  if not IsValid(trace.Entity) then return end
  if trace.Entity:IsPlayer() then
    --[[ @type Player ]] --
    local targetPly = trace.Entity
    local pos = targetPly:EyePos()

    local screenPos = pos:ToScreen()
    local x, y = screenPos.x, screenPos.y
    
    -- Get player info
    local name = targetPly.GetRPName and targetPly:GetRPName() or targetPly:Nick()
    local rankName = targetPly.GetRankName and targetPly:GetRankName() or ""
    local rankColor = targetPly.GetRankColor and targetPly:GetRankColor() or Color(200, 200, 200)
    local health = targetPly:Health()
    
    -- Draw rank (if not User)
    local yOffset = y
    if rankName ~= "" and rankName ~= "User" then
      draw.SimpleText(rankName, "DermaDefault", x, yOffset, rankColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
      yOffset = yOffset + 15
    end

    -- Draw player name
    draw.SimpleText(name, "DermaDefault", x, yOffset, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Draw player health
    draw.SimpleText("Health: " .. health, "DermaDefault", x, yOffset + 15, Color(255, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end
end

--[[
  Draw recently picked up items
--]]
function GM:HUDDrawPickupHistory()
  -- This is handled by the base gamemode
  self.BaseClass.HUDDrawPickupHistory(self)
end

--[[
  Called after rendering opaque entities
--]]
function GM:PostDrawOpaqueRenderables()
  -- Draw 3D stuff here
end

--[[
  Draw death notices
--]]
function GM:DrawDeathNotice(x, y)
  -- Use default death notices or create custom ones
  return self.BaseClass.DrawDeathNotice(self, x, y)
end
