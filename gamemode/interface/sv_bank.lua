--[[
  IonRP - Bank System (Server)
  Handles bank transactions
--]]

util.AddNetworkString("IonRP_BankOpenMenu")
util.AddNetworkString("IonRP_BankWithdraw")
util.AddNetworkString("IonRP_BankDeposit")

IonRP = IonRP or {}
IonRP.Bank = IonRP.Bank or {}

-- Bank configuration
IonRP.Bank.Config = {
  WithdrawFee = 0, -- Percentage fee for withdrawals (0 = no fee)
  DepositFee = 0,  -- Percentage fee for deposits (0 = no fee)
  MinWithdraw = 1,
  MinDeposit = 1,
  StartingBank = GetConVar("ionrp_starting_money"):GetInt() or 0, -- Starting bank balance for new players
}

--[[
  Initialize player bank account
--]]
function IonRP.Bank:InitializePlayer(ply)
  -- if ply:GetBank() == 0 then
  --   ply:SetBank(self.Config.StartingBank)
  -- end
end

--- Withdraw money from bank to wallet
--- @param ply Player
--- @param amount number
function IonRP.Bank:Withdraw(ply, amount)
  -- Validate amount
  amount = math.floor(amount)
  if amount < self.Config.MinWithdraw then
    ply:ChatPrint("Minimum withdrawal amount is $" .. self.Config.MinWithdraw)
    return false
  end

  -- Check if player has enough in bank
  local bank = ply:GetBank()
  if bank < amount then
    ply:ChatPrint("Insufficient funds in bank!")
    return false
  end

  -- Calculate fee
  local fee = math.floor(amount * (self.Config.WithdrawFee / 100))
  local totalWithdrawn = amount + fee

  -- Check if player can afford fee
  if bank < totalWithdrawn then
    ply:ChatPrint("Insufficient funds to cover withdrawal fee!")
    return false
  end

  -- Process transaction
  ply:SetBank(bank - totalWithdrawn)
  ply:AddWallet(amount)

  -- Notify player
  if fee > 0 then
    ply:ChatPrint("Withdrew $" .. amount .. " (Fee: $" .. fee .. ")")
  else
    ply:ChatPrint("Withdrew $" .. amount)
  end

  print(string.format("[Bank] %s withdrew $%d", ply:Nick(), amount))
  return true
end

--[[
  Deposit money from wallet to bank
--]]
function IonRP.Bank:Deposit(ply, amount)
  -- Validate amount
  amount = math.floor(amount)
  if amount < self.Config.MinDeposit then
    ply:ChatPrint("Minimum deposit amount is $" .. self.Config.MinDeposit)
    return false
  end

  -- Check if player has enough in wallet
  local wallet = ply:GetWallet()
  if wallet < amount then
    ply:ChatPrint("Insufficient funds in wallet!")
    return false
  end

  -- Calculate fee
  local fee = math.floor(amount * (self.Config.DepositFee / 100))

  -- Check if player can afford amount + fee
  if wallet < (amount + fee) then
    ply:ChatPrint("Insufficient funds to cover deposit fee!")
    return false
  end

  -- Process transaction
  ply:SetWallet(wallet - (amount + fee))
  ply:AddBank(amount)

  -- Notify player
  if fee > 0 then
    ply:ChatPrint("Deposited $" .. amount .. " (Fee: $" .. fee .. ")")
  else
    ply:ChatPrint("Deposited $" .. amount)
  end

  print(string.format("[Bank] %s deposited $%d", ply:Nick(), amount))
  return true
end

--[[
  Open bank menu for player
--]]
function IonRP.Bank:OpenMenu(ply)
  net.Start("IonRP_BankOpenMenu")
  net.Send(ply)
end

-- Network message handlers
net.Receive("IonRP_BankWithdraw", function(len, ply)
  local amount = net.ReadUInt(32)
  IonRP.Bank:Withdraw(ply, amount)
end)

net.Receive("IonRP_BankDeposit", function(len, ply)
  local amount = net.ReadUInt(32)
  IonRP.Bank:Deposit(ply, amount)
end)

-- Initialize bank for new players
hook.Add("PlayerInitialSpawn", "IonRP_BankInit", function(ply)
  timer.Simple(1, function()
    if IsValid(ply) then
      IonRP.Bank:InitializePlayer(ply)
    end
  end)
end)

