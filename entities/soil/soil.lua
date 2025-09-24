local Transform = require 'components.transform'
local Renderable = require 'components.renderable'
local Gridcell = require 'components.gridcell'
local SoilComponent = require 'components.soil'

local SoilDomain = {}

local function key(x, y)
  return x .. ':' .. y
end

local function registry(app)
  app.state = app.state or {}
  app.state.soil = app.state.soil or {}
  return app.state.soil
end

function SoilDomain.get(app, x, y)
  return registry(app)[key(x, y)]
end

function SoilDomain.ensure(app, x, y)
  local store = registry(app)
  local existing = store[key(x, y)]
  if existing then
    return existing
  end
  local ecs = app.ecs
  local entity = ecs:createEntity()
  local worldX, _, worldZ = app.grid:cellToWorld(x, y)
  ecs:addComponent(entity, 'transform', Transform.create({
    position = { worldX, 0.05, worldZ }
  }))
  ecs:addComponent(entity, 'renderable', Renderable.create({
    primitive = 'tile',
    tint = { 0.53, 0.40, 0.24, 1 }
  }))
  ecs:addComponent(entity, 'gridcell', Gridcell.create({
    x = x,
    y = y
  }))
  ecs:addComponent(entity, 'soil', SoilComponent.create({
    tilled = false,
    wetness = 0
  }))

  store[key(x, y)] = entity
  return entity
end

function SoilDomain.spawnRect(app, minX, maxX, minY, maxY)
  for gx = minX, maxX do
    for gy = minY, maxY do
      SoilDomain.ensure(app, gx, gy)
    end
  end
end

function SoilDomain.forEach(app, callback)
  for k, entity in pairs(registry(app)) do
    local cx, cy = k:match('([^:]+):([^:]+)')
    callback(entity, tonumber(cx), tonumber(cy))
  end
end

return SoilDomain
