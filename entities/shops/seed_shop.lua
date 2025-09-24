local Transform = require 'components.transform'
local Renderable = require 'components.renderable'
local ShopComponent = require 'components.shop'

local SeedShop = {}

function SeedShop.spawn(app, position)
  local ecs = app.ecs
  local entity = ecs:createEntity()
  ecs:addComponent(entity, 'transform', Transform.create({
    position = position or { 8, 0, -4 },
    scale = { 2, 2, 2 }
  }))
  ecs:addComponent(entity, 'renderable', Renderable.create({
    primitive = 'prop',
    tint = { 0.5, 0.8, 0.5, 1 }
  }))
  ecs:addComponent(entity, 'shop', ShopComponent.create({
    id = 'seed_shop',
    stock = app.gameplay.shops.seed_shop.items,
    category = 'seeds'
  }))
  return entity
end

return SeedShop
