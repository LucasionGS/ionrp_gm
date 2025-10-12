--[[
    IonRP Crafting System
    Client-side crafting UI
]]--

include("sh_crafting.lua")

IonRP.CraftingUI = IonRP.CraftingUI or {}

-- Config
IonRP.CraftingUI.Config = {
  RecipeWidth = 300,
  RecipeHeight = 120,
  RecipePadding = 8,
  HeaderHeight = 60,
  Padding = 12,
  
  Colors = {
    Background = Color(25, 25, 35, 250),
    Header = Color(45, 35, 60, 255),
    RecipeBackground = Color(35, 35, 45, 220),
    RecipeHover = Color(45, 45, 60, 230),
    RecipeDisabled = Color(30, 30, 35, 200),
    
    IngredientBox = Color(40, 40, 50, 200),
    IngredientHave = Color(30, 80, 50, 100),
    IngredientNeed = Color(80, 30, 30, 100),
    
    Divider = Color(100, 80, 120, 100),
    Text = Color(255, 255, 255, 255),
    TextDim = Color(200, 200, 210, 255),
    TextMuted = Color(160, 160, 175, 255),
    Accent = Color(120, 100, 255, 255),
    AccentCyan = Color(100, 200, 255, 255),
    AccentGreen = Color(100, 255, 150, 255),
    Border = Color(60, 50, 80, 200),
  }
}

-- Current recipes
IonRP.CraftingUI.Recipes = {}

--[[
    Receive recipe sync from server
]]--
net.Receive("IonRP_SyncRecipes", function()
  local recipes = net.ReadTable()
  IonRP.CraftingUI.Recipes = recipes
  print("[IonRP Crafting] Received " .. #recipes .. " recipes from server")
  
  -- Refresh UI if open
  if IsValid(IonRP.CraftingUI.Frame) then
    IonRP.CraftingUI:RefreshRecipes()
  end
end)

--[[
    Open crafting UI
]]--
net.Receive("IonRP_OpenCrafting", function()
  IonRP.CraftingUI:Open()
end)

--[[
    Receive craft result
]]--
net.Receive("IonRP_CraftResult", function()
  local success = net.ReadBool()
  local message = net.ReadString()
  
  if success then
    surface.PlaySound("buttons/button14.wav")
  else
    surface.PlaySound("buttons/button10.wav")
    if message ~= "" then
      chat.AddText(Color(255, 100, 100), "[IonRP] ", Color(255, 255, 255), message)
    end
  end
end)

--[[
    Open the crafting UI
]]--
function IonRP.CraftingUI:Open()
  if IsValid(self.Frame) then
    self.Frame:Remove()
  end
  
  local cfg = self.Config
  local frameWidth = 900
  local frameHeight = 700
  
  -- Main frame
  local frame = vgui.Create("DFrame")
  frame:SetSize(frameWidth, frameHeight)
  frame:Center()
  frame:SetTitle("")
  frame:SetDraggable(true)
  frame:ShowCloseButton(false)
  frame:MakePopup()
  
  frame.Paint = function(self, w, h)
    draw.RoundedBox(8, 0, 0, w, h, cfg.Colors.Background)
    draw.RoundedBox(8, 0, 0, w, cfg.HeaderHeight, cfg.Colors.Header)
  end
  
  self.Frame = frame
  
  -- Header
  local header = vgui.Create("DPanel", frame)
  header:Dock(TOP)
  header:SetTall(cfg.HeaderHeight)
  header:DockMargin(0, 0, 0, 0)
  
  header.Paint = function(self, w, h)
    -- Title
    draw.SimpleText("Crafting", "DermaLarge", cfg.Padding + 5, h / 2, cfg.Colors.Text, 
      TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    
    -- Subtitle
    local recipeCount = #IonRP.CraftingUI.Recipes
    local craftableCount = 0
    for _, recipe in ipairs(IonRP.CraftingUI.Recipes) do
      if recipe.canCraft then
        craftableCount = craftableCount + 1
      end
    end
    
    draw.SimpleText(
      craftableCount .. " / " .. recipeCount .. " recipes available",
      "DermaDefault",
      cfg.Padding + 5,
      h / 2 + 20,
      cfg.Colors.TextMuted,
      TEXT_ALIGN_LEFT,
      TEXT_ALIGN_CENTER
    )
  end
  
  -- Close button
  local closeBtn = vgui.Create("DButton", header)
  closeBtn:SetPos(frameWidth - 40, 10)
  closeBtn:SetSize(30, 30)
  closeBtn:SetText("")
  
  closeBtn.Paint = function(self, w, h)
    local col = cfg.Colors.Border
    if self:IsHovered() then
      col = Color(255, 100, 100)
    end
    
    draw.RoundedBox(4, 0, 0, w, h, col)
    
    -- X
    surface.SetDrawColor(255, 255, 255)
    surface.DrawLine(8, 8, w - 8, h - 8)
    surface.DrawLine(w - 8, 8, 8, h - 8)
  end
  
  closeBtn.DoClick = function()
    IonRP.CraftingUI:Close()
  end
  
  -- Recipe scroll panel
  local scrollPanel = vgui.Create("DScrollPanel", frame)
  scrollPanel:Dock(FILL)
  scrollPanel:DockMargin(cfg.Padding, cfg.Padding, cfg.Padding, cfg.Padding)
  
  -- Style the scrollbar
  local sbar = scrollPanel:GetVBar()
  sbar:SetWide(8)
  sbar:SetHideButtons(true)
  
  function sbar:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 25, 150))
  end
  
  function sbar.btnGrip:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, cfg.Colors.Accent)
  end
  
  self.ScrollPanel = scrollPanel
  
  -- Create recipe list
  self:RefreshRecipes()
