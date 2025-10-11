--[[
    Garage Commands
    Commands for managing garage groups and parking spots
]]--

-- List all garage groups on current map
IonRP.Commands.Add("garages", function(ply)
  if not ply:HasPermission("developer") then
    ply:ChatPrint("[IonRP] You don't have permission to list garages!")
    return
  end
  
  local count = 0
  ply:ChatPrint("[IonRP] Garage Groups on this map:")
  
  for id, group in pairs(IonRP.Garage.Groups) do
    count = count + 1
    ply:ChatPrint(string.format("  [%d] %s - %d spots (ID: %d)", 
      count, group.name, #group.spots, group.id or 0))
  end
  
  if count == 0 then
    ply:ChatPrint("  No garage groups found")
  end
end, "List all garage groups on current map", "developer")

-- Find closest garage to player
IonRP.Commands.Add("closestgarage", function(ply)
  local group, distance = IonRP.Garage:FindClosestGroup(ply:GetPos())
  
  if group then
    ply:ChatPrint(string.format("[IonRP] Closest garage: %s (%.0f units away)", 
      group.name, distance))
    ply:ChatPrint(string.format("  Available spots: %d", #group.spots))
  else
    ply:ChatPrint("[IonRP] No garages found on this map")
  end
end, "Find the closest garage to your position", nil)

-- Teleport to a garage group
IonRP.Commands.Add("tpgarage", function(ply, args)
  if not ply:HasPermission("developer") then
    ply:ChatPrint("[IonRP] You don't have permission to teleport to garages!")
    return
  end
  
  local identifier = args[1]
  if not identifier then
    ply:ChatPrint("[IonRP] Usage: /tpgarage <identifier>")
    return
  end
  
  local group = IonRP.Garage:GetGroupByIdentifier(identifier)
  if not group then
    ply:ChatPrint("[IonRP] Garage not found: " .. identifier)
    return
  end
  
  ply:SetPos(group.anchor + Vector(0, 0, 50))
  ply:ChatPrint("[IonRP] Teleported to garage: " .. group.name)
end, "Teleport to a garage group", "developer")

-- Delete a garage group by identifier
IonRP.Commands.Add("deletegarage", function(ply, args, rawArgs)
  if not ply:HasPermission("developer") then
    ply:ChatPrint("[IonRP] You don't have permission to delete garages!")
    return
  end
  
  local identifier = rawArgs
  if not identifier or identifier == "" then
    ply:ChatPrint("[IonRP] Usage: /deletegarage <identifier>")
    return
  end
  
  local group = IonRP.Garage:GetGroupByIdentifier(identifier)
  if not group then
    ply:ChatPrint("[IonRP] Garage not found: " .. identifier)
    return
  end
  
  if not group.id then
    ply:ChatPrint("[IonRP] Cannot delete garage without database ID")
    return
  end
  
  -- Confirm deletion
  local options = {
    {
      text = "Delete '" .. group.name .. "'?",
      isLabel = true
    },
    {
      text = "This will delete all " .. #group.spots .. " parking spots!",
      isLabel = true
    },
    {
      text = "Delete Garage",
      callback = function()
        IonRP.Garage:DeleteGroup(group.id, function(success)
          if success then
            -- Remove all entities
            for _, ent in pairs(IonRP.Garage.Entities) do
              if IsValid(ent) and ent:GetNWInt("GarageGroupID") == group.id then
                ent:Remove()
              end
            end
            
            ply:ChatPrint("[IonRP] Deleted garage: " .. group.name)
          else
            ply:ChatPrint("[IonRP] Failed to delete garage!")
          end
        end)
      end
    },
    {
      text = "Cancel",
      callback = function()
        ply:ChatPrint("[IonRP] Cancelled")
      end
    }
  }
  
  IonRP.Dialog:ShowOptions(ply, "Confirm Deletion", options)
end, "Delete a garage group by identifier", "developer")

print("[IonRP Garage] Commands loaded")
