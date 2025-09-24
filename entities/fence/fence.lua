local Transform = require 'components.transform'
local Renderable = require 'components.renderable'

local Fence = {}

local function spawnSegment(app, x, z, rotation)
  local ecs = app.ecs
  local entity = ecs:createEntity()
  ecs:addComponent(entity, 'transform', Transform.create({
    position = { x, 0.35, z },
    rotation = { 0, math.sin(rotation / 2), 0, math.cos(rotation / 2) },
    scale = { 1, 0.7, 0.12 }
  }))
  ecs:addComponent(entity, 'renderable', Renderable.create({
    primitive = 'prop',
    tint = { 0.72, 0.55, 0.33, 1 }
  }))
  return entity
end

function Fence.spawnPerimeter(app, minX, maxX, minZ, maxZ)
  for x = minX, maxX do
    spawnSegment(app, x, minZ, 0)
    spawnSegment(app, x, maxZ, 0)
  end
  for z = minZ, maxZ do
    spawnSegment(app, minX, z, math.pi / 2)
    spawnSegment(app, maxX, z, math.pi / 2)
  end
end

return Fence
