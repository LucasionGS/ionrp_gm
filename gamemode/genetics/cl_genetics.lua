--[[
    IonRP Genetics System - Client
    UI for displaying and upgrading genetic attributes
]]--

include("sh_genetics.lua")

IonRP.Genetics = IonRP.Genetics or {}
IonRP.Genetics.ClientData = IonRP.Genetics.ClientData or nil

--- Receive genetics sync
net.Receive("IonRP_Genetics_Sync", function()
  local data = net.ReadTable()
  IonRP.Genetics.ClientData = data
  
  -- Refresh genetics UI if inventory is open and on Genetics tab
  if IsValid(IonRP.InventoryUI.State.frame) and IonRP.InventoryUI.State.activeTab == "Genetics" then
    IonRP.InventoryUI:SwitchTab("Genetics")
  end
end)

--- Show genetics tab content
function IonRP.InventoryUI:ShowGeneticsTab()
  if not IonRP.Genetics.ClientData then
    local label = vgui.Create("DLabel", IonRP.InventoryUI.State.contentPanel)
    label:SetText("Loading genetics...")
    label:SetFont("DermaLarge")
    label:SetTextColor(IonRP.InventoryUI.Config.Colors.TextDim)
    label:SizeToContents()
    label:Center()
    return
  end
  
  local genetics = IonRP.Genetics.ClientData
  local contentWidth = IonRP.InventoryUI.State.contentPanel:GetWide() - IonRP.InventoryUI.Config.Padding * 2
  local contentHeight = IonRP.InventoryUI.State.contentPanel:GetTall() - IonRP.InventoryUI.Config.Padding * 2
  
  -- Main panel
  local panel = vgui.Create("DPanel", IonRP.InventoryUI.State.contentPanel)
  panel:SetPos(IonRP.InventoryUI.Config.Padding, IonRP.InventoryUI.Config.Padding)
  panel:SetSize(contentWidth, contentHeight)
  panel.Paint = function() end
  
  -- Available points display at top
  local pointsPanel = vgui.Create("DPanel", panel)
  pointsPanel:SetPos(0, 0)
  pointsPanel:SetSize(contentWidth, 60)
  
  pointsPanel.Paint = function(self, w, h)
    draw.RoundedBox(6, 0, 0, w, h, Color(20, 22, 26, 240))
    
    surface.SetDrawColor(IonRP.InventoryUI.Config.Colors.BorderDark)
    surface.DrawOutlinedRect(0, 0, w, h, 2)
    
    -- Title
    draw.SimpleText("GENETIC POINTS AVAILABLE", "DermaDefaultBold", w / 2, 15, IonRP.InventoryUI.Config.Colors.TextDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    -- Points count
    local pointsText = tostring(genetics.availablePoints)
    draw.SimpleText(pointsText, "DermaLarge", w / 2, 32, IonRP.InventoryUI.Config.Colors.Accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
  end
  
  -- Genetics list
  local yPos = 75
  local entryHeight = 85
  local entryGap = 12
  
  local geneticTypes = {
    IonRP.Genetics.Types.STRENGTH,
    IonRP.Genetics.Types.INTELLIGENCE,
    IonRP.Genetics.Types.DEXTERITY,
    IonRP.Genetics.Types.INFLUENCE,
    IonRP.Genetics.Types.PERCEPTION
  }
  
  for _, gType in ipairs(geneticTypes) do
    self:CreateGeneticEntry(panel, gType, genetics, yPos, contentWidth, entryHeight)
    yPos = yPos + entryHeight + entryGap
  end
  
  -- Info text at bottom
  local infoText = "Influence affects purchase price from meat vendors."
  local infoY = contentHeight - 30
  
  panel.PaintOver = function(self, w, h)
    draw.SimpleText(infoText, "DermaDefault", w / 2, infoY, IonRP.InventoryUI.Config.Colors.TextDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
  end
end

--- Create a genetic entry
function IonRP.InventoryUI:CreateGeneticEntry(parent, gType, genetics, yPos, width, height)
  local info = IonRP.Genetics.Config.Info[gType]
  if not info then return end
  
  local currentLevel = genetics[gType] or 0
  local maxLevel = IonRP.Genetics.Config.MAX_LEVEL
  local canUpgrade = IonRP.Genetics.CanUpgrade(genetics, gType)
  
  local entry = vgui.Create("DPanel", parent)
  entry:SetPos(0, yPos)
  entry:SetSize(width, height)
  
  entry.Paint = function(self, w, h)
    -- Background
    local bgColor = Color(18, 20, 24, 240)
    draw.RoundedBox(6, 0, 0, w, h, bgColor)
    
    -- Border
    surface.SetDrawColor(IonRP.InventoryUI.Config.Colors.BorderDark)
    surface.DrawOutlinedRect(0, 0, w, h, 2)
    
    -- Colored left bar
    draw.RoundedBox(0, 0, 0, 8, h, info.color)
    
    -- Genetic name
    draw.SimpleText(info.name, "DermaLarge", 20, 15, info.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- Description
    draw.SimpleText(info.description, "DermaDefault", 20, 45, IonRP.InventoryUI.Config.Colors.TextDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- Level text
    local levelText = string.format("Level %d/%d", currentLevel, maxLevel)
    draw.SimpleText(levelText, "DermaLarge", w - 160, h / 2 - 5, IonRP.InventoryUI.Config.Colors.TextBright, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
  end
  
  -- Progress bar (visual level indicator)
  local barX = 20
  local barY = height - 20
  local barW = width - 180
  local barH = 8
  
  entry.PaintOver = function(self, w, h)
    -- Background bar
    draw.RoundedBox(4, barX, barY, barW, barH, Color(12, 14, 18, 255))
    
    -- Filled bar
    local fillW = barW * (currentLevel / maxLevel)
    if fillW > 0 then
      draw.RoundedBox(4, barX, barY, fillW, barH, info.color)
    end
  end
  
  -- Upgrade button
  local btn = vgui.Create("DButton", entry)
  btn:SetPos(width - 135, height / 2 - 17)
  btn:SetSize(120, 35)
  btn:SetText("")
  
  btn.Paint = function(self, w, h)
    local bgColor
    
    if canUpgrade then
      bgColor = Color(60, 140, 80, 255)
      if self:IsHovered() then
        bgColor = Color(80, 180, 100, 255)
      end
    else
      bgColor = Color(40, 42, 46, 255)
    end
    
    draw.RoundedBox(6, 0, 0, w, h, bgColor)
    
    surface.SetDrawColor(IonRP.InventoryUI.Config.Colors.BorderDark)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
    
    -- Plus icon and text
    local btnText = canUpgrade and "+ UPGRADE" or "MAX LEVEL"
    if not canUpgrade and genetics.availablePoints > 0 then
      btnText = "MAX"
    elseif not canUpgrade and currentLevel == 0 then
      btnText = "NO POINTS"
    end
    
    local textColor = canUpgrade and IonRP.InventoryUI.Config.Colors.TextBright or IonRP.InventoryUI.Config.Colors.TextDim
    draw.SimpleText(btnText, "DermaDefaultBold", w / 2, h / 2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end
  
  btn.DoClick = function()
    if canUpgrade then
      -- Send upgrade request to server
      net.Start("IonRP_Genetics_Upgrade")
      net.WriteString(gType)
      net.SendToServer()
    end
  end
end

print("[IonRP Genetics] Client-side genetics UI loaded")
