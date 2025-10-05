--[[
    IonRP Model Explorer
    Developer tool for browsing and copying model paths
]]--

IonRP.ModelExplorer = IonRP.ModelExplorer or {}

-- Cache models for performance
IonRP.ModelExplorer.ModelCache = {}
IonRP.ModelExplorer.IsLoading = false

--[[
    Scan for models in the game
]]--
function IonRP.ModelExplorer:ScanModels()
  if self.IsLoading then return end
  
  self.IsLoading = true
  self.ModelCache = {}
  
  -- Common model directories to scan
  local directories = {
    "models/player/",
    "models/props_c17/",
    "models/props_junk/",
    "models/props_combine/",
    "models/props_lab/",
    "models/props_interiors/",
    "models/props_wasteland/",
    "models/props_vehicles/",
    "models/weapons/",
    "models/items/",
    "models/combine_soldier/",
    "models/police/",
  }
  
  -- Scan each directory for .mdl files
  for _, dir in ipairs(directories) do
    local files, folders = file.Find(dir .. "*", "GAME")
    
    -- Add models from this directory
    for _, fileName in ipairs(files) do
      if string.EndsWith(fileName, ".mdl") then
        local modelPath = dir .. fileName
        table.insert(self.ModelCache, modelPath)
      end
    end
    
    -- Recursively scan subdirectories (one level deep)
    for _, folder in ipairs(folders) do
      local subFiles = file.Find(dir .. folder .. "/*.mdl", "GAME")
      for _, fileName in ipairs(subFiles) do
        local modelPath = dir .. folder .. "/" .. fileName
        table.insert(self.ModelCache, modelPath)
      end
    end
  end
  
  -- Sort alphabetically
  table.sort(self.ModelCache)
  
  self.IsLoading = false
  
  print("[IonRP] Model Explorer: Found " .. #self.ModelCache .. " models")
end

--[[
    Open the model explorer
]]--
function IonRP.ModelExplorer:Open()
  -- Check if player is developer
  local ply = LocalPlayer()
  if not (ply.GetRankName and ply:GetRankName() == "Developer") then
    chat.AddText(Color(231, 76, 60), "[IonRP] ", Color(255, 255, 255), "Only Developers can access the Model Explorer")
    return
  end
  
  if IsValid(self.Frame) then
    self.Frame:Remove()
  end
  
  -- Scan models if not cached
  if #self.ModelCache == 0 then
    self:ScanModels()
  end
  
  local scrW, scrH = ScrW(), ScrH()
  
  -- Main frame
  local frame = vgui.Create("DFrame")
  frame:SetSize(900, scrH * 0.8)
  frame:SetTitle("")
  frame:SetDraggable(true)
  frame:ShowCloseButton(true)
  frame:Center()
  frame:MakePopup()
  self.Frame = frame
  
  -- Custom paint
  frame.Paint = function(self, w, h)
    -- Background
    draw.RoundedBox(6, 0, 0, w, h, Color(30, 30, 40, 250))
    
    -- Blue accent border
    surface.SetDrawColor(100, 200, 255, 220)
    surface.DrawOutlinedRect(0, 0, w, h, 2)
    
    -- Title bar
    draw.RoundedBox(4, 4, 4, w - 8, 30, Color(40, 40, 50, 255))
    draw.SimpleText("Model Explorer", "DermaLarge", w / 2, 19, Color(100, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end
  
  -- Close button
  local closeBtn = vgui.Create("DButton", frame)
  closeBtn:SetPos(frame:GetWide() - 32, 6)
  closeBtn:SetSize(26, 26)
  closeBtn:SetText("✕")
  closeBtn:SetTextColor(Color(255, 255, 255))
  closeBtn.Paint = function(self, w, h)
    local bgCol = self:IsHovered() and Color(231, 76, 60) or Color(60, 60, 70)
    draw.RoundedBox(4, 0, 0, w, h, bgCol)
  end
  closeBtn.DoClick = function()
    frame:Close()
  end
  
  -- Search bar
  local searchPanel = vgui.Create("DPanel", frame)
  searchPanel:Dock(TOP)
  searchPanel:SetTall(50)
  searchPanel:DockMargin(10, 40, 10, 5)
  searchPanel.Paint = function(self, w, h)
    draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 50, 255))
  end
  
  local searchLabel = vgui.Create("DLabel", searchPanel)
  searchLabel:SetPos(10, 8)
  searchLabel:SetText("Search:")
  searchLabel:SetTextColor(Color(200, 200, 210))
  searchLabel:SizeToContents()
  
  local searchBox = vgui.Create("DTextEntry", searchPanel)
  searchBox:SetPos(70, 10)
  searchBox:SetSize(searchPanel:GetWide() - 220, 30)
  searchBox:SetPlaceholderText("Type to filter models...")
  searchBox.Paint = function(self, w, h)
    draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 60, 255))
    self:DrawTextEntryText(Color(255, 255, 255), Color(100, 200, 255), Color(255, 255, 255))
  end
  
  -- Refresh button
  local refreshBtn = vgui.Create("DButton", searchPanel)
  refreshBtn:SetPos(searchPanel:GetWide() - 140, 10)
  refreshBtn:SetSize(130, 30)
  refreshBtn:SetText("🔄 Refresh Models")
  refreshBtn:SetTextColor(Color(255, 255, 255))
  refreshBtn.Paint = function(self, w, h)
    local bgCol = self:IsHovered() and Color(120, 220, 255) or Color(100, 200, 255)
    draw.RoundedBox(4, 0, 0, w, h, bgCol)
  end
  
  -- Info panel
  local infoPanel = vgui.Create("DPanel", frame)
  infoPanel:Dock(TOP)
  infoPanel:SetTall(30)
  infoPanel:DockMargin(10, 5, 10, 5)
  infoPanel.Paint = function(self, w, h)
    draw.RoundedBox(4, 0, 0, w, h, Color(45, 45, 55, 200))
    
    local text = string.format("Total Models: %d | Click a model to copy its path", #IonRP.ModelExplorer.ModelCache)
    draw.SimpleText(text, "DermaDefault", w / 2, h / 2, Color(180, 180, 190), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end
  
  -- Model list scroll panel
  local scroll = vgui.Create("DScrollPanel", frame)
  scroll:Dock(FILL)
  scroll:DockMargin(10, 5, 10, 10)
  
  -- Custom scrollbar
  local sbar = scroll:GetVBar()
  sbar:SetWide(10)
  sbar:SetHideButtons(true)
  
  function sbar:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 30, 200))
  end
  
  function sbar.btnGrip:Paint(w, h)
    local col = self:IsHovered() and Color(120, 220, 255) or Color(100, 200, 255)
    draw.RoundedBox(4, 0, 0, w, h, col)
  end
  
  -- Function to populate the list
  local function PopulateList(filter)
    scroll:Clear()
    
    filter = filter and filter:lower() or ""
    local displayedCount = 0
    
    for _, modelPath in ipairs(self.ModelCache) do
      -- Apply filter
      if filter == "" or string.find(modelPath:lower(), filter, 1, true) then
        displayedCount = displayedCount + 1
        
        -- Create model row
        local row = vgui.Create("DButton", scroll)
        row:Dock(TOP)
        row:SetTall(40)
        row:DockMargin(0, 0, 0, 2)
        row:SetText("")
        
        -- Store model path
        row.ModelPath = modelPath
        
        row.Paint = function(self, w, h)
          local bgCol = Color(45, 45, 55, 200)
          
          if self:IsHovered() then
            bgCol = Color(60, 60, 75, 230)
          end
          
          draw.RoundedBox(4, 0, 0, w, h, bgCol)
          
          -- Left accent
          draw.RoundedBox(0, 0, 0, 3, h, Color(100, 200, 255, 200))
          
          -- Model path text
          draw.SimpleText(self.ModelPath, "DermaDefault", 15, h / 2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
          
          -- Copy hint
          if self:IsHovered() then
            draw.SimpleText("Click to copy", "DermaDefault", w - 10, h / 2, Color(100, 255, 150), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
          end
        end
        
        row.DoClick = function(self)
          SetClipboardText(self.ModelPath)
          chat.AddText(Color(100, 255, 150), "[Model Explorer] ", Color(255, 255, 255), "Copied: ", Color(100, 200, 255), self.ModelPath)
          
          -- Visual feedback
          surface.PlaySound("buttons/button15.wav")
        end
      end
    end
    
    -- Update info text
    infoPanel.Paint = function(self, w, h)
      draw.RoundedBox(4, 0, 0, w, h, Color(45, 45, 55, 200))
      
      local text = string.format("Showing %d / %d models | Click a model to copy its path", displayedCount, #IonRP.ModelExplorer.ModelCache)
      draw.SimpleText(text, "DermaDefault", w / 2, h / 2, Color(180, 180, 190), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
  end
  
  -- Initial population
  PopulateList()
  
  -- Search functionality
  searchBox.OnValueChange = function(self, value)
    PopulateList(value)
  end
  
  -- Refresh functionality
  refreshBtn.DoClick = function()
    IonRP.ModelExplorer:ScanModels()
    PopulateList(searchBox:GetValue())
    surface.PlaySound("buttons/button9.wav")
  end
end

-- Console command to open model explorer
concommand.Add("ionrp_models", function()
  IonRP.ModelExplorer:Open()
end)

-- Chat command
hook.Add("OnPlayerChat", "IonRP_ModelExplorerCommand", function(ply, text)
  if ply == LocalPlayer() and string.lower(text) == "!models" then
    IonRP.ModelExplorer:Open()
    return true
  end
end)

print("[IonRP] Model Explorer loaded - Type !models or ionrp_models to open")
