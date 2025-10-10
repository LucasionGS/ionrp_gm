--[[
  IonRP - Dialog System (Server)
  Server-side functions for sending dialogs to clients
--]]

util.AddNetworkString("IonRP_OpenDialog")
util.AddNetworkString("IonRP_RequestString")
util.AddNetworkString("IonRP_RequestStringResponse")
util.AddNetworkString("IonRP_ShowOptions")
util.AddNetworkString("IonRP_ShowOptionsResponse")

IonRP.Dialog = IonRP.Dialog or {}

-- Callback storage
local callbackStorage = {}
local nextCallbackId = 1

--- Send a dialog to a player or players
--- @param ply Player or table of players
--- @param data {title: string, message: string, buttons: {text: string, callback: string }}}
--- Note: callbacks are network message names that will be sent when button is clicked
function IonRP.Dialog:Send(ply, data)
  if not data or not data.message then
    ErrorNoHalt("[IonRP Dialog] No message provided!\n")
    return
  end

  -- Ensure ply is a table
  local players = {}
  if type(ply) == "Player" then
    players = { ply }
  elseif type(ply) == "table" then
    players = ply
  else
    ErrorNoHalt("[IonRP Dialog] Invalid player parameter!\n")
    return
  end

  -- Process buttons to handle callbacks
  local processedData = table.Copy(data)
  if processedData.buttons then
    for i, btn in ipairs(processedData.buttons) do
      -- Convert callback to network message name if it's a function
      -- Server callbacks should be network strings
      if type(btn.callback) == "function" then
        -- We can't send functions over network, remove it
        processedData.buttons[i].callback = nil
      end
    end
  end

  -- Send to all players
  net.Start("IonRP_OpenDialog")
  net.WriteTable(processedData)
  net.Send(players)
end

--- Convenience function: Send message dialog
--- @param ply Player or table of players
--- @param title string
--- @param message string
function IonRP.Dialog:Message(ply, title, message)
  return self:Send(ply, {
    title = title,
    message = message,
    buttons = {
      { text = "OK" }
    }
  })
end

--[[
  Convenience function: Send confirmation dialog
--]]
function IonRP.Dialog:Confirm(ply, title, message)
  return self:Send(ply, {
    title = title,
    message = message,
    buttons = {
      { text = "Cancel" },
      { text = "Confirm" }
    }
  })
end

--[[
  Example: NPC Dialog
  Usage in your NPC code:

  IonRP.Dialog:Send(ply, {
    title = "Shopkeeper",
    message = "Welcome to my shop! Would you like to buy something?",
    buttons = {
      {text = "Show me your wares"},
      {text = "No thanks"},
    }
  })
--]]

--[[
  Example: ATM Dialog
  Usage in your ATM code:

  IonRP.Dialog:Send(ply, {
    title = "ATM - Bank of IonRP",
    message = "Your current balance: $" .. ply:GetMoney() .. "\n\nWhat would you like to do?",
    buttons = {
      {text = "Deposit"},
      {text = "Withdraw"},
      {text = "Cancel"},
    }
  })
--]]

--[[
  Request string input from a player
]]
--- @param ply Player The player to show the dialog to
--- @param title string Dialog title
--- @param message string Message to display
--- @param default string Default value
--- @param callback fun(result: string|nil) Callback with the entered string (or nil if cancelled)
function IonRP.Dialog:RequestString(ply, title, message, default, callback)
  if not IsValid(ply) then return end

  -- Generate callback ID
  local callbackId = "reqstr_" .. nextCallbackId
  nextCallbackId = nextCallbackId + 1

  -- Store callback
  callbackStorage[callbackId] = {
    player = ply,
    callback = callback,
    expiry = CurTime() + 300 -- 5 minute timeout
  }

  -- Send to client
  net.Start("IonRP_RequestString")
    net.WriteString(title)
    net.WriteString(message)
    net.WriteString(default or "")
    net.WriteString(callbackId)
  net.Send(ply)
end

--[[
  Show options menu to a player
]]
--- @param ply Player The player to show the dialog to
--- @param title string Dialog title
--- @param options table Array of option objects with {text, callback, isLabel?}
function IonRP.Dialog:ShowOptions(ply, title, options)
  if not IsValid(ply) then return end

  -- Generate callback ID
  local callbackId = "showopts_" .. nextCallbackId
  nextCallbackId = nextCallbackId + 1

  -- Store callbacks
  local callbacks = {}
  for i, option in ipairs(options) do
    if not option.isLabel then
      callbacks[i] = option.callback
    end
  end

  callbackStorage[callbackId] = {
    player = ply,
    callbacks = callbacks,
    expiry = CurTime() + 300 -- 5 minute timeout
  }

  -- Send to client (without callback functions)
  local clientOptions = {}
  for i, option in ipairs(options) do
    table.insert(clientOptions, {
      text = option.text,
      isLabel = option.isLabel or false
    })
  end

  net.Start("IonRP_ShowOptions")
    net.WriteString(title)
    net.WriteTable(clientOptions)
    net.WriteString(callbackId)
  net.Send(ply)
end

--[[
  Handle RequestString response from client
]]
net.Receive("IonRP_RequestStringResponse", function(len, ply)
  local callbackId = net.ReadString()
  local hasResult = net.ReadBool()
  local result = net.ReadString()

  local stored = callbackStorage[callbackId]
  if not stored then return end

  -- Verify player
  if stored.player ~= ply then return end

  -- Execute callback
  if stored.callback then
    stored.callback(hasResult and result or nil)
  end

  -- Clean up
  callbackStorage[callbackId] = nil
end)

--[[
  Handle ShowOptions response from client
]]
net.Receive("IonRP_ShowOptionsResponse", function(len, ply)
  local callbackId = net.ReadString()
  local selectedIndex = net.ReadUInt(8)

  local stored = callbackStorage[callbackId]
  if not stored then return end

  -- Verify player
  if stored.player ~= ply then return end

  -- Execute callback
  local callback = stored.callbacks[selectedIndex]
  if callback then
    callback()
  end

  -- Clean up
  callbackStorage[callbackId] = nil
end)

--[[
  Clean up expired callbacks
]]
timer.Create("IonRP_CleanDialogCallbacks", 60, 0, function()
  local now = CurTime()
  for id, data in pairs(callbackStorage) do
    if data.expiry < now then
      callbackStorage[id] = nil
    end
  end
end)

print("[IonRP] Dialog system (server) loaded")
