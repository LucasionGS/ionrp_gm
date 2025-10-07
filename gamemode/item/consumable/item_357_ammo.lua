ITEM_357_AMMO = ITEM:New("item_357_ammo", "357 Ammo")
ITEM_357_AMMO.description = "A box of 357 ammunition."
ITEM_357_AMMO.model = "models/Items/BoxSRounds.mdl"
ITEM_357_AMMO.weight = 1
ITEM_357_AMMO.size = { 1, 1 }
ITEM_357_AMMO.type = "consumable"
ITEM_357_AMMO.stackSize = 20
local ammoType = "357" -- The type of ammo this item restores

function ITEM_357_AMMO:SV_Use()
  local ply = self.owner
  if not ply or not IsValid(ply) then
    return false
  end

  if not ply:Alive() then
    ply:ChatPrint("You cannot use an ammo pack while dead.")
    return false
  end

  local ammoAmount = 30
  ply:GiveAmmo(ammoAmount, ammoType)
  ply:ChatPrint("You used an ammo pack and restored " .. ammoAmount .. " ammo.")

  return true
end