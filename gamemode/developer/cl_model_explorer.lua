--[[
    IonRP Model Explorer
    Developer tool for browsing and copying model paths
]] --

IonRP.ModelExplorer = IonRP.ModelExplorer or {}

-- Cache models for performance
IonRP.ModelExplorer.ModelCache = {}
IonRP.ModelExplorer.Categories = {}
IonRP.ModelExplorer.WeaponClasses = {} -- Cache for weapon classes
IonRP.ModelExplorer.IsLoading = false

--[[
    Categorize a model path
]] --
local function CategorizeModel(modelPath)
  local lower = modelPath:lower()

  -- Player models
  if string.find(lower, "models/player") then
    return "Players"
  end

  -- NPCs and characters
  if string.find(lower, "combine") or string.find(lower, "police") or
      string.find(lower, "zombie") or string.find(lower, "vortigaunt") or
      string.find(lower, "alyx") or string.find(lower, "barney") or
      string.find(lower, "citizens") or string.find(lower, "refugee") then
    return "NPCs & Characters"
  end

  -- Vehicles
  if string.find(lower, "vehicle") or string.find(lower, "airboat") or
      string.find(lower, "buggy") or string.find(lower, "jeep") then
    return "Vehicles"
  end

  -- Weapons
  if string.find(lower, "weapon") or string.find(lower, "/w_") then
    return "Weapons"
  end

  -- Props - specific categories
  if string.find(lower, "props_c17") then
    return "Props - City"
  elseif string.find(lower, "props_junk") then
    return "Props - Junk"
  elseif string.find(lower, "props_lab") then
    return "Props - Lab"
  elseif string.find(lower, "props_interiors") then
    return "Props - Interiors"
  elseif string.find(lower, "props_wasteland") then
    return "Props - Wasteland"
  elseif string.find(lower, "props_combine") then
    return "Props - Combine"
  elseif string.find(lower, "props_") then
    return "Props - Other"
  end

  -- Items
  if string.find(lower, "items/") then
    return "Items"
  end

  -- Effects
  if string.find(lower, "effects/") then
    return "Effects"
  end

  -- Everything else
  return "Other"
end

--- Recursively scan a directory for models
--- @param dir string
--- @param models table
local function ScanDirectory(dir, models)
  local files, folders = file.Find(dir .. "*", "GAME")

  -- Add all .mdl files
  for _, fileName in ipairs(files) do
    if string.EndsWith(fileName, ".mdl") then
      table.insert(models, dir .. fileName)
    end
  end

  -- Recursively scan subdirectories
  for _, folder in ipairs(folders) do
    ScanDirectory(dir .. folder .. "/", models)
  end
end

--[[
    Scan for models in the game
]] --
function IonRP.ModelExplorer:ScanModels()
  if self.IsLoading then return end

  self.IsLoading = true
  self.ModelCache = {}
  self.Categories = {}
  self.WeaponClasses = {}

  print("[IonRP] Model Explorer: Scanning all models and weapon classes...")

  -- Scan the entire models directory recursively
  ScanDirectory("models/", self.ModelCache)

  -- Organize into categories
  for _, modelPath in ipairs(self.ModelCache) do
    local category = CategorizeModel(modelPath)

    if not self.Categories[category] then
      self.Categories[category] = {}
    end

    table.insert(self.Categories[category], modelPath)
  end

  -- Scan for weapon classes
  local weaponList = weapons.GetList()
  for _, wep in ipairs(weaponList) do
    if wep.ClassName and wep.ClassName ~= "" then
      -- Store weapon data: class, printname, and model
      table.insert(self.WeaponClasses, {
        class = wep.ClassName,
        name = wep.PrintName or wep.ClassName,
        model = wep.WorldModel or ""
      })
    end
  end

  -- Sort weapon classes by name
  table.sort(self.WeaponClasses, function(a, b)
    return a.name:lower() < b.name:lower()
  end)

  -- Add weapon classes as a special category
  self.Categories["Weapon Classes"] = self.WeaponClasses

  -- Sort each category
  for category, models in pairs(self.Categories) do
    if category ~= "Weapon Classes" then -- Already sorted
      table.sort(models)
    end
  end

  self.IsLoading = false

  local totalModels = #self.ModelCache
  local totalWeapons = #self.WeaponClasses
  local categoryCount = table.Count(self.Categories)
  print(string.format("[IonRP] Model Explorer: Found %d models, %d weapon classes in %d categories",
    totalModels, totalWeapons, categoryCount))
