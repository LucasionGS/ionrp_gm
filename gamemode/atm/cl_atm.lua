--[[
    ATM System - Client
    Visual feedback for ATM placement and interaction
]]--

--- Draw ATM outlines for developers
hook.Add("PostDrawOpaqueRenderables", "IonRP_ATM_DrawOutlines", function()
  local ply = LocalPlayer()
  
  -- Only show to developers
  if not ply:IsDeveloper() then return end
  
  -- Draw outline for all ATMs
  for _, ent in pairs(ents.GetAll()) do
    if IsValid(ent) and ent:GetNWString("EntityType") == IonRP.ATM.EntityClass then
      local pos = ent:GetPos()
      local ang = ent:GetAngles()
      local mins = IonRP.ATM.BoundsMin
      local maxs = IonRP.ATM.BoundsMax
      
      -- Draw box outline
      render.DrawWireframeBox(pos, ang, mins, maxs, Color(100, 200, 255, 200), true)
      
      -- Draw "ATM" text above
      local textPos = pos + Vector(0, 0, maxs.z + 10)
      local distance = ply:GetPos():Distance(pos)
      
      if distance < 500 then
        local atmId = ent:GetNWInt("ATM_ID", 0)
        
        cam.Start3D2D(textPos, Angle(0, LocalPlayer():EyeAngles().y - 90, 90), 0.1)
          draw.SimpleText("ATM", "DermaLarge", 0, 0, Color(100, 200, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
          draw.SimpleText("ID: " .. atmId, "DermaDefault", 0, 25, Color(200, 200, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
          draw.SimpleText("Press E to use", "DermaDefault", 0, 45, Color(255, 255, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
      end
    end
  end
end)

--- Draw placement preview when looking at a surface
hook.Add("HUDPaint", "IonRP_ATM_PlacementHint", function()
  local ply = LocalPlayer()
  
  -- Only show to developers
  if not ply:IsDeveloper() then return end
  
  local trace = ply:GetEyeTrace()
  
  -- Check if looking at an ATM
  if IsValid(trace.Entity) and trace.Entity:GetNWString("EntityType") == IonRP.ATM.EntityClass then
    local scrW, scrH = ScrW(), ScrH()
    
    draw.SimpleText("ATM Entity", "DermaLarge", scrW / 2, scrH / 2 + 40, Color(100, 200, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("Use /removeatm to delete", "DermaDefault", scrW / 2, scrH / 2 + 70, Color(255, 255, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end
end)

--- Console command for placement info
concommand.Add("ionrp_atm_help", function()
  print("=== IonRP ATM System Commands ===")
  print("/placeatm - Place an ATM at your crosshair position")
  print("/removeatm - Remove the ATM you're looking at")
  print("/listatms - List all ATMs on the current map")
  print("")
  print("ATMs are visible as blue wireframe boxes to developers.")
  print("Players can press E on ATMs to open the banking interface.")
end)

print("[IonRP ATM] Client module loaded")
