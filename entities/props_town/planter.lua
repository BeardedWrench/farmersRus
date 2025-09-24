local Transform = require 'components.transform'
local Renderable = require 'components.renderable'

local Planter = {}

function Planter.spawn(app, position)
  local ecs = app.ecs
  local entity = ecs:createEntity()
  ecs:addComponent(entity, 'transform', Transform.create({
    position = position or { 2, 0, -3 },
    scale = { 1.0, 0.4, 1.0 }
  }))
  ecs:addComponent(entity, 'renderable', Renderable.create({
    primitive = 'prop',
    tint = { 0.45, 0.6, 0.3, 1 }
  }))
  return entity
end

return Planter
