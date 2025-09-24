local Transform = require 'components.transform'
local Renderable = require 'components.renderable'

local Bench = {}

function Bench.spawn(app, position)
  local ecs = app.ecs
  local entity = ecs:createEntity()
  ecs:addComponent(entity, 'transform', Transform.create({
    position = position or { 4, 0, -3 },
    scale = { 1.5, 1, 0.5 }
  }))
  ecs:addComponent(entity, 'renderable', Renderable.create({
    primitive = 'prop',
    tint = { 0.5, 0.3, 0.2, 1 }
  }))
  return entity
end

return Bench
