local Transform = require 'components.transform'
local Renderable = require 'components.renderable'
local Gridcell = require 'components.gridcell'
local CropComponent = require 'components.crop'
local SocketsComponent = require 'components.sockets'
local SoilDomain = require 'entities.soil.soil'

local config = require 'entities.wheat.config'
local socketDefs = require 'entities.wheat.sockets'

local Wheat = {}

function Wheat.applyStage(app, entity, stageIndex)
  local stage = config.stages[stageIndex]
  if not stage then
    return
  end
  local renderable = app.ecs:getComponent(entity, 'renderable')
  if renderable then
    renderable.model = app.resources:getModel(stage.model)
    renderable.tint = { 0.9, 0.85, 0.5, 1 }
  end
  local crop = app.ecs:getComponent(entity, 'crop')
  if crop then
    crop.stage = stageIndex
    crop.progress = 0
  end
end

function Wheat.spawn(app, cellX, cellY)
  SoilDomain.ensure(app, cellX, cellY)
  local ecs = app.ecs
  local entity = ecs:createEntity()
  local worldX, _, worldZ = app.grid:cellToWorld(cellX, cellY)

  ecs:addComponent(entity, 'transform', Transform.create({
    position = { worldX, 0, worldZ }
  }))
  ecs:addComponent(entity, 'renderable', Renderable.create({
    primitive = 'prop',
    tint = { 0.9, 0.85, 0.5, 1 }
  }))
  ecs:addComponent(entity, 'gridcell', Gridcell.create({ x = cellX, y = cellY }))
  local crop = CropComponent.create({ id = config.id })
  crop.cell = { x = cellX, y = cellY }
  ecs:addComponent(entity, 'crop', crop)
  ecs:addComponent(entity, 'sockets', SocketsComponent.create())
  Wheat.applyStage(app, entity, 1)
  app.grid:setOccupied(cellX, cellY, entity, true)
  return entity
end

function Wheat.spawnFruit(app, parentEntity, socketName)
  local socket = socketDefs[socketName]
  if not socket then
    return nil
  end
  local ecs = app.ecs
  local transform = ecs:getComponent(parentEntity, 'transform')
  if not transform then
    return nil
  end
  local entity = ecs:createEntity()
  local ox = socket.offset[1] or 0
  local oy = socket.offset[2] or 0
  local oz = socket.offset[3] or 0
  ecs:addComponent(entity, 'transform', Transform.create({
    position = {
      transform.position[1] + ox,
      transform.position[2] + oy,
      transform.position[3] + oz
    },
    scale = socket.scale or { 0.18, 0.35, 0.18 }
  }))
  ecs:addComponent(entity, 'renderable', Renderable.create({
    primitive = 'prop',
    tint = { 0.95, 0.85, 0.45, 1 },
    model = app.resources:getModel(config.fruit.model)
  }))
  return entity
end

Wheat.config = config
Wheat.sockets = socketDefs

return Wheat
