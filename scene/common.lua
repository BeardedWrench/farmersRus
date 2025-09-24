local Transform = require 'components.transform'
local Renderable = require 'components.renderable'

local Common = {}

Common.GROUND_DEFAULTS = {
  position = { 0, -0.05, 0 },
  size = { 400, 400 },
  tint = { 0.56, 0.75, 0.55, 1.0 }
}

local function clone(vec)
  if not vec then
    return nil
  end
  local copy = {}
  for i = 1, #vec do
    copy[i] = vec[i]
  end
  return copy
end

---@param app table
---@param options table
function Common.spawnGround(app, options)
  options = options or {}
  local defaults = Common.GROUND_DEFAULTS

  local position = clone(options.position) or clone(defaults.position)
  local size = options.size or defaults.size
  if type(size) == 'number' then
    size = { size, size }
  else
    size = { size[1], size[2] }
  end
  local tint = clone(options.tint) or clone(defaults.tint)

  local ecs = app.ecs
  local entity = ecs:createEntity()

  ecs:addComponent(entity, 'transform', Transform.create({
    position = position
  }))

  ecs:addComponent(entity, 'renderable', Renderable.create({
    primitive = 'ground',
    tint = tint,
    size = size
  }))

  return entity
end

return Common
