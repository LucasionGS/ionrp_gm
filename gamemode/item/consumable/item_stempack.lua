ITEM_STEMPACK = ITEM:New("item_stempack", "Stem Pack")
ITEM_STEMPACK.description = "A stem pack for medical use."
ITEM_STEMPACK.model = "models/healthvial.mdl"
ITEM_STEMPACK.weight = 1
ITEM_STEMPACK.size = { 1, 1 }
ITEM_STEMPACK.type = "consumable"
ITEM_STEMPACK.stackSize = 20

function ITEM_STEMPACK:SV_Use()
  local ply = self.owner
  if not ply or not IsValid(ply) then
    return false
  end

  if not ply:Alive() then
    ply:ChatPrint("You cannot use a stem pack while dead.")
    return false
  end

  local healAmount = 25
  local newHealth = math.min(ply:Health() + healAmount, ply:GetMaxHealth())
  ply:SetHealth(newHealth)
  ply:ChatPrint("You used a stem pack and healed " .. healAmount .. " health.")

  return true
end