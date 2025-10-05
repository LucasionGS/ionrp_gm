--[[
	IonRP - Dialog System (Server)
	Server-side functions for sending dialogs to clients
--]]

util.AddNetworkString("IonRP_OpenDialog")

IonRP.Dialog = IonRP.Dialog or {}

--[[
	Send a dialog to a player or players
	@param ply Player or table of players
	@param data table {
		title = string (optional),
		message = string,
		buttons = table of {text = string, callback = string (optional)}
	}
	Note: callbacks are network message names that will be sent when button is clicked
--]]
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

--[[
	Convenience function: Send message dialog
--]]
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
			{text = "No thanks"},
			{text = "Show me your wares"}
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
			{text = "Cancel"},
			{text = "Withdraw"},
			{text = "Deposit"}
		}
	})
--]]

print("[IonRP] Dialog system (server) loaded")
