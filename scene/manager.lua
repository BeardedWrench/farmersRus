local SceneManager = {}
SceneManager.__index = SceneManager

function SceneManager.new()
  local instance = {
    app = nil,
    scenes = {},
    active = nil,
    overlay = {
      alpha = 0,
      duration = 0.6,
      timer = 0,
      target = nil,
      phase = 'idle'
    }
  }
  return setmetatable(instance, SceneManager)
end

function SceneManager:bind(app)
  self.app = app
end

function SceneManager:register(name, sceneModule)
  self.scenes[name] = sceneModule
end

function SceneManager:activate(name, data)
  local definition = self.scenes[name]
  if not definition then
    return
  end
  if self.active and self.active.leave then
    self.active:leave()
  end
  local instance
  if type(definition) == 'table' then
    instance = setmetatable({ app = self.app }, { __index = definition })
  else
    instance = definition(self.app)
  end
  self.active = instance
  if instance.enter then
    instance:enter(data)
  end
end

function SceneManager:update(dt)
  local overlay = self.overlay
  if overlay.phase ~= 'idle' then
    overlay.timer = overlay.timer + dt
    local t = overlay.timer / overlay.duration
    if overlay.phase == 'out' then
      overlay.alpha = math.min(1, t)
      if overlay.timer >= overlay.duration then
        self:activate(overlay.target, overlay.payload)
        overlay.phase = 'in'
        overlay.timer = 0
      end
    elseif overlay.phase == 'in' then
      overlay.alpha = math.max(0, 1 - t)
      if overlay.timer >= overlay.duration then
        overlay.phase = 'idle'
        overlay.timer = 0
        overlay.target = nil
        overlay.alpha = 0
      end
    end
  else
    if self.active and self.active.update then
      self.active:update(dt)
    end
  end
end

function SceneManager:draw(pass)
  if self.active and self.active.draw then
    self.active:draw(pass)
  end
end

function SceneManager:drawOverlay(pass)
  local overlay = self.overlay
  if overlay.alpha <= 0 then
    return
  end
  local camera = self.app and self.app.camera
  if not camera then
    return
  end
  pass:push('transform')
  pass:translate(camera.position[1], camera.position[2], camera.position[3])
  pass:rotate(camera.yaw, 0, 1, 0)
  pass:rotate(-camera.pitch, 1, 0, 0)
  pass:translate(0, 0, -2)
  pass:scale(0.01)
  pass:setColor(0, 0, 0, overlay.alpha)
  pass:plane(0, 0, 0, 400, 400)
  pass:setColor(1, 1, 1, 1)
  pass:pop()
end

function SceneManager:travel(target, payload)
  local overlay = self.overlay
  overlay.target = target
  overlay.payload = payload
  overlay.phase = 'out'
  overlay.timer = 0
end

function SceneManager:getActive()
  return self.active
end

function SceneManager:getActiveName()
  local active = self.active
  if not active then
    return nil
  end
  for name, definition in pairs(self.scenes) do
    if definition == active or (type(definition) == 'table' and getmetatable(active) and getmetatable(active).__index == definition) then
      return name
    end
  end
  return nil
end

function SceneManager:getAlternate()
  local current = self:getActiveName()
  if current == 'farm' then
    return 'town'
  elseif current == 'town' then
    return 'farm'
  end
  return nil
end

return SceneManager
