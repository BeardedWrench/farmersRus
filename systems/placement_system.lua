local Transform = require 'components.transform'
local Renderable = require 'components.renderable'
local CursorComponent = require 'components.cursor'

return function(app)
  local ecs = app.ecs
  local grid = app.grid

  local cursorEntity
  local highlightCells = {}

  local colors = {
    valid = { 0.3, 0.9, 0.4, 0.35 },
    blocked = { 0.9, 0.3, 0.3, 0.35 },
    occupied = { 0.9, 0.8, 0.3, 0.35 },
    preview = { 0.3, 0.6, 0.9, 0.35 },
    none = { 0.2, 0.2, 0.2, 0.15 }
  }

  local system = {
    name = 'placement_system',
    updateOrder = -70
  }

  local function applyHighlight(cells, state)
    for i = 1, #cells do
      local cell = cells[i]
      grid:setHighlight(cell.x, cell.y, state)
    end
  end

  local function clearHighlights()
    applyHighlight(highlightCells, 'none')
    for i = #highlightCells, 1, -1 do
      highlightCells[i] = nil
    end
  end

  local function setCursorState(cursor, renderable, state)
    cursor.state = state
    renderable.tint = colors[state] or colors.none
  end

  function system:init()
    cursorEntity = ecs:createEntity()
    ecs:addComponent(cursorEntity, 'transform', Transform.create({}))
    ecs:addComponent(cursorEntity, 'renderable', Renderable.create({
      primitive = 'cursor',
      tint = colors.none,
      visible = true
    }))
    ecs:addComponent(cursorEntity, 'cursor', CursorComponent.create({}))

    app.cursorEntity = cursorEntity

    app.events:on('grid:hover', function(data)
      local cursor = ecs:getComponent(cursorEntity, 'cursor')
      local transform = ecs:getComponent(cursorEntity, 'transform')
      local renderable = ecs:getComponent(cursorEntity, 'renderable')
      if not cursor or not transform then
        return
      end

      transform.position[1], transform.position[2], transform.position[3] = app.grid:cellToWorld(data.x, data.y)
      cursor.cellX = data.x
      cursor.cellY = data.y
      cursor.worldHit = { data.world[1], data.world[2], data.world[3] }

      clearHighlights()
      highlightCells[1] = { x = data.x, y = data.y }

      local state
      if not grid:isWithin(data.x, data.y) then
        state = 'blocked'
      else
        local cell = grid.cells[data.x] and grid.cells[data.x][data.y]
        if cell and cell.occupied then
          state = cell.blocking and 'blocked' or 'occupied'
        else
          state = 'valid'
        end
      end

      applyHighlight(highlightCells, state)
      setCursorState(cursor, renderable, state)
    end)
  end

  return system
end
