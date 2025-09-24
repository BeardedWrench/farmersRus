local Transform = require 'components.transform'
local Renderable = require 'components.renderable'
local ShopComponent = require 'components.shop'

local ToolShop = {}

function ToolShop.spawn(app, position)
  local ecs = app.ecs
  local entity = ecs:createEntity()
  ecs:addComponent(entity, 'transform', Transform.create({
    position = position or { 10, 0, -2 },
    scale = { 2, 2, 2 }
  }))
  ecs:addComponent(entity, 'renderable', Renderable.create({
    primitive = 'prop',
    tint = { 0.6, 0.6, 0.9, 1 }
  }))
  ecs:addComponent(entity, 'shop', ShopComponent.create({
    id = 'tool_shop',
    stock = app.gameplay.shops.tool_shop.items,
    category = 'tools'
  }))
  return entity
end

return ToolShop
