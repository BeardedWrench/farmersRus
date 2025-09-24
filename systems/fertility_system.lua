return function(app)
  local ecs = app.ecs
  local cropQuery

  local system = {
    name = 'fertility_system',
    updateOrder = 6
  }

  function system:init()
    cropQuery = ecs:getQuery({ 'crop' })
  end

  function system:update(dt)
    local list = cropQuery.list
    for i = 1, #list do
      local entity = list[i]
      local crop = ecs:getComponent(entity, 'crop')
      if crop and crop.stats then
        if crop.stats.fertilizer and crop.stats.fertilizer > 0 then
          crop.stats.fertilizer = math.max(0, crop.stats.fertilizer - 0.01 * dt)
        end
      end
    end
  end

  return system
end
