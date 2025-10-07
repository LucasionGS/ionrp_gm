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
  if ply:GetBank() == 0 then
    ply:SetBank(self.Config.StartingBank)
  end
end

--[[
	Withdraw money from bank to wallet
--]]
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
    target = Player(tonumber(args[1]))
  end

  if IsValid(target) then
    IonRP.Bank:OpenMenu(target)
    if ply ~= target then
      ply:ChatPrint("Opened bank for " .. target:Nick())
    end
  end
end)

print("[IonRP] Bank system (server) loaded")
