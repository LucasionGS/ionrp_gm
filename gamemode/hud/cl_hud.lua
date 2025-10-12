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
  local moneyText = IonRP.Util:FormatMoney(money)
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
  Draw player names above their heads for all nearby players
--]]
function GM:HUDDrawTargetID()
  local localPly = LocalPlayer()
  if not IsValid(localPly) then return end
  
  local eyePos = localPly:EyePos()

  for _, ply in ipairs(player.GetAll()) do
    if ply == localPly or not ply:Alive() or ply:Crouching() then continue end

    local distance = ply:GetPos():Distance(eyePos)

    if distance < 250 then
      local isHandcuffed = ply.IsHandcuffed and ply:IsHandcuffed() or false
      local pos = ply:GetPos() + Vector(0, 0, 75) -- Adjust the Z value to change the height of the text
      -- +10 in the direction the player is looking
      pos = pos + ply:GetAimVector() * 10
      local screenPos = pos:ToScreen()
      local playerName = ply.GetRPName and ply:GetRPName() or ply:Nick()
      local wantedLevel = ply.GetWantedLevel and ply:GetWantedLevel() or 0

      local traceData = {
        start = eyePos,
        endpos = pos,
        filter = {localPly, ply}
      }

      local trace = util.TraceLine(traceData)

      local alpha = 255 * (1 - distance / 250)
      if not trace.HitWorld then
        surface.SetFont("DermaLarge")
        local w, h = surface.GetTextSize(playerName)

        surface.SetTextColor(255, 255, 255, alpha)
        surface.SetTextPos(screenPos.x - w / 2, screenPos.y - h / 2)
        surface.DrawText(playerName)

        -- Draw organization if set (TODO: make orgs work)
        local org = ply:GetNWString("organization", "")
        if org and org ~= "" then
          surface.SetFont("DermaDefault")

          local w, h = surface.GetTextSize(org)

          surface.SetTextColor(0, 84, 201, alpha)
          surface.SetTextPos(screenPos.x - w / 2, screenPos.y - h / 2 + 30)
          surface.DrawText(org)
        end
      end

      -- Draw arrested status or wanted level
      if isHandcuffed then
        -- Draw "Arrested" over the name
        surface.SetFont("DermaLarge")
        local w, h = surface.GetTextSize("Arrested")

        surface.SetTextColor(255, 0, 0, alpha)
        surface.SetTextPos(screenPos.x - w / 2, screenPos.y - h / 2 - 30)
        surface.DrawText("Arrested")
      elseif wantedLevel > 0 then
        -- Draw wanted level in stars
        local starSize = 32
        local spacing = 4
        local x = screenPos.x - ((wantedLevel / 2) * (starSize + spacing / 2)) - spacing
        local y = screenPos.y - 50

        surface.SetDrawColor(255, 255, 255, alpha)
        for i = 1, wantedLevel do
          local starIcon = Material("icon16/star.png")
          surface.SetMaterial(starIcon)
          surface.DrawTexturedRect(x, y, starSize, starSize)

          x = x + starSize + spacing
        end
      end
    end
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
