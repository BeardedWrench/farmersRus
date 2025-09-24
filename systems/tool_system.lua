local SoilDomain = require 'entities.soil.soil'
local InventoryLib = require 'components.inventory'

return function(app)
  local ecs = app.ecs
  local events = app.events
  local input = app.input
  local grid = app.grid
  local inventorySystem

  local system = {
    name = 'tool_system',
    updateOrder = -50
  }

  local hotbar = {
    'shovel',
    'watering',
    'seed:corn',
    'harvest'
  }

  local function getCursor()
    if not app.cursorEntity then
      return nil
    end
    return ecs:getComponent(app.cursorEntity, 'cursor')
  end

  local function setTool(toolComponent, toolType)
    toolComponent.type = toolType
    local cursor = getCursor()
    if cursor then
      cursor.tool = toolType
    end
  end

  local function getSoil(cellX, cellY)
    return SoilDomain.get(app, cellX, cellY)
  end

  function system:init()
    inventorySystem = app.inventory
    events:on('player:spawned', function(entity)
      local toolComponent = ecs:getComponent(entity, 'tool')
      if toolComponent then
        setTool(toolComponent, toolComponent.type)
      end
    end)

    events:on('input:mousepressed', function(x, y, button)
      if button == 1 then
        self:applyCurrentTool()
      end
    end)
  end

  function system:applyCurrentTool()
    if not inventorySystem then
      return
    end
    local player = inventorySystem:getPlayer()
    if not player then
      return
    end
    local tool = ecs:getComponent(player, 'tool')
    local cursor = getCursor()
    if not tool or not cursor then
      return
    end
    if cursor.state ~= 'valid' and tool.type ~= 'harvest' then
      return
    end
    local cellX, cellY = cursor.cellX, cursor.cellY
    local current = tool.type
    if current == 'shovel' then
      local soilEntity = getSoil(cellX, cellY)
      if not soilEntity then
        soilEntity = SoilDomain.ensure(app, cellX, cellY)
      end
      if soilEntity then
        local soil = ecs:getComponent(soilEntity, 'soil')
        soil.tilled = not soil.tilled
        soil.wetness = 0
        events:emit('audio:play', 'entities/tools/sfx/shovel_dig.wav', 0.8)
      end
    elseif current == 'watering' then
      local soilEntity = getSoil(cellX, cellY)
      if soilEntity then
        local soil = ecs:getComponent(soilEntity, 'soil')
        soil.wetness = math.min(1.0, soil.wetness + 0.5)
        soil.darkenTimer = 1.0
        events:emit('fx:water', cellX, cellY)
        events:emit('audio:play', 'entities/tools/sfx/water_pour.wav', 0.7)
      end
    elseif current == 'harvest' then
      local column = grid.cells[cellX]
      local cell = column and column[cellY]
      if cell and cell.entity then
        events:emit('harvest:collect', cell.entity)
      end
    else
      local cropId = current:match('seed:(.+)')
      if cropId then
        local soilEntity = getSoil(cellX, cellY)
        if soilEntity then
          local soil = ecs:getComponent(soilEntity, 'soil')
          if soil.tilled then
            local column = grid.cells[cellX]
            local cell = column and column[cellY]
            if not cell or not cell.entity then
              local inventory = inventorySystem:getInventory()
              if inventory and InventoryLib.hasItem(inventory, 'seed:' .. cropId, 1) then
                local planted = app.gameplay.crops[cropId].spawn(app, cellX, cellY)
                if planted then
                  InventoryLib.removeItem(inventory, 'seed:' .. cropId, 1)
                  events:emit('audio:play', 'assets/sfx/ui_click.wav', 0.5)
                end
              end
            end
          end
        end
      end
    end
  end

  function system:update(dt)
    local player = inventorySystem and inventorySystem:getPlayer()
    if not player then
      return
    end
    local tool = ecs:getComponent(player, 'tool')
    if not tool then
      return
    end
    for index, code in ipairs({ '1', '2', '3', '4' }) do
      if input:pressed(code) then
        local entry = hotbar[index]
        if entry then
          setTool(tool, entry)
        end
      end
    end
  end

  return system
end
