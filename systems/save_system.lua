return function(app)
  local ecs = app.ecs
  local events = app.events

  local system = {
    name = 'save_system',
    updateOrder = 100
  }

  local soilQuery
  local cropQuery
  local loaded

  function system:init()
    soilQuery = ecs:getQuery({ 'soil', 'gridcell' })
    cropQuery = ecs:getQuery({ 'crop', 'gridcell' })
    app.saveSystem = self

    events:on('save:collect', function(payload)
      payload.version = 1
      payload.farm = self:collectFarm()
    end)

    events:on('save:load', function(data)
      loaded = data
    end)
  end

  function system:collectFarm()
    local farm = {
      soil = {},
      crops = {}
    }
    local soilList = soilQuery.list
    for i = 1, #soilList do
      local entity = soilList[i]
      local soil = ecs:getComponent(entity, 'soil')
      local cell = ecs:getComponent(entity, 'gridcell')
      farm.soil[#farm.soil + 1] = {
        x = cell.x,
        y = cell.y,
        tilled = soil.tilled,
        wetness = soil.wetness
      }
    end

    local cropList = cropQuery.list
    for i = 1, #cropList do
      local entity = cropList[i]
      local crop = ecs:getComponent(entity, 'crop')
      local cell = ecs:getComponent(entity, 'gridcell')
      farm.crops[#farm.crops + 1] = {
        id = crop.id,
        stage = crop.stage,
        progress = crop.progress,
        x = cell.x,
        y = cell.y
      }
    end
    return farm
  end

  function system:getLoaded()
    return loaded
  end

  function system:consumeFarm()
    if loaded and loaded.farm then
      local farm = loaded.farm
      loaded.farm = nil
      return farm
    end
    return nil
  end

  return system
end
