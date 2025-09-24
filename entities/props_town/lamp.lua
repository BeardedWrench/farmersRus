local Transform = require 'components.transform'
local Renderable = require 'components.renderable'

local Lamp = {}

function Lamp.spawn(app, position)
  local ecs = app.ecs
  local entity = ecs:createEntity()
  ecs:addComponent(entity, 'transform', Transform.create({
    position = position or { 3, 0, -5 },
    scale = { 0.2, 2.0, 0.2 }
  }))
  ecs:addComponent(entity, 'renderable', Renderable.create({
    primitive = 'prop',
    tint = { 0.2, 0.2, 0.25, 1 }
  }))
  return entity
end

return Lamp
