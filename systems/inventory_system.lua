local InventoryComponent = require 'components.inventory'
local WalletComponent = require 'components.wallet'
local ToolComponent = require 'components.tool'
local ItemLibrary = require 'entities.item_library'

return function(app)
  local ecs = app.ecs
  local events = app.events

  local system = {
    name = 'inventory_system',
    updateOrder = -60
  }

  function system:init()
    self.playerEntity = nil
    app.inventory = self

    events:on('game:start', function()
      if not self.playerEntity then
        self:createPlayerFromStarter()
      end
    end)

    events:on('save:collect', function(payload)
      self:serialize(payload)
    end)

    events:on('save:load', function(data)
      if data and data.player then
        self:load(data.player)
      end
    end)

    events:on('inventory:add', function(itemId, amount, options)
      self:addItem(itemId, amount, options)
    end)

    events:on('inventory:remove', function(itemId, amount)
      self:removeItem(itemId, amount)
    end)
  end

  function system:getPlayer()
    return self.playerEntity
  end

  function system:getInventory()
    if not self.playerEntity then
      return nil
    end
    return ecs:getComponent(self.playerEntity, 'inventory')
  end

  function system:getWallet()
    if not self.playerEntity then
      return nil
    end
    return ecs:getComponent(self.playerEntity, 'wallet')
  end

  function system:getTool()
    if not self.playerEntity then
      return nil
    end
    return ecs:getComponent(self.playerEntity, 'tool')
  end

  function system:createPlayerFromStarter()
    local starter = app.gameplay.starter
    local entity = ecs:createEntity()

    local inventory = InventoryComponent.create({
      capacity = starter.inventory.capacity
    })
    for _, item in ipairs(starter.inventory.items) do
      local meta = item.meta or ItemLibrary.get(item.id)
      InventoryComponent.addItem(inventory, item.id, item.qty, {
        stackable = item.stackable,
        meta = meta
      })
    end

    local wallet = WalletComponent.create({
      balance = starter.money
    })

    ecs:addComponent(entity, 'inventory', inventory)
    ecs:addComponent(entity, 'wallet', wallet)
    ecs:addComponent(entity, 'tool', ToolComponent.create({
      type = starter.activeTool or 'shovel'
    }))

    self.playerEntity = entity
    app.playerEntity = entity
    events:emit('player:spawned', entity)
  end

  function system:addItem(itemId, amount, options)
    local inventory = self:getInventory()
    if not inventory then
      return false
    end
    options = options or {}
    if not options.meta then
      options.meta = ItemLibrary.get(itemId)
    end
    if options.meta and not options.meta.label then
      options.meta.label = itemId
    end
    return InventoryComponent.addItem(inventory, itemId, amount, options)
  end

  function system:removeItem(itemId, amount)
    local inventory = self:getInventory()
    if not inventory then
      return false
    end
    return InventoryComponent.removeItem(inventory, itemId, amount)
  end

  function system:serialize(payload)
    if not self.playerEntity then
      return
    end
    local inventory = ecs:getComponent(self.playerEntity, 'inventory')
    local wallet = ecs:getComponent(self.playerEntity, 'wallet')
    local tool = ecs:getComponent(self.playerEntity, 'tool')
    payload.player = {
      inventory = inventory and inventory.slots or {},
      capacity = inventory and inventory.capacity or 0,
      balance = wallet and wallet.balance or 0,
      tool = tool and tool.type or 'shovel'
    }
  end

  function system:load(data)
    local entity = ecs:createEntity()
    local inventory = InventoryComponent.create({
      capacity = data.capacity or 40,
      slots = data.inventory or {}
    })
    local wallet = WalletComponent.create({
      balance = data.balance or 0
    })
    ecs:addComponent(entity, 'inventory', inventory)
    ecs:addComponent(entity, 'wallet', wallet)
    ecs:addComponent(entity, 'tool', ToolComponent.create({
      type = data.tool or 'shovel'
    }))
    self.playerEntity = entity
    app.playerEntity = entity
    events:emit('player:spawned', entity)
  end

  return system
end
