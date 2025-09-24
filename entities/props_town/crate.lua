local Transform = require 'components.transform'
local Renderable = require 'components.renderable'

local Crate = {}

function Crate.spawn(app, position)
  local ecs = app.ecs
  local entity = ecs:createEntity()
  ecs:addComponent(entity, 'transform', Transform.create({
    position = position or { 5, 0, -4 },
    scale = { 0.8, 0.8, 0.8 }
  }))
  ecs:addComponent(entity, 'renderable', Renderable.create({
    primitive = 'prop',
    tint = { 0.6, 0.45, 0.3, 1 }
  }))
  return entity
end

return Crate
