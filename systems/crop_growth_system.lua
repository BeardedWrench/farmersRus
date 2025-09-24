local TransformComponent = require 'components.transform'
local RenderableComponent = require 'components.renderable'
local CropComponent = require 'components.crop'
local SocketsComponent = require 'components.sockets'

return function(app)
  local ecs = app.ecs
  local cropsDb = app.gameplay.crops

  local system = {
    name = 'crop_growth_system',
    updateOrder = 10
  }

  local query

  local function ensureSockets(entity)
    local sockets = ecs:getComponent(entity, 'sockets')
    if not sockets then
      sockets = SocketsComponent.create()
      ecs:addComponent(entity, 'sockets', sockets)
    end
    return sockets
  end

  local function applyStage(entity, crop, config, stageIndex)
    local renderable = ecs:getComponent(entity, 'renderable')
    local transform = ecs:getComponent(entity, 'transform')
    local stage = config.stages[stageIndex]
    if stage then
      crop.stage = stageIndex
      crop.progress = 0
      if renderable then
        renderable.model = app.resources:getModel(stage.model)
        renderable.tint[1], renderable.tint[2], renderable.tint[3] = 0.6 + 0.1 * stageIndex, 0.8, 0.6
        transform.scale[2] = 0.6 + 0.2 * stageIndex
      end
    end
    if stageIndex == #config.stages then
      crop.ready = true
      local sockets = ensureSockets(entity)
      local socketDefs = config.stages[stageIndex].sockets or {}
      for _, socketName in ipairs(socketDefs) do
        if not sockets.attachments[socketName] then
          local fruitEntity = config.spawnFruit(app, entity, socketName)
          if fruitEntity then
            SocketsComponent.attach(sockets, socketName, fruitEntity)
          end
        end
      end
    else
      crop.ready = false
      local sockets = ecs:getComponent(entity, 'sockets')
      if sockets then
        for socketName, fruitEntity in pairs(sockets.attachments) do
          ecs:destroyEntity(fruitEntity)
          sockets.attachments[socketName] = nil
        end
      end
    end
  end

  function system:init()
    query = ecs:getQuery({ 'crop', 'transform', 'renderable' })
  end

  function system:update(dt)
    local list = query.list
    for i = 1, #list do
      local entity = list[i]
      local crop = ecs:getComponent(entity, 'crop')
      local config = cropsDb[crop.id]
      if config then
        local hydrationFactor = crop.stats.hydration or 1
        local fertilizerFactor = 1 + (crop.stats.fertilizer or 0) * 0.3
        crop.progress = crop.progress + dt * (crop.stats.growth or 1) * hydrationFactor * fertilizerFactor
        local stage = config.stages[crop.stage]
        if stage and crop.progress >= stage.time then
          local nextStage = math.min(#config.stages, crop.stage + 1)
          applyStage(entity, crop, config, nextStage)
        end
      end
    end
  end

  return system
end
