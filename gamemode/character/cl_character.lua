--[[
    Character Creation UI
    Client-side character creation interface
]] --

IonRP.Character = IonRP.Character or {}

-- Available character models (synced from server)
IonRP.Character.Models = {
  Male = {
    "models/player/Group01/male_01.mdl",
    "models/player/Group01/male_02.mdl",
    "models/player/Group01/male_03.mdl",
    "models/player/Group01/male_04.mdl",
    "models/player/Group01/male_05.mdl",
    "models/player/Group01/male_06.mdl",
    "models/player/Group01/male_07.mdl",
    "models/player/Group01/male_08.mdl",
    "models/player/Group01/male_09.mdl",
  },
  Female = {
    "models/player/Group01/female_01.mdl",
    "models/player/Group01/female_02.mdl",
    "models/player/Group01/female_03.mdl",
    "models/player/Group01/female_04.mdl",
    "models/player/Group01/female_05.mdl",
    "models/player/Group01/female_06.mdl",
  }
}

--[[
    Open character creation menu
]] --
function IonRP.Character:OpenCreationMenu()
  if IsValid(self.CreationFrame) then
    self.CreationFrame:Remove()
  end

  local scrW, scrH = ScrW(), ScrH()
  local frameW, frameH = 600, 500

  -- Main frame
  local frame = vgui.Create("DFrame")
  frame:SetSize(frameW, frameH)
  frame:Center()
  frame:SetTitle("Create Your Character")
  frame:SetDraggable(false)
  frame:ShowCloseButton(false)
  frame:MakePopup()
  self.CreationFrame = frame

  -- Background
  frame.Paint = function(self, w, h)
    draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 40, 250))
    draw.RoundedBox(0, 0, 0, w, 30, Color(30, 30, 30, 255))
  end

  local y = 50
  local padding = 20

  -- First Name
  local lblFirstName = vgui.Create("DLabel", frame)
  lblFirstName:SetPos(padding, y)
  lblFirstName:SetText("First Name:")
  lblFirstName:SetFont("DermaDefault")
  lblFirstName:SizeToContents()

  local txtFirstName = vgui.Create("DTextEntry", frame)
  txtFirstName:SetPos(padding, y + 20)
  txtFirstName:SetSize(frameW - padding * 2, 30)
  txtFirstName:SetPlaceholderText("Enter first name...")

  y = y + 70

  -- Last Name
  local lblLastName = vgui.Create("DLabel", frame)
  lblLastName:SetPos(padding, y)
  lblLastName:SetText("Last Name:")
  lblLastName:SetFont("DermaDefault")
  lblLastName:SizeToContents()

  local txtLastName = vgui.Create("DTextEntry", frame)
  txtLastName:SetPos(padding, y + 20)
  txtLastName:SetSize(frameW - padding * 2, 30)
  txtLastName:SetPlaceholderText("Enter last name...")

  y = y + 70

  -- Gender selection
  local lblGender = vgui.Create("DLabel", frame)
  lblGender:SetPos(padding, y)
  lblGender:SetText("Gender:")
  lblGender:SetFont("DermaDefault")
  lblGender:SizeToContents()

  local selectedGender = "Male"
  local selectedModelIndex = 1

  local btnMale = vgui.Create("DButton", frame)
  btnMale:SetPos(padding, y + 20)
  btnMale:SetSize((frameW - padding * 3) / 2, 30)
  btnMale:SetText("Male")
  btnMale.DoClick = function()
    selectedGender = "Male"
    selectedModelIndex = 1
  end
  btnMale.Paint = function(self, w, h)
    local col = selectedGender == "Male" and Color(52, 152, 219, 255) or Color(60, 60, 60, 255)
    draw.RoundedBox(4, 0, 0, w, h, col)
    draw.SimpleText(self:GetText(), "DermaDefault", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER,
      TEXT_ALIGN_CENTER)
  end

  local btnFemale = vgui.Create("DButton", frame)
  btnFemale:SetPos(padding + (frameW - padding * 3) / 2 + padding, y + 20)
  btnFemale:SetSize((frameW - padding * 3) / 2, 30)
  btnFemale:SetText("Female")
  btnFemale.DoClick = function()
    selectedGender = "Female"
    selectedModelIndex = 1
  end
  btnFemale.Paint = function(self, w, h)
    local col = selectedGender == "Female" and Color(52, 152, 219, 255) or Color(60, 60, 60, 255)
    draw.RoundedBox(4, 0, 0, w, h, col)
    draw.SimpleText(self:GetText(), "DermaDefault", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER,
      TEXT_ALIGN_CENTER)
  end

  y = y + 70

  -- Model selection
  local lblModel = vgui.Create("DLabel", frame)
  lblModel:SetPos(padding, y)
  lblModel:SetText("Character Model:")
  lblModel:SetFont("DermaDefault")
  lblModel:SizeToContents()

  local modelPreview = vgui.Create("DModelPanel", frame)
  modelPreview:SetPos(padding, y + 20)
  modelPreview:SetSize(200, 200)
  modelPreview:SetModel(self.Models.Male[1])
  modelPreview:SetCamPos(Vector(50, 0, 50))
  modelPreview:SetLookAt(Vector(0, 0, 40))

  local btnPrevModel = vgui.Create("DButton", frame)
  btnPrevModel:SetPos(padding + 220, y + 20)
  btnPrevModel:SetSize(100, 30)
  btnPrevModel:SetText("< Previous")
  btnPrevModel.DoClick = function()
    local models = self.Models[selectedGender]
    selectedModelIndex = selectedModelIndex - 1
    if selectedModelIndex < 1 then
      selectedModelIndex = #models
    end
    modelPreview:SetModel(models[selectedModelIndex])
  end

  local btnNextModel = vgui.Create("DButton", frame)
  btnNextModel:SetPos(padding + 330, y + 20)
  btnNextModel:SetSize(100, 30)
  btnNextModel:SetText("Next >")
  btnNextModel.DoClick = function()
    local models = self.Models[selectedGender]
    selectedModelIndex = selectedModelIndex + 1
    if selectedModelIndex > #models then
      selectedModelIndex = 1
    end
    modelPreview:SetModel(models[selectedModelIndex])
  end

  -- Create button
  local btnCreate = vgui.Create("DButton", frame)
  btnCreate:SetPos(padding, frameH - 50)
  btnCreate:SetSize(frameW - padding * 2, 35)
  btnCreate:SetText("Create Character")
  btnCreate.Paint = function(self, w, h)
    local col = self:IsHovered() and Color(46, 204, 113, 255) or Color(39, 174, 96, 255)
    draw.RoundedBox(4, 0, 0, w, h, col)
    draw.SimpleText(self:GetText(), "DermaLarge", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER,
      TEXT_ALIGN_CENTER)
  end
  btnCreate.DoClick = function()
    local firstName = txtFirstName:GetValue()
    local lastName = txtLastName:GetValue()

    -- Validate
    if firstName == "" or lastName == "" then
      Derma_Message("Please enter both first and last name!", "Error", "OK")
      return
    end

    local selectedModel = self.Models[selectedGender][selectedModelIndex]

    -- Send to server
    net.Start("IonRP_CreateCharacter")
    net.WriteString(firstName)
    net.WriteString(lastName)
    net.WriteString(selectedModel)
    net.SendToServer()

    frame:Remove()
  end
end

-- Network handlers
net.Receive("IonRP_RequestCharacterCreation", function()
  IonRP.Character:OpenCreationMenu()
end)

net.Receive("IonRP_CharacterLoaded", function()
  if IsValid(IonRP.Character.CreationFrame) then
    IonRP.Character.CreationFrame:Remove()
  end

  chat.AddText(Color(46, 204, 113), "[IonRP] ", Color(255, 255, 255), "Character loaded! Welcome back!")
end)

-- Player meta
---@class Player
local plyMeta = FindMetaTable("Player")
-- Helper functions for getting character info
function plyMeta:GetRPName()
  local firstName = self:GetNWString("IonRP_FirstName", "")
  local lastName = self:GetNWString("IonRP_LastName", "")

  if firstName == "" or lastName == "" then
    return self:Nick()
  end

  return firstName .. " " .. lastName
end

function plyMeta:GetFirstName()
  return self:GetNWString("IonRP_FirstName", "Unknown")
end

function plyMeta:GetLastName()
  return self:GetNWString("IonRP_LastName", "Unknown")
end
