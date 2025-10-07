ITEM_PISTOL_AMMO = ITEM:New("item_pistol_ammo", "Pistol Ammo")
ITEM_PISTOL_AMMO.description = "A box of pistol ammunition."
ITEM_PISTOL_AMMO.model = "models/items/357ammobox.mdl"
ITEM_PISTOL_AMMO.weight = 1
ITEM_PISTOL_AMMO.size = { 1, 1 }
ITEM_PISTOL_AMMO.type = "consumable"
ITEM_PISTOL_AMMO.stackSize = 20
local ammoType = "pistol" -- The type of ammo this item restores

function ITEM_PISTOL_AMMO:SV_Use()
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