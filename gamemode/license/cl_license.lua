--- Client-side license management
--- Handles receiving synced licenses and UI rendering

--- Store local player's licenses
LocalPlayer().IonRP_Licenses = LocalPlayer().IonRP_Licenses or {}

--- Receive license sync from server
net.Receive("IonRP_License_SyncAll", function()
  local licensesData = net.ReadTable()
  local ply = LocalPlayer()
  
  ply.IonRP_Licenses = {}
  
  for _, data in ipairs(licensesData) do
    local licenseType = IonRP.Licenses.List[data.identifier]
    
    if licenseType then
      local licenseInstance = licenseType:MakeOwnedInstance(
        ply,
        data.state,
        data.reason,
        data.activateOn,
        data.grantedAt,
        data.updatedAt
      )
      
      ply.IonRP_Licenses[data.identifier] = licenseInstance
    end
  end
  
  print("[IonRP Licenses] Synced " .. #licensesData .. " licenses from server")
end)

--- Render a license card in a Derma panel
--- @param parent Panel The parent panel
--- @param licenseInstance LicenseInstance The license instance to render
--- @param x number X position
--- @param y number Y position
--- @param width number Card width
--- @param height number Card height
--- @return Panel The created license card panel
function IonRP.Licenses:RenderCard(parent, licenseInstance, x, y, width, height)
  local card = vgui.Create("DPanel", parent)
  card:SetPos(x, y)
  card:SetSize(width, height)
  
  local licenseType = licenseInstance.licenseType
  local isValid = LICENSE:IsValid(licenseInstance)
  
  card.Paint = function(self, w, h)
    -- Background
    local bgColor = isValid and Color(35, 45, 35, 230) or Color(45, 35, 35, 230)
    draw.RoundedBox(6, 0, 0, w, h, bgColor)
    
    -- Header bar with license color
    local headerColor = licenseType.color or Color(100, 150, 255)
    if not isValid then
      headerColor = Color(180, 60, 60) -- Red for invalid
    end
    draw.RoundedBox(6, 0, 0, w, 30, headerColor)
    draw.RoundedBox(0, 0, 24, w, 6, headerColor)
    
    -- License name
    draw.SimpleText(licenseType.name, "DermaDefaultBold", 10, 15, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    
    -- Status badge
    local statusText = licenseInstance.state == "active" and "ACTIVE" or "SUSPENDED"
    local statusColor = licenseInstance.state == "active" and Color(100, 255, 100) or Color(255, 100, 100)
    
    -- Check if waiting for activation
    if licenseInstance.activateOn then
      local activateTime = LICENSE:ParseDateTime(licenseInstance.activateOn)
      if activateTime and os.time() < activateTime then
        statusText = "PENDING"
        statusColor = Color(255, 200, 100)
      end
    end
    
    surface.SetFont("DermaDefaultBold")
    local statusW = surface.GetTextSize(statusText)
    draw.RoundedBox(4, w - statusW - 15, 8, statusW + 10, 14, Color(0, 0, 0, 150))
    draw.SimpleText(statusText, "DermaDefaultBold", w - 10, 15, statusColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    
    -- License info
    local yPos = 45
    
    -- Granted date
    if licenseInstance.grantedAt then
      draw.SimpleText("Granted: " .. licenseInstance.grantedAt, "DermaDefault", 10, yPos, Color(200, 200, 200), TEXT_ALIGN_LEFT)
      yPos = yPos + 18
    end
    
    -- Activation date (if pending)
    if licenseInstance.activateOn then
      local activateTime = LICENSE:ParseDateTime(licenseInstance.activateOn)
      if activateTime and os.time() < activateTime then
        draw.SimpleText("Activates: " .. licenseInstance.activateOn, "DermaDefault", 10, yPos, Color(255, 200, 100), TEXT_ALIGN_LEFT)
        yPos = yPos + 18
      end
    end
    
    -- Suspension reason
    if licenseInstance.state == "suspended" and licenseInstance.reason then
      draw.SimpleText("Reason:", "DermaDefaultBold", 10, yPos, Color(255, 150, 150), TEXT_ALIGN_LEFT)
      yPos = yPos + 18
      
      -- Word wrap the reason
      local reason = licenseInstance.reason
      surface.SetFont("DermaDefault")
      local maxWidth = w - 20
      local words = string.Explode(" ", reason)
      local line = ""
      
      for _, word in ipairs(words) do
        local testLine = line == "" and word or (line .. " " .. word)
        local lineW = surface.GetTextSize(testLine)
        
        if lineW > maxWidth then
          draw.SimpleText(line, "DermaDefault", 10, yPos, Color(255, 200, 200), TEXT_ALIGN_LEFT)
          yPos = yPos + 16
          line = word
        else
          line = testLine
        end
      end
      
      if line ~= "" then
        draw.SimpleText(line, "DermaDefault", 10, yPos, Color(255, 200, 200), TEXT_ALIGN_LEFT)
      end
    end
  end
  
  return card
end

--- Open a UI showing all player licenses
function IonRP.Licenses:OpenMenu()
  local ply = LocalPlayer()
  
  local frame = vgui.Create("DFrame")
  frame:SetSize(700, 500)
  frame:Center()
  frame:SetTitle("My Licenses")
  frame:MakePopup()
  
  local scroll = vgui.Create("DScrollPanel", frame)
  scroll:Dock(FILL)
  
  local yPos = 10
  local cardHeight = 120
  
  -- Show all registered license types
  for identifier, licenseType in pairs(IonRP.Licenses.List) do
    local licenseInstance = ply.IonRP_Licenses and ply.IonRP_Licenses[identifier]
    
    if licenseInstance then
      -- Player has this license
      self:RenderCard(scroll, licenseInstance, 10, yPos, 660, cardHeight)
      yPos = yPos + cardHeight + 10
    else
      -- Player doesn't have this license
      local card = vgui.Create("DPanel", scroll)
      card:SetPos(10, yPos)
      card:SetSize(660, 60)
      
      card.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(50, 50, 50, 150))
        draw.SimpleText(licenseType.name, "DermaDefaultBold", 10, 15, Color(150, 150, 150), TEXT_ALIGN_LEFT)
        draw.SimpleText("Not owned", "DermaDefault", 10, 35, Color(120, 120, 120), TEXT_ALIGN_LEFT)
      end
      
      yPos = yPos + 70
    end
  end
end