-- Console command for admins to open bank for players
concommand.Add("ionrp_openbank", function(ply, cmd, args)
  if IsValid(ply) and not ply:IsAdmin() then
    ply:ChatPrint("You must be an admin to use this command!")
    return
  end

  local target = ply
  if args[1] then
    target = Player(tonumber(args[1]) or 0)
  end

  if IsValid(target) then
    IonRP.Bank:OpenMenu(target)
    if ply ~= target then
      ply:ChatPrint("Opened bank for " .. target:Nick())
    end
  end
end)

IonRP.Commands.Add("atm", function(activator, args, rawArgs)
  IonRP.Bank:OpenMenu(activator)
end, "Open your bank account", "developer")

IonRP.Commands.Add("setwallet", function(activator, args, rawArgs)
  local target = activator
  local amount = tonumber(args[1]) or 0

  if args[1] and args[2] then
    target = IonRP.Util:FindPlayer(args[1]) or activator
    amount = tonumber(args[2]) or 0
  end

  if not IsValid(target) then
    activator:ChatPrint("Invalid target player!")
    return
  end

  if amount < 0 then
    activator:ChatPrint("Amount must be non-negative!")
    return
  end

  target:SetWallet(amount)
  activator:ChatPrint(string.format("Set %s's wallet to $%d", target:Nick(), amount))
  if activator ~= target then
    target:ChatPrint(string.format("Your wallet has been set to $%d by %s", amount, activator:Nick()))
  end

  print(string.format("[Admin] %s set %s's wallet to $%d", activator:Nick(), target:Nick(), amount))
end, "Set the amount of money in a wallet (Yours by default)", "manage_money")

IonRP.Commands.Add("setbank", function(activator, args, rawArgs)
  local target = activator
  local amount = tonumber(args[1]) or 0

  if args[1] and args[2] then
    target = IonRP.Util:FindPlayer(args[1]) or activator
    amount = tonumber(args[2]) or 0
  end

  if not IsValid(target) then
    activator:ChatPrint("Invalid target player!")
    return
  end

  if amount < 0 then
    activator:ChatPrint("Amount must be non-negative!")
    return
  end

  target:SetBank(amount)
  activator:ChatPrint(string.format("Set %s's bank to $%d", target:Nick(), amount))
  if activator ~= target then
    target:ChatPrint(string.format("Your bank has been set to $%d by %s", amount, activator:Nick()))
  end

  print(string.format("[Admin] %s set %s's bank to $%d", activator:Nick(), target:Nick(), amount))
end, "Set the amount of money in a bank (Yours by default)", "manage_money")

-- Add money and bank
IonRP.Commands.Add("addmoney", function(activator, args, rawArgs)
  local target = activator
  local amount = tonumber(args[1]) or 0

  if args[1] and args[2] then
    target = IonRP.Util:FindPlayer(args[1]) or activator
    amount = tonumber(args[2]) or 0
  end

  if not IsValid(target) then
    activator:ChatPrint("Invalid target player!")
    return
  end

  if amount <= 0 then
    activator:ChatPrint("Amount must be positive!")
    return
  end

  target:AddWallet(amount)
  activator:ChatPrint(string.format("Added $%d to %s's wallet", amount, target:Nick()))
  if activator ~= target then
    target:ChatPrint(string.format("You received $%d from %s", amount, activator:Nick()))
  end

  print(string.format("[Admin] %s added $%d to %s's wallet", activator:Nick(), amount, target:Nick()))
end, "Add money to a wallet (Yours by default)", "manage_money")

IonRP.Commands.Add("addbank", function(activator, args, rawArgs)
  local target = activator
  local amount = tonumber(args[1]) or 0

  if args[1] and args[2] then
    target = IonRP.Util:FindPlayer(args[1]) or activator
    amount = tonumber(args[2]) or 0
  end

  if not IsValid(target) then
    activator:ChatPrint("Invalid target player!")
    return
  end

  if amount <= 0 then
    activator:ChatPrint("Amount must be positive!")
    return
  end

  target:AddBank(amount)
  activator:ChatPrint(string.format("Added $%d to %s's bank", amount, target:Nick()))
  if activator ~= target then
    target:ChatPrint(string.format("You received $%d in your bank from %s", amount, activator:Nick()))
  end

  print(string.format("[Admin] %s added $%d to %s's bank", activator:Nick(), amount, target:Nick()))
end, "Add money to a bank (Yours by default)", "manage_money")



print("[IonRP] Bank system (server) loaded")
