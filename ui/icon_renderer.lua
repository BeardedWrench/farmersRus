local IconRenderer = {}
IconRenderer.__index = IconRenderer

local DEFAULT_SIZE = 128

function IconRenderer.new(app)
  local self = {
    app = app,
    cache = {},
    size = DEFAULT_SIZE,
    defaultColor = { 0.3, 0.35, 0.42, 1 }
  }
  return setmetatable(self, IconRenderer)
end

local function makeFallbackMaterial()
  if not IconRenderer._fallbackMaterial then
    IconRenderer._fallbackMaterial = lovr.graphics.newMaterial({
      color = { 0.3, 0.35, 0.42, 1 }
    })
  end
  return IconRenderer._fallbackMaterial
end

function IconRenderer:getIcon(key, descriptor)
  if not key then
    return nil
  end
  local cached = self.cache[key]
  if cached then
    return cached
  end

  if descriptor and descriptor.model then
    local created = self:renderModelIcon(key, descriptor.model, descriptor)
    if created then
      self.cache[key] = created
      return created
    end
  end

  local fallback = {
    material = makeFallbackMaterial(),
    metadata = { fallback = true }
  }
  self.cache[key] = fallback
  return fallback
end

local function applyRotation(pass, options)
  if not options then
    return
  end

  if options.orientation then
    local orientation = options.orientation
    if orientation.pitch then
      pass:rotate(math.rad(orientation.pitch), 1, 0, 0)
    end
    if orientation.yaw then
      pass:rotate(math.rad(orientation.yaw), 0, 1, 0)
    end
    if orientation.roll then
      pass:rotate(math.rad(orientation.roll), 0, 0, 1)
    end
    return
  end

  if options.rotations then
    for i = 1, #options.rotations do
      local rotation = options.rotations[i]
      pass:rotate(rotation[1], rotation[2], rotation[3], rotation[4] or 0)
    end
    return
  end

  local rotation = options.rotation or { math.rad(35), 0, 1, 0 }
  pass:rotate(rotation[1], rotation[2], rotation[3], rotation[4] or 0)
end

function IconRenderer:renderModelIcon(key, modelPath, options)
  if not lovr.graphics.newModel or not lovr.graphics.newPass then
    return nil
  end

  local ok, model = pcall(lovr.graphics.newModel, modelPath)
  if not ok or not model then
    return nil
  end

  local size = options.iconSize or self.size
  local texture = lovr.graphics.newTexture(size, size, { mipmaps = false })
  local pass = lovr.graphics.newPass(texture)
  pass:setClear(0, 0, 0, 0)
  pass:setDepthTest('lequal', true)

  local cameraPos = lovr.math.newVec3(0, options.cameraY or 0.2, options.distance or 3.2)
  local target = lovr.math.newVec3(0, options.targetY or 0, 0)
  local up = lovr.math.newVec3(0, 1, 0)
  local view = lovr.math.newMat4():target(cameraPos, target, up)
  local projection = lovr.math.newMat4():perspective(math.rad(55), 1, 0.1, 100)
  pass:setViewPose(1, view)
  pass:setProjection(1, projection)

  pass:push('transform')
  if options.offset then
    pass:translate(options.offset[1] or 0, options.offset[2] or 0, options.offset[3] or 0)
  end
  applyRotation(pass, options)
  if options.scale then
    local scale = options.scale
    if type(scale) == 'number' then
      pass:scale(scale)
    else
      pass:scale(scale[1] or 1, scale[2] or scale[1] or 1, scale[3] or scale[1] or 1)
    end
  end
  pass:draw(model)
  pass:pop()

  lovr.graphics.submit(pass)

  local ok, result = pcall(function()
    return lovr.graphics.newMaterial({ texture = texture })
  end)
  local material = ok and result or lovr.graphics.newMaterial(texture)
  
  -- local material = lovr.graphics.newMaterial(texture)
  return {
    texture = texture,
    material = material,
    metadata = {
      model = modelPath
    }
  }
end

return IconRenderer
