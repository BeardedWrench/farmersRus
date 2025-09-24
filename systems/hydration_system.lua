return function(app)
  local ecs = app.ecs
  local soilQuery
  local cropQuery
  local SoilDomain = require 'entities.soil.soil'

  local system = {
    name = 'hydration_system',
    updateOrder = 5
  }

  function system:init()
    soilQuery = ecs:getQuery({ 'soil', 'renderable' })
    cropQuery = ecs:getQuery({ 'crop' })
  end

  function system:update(dt)
    local soilList = soilQuery.list
    for i = 1, #soilList do
      local entity = soilList[i]
      local soil = ecs:getComponent(entity, 'soil')
      local renderable = ecs:getComponent(entity, 'renderable')
      if soil and renderable then
        if soil.wetness > 0 then
          soil.wetness = math.max(0, soil.wetness - soil.hydrationLoss * dt)
          soil.darkenTimer = 1.0
        else
          soil.darkenTimer = math.max(soil.darkenTimer - dt, 0)
        end
        local tint = renderable.tint
        local wetTint = 0.35 + soil.wetness * 0.3
        tint[1], tint[2], tint[3], tint[4] = wetTint, wetTint, wetTint, tint[4] or 1
      end
    end

    local cropList = cropQuery.list
    for i = 1, #cropList do
      local entity = cropList[i]
      local crop = ecs:getComponent(entity, 'crop')
      if crop and crop.cell then
        local soilEntity = SoilDomain.get(app, crop.cell.x, crop.cell.y)
        if soilEntity then
          local soil = ecs:getComponent(soilEntity, 'soil')
          if soil then
            crop.stats.hydration = 0.2 + soil.wetness * 0.8
          end
        end
      end
    end
  end

  return system
end
