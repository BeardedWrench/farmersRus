local Transform = require 'components.transform'
local Renderable = require 'components.renderable'
local CompostComponent = require 'components.compost'
local Gridcell = require 'components.gridcell'

local CompostBin = {}

function CompostBin.spawn(app, cellX, cellY)
  local ecs = app.ecs
  local entity = ecs:createEntity()
  local worldX, _, worldZ = app.grid:cellToWorld(cellX, cellY)
  ecs:addComponent(entity, 'transform', Transform.create({
    position = { worldX, 0, worldZ },
    scale = { 1, 1, 1 }
  }))
  ecs:addComponent(entity, 'renderable', Renderable.create({
    primitive = 'prop',
    tint = { 0.4, 0.25, 0.15, 1 }
  }))
  ecs:addComponent(entity, 'gridcell', Gridcell.create({ x = cellX, y = cellY }))
  ecs:addComponent(entity, 'compost', CompostComponent.create({}))
  app.grid:setOccupied(cellX, cellY, entity, true)
  return entity
end

return CompostBin
