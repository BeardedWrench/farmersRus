local Shovel = require 'entities.tools.shovel'
local Watering = require 'entities.tools.watering_can'
local Harvest = require 'entities.tools.harvest_tool'
local SeedBag = require 'entities.tools.seed_bag'

return {
  [Shovel.id] = Shovel,
  [Watering.id] = Watering,
  [Harvest.id] = Harvest,
  [SeedBag.id] = SeedBag
}
