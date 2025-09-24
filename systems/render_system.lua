return function(app)
  local ecs = app.ecs
  local query

  local system = {
    name = 'render_system',
    drawOrder = 100
  }

  local function applyColor(pass, color)
    if not color then
      pass:setColor(1, 1, 1, 1)
    else
      pass:setColor(color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1)
    end
  end

  function system:init()
    query = ecs:getQuery({ 'transform', 'renderable' })
  end

  local primitiveDraw = {
    cursor = function(pass, transform, renderable)
      applyColor(pass, renderable.tint)
      pass:push('state')
      pass:setCullMode('none')
      pass:plane(transform.position[1], transform.position[2] + 0.02, transform.position[3], 1, 1, -math.pi / 2, 1, 0, 0)
      pass:pop('state')
      pass:setColor(1, 1, 1, 1)
    end,
    tile = function(pass, transform, renderable)
      applyColor(pass, renderable.tint)
      pass:push('state')
      pass:setCullMode('none')
      pass:plane(transform.position[1], transform.position[2], transform.position[3], 1, 1, -math.pi / 2, 1, 0, 0)
      pass:pop('state')
      pass:setColor(1, 1, 1, 1)
    end,
    prop = function(pass, transform, renderable)
      applyColor(pass, renderable.tint)
      pass:cube(transform.position[1], transform.position[2] + 0.5 * transform.scale[2], transform.position[3], transform.scale[1], transform.scale[2], transform.scale[3])
      pass:setColor(1, 1, 1, 1)
    end,
    fx = function(pass, transform, renderable)
      applyColor(pass, renderable.tint)
      pass:sphere(transform.position[1], transform.position[2], transform.position[3], 0.15)
      pass:setColor(1, 1, 1, 1)
    end,
    ground = function(pass, transform, renderable)
      applyColor(pass, renderable.tint)
      local sx = renderable.size and renderable.size[1] or transform.scale[1] or 1
      local sz = renderable.size and renderable.size[2] or transform.scale[3] or 1
      pass:push('state')
      pass:setCullMode('none')
      pass:plane(transform.position[1], transform.position[2], transform.position[3], sx, sz, -math.pi / 2, 1, 0, 0)
      pass:pop('state')
      pass:setColor(1, 1, 1, 1)
    end,
    panel = function(pass, transform, renderable)
      applyColor(pass, renderable.tint)
      local sx = renderable.size and renderable.size[1] or 1
      local sy = renderable.size and renderable.size[2] or 1
      pass:plane(transform.position[1], transform.position[2], transform.position[3], sx, sy)
      pass:setColor(1, 1, 1, 1)
    end
  }

  function system:draw(pass)
    local list = query.list
    for i = 1, #list do
      local entity = list[i]
      local transform = ecs:getComponent(entity, 'transform')
      local renderable = ecs:getComponent(entity, 'renderable')
      if renderable and renderable.visible ~= false then
        if renderable.model and not renderable.model.__placeholder then
          applyColor(pass, renderable.tint)
          pass:draw(renderable.model,
            transform.position[1], transform.position[2], transform.position[3],
            transform.scale[1], transform.scale[2], transform.scale[3],
            transform.rotation[1], transform.rotation[2], transform.rotation[3], transform.rotation[4])
          pass:setColor(1, 1, 1, 1)
        else
          local drawer = primitiveDraw[renderable.primitive or 'prop'] or primitiveDraw.prop
          drawer(pass, transform, renderable)
        end
      end
    end
  end

  return system
end
