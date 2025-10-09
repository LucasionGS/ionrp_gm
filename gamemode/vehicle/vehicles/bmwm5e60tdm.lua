local V = VEHICLE:NewFrom("bmwm5e60tdm")
V.marketValue = 15000
V.category = IonRP.Vehicles.Categories.OTHER
V.Upgradeable.horsepower = { 1, 1.05, 1.1, 1.2 }
V.Upgrades.horsepower = 1
V.Upgrades.engine = 3

function V:ApplyUpgradesToScript(tbl, ops)
  V.__index:ApplyUpgradesToScript(tbl, ops) -- Call base implementation
end