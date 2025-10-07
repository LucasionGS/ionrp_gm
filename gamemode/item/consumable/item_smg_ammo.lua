ITEM_SMG_AMMO = ITEM:New("item_smg_ammo", "SMG Ammo")
ITEM_SMG_AMMO.description = "A box of SMG ammunition."
ITEM_SMG_AMMO.model = "models/items/ammopack_small.mdl"
ITEM_SMG_AMMO.weight = 1
ITEM_SMG_AMMO.size = { 1, 1 }
ITEM_SMG_AMMO.type = "consumable"
ITEM_SMG_AMMO.stackSize = 20
local ammoType = "smg1" -- The type of ammo this item restores

function ITEM_SMG_AMMO:SV_Use()
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