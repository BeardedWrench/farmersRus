return function(app)
  local events = app.events

  local system = {
    name = 'fx_system',
    updateOrder = 90,
    drawOrder = 95
  }

  local effects = {}

  local function spawnEffect(kind, x, y, z)
    effects[#effects + 1] = {
      kind = kind,
      position = { x, y, z },
      life = kind == 'water' and 0.4 or 0.6
    }
  end

  function system:init()
    events:on('fx:water', function(cx, cy)
      local wx, _, wz = app.grid:cellToWorld(cx, cy)
      spawnEffect('water', wx, 0.5, wz)
    end)

    events:on('fx:sparkle', function(x, y, z)
      spawnEffect('sparkle', x, y, z)
    end)
  end

  function system:update(dt)
    for i = #effects, 1, -1 do
      local fx = effects[i]
      fx.life = fx.life - dt
      if fx.life <= 0 then
        table.remove(effects, i)
      end
    end
  end

  function system:draw(pass)
    for i = 1, #effects do
      local fx = effects[i]
      local alpha = math.max(0, fx.life)
      if fx.kind == 'water' then
        pass:setColor(0.4, 0.6, 1.0, alpha)
        pass:cylinder(fx.position[1], fx.position[2], fx.position[3], 0.1, 0.2)
      else
        pass:setColor(1.0, 0.9, 0.4, alpha)
        pass:sphere(fx.position[1], fx.position[2], fx.position[3], 0.15)
      end
    end
    pass:setColor(1, 1, 1, 1)
  end

  return system
end
