--[[
    Garage System - Client
    Visual indicators and UI for garage system
]]--

--- Draw garage entity information in developer mode
hook.Add("PostDrawTranslucentRenderables", "IonRP_Garage_DrawInfo", function()
  local ply = LocalPlayer()
  
  -- Only show to developers
  if not ply:IsDevMode() then return end
  
  -- Draw info for all garage entities
  for _, ent in pairs(IonRP.Garage.Entities) do
    if IsValid(ent) then
      local entType = ent:GetNWString("EntityType", "")
      local pos = ent:GetPos()
      local ang = ent:GetAngles()
      
      -- Calculate screen position
      local screenPos = pos:ToScreen()
      
      if entType == IonRP.Garage.AnchorClass then
        -- Draw anchor info
        local garageName = ent:GetNWString("GarageName", "Unknown")
        local groupId = ent:GetNWInt("GarageGroupID", 0)
        
        -- Draw box around anchor
        render.DrawWireframeBox(pos, ang, Vector(-15, -15, -15), Vector(15, 15, 15), Color(255, 200, 0, 255), true)
        
        -- Draw text
        if screenPos.visible then
          draw.SimpleText("⚓ " .. garageName, "DermaDefault", screenPos.x, screenPos.y - 20, 
            Color(255, 200, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
          draw.SimpleText("Anchor (ID: " .. groupId .. ")", "DermaDefault", screenPos.x, screenPos.y - 5, 
            Color(255, 255, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
      elseif entType == IonRP.Garage.SpotClass then
        -- Draw spot info
        local spotId = ent:GetNWInt("GarageSpotID", 0)
        local groupId = ent:GetNWInt("GarageGroupID", 0)
        
        -- Draw box around spot
        render.DrawWireframeBox(pos, ang, Vector(-25, -25, 0), Vector(25, 25, 5), Color(0, 255, 100, 255), true)
        
        -- Draw text
        if screenPos.visible and ply:GetPos():Distance(pos) < 500 then
          draw.SimpleText("🅿 Spot #" .. spotId, "DermaDefault", screenPos.x, screenPos.y + 10, 
            Color(0, 255, 100, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
      end
    end
  end
end)

--- Draw HUD hints when looking at garage entities
hook.Add("HUDPaint", "IonRP_Garage_HUDHint", function()
  local ply = LocalPlayer()
  
  -- Only show to developers
  if not ply:IsDevMode() then return end
  
  local trace = ply:GetEyeTrace()
  
  -- Check if looking at a garage entity
  if IsValid(trace.Entity) then
    local entType = trace.Entity:GetNWString("EntityType", "")
    
    if entType == IonRP.Garage.AnchorClass or entType == IonRP.Garage.SpotClass then
      local scrW, scrH = ScrW(), ScrH()
      
      if entType == IonRP.Garage.AnchorClass then
        local garageName = trace.Entity:GetNWString("GarageName", "Unknown")
        draw.SimpleText("Garage Anchor: " .. garageName, "DermaLarge", scrW / 2, scrH / 2 + 40, 
          Color(255, 200, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Use Garage Gun to edit", "DermaDefault", scrW / 2, scrH / 2 + 70, 
          Color(255, 255, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
      else
        draw.SimpleText("Parking Spot", "DermaLarge", scrW / 2, scrH / 2 + 40, 
          Color(0, 255, 100, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Use Garage Gun to edit or delete", "DermaDefault", scrW / 2, scrH / 2 + 70, 
          Color(255, 255, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
      end
    end
  end
end)

--- Find and track all garage entities
local function UpdateGarageEntities()
  IonRP.Garage.Entities = {}
  
  for _, ent in pairs(ents.GetAll()) do
    if IsValid(ent) then
      local entType = ent:GetNWString("EntityType", "")
      if entType == IonRP.Garage.AnchorClass or entType == IonRP.Garage.SpotClass then
        IonRP.Garage.Entities[ent:EntIndex()] = ent
      end
    end
  end
end

--- Update entity visibility based on devmode status
local function UpdateEntityVisibility()
  local ply = LocalPlayer()
  if not IsValid(ply) then return end
  
  local isDevMode = ply:IsDevMode()
  
  for _, ent in pairs(ents.GetAll()) do
    if IsValid(ent) and ent:GetNWBool("IonRP_DevModeOnly", false) then
      -- Set visibility based on devmode status
      if isDevMode then
        ent:SetNoDraw(false)
        ent:SetRenderMode(RENDERMODE_TRANSALPHA)
      else
        ent:SetNoDraw(true)
        ent:SetRenderMode(RENDERMODE_NONE)
      end
    end
  end
end

--- Hook to handle new entities
hook.Add("OnEntityCreated", "IonRP_Garage_TrackEntity", function(ent)
  -- Wait a tick for NWVars to be set
  timer.Simple(0, function()
    if not IsValid(ent) then return end
    
    local entType = ent:GetNWString("EntityType", "")
    if entType == IonRP.Garage.AnchorClass or entType == IonRP.Garage.SpotClass then
      IonRP.Garage.Entities[ent:EntIndex()] = ent
      UpdateEntityVisibility()
    end
  end)
end)

--- Periodic visibility update (every second)
timer.Create("IonRP_Garage_VisibilityUpdate", 1, 0, function()
  UpdateEntityVisibility()
end)

--- Initial update when player spawns
hook.Add("InitPostEntity", "IonRP_Garage_InitialUpdate", function()
  timer.Simple(2, function()
    UpdateGarageEntities()
    UpdateEntityVisibility()
  end)
end)

print("[IonRP Garage] Client module loaded")
