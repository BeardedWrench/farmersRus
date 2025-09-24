return function(app)
  local events = app.events

  local system = {
    name = 'scene_system',
    updateOrder = -95,
    drawOrder = 99
  }

  function system:init()
    events:on('scene:travel', function(target)
      app.scenes:travel(target)
    end)
  end

  function system:update(dt)
    -- Scene transitions handled by scene manager in main update path.
  end

  function system:draw(pass)
    app.scenes:drawOverlay(pass)
  end

  return system
end
