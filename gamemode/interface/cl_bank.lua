--[[
	IonRP - Bank Interface (Client)
	ATM and bank interaction system
--]]

IonRP = IonRP or {}
IonRP.Bank = IonRP.Bank or {}

-- Bank configuration
IonRP.Bank.Config = {
  WithdrawAmounts = { 100, 500, 1000, 5000 },
  DepositAmounts = { 100, 500, 1000, 5000 },
  AllowCustomAmount = true, -- Future feature
}

--[[
	Format money for display
--]]
local function FormatMoney(amount)
  local formatted = tostring(amount)
  local k
  while true do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    if k == 0 then break end
  end
  return "$" .. formatted
end

--- @type boolean
IonRP.Bank.isOpen = false

--- Open the main bank menu
--- @param wallet number|nil The player's wallet balance
--- @param bank number|nil The player's bank balance
function IonRP.Bank:OpenMenu(wallet, bank)
  local ply = LocalPlayer()
  if not IsValid(ply) then return end
  if self.isOpen then return end
  self.isOpen = true

  wallet = wallet or ply:GetWallet()
  bank = bank or ply:GetBank()

  IonRP.Dialog:Create({
    title = "Bank of IonRP - ATM",
    message = string.format(
      "Welcome to the Bank of IonRP!\n\n" ..
      "Wallet: %s\n" ..
      "Bank: %s\n" ..
      "What would you like to do?",
      FormatMoney(wallet),
      FormatMoney(bank)
    ),
    buttons = {
      {
        text = "Withdraw",
        callback = function()
          IonRP.Bank:OpenWithdrawMenu()
          -- Don't animate, opening new dialog
        end,
        color = Color(180, 70, 70, 255)
      },
      {
        text = "Deposit",
        callback = function()
          IonRP.Bank:OpenDepositMenu()
          -- Don't animate, opening new dialog
        end,
        color = Color(70, 180, 70, 255)
      },
      {
        text = "Close",
        callback = function()
          self.isOpen = false
          return true -- Animate on close
        end,
        color = Color(100, 100, 110, 255)
      }
    }
  })
end

--[[
	Open the withdraw menu
--]]
function IonRP.Bank:OpenWithdrawMenu()
  local ply = LocalPlayer()
  if not IsValid(ply) then return end

  local wallet = ply:GetWallet()
  local bank = ply:GetBank()

  -- Create buttons for each amount
  local buttons = {}

  for _, amount in ipairs(self.Config.WithdrawAmounts) do
    if bank >= amount then
      table.insert(buttons, {
        text = "Withdraw " .. FormatMoney(amount),
        callback = function()
          net.Start("IonRP_BankWithdraw")
          net.WriteUInt(amount, 32)
          net.SendToServer()

          -- Reopen menu after transaction
          IonRP.Bank.isOpen = false
          IonRP.Bank:OpenMenu(wallet + amount, bank - amount)
          -- Don't animate, opening new dialog
        end,
        color = Color(180, 70, 70, 255)
      })
    end
  end

  -- Add back button
  table.insert(buttons, {
    text = "Back",
    callback = function()
      IonRP.Bank.isOpen = false
      IonRP.Bank:OpenMenu()
      -- Don't animate, opening previous dialog
    end,
    color = Color(100, 100, 110, 255)
  })

  IonRP.Dialog:Create({
    title = "Withdraw Money",
    message = string.format(
      "Select an amount to withdraw:\n\n" ..
      "Bank: %s\n" ..
      "Wallet: %s",
      FormatMoney(bank),
      FormatMoney(wallet)
    ),
    buttons = buttons
  })
end

--[[
	Open the deposit menu
--]]
function IonRP.Bank:OpenDepositMenu()
  local ply = LocalPlayer()
  if not IsValid(ply) then return end

  local wallet = ply:GetWallet()
  local bank = ply:GetBank()

  -- Create buttons for each amount
  local buttons = {}

  for _, amount in ipairs(self.Config.DepositAmounts) do
    if wallet >= amount then
      table.insert(buttons, {
        text = "Deposit " .. FormatMoney(amount),
        callback = function()
          net.Start("IonRP_BankDeposit")
          net.WriteUInt(amount, 32)
          net.SendToServer()

          -- Reopen menu after transaction
          IonRP.Bank.isOpen = false
          IonRP.Bank:OpenMenu(wallet - amount, bank + amount)
          -- Don't animate, opening new dialog
        end,
        color = Color(70, 180, 70, 255)
      })
    end
  end

  -- Add deposit all button
  if wallet > 0 then
    table.insert(buttons, {
      text = "Deposit All (" .. FormatMoney(wallet) .. ")",
      callback = function()
        net.Start("IonRP_BankDeposit")
        net.WriteUInt(wallet, 32)
        net.SendToServer()

        -- Reopen menu after transaction
        IonRP.Bank.isOpen = false
        IonRP.Bank:OpenMenu()
        -- Don't animate, opening new dialog
      end,
      color = Color(90, 150, 90, 255)
    })
  end

  -- Add back button
  table.insert(buttons, {
    text = "Back",
    callback = function()
      IonRP.Bank.isOpen = false
      IonRP.Bank:OpenMenu()
      -- Don't animate, opening previous dialog
    end,
    color = Color(100, 100, 110, 255)
  })

  IonRP.Dialog:Create({
    title = "Deposit Money",
    message = string.format(
      "Select an amount to deposit:\n\n" ..
      "Wallet: %s\n" ..
      "Bank: %s",
      FormatMoney(wallet),
      FormatMoney(bank)
    ),
    buttons = buttons
  })
end

-- Network message setup
net.Receive("IonRP_BankOpenMenu", function()
  IonRP.Bank:OpenMenu()
end)

-- Console command for testing
concommand.Add("ionrp_bank", function()
  IonRP.Bank:OpenMenu()
end)

print("[IonRP] Bank interface loaded")
