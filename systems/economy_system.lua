local Wallet = require 'components.wallet'
local Inventory = require 'components.inventory'

return function(app)
  local events = app.events
  local balance = app.gameplay.balance
  local shopDb = app.gameplay.shops

  local system = {
    name = 'economy_system',
    updateOrder = 40
  }

  local function getWallet()
    local inventorySystem = app.inventory
    return inventorySystem and inventorySystem:getWallet() or nil
  end

  local function getInventory()
    local inventorySystem = app.inventory
    return inventorySystem and inventorySystem:getInventory() or nil
  end

  local function getItemPrice(shopId, itemId)
    local shop = shopDb[shopId]
    if shop and shop.items and shop.items[itemId] then
      return shop.items[itemId]
    end
    return balance.items[itemId] or 0
  end

  function system:init()
    events:on('economy:buy', function(shopId, itemId, quantity)
      self:buy(shopId, itemId, quantity or 1)
    end)

    events:on('economy:sell', function(itemId, quantity)
      self:sell(itemId, quantity or 1)
    end)
  end

  function system:buy(shopId, itemId, quantity)
    local wallet = getWallet()
    local inventoryComponent = getInventory()
    if not wallet or not inventoryComponent then
      return false
    end
    local price = getItemPrice(shopId, itemId)
    local total = price * quantity
    if total <= 0 then
      return false
    end
    if not Wallet.spend(wallet, total) then
      events:emit('economy:failed', 'not_enough_money')
      return false
    end
    local ok = Inventory.addItem(inventoryComponent, itemId, quantity)
    if not ok then
      Wallet.add(wallet, total)
      events:emit('economy:failed', 'inventory_full')
      return false
    end
    events:emit('economy:purchase', shopId, itemId, quantity, total)
    events:emit('audio:play', 'assets/sfx/ui_click.wav', 0.7)
    return true
  end

  function system:sell(itemId, quantity)
    local wallet = getWallet()
    local inventoryComponent = getInventory()
    if not wallet or not inventoryComponent then
      return false
    end
    local price = balance.sell[itemId]
    if not price then
      events:emit('economy:failed', 'cannot_sell')
      return false
    end
    local removed = Inventory.removeItem(inventoryComponent, itemId, quantity)
    if not removed then
      events:emit('economy:failed', 'missing_items')
      return false
    end
    Wallet.add(wallet, price * quantity)
    events:emit('economy:sold', itemId, quantity, price * quantity)
    events:emit('audio:play', 'entities/shops/sfx/sell.wav', 0.7)
    return true
  end

  return system
end
