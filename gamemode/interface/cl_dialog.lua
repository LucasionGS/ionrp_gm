--[[
  IonRP - Dialog System
  Client-side dialog interface for NPCs, ATMs, and interactions
--]]

IonRP.Dialog = IonRP.Dialog or {}

-- Dialog configuration
IonRP.Dialog.Config = {
  Width = 600,
  MinHeight = 200,
  MaxHeight = 500,
  Padding = 20,
  ButtonHeight = 32,   -- Reduced from 40
  ButtonSpacing = 8,   -- Spacing between buttons
  AnimationTime = 0.3,
  BottomPadding = 100, -- Distance from bottom of screen

  -- Colors
  Colors = {
    Background = Color(40, 40, 45, 250),
    Header = Color(60, 60, 70, 255),
    Title = Color(255, 255, 255, 255),
    Message = Color(220, 220, 220, 255),
    ButtonNormal = Color(70, 130, 180, 255),
    ButtonHover = Color(90, 150, 200, 255),
    ButtonText = Color(255, 255, 255, 255),
    CloseButton = Color(180, 70, 70, 255),
    CloseButtonHover = Color(200, 90, 90, 255),
    Overlay = Color(0, 0, 0, 150),
  }
}

-- Current active dialog
--- @type DPanel | nil
local activeDialog = nil

