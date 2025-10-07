--[[
    IonRP Command System
    Handles chat-based commands with / prefix
]] --

IonRP.Commands = IonRP.Commands or {}
IonRP.Commands.List = IonRP.Commands.List or {}


--- Register a new command
--- @param name string - Command name (without /)
--- @param callback fun(activator: Player, args: table, rawArgs: string, permission: string|nil) - Function to execute (activator, args, rawArgs)
--- @param description string - Optional description
--- @param permission string|nil - Optional permission requirement
function IonRP.Commands.Add(name, callback, description, permission)
  name = string.lower(name)

  IonRP.Commands.List[name] = {
    callback = callback,
    description = description or "No description",
    permission = permission or nil
  }

  if SERVER then
    print("[IonRP Commands] Registered: /" .. name)
  end
end

--- Get a command by name
--- @param name string
--- @return table or nil
function IonRP.Commands.Get(name)
  return IonRP.Commands.List[string.lower(name)]
end

--- Get all registered commands
--- @return table
function IonRP.Commands.GetAll()
  return IonRP.Commands.List
end

--- Check if a player has permission to run a command
--- @param ply Player
--- @param cmd table - Command data
--- @return boolean
function IonRP.Commands.HasPermission(ply, cmd)
  if not cmd.permission then return true end

  -- Check if player has the required permission
  if ply.HasPermission then
    return ply:HasPermission(cmd.permission)
  end

  return false
end

if SERVER then
  --- Execute a command
  --- @param ply Player - Player executing the command
  --- @param text string - Full command text
  function IonRP.Commands.Execute(ply, text)
    -- Parse command and arguments
    local args = string.Explode("%s+", text)
    local cmdName = string.lower(args[1] or "")

    -- Remove command name from args
    table.remove(args, 1)

    -- Get raw arguments (everything after command)
    local rawArgs = string.sub(text, string.len(cmdName) + 2)
    rawArgs = string.Trim(rawArgs)

    -- Get command
    local cmd = IonRP.Commands.Get(cmdName)

    if not cmd then
      ply:ChatPrint("[IonRP] Unknown command: /" .. cmdName)
      ply:ChatPrint("[IonRP] Type /help for a list of commands")
      return false
    end

    -- Check permissions
    if not IonRP.Commands.HasPermission(ply, cmd) then
      ply:ChatPrint("[IonRP] You don't have permission to use this command")
      return false
    end

    -- Execute command
    local success, err = pcall(function()
      cmd.callback(ply, args, rawArgs)
    end)

    if not success then
      ply:ChatPrint("[IonRP] Error executing command: " .. tostring(err))
      ErrorNoHalt("[IonRP Commands] Error in /" .. cmdName .. ": " .. tostring(err) .. "\n")
      return false
    end

    return true
  end

  -- Hook into player chat
  hook.Add("PlayerSay", "IonRP_CommandSystem", function(ply, text, teamChat)
    -- Check if it's a command
    if string.sub(text, 1, 1) == "/" then
      -- Remove the / prefix
      local cmdText = string.sub(text, 2)

      -- Execute command
      IonRP.Commands.Execute(ply, cmdText)

      -- Suppress the chat message
      return ""
    end
  end)

  -- Built-in help command
  IonRP.Commands.Add("help", function(ply, args, rawArgs)
    ply:ChatPrint("========== IonRP Commands ==========")

    local commands = {}
    for name, cmd in pairs(IonRP.Commands.GetAll()) do
      if IonRP.Commands.HasPermission(ply, cmd) then
        table.insert(commands, {
          name = name,
          description = cmd.description
        })
      end
    end

    -- Sort alphabetically
    table.sort(commands, function(a, b) return a.name < b.name end)

    for _, cmd in ipairs(commands) do
      ply:ChatPrint("  /" .. cmd.name .. " - " .. cmd.description)
    end

    ply:ChatPrint("====================================")
  end, "List all available commands")

  print("[IonRP] Command system loaded")
end
