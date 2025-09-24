local Transform = require 'components.transform'
local Renderable = require 'components.renderable'
local ShopComponent = require 'components.shop'

local SellStand = {}

function SellStand.spawn(app, position)
  local ecs = app.ecs
  local entity = ecs:createEntity()
  ecs:addComponent(entity, 'transform', Transform.create({
    position = position or { 6, 0, -6 },
    scale = { 1.5, 1.5, 1.5 }
  }))
  ecs:addComponent(entity, 'renderable', Renderable.create({
    primitive = 'prop',
    tint = { 0.9, 0.7, 0.4, 1 }
  }))
  ecs:addComponent(entity, 'shop', ShopComponent.create({
    id = 'sell_stand',
    stock = app.gameplay.shops.sell_stand.buys,
    category = 'sell'
  }))
  return entity
end

return SellStand