end

--[[
    Open the model explorer
]] --
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
  frame:ShowCloseButton(false)
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

  -- Category selector panel
  local categoryPanel = vgui.Create("DPanel", frame)
  categoryPanel:Dock(TOP)
  categoryPanel:SetTall(50)
  categoryPanel:DockMargin(10, 40, 10, 5)
  categoryPanel.Paint = function(self, w, h)
    draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 50, 255))
  end

  local categoryLabel = vgui.Create("DLabel", categoryPanel)
  categoryLabel:SetPos(10, 15)
  categoryLabel:SetText("Category:")
  categoryLabel:SetTextColor(Color(200, 200, 210))
  categoryLabel:SizeToContents()

  local categoryBox = vgui.Create("DComboBox", categoryPanel)
  categoryBox:SetPos(80, 10)
  categoryBox:SetSize(300, 30)
  categoryBox:SetValue("Select a category...")
  categoryBox.Paint = function(self, w, h)
    draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 60, 255))
  end

  -- Add "All Models" option
  categoryBox:AddChoice("All Models")

  -- Add all categories sorted
  local sortedCategories = {}
  for category, _ in pairs(self.Categories) do
    table.insert(sortedCategories, category)
  end
  table.sort(sortedCategories)

  for _, category in ipairs(sortedCategories) do
    local count = #self.Categories[category]
    categoryBox:AddChoice(string.format("%s (%d)", category, count))
  end

  -- Search bar
  local searchPanel = vgui.Create("DPanel", frame)
  searchPanel:Dock(TOP)
  searchPanel:SetTall(50)
  searchPanel:DockMargin(10, 5, 10, 5)
  searchPanel.Paint = function(self, w, h)
    draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 50, 255))
  end

  -- Refresh button (dock first so it stays right)
  local refreshBtn = vgui.Create("DButton", searchPanel)
  refreshBtn:Dock(RIGHT)
  refreshBtn:SetWide(130)
  refreshBtn:DockMargin(5, 10, 10, 10)
  refreshBtn:SetText("🔄 Refresh")
  refreshBtn:SetTextColor(Color(255, 255, 255))
  refreshBtn.Paint = function(self, w, h)
    local bgCol = self:IsHovered() and Color(120, 220, 255) or Color(100, 200, 255)
    draw.RoundedBox(4, 0, 0, w, h, bgCol)
  end

  local searchLabel = vgui.Create("DLabel", searchPanel)
  searchLabel:Dock(LEFT)
  searchLabel:SetWide(60)
  searchLabel:DockMargin(10, 0, 0, 0)
  searchLabel:SetText("Search:")
  searchLabel:SetTextColor(Color(200, 200, 210))
  searchLabel:SetContentAlignment(5) -- Center align

  local searchBox = vgui.Create("DTextEntry", searchPanel)
  searchBox:Dock(FILL)
  searchBox:DockMargin(5, 10, 5, 10)
  searchBox:SetPlaceholderText("Type to filter models...")
  searchBox.Paint = function(self, w, h)
    draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 60, 255))
    self:DrawTextEntryText(Color(255, 255, 255), Color(100, 200, 255), Color(255, 255, 255))
  end

  -- Info panel
  local infoPanel = vgui.Create("DPanel", frame)
  infoPanel:Dock(TOP)
  infoPanel:SetTall(30)
  infoPanel:DockMargin(10, 5, 10, 5)
  infoPanel.Paint = function(self, w, h)
    draw.RoundedBox(4, 0, 0, w, h, Color(45, 45, 55, 200))

    local text = string.format("Models: %d | Weapons: %d | Left-Click: Copy | Right-Click: Spawn/Give",
      #IonRP.ModelExplorer.ModelCache, #IonRP.ModelExplorer.WeaponClasses)
    draw.SimpleText(text, "DermaDefault", w / 2, h / 2, Color(180, 180, 190), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end

  -- Model list scroll panel
  local scroll = vgui.Create("DScrollPanel", frame)
  scroll:Dock(FILL)
  scroll:DockMargin(10, 5, 10, 5)

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

  -- Store current category and page
  local currentCategory = nil
  local currentPage = 1
  local modelsPerPage = 100

  -- Function to populate the list
  local function PopulateList(category, filter, page)
    scroll:Clear()

    filter = filter and filter:lower() or ""
    page = page or 1
    local displayedCount = 0
    local totalCount = 0
    local isWeaponCategory = false

    -- Determine which models to show
    local modelsToShow = {}

    if not category or category == "All Models" then
      -- Show all models
      modelsToShow = self.ModelCache
      totalCount = #self.ModelCache
    else
      -- Extract category name (remove count)
      local categoryName = category:match("(.+)%s%(%d+%)") or category

      -- Check if this is the weapon classes category
      if categoryName == "Weapon Classes" then
        isWeaponCategory = true
        modelsToShow = self.WeaponClasses
        totalCount = #modelsToShow
      elseif self.Categories[categoryName] then
        -- Show models from specific category
        modelsToShow = self.Categories[categoryName]
        totalCount = #modelsToShow
      end
    end

    -- Apply filter first to get filtered list
    local filteredModels = {}
    if isWeaponCategory then
      -- Filter weapon classes by name or class
      for _, weaponData in ipairs(modelsToShow) do
        local searchText = (weaponData.name .. " " .. weaponData.class):lower()
        if filter == "" or string.find(searchText, filter, 1, true) then
          table.insert(filteredModels, weaponData)
        end
      end
    else
      -- Filter models by path
      for _, modelPath in ipairs(modelsToShow) do
        if filter == "" or string.find(modelPath:lower(), filter, 1, true) then
          table.insert(filteredModels, modelPath)
        end
      end
    end

    local filteredCount = #filteredModels
    local totalPages = math.ceil(filteredCount / modelsPerPage)
    if totalPages < 1 then totalPages = 1 end

    -- Clamp page number
    if page < 1 then page = 1 end
    if page > totalPages then page = totalPages end
    currentPage = page

    -- Calculate range for current page
    local startIdx = ((page - 1) * modelsPerPage) + 1
    local endIdx = math.min(page * modelsPerPage, filteredCount)

    -- Display only models for current page
    for i = startIdx, endIdx do
      local entry = filteredModels[i]
      if entry then
        displayedCount = displayedCount + 1

        -- Check if this is a weapon class or model
        local isWeapon = isWeaponCategory
        local displayPath, weaponClass, weaponName, weaponModel

        if isWeapon then
          weaponClass = entry.class
          weaponName = entry.name
          weaponModel = entry.model
          displayPath = string.format("%s (%s)", weaponName, weaponClass)
        else
          displayPath = entry
        end

        -- Create model row
        local row = vgui.Create("DButton", scroll)
        row:Dock(TOP)
        row:SetTall(50)
        row:DockMargin(0, 0, 0, 2)
        row:SetText("")

        -- Store data based on type
        if isWeapon then
          row.WeaponClass = weaponClass
          row.WeaponName = weaponName
          row.DisplayPath = displayPath
          row.IsWeapon = true
        else
          row.ModelPath = displayPath
          row.IsWeapon = false
        end

        -- Model preview icon
        local modelIcon = vgui.Create("DModelPanel", row)
        modelIcon:SetPos(8, 5)
        modelIcon:SetSize(40, 40)
        modelIcon:SetModel(isWeapon and weaponModel or displayPath)
        modelIcon:SetMouseInputEnabled(false)

        -- Auto-calculate camera position based on model size
        local function UpdateCamera()
          local ent = modelIcon:GetEntity()
          if not IsValid(ent) then return end

          -- Get model bounds
          local mins, maxs = ent:GetRenderBounds()
          local size = maxs - mins
          local center = (mins + maxs) / 2

          -- Calculate the largest dimension
          local radius = math.max(size.x, size.y, size.z)

          -- Adjust camera distance based on model size
          local distance = radius * 2.5
          if distance < 20 then distance = 20 end   -- Minimum distance
          if distance > 150 then distance = 150 end -- Maximum distance

          -- Position camera at an angle
          local camPos = center + Vector(distance * 0.7, distance * 0.7, distance * 0.5)

          modelIcon:SetCamPos(camPos)
          modelIcon:SetLookAt(center)
          modelIcon:SetFOV(45)
        end

        -- Initial camera setup with delay to let model load
        timer.Simple(0.1, function()
          if IsValid(modelIcon) then
            UpdateCamera()
          end
        end)

        -- Rotate the model slowly
        modelIcon.LayoutEntity = function(self, ent)
          if IsValid(ent) then
            ent:SetAngles(Angle(0, RealTime() * 30, 0))
          end
        end

        row.Paint = function(self, w, h)
          local bgCol = Color(45, 45, 55, 200)

          if self:IsHovered() then
            bgCol = Color(60, 60, 75, 230)
          end

          draw.RoundedBox(4, 0, 0, w, h, bgCol)

          -- Left accent (different color for weapons)
          local accentCol = self.IsWeapon and Color(255, 150, 100, 200) or Color(100, 200, 255, 200)
          draw.RoundedBox(0, 0, 0, 3, h, accentCol)

          -- Display text (offset to make room for preview)
          local displayText = self.IsWeapon and self.DisplayPath or self.ModelPath
          draw.SimpleText(displayText, "DermaDefault", 60, h / 2, Color(255, 255, 255), TEXT_ALIGN_LEFT,
            TEXT_ALIGN_CENTER)

          -- Copy hint
          if self:IsHovered() then
            local hintText = self.IsWeapon and "Click to copy class" or "Click to copy"
            draw.SimpleText(hintText, "DermaDefault", w - 10, h / 2, Color(100, 255, 150), TEXT_ALIGN_RIGHT,
              TEXT_ALIGN_CENTER)
          end
        end

        row.DoClick = function(self)
          if self.IsWeapon then
            -- Copy weapon class
            SetClipboardText(self.WeaponClass)
            chat.AddText(Color(100, 255, 150), "[Model Explorer] ", Color(255, 255, 255), "Copied weapon class: ",
              Color(255, 150, 100), self.WeaponClass)
          else
            -- Copy model path
            SetClipboardText(self.ModelPath)
            chat.AddText(Color(100, 255, 150), "[Model Explorer] ", Color(255, 255, 255), "Copied: ",
              Color(100, 200, 255), self.ModelPath)
          end

          -- Visual feedback
          surface.PlaySound("buttons/button15.wav")
        end

        row.DoRightClick = function(self)
          if self.IsWeapon then
            -- Give weapon to player
            net.Start("IonRP_GiveWeapon")
            net.WriteString(self.WeaponClass)
            net.SendToServer()

            chat.AddText(Color(100, 200, 255), "[Model Explorer] ", Color(255, 255, 255), "Giving weapon: ",
              Color(255, 150, 100), self.WeaponClass)
            surface.PlaySound("buttons/button9.wav")
          else
            -- Spawn model at crosshair
            local ply = LocalPlayer()
            local trace = ply:GetEyeTrace()

            if trace.Hit then
              -- Send spawn request to server
              net.Start("IonRP_SpawnModel")
              net.WriteString(self.ModelPath)
              net.WriteVector(trace.HitPos)
              net.WriteAngle(Angle(0, ply:EyeAngles().y, 0))
              net.SendToServer()

              chat.AddText(Color(100, 200, 255), "[Model Explorer] ", Color(255, 255, 255), "Spawned model at crosshair")
              surface.PlaySound("buttons/button9.wav")
            else
              chat.AddText(Color(231, 76, 60), "[Model Explorer] ", Color(255, 255, 255),
                "Aim at a surface to spawn the model")
            end
          end
        end
      end
    end

    -- Update info text with pagination
    infoPanel.Paint = function(self, w, h)
      draw.RoundedBox(4, 0, 0, w, h, Color(45, 45, 55, 200))

      local text = string.format("Page %d / %d | Showing %d-%d of %d models | Click to copy",
        currentPage, totalPages, startIdx, endIdx, filteredCount)

      draw.SimpleText(text, "DermaDefault", w / 2, h / 2, Color(180, 180, 190), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
  end

  -- Pagination controls
  local paginationPanel = vgui.Create("DPanel", frame)
  paginationPanel:Dock(BOTTOM)
  paginationPanel:SetTall(50)
  paginationPanel:DockMargin(10, 5, 10, 10)
  paginationPanel.Paint = function(self, w, h)
    draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 50, 255))
  end

  -- Previous page button
  local prevBtn = vgui.Create("DButton", paginationPanel)
  prevBtn:Dock(LEFT)
  prevBtn:SetWide(120)
  prevBtn:DockMargin(10, 10, 5, 10)
  prevBtn:SetText("◀ Previous")
  prevBtn:SetTextColor(Color(255, 255, 255))
  prevBtn.Paint = function(self, w, h)
    local bgCol = Color(70, 70, 80, 255)
    if self:IsHovered() and currentPage > 1 then
      bgCol = Color(100, 200, 255, 255)
    elseif currentPage <= 1 then
      bgCol = Color(50, 50, 60, 255)
    end
    draw.RoundedBox(4, 0, 0, w, h, bgCol)
  end
  prevBtn.DoClick = function()
    if currentPage > 1 then
      PopulateList(currentCategory or "All Models", searchBox:GetValue(), currentPage - 1)
      surface.PlaySound("buttons/button14.wav")
    end
  end

  -- Next page button
  local nextBtn = vgui.Create("DButton", paginationPanel)
  nextBtn:Dock(RIGHT)
  nextBtn:SetWide(120)
  nextBtn:DockMargin(5, 10, 10, 10)
  nextBtn:SetText("Next ▶")
  nextBtn:SetTextColor(Color(255, 255, 255))
  nextBtn.Paint = function(self, w, h)
    local bgCol = Color(70, 70, 80, 255)
    if self:IsHovered() then
      bgCol = Color(100, 200, 255, 255)
    end
    draw.RoundedBox(4, 0, 0, w, h, bgCol)
  end
  nextBtn.DoClick = function()
    PopulateList(currentCategory or "All Models", searchBox:GetValue(), currentPage + 1)
    surface.PlaySound("buttons/button14.wav")
  end

  -- Page info label (in center)
  local pageLabel = vgui.Create("DPanel", paginationPanel)
  pageLabel:Dock(FILL)
  pageLabel:DockMargin(5, 10, 5, 10)
  pageLabel.Paint = function(self, w, h)
    draw.SimpleText("Page " .. currentPage, "DermaDefault", w / 2, h / 2, Color(100, 200, 255), TEXT_ALIGN_CENTER,
      TEXT_ALIGN_CENTER)
  end

  -- Initial population (show all)
  PopulateList("All Models", "", 1)
  categoryBox:SetValue("All Models")

  -- Category selection functionality
  categoryBox.OnSelect = function(self, index, value)
    currentCategory = value
    currentPage = 1
    PopulateList(value, searchBox:GetValue(), 1)
  end

  -- Search functionality
  searchBox.OnValueChange = function(self, value)
    currentPage = 1
    PopulateList(currentCategory or "All Models", value, 1)
  end

  -- Refresh functionality
  refreshBtn.DoClick = function()
    -- Store current selections
    local oldCategory = currentCategory
    local oldSearch = searchBox:GetValue()

    -- Rescan
    IonRP.ModelExplorer:ScanModels()

    -- Rebuild category dropdown
    categoryBox:Clear()
    categoryBox:AddChoice("All Models")

    local sortedCategories = {}
    for category, _ in pairs(IonRP.ModelExplorer.Categories) do
      table.insert(sortedCategories, category)
    end
    table.sort(sortedCategories)

    for _, category in ipairs(sortedCategories) do
      local count = #IonRP.ModelExplorer.Categories[category]
      categoryBox:AddChoice(string.format("%s (%d)", category, count))
    end

    -- Restore selections
    categoryBox:SetValue(oldCategory or "All Models")
    currentPage = 1
    PopulateList(oldCategory or "All Models", oldSearch, 1)
    surface.PlaySound("buttons/button9.wav")
  end
end

if CLIENT then
  -- Network receiver to open model explorer
  net.Receive("IonRP_OpenModelExplorer", function()
    IonRP.ModelExplorer:Open()
  end)

  -- Console command to open model explorer
  concommand.Add("ionrp_models", function()
    IonRP.ModelExplorer:Open()
  end)

  print("[IonRP] Model Explorer loaded - Type /models or ionrp_models to open")
end
