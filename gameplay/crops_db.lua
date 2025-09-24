local Corn = require 'entities.corn.corn'
local Wheat = require 'entities.wheat.wheat'

return {
  corn = {
    id = Corn.config.id,
    stages = Corn.config.stages,
    fruit = Corn.config.fruit,
    spawn = function(app, x, y)
      return Corn.spawn(app, x, y)
    end,
    spawnFruit = function(app, parent, socketName)
      return Corn.spawnFruit(app, parent, socketName)
    end,
    applyStage = function(app, entity, stage)
      Corn.applyStage(app, entity, stage)
    end
  },
  wheat = {
    id = Wheat.config.id,
    stages = Wheat.config.stages,
    fruit = Wheat.config.fruit,
    spawn = function(app, x, y)
      return Wheat.spawn(app, x, y)
    end,
    spawnFruit = function(app, parent, socketName)
      return Wheat.spawnFruit(app, parent, socketName)
    end,
    applyStage = function(app, entity, stage)
      Wheat.applyStage(app, entity, stage)
    end
  }
}
