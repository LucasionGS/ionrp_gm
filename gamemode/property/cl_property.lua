--[[
  IonRP - Property System (Client)
  Displays property information when looking at doors
]]--

IonRP.Properties = IonRP.Properties or {}
IonRP.Properties.List = IonRP.Properties.List or {}

-- Display settings
local DISPLAY_DISTANCE = 200 -- Max distance to show property name
local FADE_START_DISTANCE = 150 -- Distance where fade starts
local TEXT_OFFSET = Vector(0, 0, 50) -- Offset above the door

-- Colors
local Colors = {
  PropertyName = Color(255, 255, 255, 255),
  PropertyOwned = Color(100, 255, 100, 255),
  PropertyUnowned = Color(150, 150, 255, 255),
  PropertyPrice = Color(255, 255, 100, 255),
  Background = Color(25, 25, 35, 200),
}

--[[
  Draw 3D text over a door
]]
local function Draw3DText(pos, text, color, scale)
  local ang = EyeAngles()
  ang:RotateAroundAxis(ang:Forward(), 90)
  ang:RotateAroundAxis(ang:Right(), 90)
  
  cam.Start3D2D(pos, ang, scale)
    draw.SimpleTextOutlined(
      text,
      "DermaLarge",
      0, 0,
      color,
      TEXT_ALIGN_CENTER,
      TEXT_ALIGN_CENTER,
      2,
      Color(0, 0, 0, 200)
    )
  cam.End3D2D()
end

--[[
  Find property by door position
]]
local function FindPropertyByDoor(doorPos)
  for id, property in pairs(IonRP.Properties.List) do
    for _, door in ipairs(property.doors) do
      if doorPos:DistToSqr(door.pos) < 100 then -- Within ~10 units
        return property
      end
    end
  end
  return nil
end

--[[
  Draw property information over doors
]]
hook.Add("PostDrawTranslucentRenderables", "IonRP_Properties_DrawDoorText", function(bDrawingSkybox, bDrawingDepth)
  if bDrawingSkybox or bDrawingDepth then return end
  
  local ply = LocalPlayer()
  if not IsValid(ply) then return end
  
  local trace = ply:GetEyeTrace()
  local ent = trace.Entity
  
  -- Check if looking at a door
  if not IsValid(ent) then return end
  
  local doorClass = ent:GetClass()
  if not (doorClass == "prop_door_rotating" or 
          doorClass == "func_door" or 
          doorClass == "func_door_rotating") then 
    return 
  end
  
  -- Check distance
  local distance = ply:GetPos():Distance(ent:GetPos())
  if distance > DISPLAY_DISTANCE then return end
  
  -- Get property ID from door
  local propertyId = ent:GetNWInt("PropertyID", 0)
  
  if propertyId <= 0 then
    -- Fallback: Try to find property by position
    local property = FindPropertyByDoor(ent:GetPos())
    if not property then 
      -- Debug: No property found
      return 
    end
    propertyId = property.id
  end
  
  -- Get property data
  local property = IonRP.Properties.List[propertyId]
  if not property then 
    -- Debug: Property not in list
    print("[IonRP Properties] Property ID " .. propertyId .. " not found in list")
    return 
  end
  
  -- Calculate fade alpha based on distance
  local alpha = 255
  if distance > FADE_START_DISTANCE then
    alpha = math.Remap(distance, FADE_START_DISTANCE, DISPLAY_DISTANCE, 255, 0)
  end
  
  -- Get door center position
  local doorCenter = ent:LocalToWorld(ent:OBBCenter())
  
  -- Move the text position toward the player (15 units forward, 5 units up from center)
  local toPlayer = (ply:EyePos() - doorCenter):GetNormalized()
  local doorPos = doorCenter + (toPlayer * 15) + Vector(0, 0, 5)
  
  -- Property name color (green if owned, blue if unowned)
  local nameColor = property.owner and Colors.PropertyOwned or Colors.PropertyUnowned
  nameColor = ColorAlpha(nameColor, alpha)
  
  -- Calculate angle to face the player
  local ang = EyeAngles()
  ang:RotateAroundAxis(ang:Forward(), 90)
  ang:RotateAroundAxis(ang:Right(), 90)
  
  -- Draw property name
  local scale = 0.15
  
  cam.Start3D2D(doorPos, ang, scale)
    -- Property name
    draw.SimpleTextOutlined(
      property.name,
      "DermaLarge",
      0, 0,
      nameColor,
      TEXT_ALIGN_CENTER,
      TEXT_ALIGN_CENTER,
      2,
      ColorAlpha(Color(0, 0, 0, 200), alpha)
    )
    
    -- Owner or price info
    local subText = ""
    local subColor = Colors.PropertyUnowned
    
    if property.owner and IsValid(property.owner) then
      subText = "Owned by " .. property.owner:Nick()
      subColor = Colors.PropertyOwned
    elseif property.purchasable then
      subText = "For Sale: $" .. string.Comma(property.price)
      subColor = Colors.PropertyPrice
    else
      subText = ""
      subColor = Color(180, 180, 180)
    end
    
    draw.SimpleTextOutlined(
      subText,
      "DermaDefault",
      0, 25,
      ColorAlpha(subColor, alpha),
      TEXT_ALIGN_CENTER,
      TEXT_ALIGN_CENTER,
      1,
      ColorAlpha(Color(0, 0, 0, 200), alpha)
    )
  cam.End3D2D()
end)

--[[
  Network receiver for property sync
]]
net.Receive("IonRP_Property_Sync", function()
  local propertyData = net.ReadTable()
  
  -- Create or update property instance on client
  local property = PROPERTY:New(propertyData, propertyData.doors)
  
  -- Store in client-side list
  IonRP.Properties.List[property.id] = property
  
  print("[IonRP Properties] Synced property: " .. property.name .. " (ID: " .. property.id .. ")")
end)

-- Debug command to list properties
concommand.Add("ionrp_list_properties", function()
  print("[IonRP Properties] Properties on client:")
  local count = 0
  for id, property in pairs(IonRP.Properties.List) do
    count = count + 1
    print("  - ID: " .. id .. " | Name: " .. property.name .. " | Doors: " .. #property.doors)
  end
  print("Total properties: " .. count)
end)

print("[IonRP Properties] Client module loaded")
