local Transform = require 'components.transform'
local Renderable = require 'components.renderable'
local AmbientComponent = require 'components.ambient'

local NPC = {}

function NPC.spawn(app, position)
  local ecs = app.ecs
  local entity = ecs:createEntity()
  ecs:addComponent(entity, 'transform', Transform.create({
    position = position or { 6, 0, -3 },
    scale = { 0.6, 1.8, 0.6 }
  }))
  ecs:addComponent(entity, 'renderable', Renderable.create({
    primitive = 'prop',
    tint = { 0.8, 0.7, 0.8, 1 }
  }))
  ecs:addComponent(entity, 'ambient', AmbientComponent.create({ kind = 'npc' }))
  return entity
end

return NPC