end

--[[
    Refresh recipe list
]]--
function IonRP.CraftingUI:RefreshRecipes()
  if not IsValid(self.ScrollPanel) then return end
  
  self.ScrollPanel:Clear()
  
  local cfg = self.Config
  
  -- Sort recipes: craftable first
  table.sort(self.Recipes, function(a, b)
    if a.canCraft ~= b.canCraft then
      return a.canCraft
    end
    return a.name < b.name
  end)
  
  -- Create recipe cards
  for _, recipe in ipairs(self.Recipes) do
    self:CreateRecipeCard(recipe)
  end
end

--[[
    Create a recipe card
]]--
function IonRP.CraftingUI:CreateRecipeCard(recipe)
  local cfg = self.Config
  
  local card = vgui.Create("DButton", self.ScrollPanel)
  card:Dock(TOP)
  card:DockMargin(0, 0, 0, cfg.RecipePadding)
  card:SetTall(cfg.RecipeHeight)
  card:SetText("")
  
  card.Paint = function(self, w, h)
    local bgColor = recipe.canCraft and cfg.Colors.RecipeBackground or cfg.Colors.RecipeDisabled
    
    if self:IsHovered() and recipe.canCraft then
      bgColor = cfg.Colors.RecipeHover
    end
    
    draw.RoundedBox(6, 0, 0, w, h, bgColor)
    
    -- Left side - Recipe info
    local padding = 12
    local yPos = padding
    
    -- Recipe name
    local nameColor = recipe.canCraft and cfg.Colors.Text or cfg.Colors.TextMuted
    draw.SimpleText(recipe.name, "DermaDefaultBold", padding, yPos, nameColor, TEXT_ALIGN_LEFT)
    yPos = yPos + 18
    
    -- Description
    draw.SimpleText(recipe.description, "DermaDefault", padding, yPos, cfg.Colors.TextDim, TEXT_ALIGN_LEFT)
    yPos = yPos + 16
    
    -- Requirements
    if recipe.requireWaterSource or recipe.requireHeatSource then
      yPos = yPos + 4
      local reqText = "Requires: "
      local reqs = {}
      if recipe.requireWaterSource then table.insert(reqs, "Water Source") end
      if recipe.requireHeatSource then table.insert(reqs, "Heat Source") end
      reqText = reqText .. table.concat(reqs, ", ")
      
      draw.SimpleText(reqText, "DermaDefault", padding, yPos, cfg.Colors.AccentCyan, TEXT_ALIGN_LEFT)
      yPos = yPos + 16
    end
    
    -- Ingredients
    yPos = yPos + 4
    draw.SimpleText("Ingredients:", "DermaDefault", padding, yPos, cfg.Colors.TextMuted, TEXT_ALIGN_LEFT)
    
    local xPos = padding
    yPos = yPos + 18
    
    local ply = LocalPlayer()
    local inv = ply.IonRP_ClientInventory
    
    for itemIdentifier, amount in pairs(recipe.ingredients) do
      local item = IonRP.Items.Get(itemIdentifier)
      if item then
        local hasAmount = 0
        
        if inv then
          for _, entry in ipairs(inv:GetAllItems()) do
            if entry.item.identifier == itemIdentifier then
              hasAmount = hasAmount + entry.quantity
            end
          end
        end
        
        local hasEnough = hasAmount >= amount
        local boxColor = hasEnough and cfg.Colors.IngredientHave or cfg.Colors.IngredientNeed
        local textColor = hasEnough and cfg.Colors.AccentGreen or Color(255, 100, 100)
        
        local boxWidth = 120
        local boxHeight = 20
        
        draw.RoundedBox(4, xPos, yPos, boxWidth, boxHeight, boxColor)
        
        local ingredientText = item.name .. " (" .. hasAmount .. "/" .. amount .. ")"
        draw.SimpleText(ingredientText, "DermaDefault", xPos + 6, yPos + boxHeight / 2, 
          textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        xPos = xPos + boxWidth + 8
        
        -- Wrap to next line if too wide
        if xPos > w - 250 then
          xPos = padding
          yPos = yPos + boxHeight + 4
        end
      end
    end
    
    -- Right side - Result
    local resultX = w - 180
    local resultY = padding
    
    draw.SimpleText("Result:", "DermaDefault", resultX, resultY, cfg.Colors.TextMuted, TEXT_ALIGN_LEFT)
    resultY = resultY + 18
    
    if recipe.result then
      local resultItem = IonRP.Items.Get(recipe.result)
      if resultItem then
        local resultText = resultItem.name
        if recipe.resultAmount > 1 then
          resultText = resultText .. " x" .. recipe.resultAmount
        end
        
        draw.RoundedBox(4, resultX, resultY, 160, 30, cfg.Colors.IngredientBox)
        draw.SimpleText(resultText, "DermaDefaultBold", resultX + 8, resultY + 15, 
          cfg.Colors.AccentGreen, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
      end
    end
    
    -- Craft button
    if recipe.canCraft then
      local btnWidth = 80
      local btnHeight = 30
      local btnX = w - btnWidth - padding
      local btnY = h - btnHeight - padding
      
      local btnColor = cfg.Colors.Accent
      if self:IsHovered() then
        btnColor = Color(140, 120, 255)
      end
      
      draw.RoundedBox(4, btnX, btnY, btnWidth, btnHeight, btnColor)
      draw.SimpleText("CRAFT", "DermaDefaultBold", btnX + btnWidth / 2, btnY + btnHeight / 2, 
        cfg.Colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
      -- Show reason
      if recipe.reason ~= "" then
        local btnX = padding
        local btnY = h - padding - 20
        draw.SimpleText("⚠ " .. recipe.reason, "DermaDefault", btnX, btnY, Color(255, 150, 100), TEXT_ALIGN_LEFT)
      end
    end
  end
  
  card.DoClick = function()
    if recipe.canCraft then
      IonRP.CraftingUI:RequestCraft(recipe.identifier)
    end
  end
end

--[[
    Request to craft a recipe
]]--
function IonRP.CraftingUI:RequestCraft(recipeIdentifier)
  net.Start("IonRP_RequestCraft")
    net.WriteString(recipeIdentifier)
  net.SendToServer()
end

--[[
    Close the crafting UI
]]--
function IonRP.CraftingUI:Close()
  if IsValid(self.Frame) then
    self.Frame:Remove()
    self.Frame = nil
  end
end

-- Key binding - F2 to open crafting menu
hook.Add("PlayerButtonDown", "IonRP_Crafting_OpenMenu", function(ply, button)
  if button == KEY_F2 then
    RunConsoleCommand("ionrp_cmd", "craft")
  end
end)

print("┌──────────────────┬─────────────────────────────────────────────────────────────•")
print("│ [IonRP Crafting] │ Client-side crafting UI loaded")
print("│ [IonRP Crafting] │ Press F2 or use /craft to open crafting menu")
print("└──────────────────┴─────────────────────────────────────────────────────────────•")
