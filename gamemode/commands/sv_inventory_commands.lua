--[[
    IonRP Inventory Commands
    Command implementations for inventory management
]] --

if SERVER then
  -- /giveitem command
  IonRP.Commands.Add("giveitem", function(activator, args, rawArgs)
    -- Check arguments
    if #args < 2 then
      activator:ChatPrint("[IonRP] Usage: /giveitem <player> <item_identifier> [quantity]")
      activator:ChatPrint("[IonRP] Example: /giveitem Player1 item_ak47 1")
      return
    end

    local targetIdentifier = args[1]
    local itemIdentifier = args[2]
    local quantity = tonumber(args[3]) or 1

    -- Find target player
    local target = nil
    for _, ply in ipairs(player.GetAll()) do
      if string.find(string.lower(ply:Nick()), string.lower(targetIdentifier)) then
        target = ply
        break
      end
    end

    if not target then
      activator:ChatPrint("[IonRP] Player not found: " .. targetIdentifier)
      return
    end

    -- Check if item exists
    local item = IonRP.Items.List[itemIdentifier]
    if not item then
      activator:ChatPrint("[IonRP] Invalid item: " .. itemIdentifier)
      activator:ChatPrint("[IonRP] Available items:")
      for id, _ in pairs(IonRP.Items.List) do
        activator:ChatPrint("  - " .. id)
      end
      return
    end

    -- Give the item
    local success, err = target:GiveItem(itemIdentifier, quantity)

    if success then
      activator:ChatPrint(string.format("[IonRP] Gave %dx %s to %s", quantity, item.name, target:Nick()))
      target:ChatPrint(string.format("[IonRP] You received %dx %s", quantity, item.name))
    else
      activator:ChatPrint("[IonRP] Failed to give item: " .. (err or "unknown error"))
    end
  end, "Give an item to a player", "giveitem")

  -- /takeitem command
  IonRP.Commands.Add("takeitem", function(activator, args, rawArgs)
    -- Check arguments
    if #args < 2 then
      activator:ChatPrint("[IonRP] Usage: /takeitem <player> <item_identifier> [quantity]")
      return
    end

    local targetIdentifier = args[1]
    local itemIdentifier = args[2]
    local quantity = tonumber(args[3]) or 1

    -- Find target player
    --- @type Player|nil
    local target = nil
    for _, ply in ipairs(player.GetAll()) do
      if string.find(string.lower(ply:Nick()), string.lower(targetIdentifier)) then
        target = ply
        break
      end
    end

    if not target then
      activator:ChatPrint("[IonRP] Player not found: " .. targetIdentifier)
      return
    end

    -- Take the item
    local success, err = target:TakeItem(itemIdentifier, quantity)

    if success then
      local item = IonRP.Items.List[itemIdentifier]
      activator:ChatPrint(string.format("[IonRP] Took %dx %s from %s", quantity, item.name, target:Nick()))
      target:ChatPrint(string.format("[IonRP] Lost %dx %s", quantity, item.name))
    else
      activator:ChatPrint("[IonRP] Failed to take item: " .. (err or "unknown error"))
    end
  end, "Take an item from a player", "takeitem")

  -- /clearinventory command
  IonRP.Commands.Add("clearinventory", function(activator, args, rawArgs)
    -- Check arguments
    if #args < 1 then
      activator:ChatPrint("[IonRP] Usage: /clearinventory <player>")
      return
    end

    local targetIdentifier = args[1]

    -- Find target player
    local target = nil
    for _, ply in ipairs(player.GetAll()) do
      if string.find(string.lower(ply:Nick()), string.lower(targetIdentifier)) then
        target = ply
        break
      end
    end

    if not target then
      activator:ChatPrint("[IonRP] Player not found: " .. targetIdentifier)
      return
    end

    local inv = target:GetInventory()
    if not inv then
      activator:ChatPrint("[IonRP] Player has no inventory")
      return
    end

    inv:Clear()
    IonRP.Inventory:SendToClient(target)
    IonRP.Inventory:Save(target)

    activator:ChatPrint(string.format("[IonRP] Cleared inventory for %s", target:Nick()))
    target:ChatPrint("[IonRP] Your inventory has been cleared")
  end, "Clear a player's inventory", "clearinventory")

  -- /listinventory command
  IonRP.Commands.Add("listinventory", function(activator, args, rawArgs)
    local target = activator

    -- If admin, allow checking other players
    if #args >= 1 then
      local targetIdentifier = args[1]
      
      for _, ply in ipairs(player.GetAll()) do
        if string.find(string.lower(ply:Nick()), string.lower(targetIdentifier)) then
          target = ply
          break
        end
      end
    end

    local inv = target:GetInventory()
    if not inv then
      activator:ChatPrint("[IonRP] Player has no inventory")
      return
    end

    activator:ChatPrint("========== Inventory: " .. target:Nick() .. " ==========")
    activator:ChatPrint(string.format("Weight: %.1f / %.1f KG", inv:GetTotalWeight(), inv.maxWeight))
    activator:ChatPrint("Items:")

    local items = inv:GetAllItems()
    if #items == 0 then
      activator:ChatPrint("  (empty)")
    else
      for _, entry in ipairs(items) do
        activator:ChatPrint(string.format("  [%d,%d] %s x%d (%.1f KG)", 
          entry.x, entry.y, entry.item.name, entry.quantity, 
          entry.item.weight * entry.quantity))
      end
    end

    activator:ChatPrint("=================================================")
  end, "List inventory contents", "listinventory")

  -- /listitems command
  IonRP.Commands.Add("listitems", function(activator, args, rawArgs)
    activator:ChatPrint("========== Available Items ==========")

    for identifier, item in pairs(IonRP.Items.List) do
      activator:ChatPrint(string.format("  %s - %s (%.1f KG)", identifier, item.name, item.weight))
    end

    activator:ChatPrint("=====================================")
  end, "List all available items", "listitems")

  IonRP.Commands.Add("checkammo", function(ply, args, rawArgs)
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) then
      ply:ChatPrint("You are not holding a valid weapon.")
      return
    end

    local ammoType = weapon:GetPrimaryAmmoType()
    if ammoType == -1 then
      ply:ChatPrint("Your current weapon does not use ammo.")
      return
    end

    local ammoName = game.GetAmmoName(ammoType) or "Unknown"

    ply:ChatPrint(string.format("Your current weapon (%s) uses %s ammo. (%s)", weapon:GetClass(), ammoName, ammoType))
  end, "Get what ammo is required for your current weapon")

  print("[IonRP] Inventory commands loaded")
end
