ITEM_RIFLE_AMMO = ITEM:New("item_rifle_ammo", "Rifle Ammo")
ITEM_RIFLE_AMMO.description = "A box of rifle ammunition."
ITEM_RIFLE_AMMO.model = "models/items/ammocrate_ar2.mdl"
ITEM_RIFLE_AMMO.weight = 1
ITEM_RIFLE_AMMO.size = { 1, 1 }
ITEM_RIFLE_AMMO.type = "consumable"
ITEM_RIFLE_AMMO.stackSize = 20
local ammoType = "AR2" -- The type of ammo this item restores

function ITEM_RIFLE_AMMO:SV_Use()
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