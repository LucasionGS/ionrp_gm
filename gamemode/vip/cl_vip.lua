--[[
    VIP System - Client
    Client-side VIP display and data handling
]]--

IonRP.VIP = IonRP.VIP or {}
IonRP.VIP.Ranks = IonRP.VIP.Ranks or {}

-- Receive VIP data from server
net.Receive("IonRP_SendVIPData", function()
  -- Receive all VIP ranks
  local rankCount = net.ReadUInt(8)
  IonRP.VIP.Ranks = {}
  
  for i = 1, rankCount do
    local id = net.ReadUInt(8)
    local name = net.ReadString()
    local color = net.ReadColor()
    local level = net.ReadUInt(8)
    local description = net.ReadString()
    local purchasable = net.ReadBool()
    
    table.insert(IonRP.VIP.Ranks, {
      id = id,
      name = name,
      color = color,
      level = level,
      description = description,
      purchasable = purchasable
    })
  end
  
  -- Receive player's current VIP
  local currentVIP = net.ReadUInt(8)
  local expiresAt = net.ReadString()
  
  LocalPlayer():SetNWInt("IonRP_VIP", currentVIP)
  LocalPlayer():SetNWString("IonRP_VIP_Expires", expiresAt)
  
  print("[IonRP VIP] Received VIP data from server")
end)

-- Receive VIP update from server
net.Receive("IonRP_VIPUpdated", function()
  local newVIP = net.ReadInt(8)
  local expiresAt = net.ReadString()
  
  LocalPlayer():SetNWInt("IonRP_VIP", newVIP)
  LocalPlayer():SetNWString("IonRP_VIP_Expires", expiresAt)
  
  -- Get VIP rank data
  local vipData = nil
  for _, rank in ipairs(IonRP.VIP.Ranks) do
    if rank.id == newVIP then
      vipData = rank
      break
    end
  end
  
  if newVIP > 0 and vipData then
    chat.AddText(
      Color(100, 255, 100),
      "[VIP] ",
      Color(255, 255, 255),
      "Your VIP rank has been updated to ",
      vipData.color,
      vipData.name,
      Color(255, 255, 255),
      expiresAt ~= "" and (" (expires " .. expiresAt .. ")") or " (permanent)"
    )
    surface.PlaySound("buttons/button14.wav")
  else
    chat.AddText(
      Color(255, 100, 100),
      "[VIP] ",
      Color(255, 255, 255),
      "Your VIP rank has been removed"
    )
    surface.PlaySound("buttons/button10.wav")
  end
end)
