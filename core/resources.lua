local Resources = {}
Resources.__index = Resources

local function normalizeKey(path)
  if not path or path == '' then
    return '__default__'
  end
  return path
end

local function loadLuaTable(path)
  if not path or not lovr.filesystem.isFile(path) then
    return nil
  end
  local chunk = lovr.filesystem.load(path)
  if not chunk then
    return nil
  end
  local ok, result = pcall(chunk)
  if not ok then
    print(('Failed to load resource descriptor %s: %s'):format(path, result))
    return nil
  end
  if type(result) ~= 'table' then
    return nil
  end
  return result
end

function Resources.new()
  local instance = {
    app = nil,
    caches = {
      model = {},
      material = {},
      texture = {},
      sound = {}
    }
  }
  return setmetatable(instance, Resources)
end

function Resources:bind(app)
  self.app = app
end

function Resources:_makePlaceholderModel(name)
  local label = name or 'placeholder'
  return {
    __placeholder = true,
    name = label
  }
end

function Resources:getModel(path, options)
  local key = normalizeKey(path)
  local cache = self.caches.model
  if cache[key] then
    return cache[key]
  end
  local model
  if os.getenv('LOVR_SKIP_MODELS') == '1' then
    model = self:_makePlaceholderModel(path)
  elseif path and lovr.filesystem.isFile(path) then
    local ok, result = pcall(lovr.graphics.newModel, path, options)
    if ok and result then
      model = result
    else
      print(('Failed to load model %s: %s'):format(path, result))
      model = self:_makePlaceholderModel(path)
    end
  else
    model = self:_makePlaceholderModel(path)
  end
  cache[key] = model
  return model
end

function Resources:getTexture(path)
  local key = normalizeKey(path)
  local cache = self.caches.texture
  if cache[key] then
    return cache[key]
  end
  if not path or not lovr.filesystem.isFile(path) then
    cache[key] = false
    return nil
  end
  local ok, texture = pcall(lovr.graphics.newTexture, path)
  if ok then
    cache[key] = texture
  else
    print(('Failed to load texture %s: %s'):format(path, texture))
    cache[key] = false
  end
  return cache[key] or nil
end

function Resources:getMaterial(path)
  local key = normalizeKey(path)
  local cache = self.caches.material
  if cache[key] then
    return cache[key]
  end
  local descriptor = loadLuaTable(path)
  if not descriptor then
    descriptor = {
      color = { 1.0, 1.0, 1.0, 1.0 },
      roughness = 0.8
    }
  end
  cache[key] = descriptor
  return descriptor
end

function Resources:getSound(path, kind)
  local key = normalizeKey(path)
  local cache = self.caches.sound
  if cache[key] ~= nil then
    return cache[key]
  end
  if not path or not lovr.filesystem.isFile(path) then
    cache[key] = false
    return nil
  end

  if not lovr.audio then
    cache[key] = false
    return nil
  end

  local options
  if type(kind) == 'table' then
    options = kind
  elseif kind == 'stream' then
    options = { decode = false }
  elseif kind == 'static' then
    options = { decode = true }
  else
    options = nil
  end

  local ok, source
  if options then
    ok, source = pcall(lovr.audio.newSource, path, options)
  else
    ok, source = pcall(lovr.audio.newSource, path)
  end

  if ok then
    cache[key] = source
  else
    print(('Failed to load sound %s: %s'):format(path, source))
    cache[key] = false
  end
  return cache[key] or nil
end

function Resources:preloadGlobal()
  self:getModel('assets/models/grid_cursor.glb')
  self:getModel('assets/models/ghost_cube.glb')
  self:getMaterial('assets/materials/ghost_preview.mat.lua')
  self:getTexture('assets/textures/checker.png')
  self:getSound('assets/sfx/ui_click.wav')
  self:getSound('assets/music/cozy_piano.ogg', 'stream')
end

return Resources
