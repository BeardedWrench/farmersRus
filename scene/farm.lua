local Transform = require 'components.transform'
local Renderable = require 'components.renderable'
local SoilDomain = require 'entities.soil.soil'
local SceneCommon = require 'scene.common'
local Fence = require 'entities.fence.fence'
local CompostBin = require 'entities.compost_bin.compost_bin'

local FarmScene = {}
FarmScene.__index = FarmScene

local FARM_CONSTANTS = {
  ground = SceneCommon.GROUND_DEFAULTS,
  soilRows = { 0, 2 },
  soilColumnMin = -4,
  soilColumnMax = 4
}

local function restoreFarm(self, data)
  if data.soil then
    for _, entry in ipairs(data.soil) do
      local soilEntity = SoilDomain.ensure(self.app, entry.x, entry.y)
      local soil = self.app.ecs:getComponent(soilEntity, 'soil')
      soil.tilled = entry.tilled
      soil.wetness = entry.wetness or 0
    end
  end
  if data.crops then
    for _, entry in ipairs(data.crops) do
      local cropDef = self.app.gameplay.crops[entry.id]
      if cropDef then
        local entity = cropDef.spawn(self.app, entry.x, entry.y)
        cropDef.applyStage(self.app, entity, entry.stage or 1)
        local crop = self.app.ecs:getComponent(entity, 'crop')
        if crop then
          crop.progress = entry.progress or 0
          crop.ready = (entry.stage or 1) >= #cropDef.stages
        end
        if (entry.stage or 1) >= #cropDef.stages then
          local sockets = self.app.ecs:getComponent(entity, 'sockets')
          local stage = cropDef.stages[#cropDef.stages]
          if sockets and stage and stage.sockets then
            for _, socketName in ipairs(stage.sockets) do
              local fruit = cropDef.spawnFruit(self.app, entity, socketName)
              if fruit then
                sockets.attachments[socketName] = fruit
              end
            end
          end
        end
      end
    end
  end
end

function FarmScene:enter()
  Fence.spawnPerimeter(self.app, -7, 7, -7, 7)
  CompostBin.spawn(self.app, -7, -5)

  SceneCommon.spawnGround(self.app, FARM_CONSTANTS.ground)

  for _, row in ipairs(FARM_CONSTANTS.soilRows) do
    for gx = FARM_CONSTANTS.soilColumnMin, FARM_CONSTANTS.soilColumnMax do
      SoilDomain.ensure(self.app, gx, row)
    end
  end
  local farmData = self.app.saveSystem and self.app.saveSystem:consumeFarm()
  if farmData then
    restoreFarm(self, farmData)
  end

  if self.app.camera then
    local target = self.app.camera.target
    target[1], target[2], target[3] = 0, 0.5, 0
  end
end

function FarmScene:update(dt)
end

function FarmScene:draw(pass)
end

return setmetatable({}, FarmScene)