--- Create a dialog panel
--- @param data table {
---   title = string (optional),
---   message = string,
---   buttons = table of {text = string, callback = function, color = Color (optional)},
---   showClose = boolean (optional, default: false) - Show X close button
--- }
function IonRP.Dialog:Create(data)
  -- Close existing dialog
  if IsValid(activeDialog) then
    self:Close()
  end

  -- Validate data
  if not data or not data.message then
    ErrorNoHalt("[IonRP Dialog] No message provided!\n")
    return
  end

  -- Create overlay
  ---@class DPanel
  local overlay = vgui.Create("DPanel")
  overlay:SetSize(ScrW(), ScrH())
  overlay:SetPos(0, 0)
  overlay:MakePopup()
  overlay:SetKeyboardInputEnabled(false) -- Don't block keyboard input
  overlay:SetMouseInputEnabled(true)     -- But allow mouse clicks
  overlay.Alpha = 0
  overlay.Paint = function(self, w, h)
    draw.RoundedBox(0, 0, 0, w, h, ColorAlpha(IonRP.Dialog.Config.Colors.Overlay, self.Alpha))
  end

  -- Animate overlay in
  overlay:AlphaTo(255, IonRP.Dialog.Config.AnimationTime, 0)

  -- Create dialog frame
  ---@class DPanel
  local frame = vgui.Create("DPanel", overlay)
  frame:SetSize(IonRP.Dialog.Config.Width, IonRP.Dialog.Config.MinHeight)

  -- Calculate content height
  local contentHeight = IonRP.Dialog.Config.Padding * 2

  -- Add title height if present
  if data.title then
    contentHeight = contentHeight + 40
  end

  -- Add message height (estimated)
  surface.SetFont("DermaDefault")
  local messageWidth = IonRP.Dialog.Config.Width - (IonRP.Dialog.Config.Padding * 2)
  local _, messageHeight = surface.GetTextSize(data.message)
  local lines = math.ceil(string.len(data.message) / 50) -- Rough estimate
  contentHeight = contentHeight + (messageHeight * lines) + 20

  -- Add buttons height (vertical layout)
  if data.buttons and #data.buttons > 0 then
    local totalButtonHeight = (#data.buttons * IonRP.Dialog.Config.ButtonHeight) +
        ((#data.buttons - 1) * IonRP.Dialog.Config.ButtonSpacing)
    contentHeight = contentHeight + totalButtonHeight + IonRP.Dialog.Config.Padding
  end

  -- Clamp height
  contentHeight = math.Clamp(contentHeight, IonRP.Dialog.Config.MinHeight, IonRP.Dialog.Config.MaxHeight)
  frame:SetTall(contentHeight)

  -- Position near bottom of screen (with some padding from bottom)
  frame.StartY = ScrH() + contentHeight                                      -- Start off-screen below
  frame.TargetY = ScrH() - contentHeight - IonRP.Dialog.Config.BottomPadding -- Target position near bottom
  frame:SetPos(ScrW() / 2 - IonRP.Dialog.Config.Width / 2, frame.StartY)
  frame.Alpha = 0
  frame:SetKeyboardInputEnabled(true) -- Allow keyboard input to children
  frame:SetMouseInputEnabled(true)    -- Allow mouse input

  -- Paint dialog frame
  frame.Paint = function(self, w, h)
    -- Background
    draw.RoundedBox(8, 0, 0, w, h, IonRP.Dialog.Config.Colors.Background)

    -- Header if title exists
    if data.title then
      draw.RoundedBoxEx(8, 0, 0, w, 40, IonRP.Dialog.Config.Colors.Header, true, true, false, false)
      draw.SimpleText(data.title, "DermaLarge", w / 2, 20, IonRP.Dialog.Config.Colors.Title, TEXT_ALIGN_CENTER,
        TEXT_ALIGN_CENTER)
    end

    -- Border
    surface.SetDrawColor(80, 80, 90, 255)
    surface.DrawOutlinedRect(0, 0, w, h, 2)
  end

  -- Animate frame in
  frame:MoveTo(ScrW() / 2 - IonRP.Dialog.Config.Width / 2, frame.TargetY, IonRP.Dialog.Config.AnimationTime, 0, -1)
  frame:AlphaTo(255, IonRP.Dialog.Config.AnimationTime, 0)

  -- Close button (optional)
  if data.showClose then
    ---@class DButton
    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetSize(30, 30)
    closeBtn:SetPos(IonRP.Dialog.Config.Width - 35, 5)
    closeBtn:SetText("")
    closeBtn.Paint = function(self, w, h)
      local col = self:IsHovered() and IonRP.Dialog.Config.Colors.CloseButtonHover or
          IonRP.Dialog.Config.Colors.CloseButton
      draw.RoundedBox(4, 0, 0, w, h, col)

      -- Draw X
      surface.SetDrawColor(255, 255, 255, 255)
      surface.DrawLine(8, 8, w - 8, h - 8)
      surface.DrawLine(w - 8, 8, 8, h - 8)
    end
    closeBtn.DoClick = function()
      IonRP.Dialog:Close()
    end
  end

  -- Message area
  local messageY = data.title and (40 + IonRP.Dialog.Config.Padding) or IonRP.Dialog.Config.Padding

  -- Calculate message height
  surface.SetFont("DermaDefault")
  local _, messageHeight = surface.GetTextSize(data.message)
  local lines = math.ceil(string.len(data.message) / 50)
  local messagePanelHeight = (messageHeight * lines) + 20

  local messagePanel = vgui.Create("DPanel", frame)
  messagePanel:SetPos(IonRP.Dialog.Config.Padding, messageY)
  messagePanel:SetSize(IonRP.Dialog.Config.Width - (IonRP.Dialog.Config.Padding * 2), messagePanelHeight)
  messagePanel.Paint = nil

  local messageLabel = vgui.Create("DLabel", messagePanel)
  messageLabel:SetPos(0, 0)
  messageLabel:SetSize(messagePanel:GetWide(), messagePanel:GetTall())
  messageLabel:SetText(data.message)
  messageLabel:SetFont("DermaDefault")
  messageLabel:SetTextColor(IonRP.Dialog.Config.Colors.Message)
  messageLabel:SetWrap(true)
  messageLabel:SetAutoStretchVertical(true)

  -- Store reference to this specific dialog for closures
  local thisDialog = overlay
  overlay.DialogFrame = frame

  -- Buttons (vertical layout)
  if data.buttons and #data.buttons > 0 then
    local totalButtonHeight = (#data.buttons * IonRP.Dialog.Config.ButtonHeight) +
        ((#data.buttons - 1) * IonRP.Dialog.Config.ButtonSpacing)
    local startY = contentHeight - totalButtonHeight - IonRP.Dialog.Config.Padding
    local buttonWidth = IonRP.Dialog.Config.Width -
        (IonRP.Dialog.Config.Padding * 4) -- Narrower buttons with side padding
    local buttonX = IonRP.Dialog.Config.Padding * 2

    for i, btnData in ipairs(data.buttons) do
      local btn = vgui.Create("DButton", frame)
      btn:SetSize(buttonWidth, IonRP.Dialog.Config.ButtonHeight)
      local btnY = startY + ((i - 1) * (IonRP.Dialog.Config.ButtonHeight + IonRP.Dialog.Config.ButtonSpacing))
      btn:SetPos(buttonX, btnY)
      btn:SetText("")

      local btnColor = btnData.color or IonRP.Dialog.Config.Colors.ButtonNormal
      local btnHoverColor = Color(
        math.min(btnColor.r + 20, 255),
        math.min(btnColor.g + 20, 255),
        math.min(btnColor.b + 20, 255),
        btnColor.a
      )

      btn.Paint = function(self, w, h)
        local col = self:IsHovered() and btnHoverColor or btnColor
        draw.RoundedBox(6, 0, 0, w, h, col)

        -- Button border
        surface.SetDrawColor(0, 0, 0, 100)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        -- Button text
        draw.SimpleText(btnData.text or "Button", "DermaDefault", w / 2, h / 2, IonRP.Dialog.Config.Colors.ButtonText,
          TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
      end

      btn.DoClick = function()
        local shouldAnimate = false
        if btnData.callback then
          local result = btnData.callback()
          -- If callback returns true, use animation
          if result == true then
            shouldAnimate = true
          end
        end
        -- Close THIS specific dialog, not the global activeDialog
        IonRP.Dialog:CloseSpecific(thisDialog, shouldAnimate)
      end
    end
  end

  -- Update global reference
  activeDialog = overlay

  -- Handle ESC key (only if close button is enabled)
  if data.showClose then
    overlay.OnKeyCodePressed = function(self, key)
      if key == KEY_ESCAPE then
        IonRP.Dialog:Close()
      end
    end
  end

  return overlay
end

--- Close a specific dialog with optional animation
--- @param dialog DPanel - The dialog overlay to close
--- @param animate boolean - If true, animate the close. If false/nil, close instantly
function IonRP.Dialog:CloseSpecific(dialog, animate)
  if not IsValid(dialog) then return end

  local frame = dialog.DialogFrame

  if animate then
    -- Animate out (slide down off screen)
    if IsValid(frame) then
      local _, h = frame:GetSize()
      frame:MoveTo(ScrW() / 2 - IonRP.Dialog.Config.Width / 2, ScrH() + h, IonRP.Dialog.Config.AnimationTime, 0, -1)
      frame:AlphaTo(0, IonRP.Dialog.Config.AnimationTime, 0)
    end

    dialog:AlphaTo(0, IonRP.Dialog.Config.AnimationTime, 0, function()
      if dialog and IsValid(dialog) then
        dialog:Remove()
        -- Clear global reference if this was the active dialog
        if activeDialog == dialog then
          activeDialog = nil
        end
      end
    end)
  else
    -- Close instantly without animation
    if IsValid(dialog) then
      dialog:Remove()
      -- Clear global reference if this was the active dialog
      if activeDialog == dialog then
        activeDialog = nil
      end
    end
  end
end

--- Close the active dialog with optional animation
--- @param animate boolean - If true, animate the close. If false/nil, close instantly
function IonRP.Dialog:Close(animate)
  if not activeDialog or not IsValid(activeDialog) then return end
  self:CloseSpecific(activeDialog, animate)
end

--[[
  Check if a dialog is currently active
--]]
function IonRP.Dialog:IsActive()
  return IsValid(activeDialog)
end

--[[
  Convenience function: Simple message dialog
--]]
function IonRP.Dialog:Message(title, message, callback)
  return self:Create({
    title = title,
    message = message,
    buttons = {
      {
        text = "OK",
        callback = callback
      }
    }
  })
end

--[[
  Convenience function: Confirmation dialog
--]]
function IonRP.Dialog:Confirm(title, message, onConfirm, onCancel)
  return self:Create({
    title = title,
    message = message,
    buttons = {
      {
        text = "Cancel",
        callback = onCancel,
        color = Color(100, 100, 110, 255)
      },
      {
        text = "Confirm",
        callback = onConfirm,
        color = Color(70, 180, 70, 255)
      }
    }
  })
end

--[[
  Convenience function: Choice dialog (Yes/No)
--]]
function IonRP.Dialog:Choice(title, message, onYes, onNo)
  return self:Create({
    title = title,
    message = message,
    buttons = {
      {
        text = "No",
        callback = onNo,
        color = Color(180, 70, 70, 255)
      },
      {
        text = "Yes",
        callback = onYes,
        color = Color(70, 180, 70, 255)
      }
    }
  })
end

--[[
  Show options menu
  @param title string Dialog title
  @param options table Array of option objects with {text, callback, isLabel?}
--]]
function IonRP.Dialog:ShowOptions(title, options)
  -- Close existing dialog
  if IsValid(activeDialog) then
    self:Close()
  end

  -- Create overlay
  local overlay = vgui.Create("DPanel")
  overlay:SetSize(ScrW(), ScrH())
  overlay:SetPos(0, 0)
  overlay:MakePopup()
  overlay:SetKeyboardInputEnabled(false)
  overlay:SetMouseInputEnabled(true)
  overlay.Alpha = 0
  overlay.Paint = function(self, w, h)
    draw.RoundedBox(0, 0, 0, w, h, ColorAlpha(IonRP.Dialog.Config.Colors.Overlay, self.Alpha))
  end

  overlay:AlphaTo(255, IonRP.Dialog.Config.AnimationTime, 0)

  -- Calculate dialog height based on options
  local headerHeight = 40
  local optionHeight = 35
  local totalOptions = #options
  local frameHeight = headerHeight + (totalOptions * optionHeight) + (IonRP.Dialog.Config.Padding * 2)

  -- Create dialog frame
  local frame = vgui.Create("DPanel", overlay)
  frame:SetSize(IonRP.Dialog.Config.Width, frameHeight)

  local scrW, scrH = ScrW(), ScrH()
  local x = (scrW - IonRP.Dialog.Config.Width) / 2
  local y = (scrH - frameHeight) / 2
  frame:SetPos(x, y)

  frame.Paint = function(self, w, h)
    -- Background
    draw.RoundedBox(8, 0, 0, w, h, IonRP.Dialog.Config.Colors.Background)

    -- Border
    surface.SetDrawColor(100, 100, 110, 255)
    surface.DrawOutlinedRect(0, 0, w, h, 2)
  end

  -- Title bar
  if title then
    local titleBar = vgui.Create("DPanel", frame)
    titleBar:Dock(TOP)
    titleBar:SetTall(headerHeight)

    titleBar.Paint = function(self, w, h)
      draw.RoundedBoxEx(8, 0, 0, w, h, IonRP.Dialog.Config.Colors.Header, true, true, false, false)
      draw.SimpleText(title, "DermaDefaultBold", w / 2, h / 2, IonRP.Dialog.Config.Colors.Title, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
  end

  -- Options container
  local optionsContainer = vgui.Create("DPanel", frame)
  optionsContainer:Dock(FILL)
  optionsContainer:DockMargin(IonRP.Dialog.Config.Padding, IonRP.Dialog.Config.Padding, IonRP.Dialog.Config.Padding, IonRP.Dialog.Config.Padding)
  optionsContainer.Paint = function() end

  -- Create option buttons
  for i, option in ipairs(options) do
    if option.isLabel then
      -- Label (non-clickable)
      local label = vgui.Create("DLabel", optionsContainer)
      label:Dock(TOP)
      label:DockMargin(0, 0, 0, 2)
      label:SetTall(optionHeight - 2)
      label:SetText("")

      label.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 60, 200))
        draw.SimpleText(option.text, "DermaDefaultBold", w / 2, h / 2, Color(150, 150, 170), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
      end
    else
      -- Button
      local btn = vgui.Create("DButton", optionsContainer)
      btn:Dock(TOP)
      btn:DockMargin(0, 0, 0, 2)
      btn:SetTall(optionHeight - 2)
      btn:SetText("")

      btn.Paint = function(self, w, h)
        local col = IonRP.Dialog.Config.Colors.ButtonNormal
        if self:IsHovered() then
          col = IonRP.Dialog.Config.Colors.ButtonHover
        end
        draw.RoundedBox(4, 0, 0, w, h, col)
        draw.SimpleText(option.text, "DermaDefaultBold", w / 2, h / 2, IonRP.Dialog.Config.Colors.ButtonText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
      end

      btn.DoClick = function()
        overlay:Remove()
        activeDialog = nil
        if option.callback then
          option.callback()
        end
      end
    end
  end

  activeDialog = overlay
end

--[[
  Request string input from the player
  @param title string Dialog title
  @param message string Message to display
  @param default string Default value
  @param callback function Callback with the entered string (or nil if cancelled)
--]]
function IonRP.Dialog:RequestString(title, message, default, callback)
  -- Close existing dialog
  if IsValid(activeDialog) then
    self:Close(false)
  end

  default = default or ""

  -- Create overlay
  local overlay = vgui.Create("DPanel")
  overlay:SetSize(ScrW(), ScrH())
  overlay:SetPos(0, 0)
  overlay:MakePopup()
  overlay:SetKeyboardInputEnabled(true)
  overlay:SetMouseInputEnabled(true)
  overlay.Alpha = 0
  overlay.Paint = function(self, w, h)
    draw.RoundedBox(0, 0, 0, w, h, ColorAlpha(IonRP.Dialog.Config.Colors.Overlay, self.Alpha))
  end

  overlay:AlphaTo(255, IonRP.Dialog.Config.AnimationTime, 0)

  -- Create dialog frame
  local frame = vgui.Create("DPanel", overlay)
  local frameHeight = 220
  frame:SetSize(IonRP.Dialog.Config.Width, frameHeight)

  local scrW, scrH = ScrW(), ScrH()
  local x = (scrW - IonRP.Dialog.Config.Width) / 2
  local y = (scrH - frameHeight) / 2
  frame:SetPos(x, y)

  frame.Paint = function(self, w, h)
    -- Background
    draw.RoundedBox(8, 0, 0, w, h, IonRP.Dialog.Config.Colors.Background)

    -- Border
    surface.SetDrawColor(100, 100, 110, 255)
    surface.DrawOutlinedRect(0, 0, w, h, 2)
  end

  -- Title bar
  if title then
    local titleBar = vgui.Create("DPanel", frame)
    titleBar:Dock(TOP)
    titleBar:SetTall(40)

    titleBar.Paint = function(self, w, h)
      draw.RoundedBoxEx(8, 0, 0, w, h, IonRP.Dialog.Config.Colors.Header, true, true, false, false)
      draw.SimpleText(title, "DermaDefaultBold", w / 2, h / 2, IonRP.Dialog.Config.Colors.Title, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
  end

  -- Message
  if message then
    local messageLabel = vgui.Create("DLabel", frame)
    messageLabel:Dock(TOP)
    messageLabel:DockMargin(IonRP.Dialog.Config.Padding, IonRP.Dialog.Config.Padding, IonRP.Dialog.Config.Padding, 10)
    messageLabel:SetText(message)
    messageLabel:SetFont("DermaDefault")
    messageLabel:SetTextColor(IonRP.Dialog.Config.Colors.Message)
    messageLabel:SetWrap(true)
    messageLabel:SetAutoStretchVertical(true)
  end

  -- Text entry
  ---@type DTextEntry
  local textEntry = vgui.Create("DTextEntry", frame)
  textEntry:Dock(TOP)
  textEntry:DockMargin(IonRP.Dialog.Config.Padding, 0, IonRP.Dialog.Config.Padding, IonRP.Dialog.Config.Padding)
  textEntry:SetTall(30)
  textEntry:SetText(default)
  textEntry:RequestFocus()
  textEntry:SelectAll()

  textEntry.Paint = function(self, w, h)
    draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 35, 255))
    surface.SetDrawColor(60, 60, 70, 255)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
    self:DrawTextEntryText(Color(255, 255, 255), Color(100, 150, 255), Color(255, 255, 255))
  end

  -- Handle Enter key
  textEntry.OnEnter = function()
    local value = textEntry:GetValue()
    overlay:Remove()
    activeDialog = nil
    if callback then
      callback(value)
    end
  end

  -- Buttons container
  local buttonContainer = vgui.Create("DPanel", frame)
  buttonContainer:Dock(TOP)
  buttonContainer:DockMargin(IonRP.Dialog.Config.Padding, 0, IonRP.Dialog.Config.Padding, IonRP.Dialog.Config.Padding)
  buttonContainer:SetTall(IonRP.Dialog.Config.ButtonHeight)
  buttonContainer.Paint = function() end

  -- Cancel button
  local cancelBtn = vgui.Create("DButton", buttonContainer)
  cancelBtn:Dock(RIGHT)
  cancelBtn:SetWide(120)
  cancelBtn:DockMargin(5, 0, 0, 0)
  cancelBtn:SetText("")

  cancelBtn.Paint = function(self, w, h)
    local col = Color(100, 100, 110, 255)
    if self:IsHovered() then
      col = Color(120, 120, 130, 255)
    end
    draw.RoundedBox(4, 0, 0, w, h, col)
    draw.SimpleText("Cancel", "DermaDefaultBold", w / 2, h / 2, IonRP.Dialog.Config.Colors.ButtonText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end

  cancelBtn.DoClick = function()
    overlay:Remove()
    activeDialog = nil
    if callback then
      callback(nil)
    end
  end

  -- Confirm button
  local confirmBtn = vgui.Create("DButton", buttonContainer)
  confirmBtn:Dock(RIGHT)
  confirmBtn:SetWide(120)
  confirmBtn:SetText("")

  confirmBtn.Paint = function(self, w, h)
    local col = IonRP.Dialog.Config.Colors.ButtonNormal
    if self:IsHovered() then
      col = IonRP.Dialog.Config.Colors.ButtonHover
    end
    draw.RoundedBox(4, 0, 0, w, h, col)
    draw.SimpleText("Confirm", "DermaDefaultBold", w / 2, h / 2, IonRP.Dialog.Config.Colors.ButtonText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  end

  confirmBtn.DoClick = function()
    local value = textEntry:GetValue()
    overlay:Remove()
    activeDialog = nil
    if callback then
      callback(value)
    end
  end

  activeDialog = overlay
end

--[[
  Network receiver for server-initiated dialogs
--]]
net.Receive("IonRP_OpenDialog", function()
  local data = net.ReadTable()
  IonRP.Dialog:Create(data)
end)

--[[
  Network receiver for server-initiated RequestString
--]]
net.Receive("IonRP_RequestString", function()
  local title = net.ReadString()
  local message = net.ReadString()
  local default = net.ReadString()
  local callbackId = net.ReadString()

  IonRP.Dialog:RequestString(title, message, default, function(result)
    -- Send result back to server
    net.Start("IonRP_RequestStringResponse")
      net.WriteString(callbackId)
      net.WriteBool(result ~= nil)
      net.WriteString(result or "")
    net.SendToServer()
  end)
end)

--[[
  Network receiver for server-initiated ShowOptions
--]]
net.Receive("IonRP_ShowOptions", function()
  local title = net.ReadString()
  local options = net.ReadTable()
  local callbackId = net.ReadString()

  -- Wrap callbacks to send response to server
  for i, option in ipairs(options) do
    if not option.isLabel then
      option.callback = function()
        -- Send selection back to server
        net.Start("IonRP_ShowOptionsResponse")
          net.WriteString(callbackId)
          net.WriteUInt(i, 8)
        net.SendToServer()
      end
    end
  end

  IonRP.Dialog:ShowOptions(title, options)
end)

-- Console commands for testing
concommand.Add("ionrp_test_dialog", function()
  IonRP.Dialog:Create({
    title = "Test Dialog",
    message = "This is a test dialog with multiple buttons. Click any button to close this dialog.",
    showClose = true, -- Show close button for testing
    buttons = {
      {
        text = "Confirm",
        callback = function()
          print("Confirm clicked")
        end,
        color = Color(70, 180, 70, 255)
      },
      {
        text = "Option 2",
        callback = function()
          print("Option 2 clicked")
        end
      },
      {
        text = "Cancel",
        callback = function()
          print("Cancel clicked")
        end,
        color = Color(100, 100, 110, 255)
      },
    }
  })
end)

print("[IonRP] Dialog system loaded")
