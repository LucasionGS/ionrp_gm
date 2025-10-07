IonRP.Items = IonRP.Items or {}

---@type table<string, ITEM>
IonRP.Items.List = IonRP.Items.List or {}

--- @class ITEM
ITEM = {}

--- @type ITEM
ITEM.__index = ITEM

--- The unique identifier for the item.
--- @type string
ITEM.identifier = "generic_item"

--- The display name of the item.
--- @type string
ITEM.name = "<No name>"

--- The description of the item.
--- @type string
ITEM.description = "<No description>"

--- The model path for the item.
--- @type string
ITEM.model = "<No model>"

--- The weight of the item in KG. Used for inventory weight limits.
--- @type number
ITEM.weight = 0

--- The size of the item in inventory grid units (width, height).
--- @type {[1]: number, [2]: number}
ITEM.size = { 1, 1 }

--- How many of this item can stack in one inventory slot.
--- @type number
ITEM.stackSize = 1

--- The item type
--- @type "weapon" | "consumable" | "misc"
ITEM.type = "misc"

--- The owner of the item instance (set when in a player context).
--- @type Player|nil
ITEM.owner = nil

--[[
  Weapon specific fields
]] --
--- For weapon items, the class to give the player when used.
--- If defined, this will equip the weapon on use.
--- @type string|nil
ITEM.weaponClass = nil

--- The inventory slot this item occupies.
---
--- `1` is for primary (Typically large guns), `2` is for secondary (Pistols).
--- @type 1|2|nil
ITEM.weaponSlot = 2

--- Create a new item instance and register it. Properties can be assigned to the returned object.
--- @param identifier string Identifier that uniquely distinguishes the item.
--- @param name string Name of the item.
--- @return ITEM
function ITEM:New(identifier, name)
  local newItem = {}
  setmetatable(newItem, self)
  self.__index = self
  newItem.identifier = identifier
  newItem.name = name

  IonRP.Items.List[identifier] = newItem
  print("│ [IonRP Items] ├ Registered item: " .. identifier .. " - " .. name)

  return newItem
end

-- Create an instance of the item with a player as the owner context.
--- @param owner Player The player who owns this item instance.
--- @return ITEM
function ITEM:MakeOwnedInstance(owner)
  local itemInstance = {}
  setmetatable(itemInstance, self)
  self.__index = self
  itemInstance.owner = owner
  return itemInstance
end

if SERVER then
  --- Callback run on the serverside when a player uses the item.
  --- @return boolean - True to consume the item, false to keep it.
  function ITEM:SV_Use()
    local ply = self.owner
    if not ply or not IsValid(ply) then return false end

    if self.type == "weapon" and self.weaponClass then
      self:_SV_EquipAsWeapon();
      return false -- Don't consume the item, it's now equipped
    end

    print("Using misc item: " .. self.name .. " - Not implemented.")

    return false
  end

  function ITEM:_SV_EquipAsWeapon()
    local ply = self.owner
    if not ply or not IsValid(ply) then return false end

    if not self.weaponClass then
      ply:ChatPrint("This item cannot be equipped as a weapon.")
      return false
    end

    if not ply:HasWeapon(self.weaponClass) then
      ply:SV_EquipWeapon(self)
    end

    return true
  end
end

if CLIENT then
  --- Client-side rendering of the item in a DModelPanel.
  function ITEM:CL_Render(width, height)
    local icon = vgui.Create("DModelPanel")
    icon:SetModel(self.model or "models/props_junk/garbage_metalcan01a.mdl")
    icon:SetSize(width or 64, height or 64)
    icon:SetFOV(45)
    icon:SetCamPos(Vector(50, 50, 50))
    icon:SetLookAt(Vector(0, 0, 0))
    return icon
  end
end

-- Import weapons
print("┌───────────────┬────────────────────────────────────────────────────────────────•")
print("│ [IonRP Items] │ Loading Items")
print("│ [IonRP Items] │ Loading weapon items...")
for _, weapon in ipairs(file.Find("ionrp/gamemode/item/weapons/*.lua", "LUA")) do
  include("weapons/" .. weapon)
  if SERVER then
    AddCSLuaFile("weapons/" .. weapon)
  end
end

-- Import consumable items
print("│ [IonRP Items] │ Loading consumable items...")
for _, consumable in ipairs(file.Find("ionrp/gamemode/item/consumable/*.lua", "LUA")) do
  include("consumable/" .. consumable)
  if SERVER then
    AddCSLuaFile("consumable/" .. consumable)
  end
end

-- Import misc items
print("│ [IonRP Items] │ Loading misc items...")
for _, misc in ipairs(file.Find("ionrp/gamemode/item/misc/*.lua", "LUA")) do
  include("misc/" .. misc)
  if SERVER then
    AddCSLuaFile("misc/" .. misc)
  end
end
print("└───────────────┴────────────────────────────────────────────────────────────────•")
