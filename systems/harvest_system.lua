return function(app)
  local ecs = app.ecs
  local events = app.events
  local cropsDb = app.gameplay.crops
  local inventoryLib = require 'components.inventory'

  local system = {
    name = 'harvest_system',
    updateOrder = 15
  }

  function system:init()
    events:on('harvest:collect', function(entity)
      self:collect(entity)
    end)
  end

  function system:collect(entity)
    local crop = ecs:getComponent(entity, 'crop')
    if not crop then
      return
    end
    local config = cropsDb[crop.id]
    if not config then
      return
    end
    local sockets = ecs:getComponent(entity, 'sockets')
    local harvested = 0
    if sockets then
      for socketName, fruitEntity in pairs(sockets.attachments) do
        ecs:destroyEntity(fruitEntity)
        sockets.attachments[socketName] = nil
        harvested = harvested + 1
      end
    end
    harvested = math.max(harvested, config.fruit.count or 1)
    local inventoryComponent = app.inventory and app.inventory:getInventory()
    if inventoryComponent then
      inventoryLib.addItem(inventoryComponent, config.fruit.itemId, harvested)
    end
    app.events:emit('audio:play', 'entities/tools/sfx/harvest.wav', 0.7)
    ecs:destroyEntity(entity)
    if app.grid and crop.cell then
      app.grid:setOccupied(crop.cell.x, crop.cell.y, nil)
    end
    app.events:emit('fx:sparkle', crop.cell and crop.cell.x or 0, 0.8, crop.cell and crop.cell.y or 0)
  end

  return system
end
