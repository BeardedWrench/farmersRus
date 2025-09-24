local Wallet = {}

function Wallet.create(props)
  props = props or {}
  return {
    balance = props.balance or 0
  }
end

function Wallet.add(wallet, amount)
  wallet.balance = wallet.balance + amount
end

function Wallet.spend(wallet, amount)
  if wallet.balance >= amount then
    wallet.balance = wallet.balance - amount
    return true
  end
  return false
end

return Wallet
