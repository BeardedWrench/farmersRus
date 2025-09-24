local SeedShop = require 'entities.shops.seed_shop'
local ToolShop = require 'entities.shops.tool_shop'
local SellStand = require 'entities.shops.sell_stand'
local Bench = require 'entities.props_town.bench'
local Crate = require 'entities.props_town.crate'
local Lamp = require 'entities.props_town.lamp'
local Planter = require 'entities.props_town.planter'
local NPC = require 'entities.props_town.npc_dummy'

local TownScene = {}
TownScene.__index = TownScene

local function ensureSpawn(self)
  self.app.state = self.app.state or {}
  if self.app.state.townSpawned then
    return
  end
  self.app.state.townSpawned = true
  SeedShop.spawn(self.app, { 12, 0, -6 })
  ToolShop.spawn(self.app, { 14, 0, -4 })
  SellStand.spawn(self.app, { 10, 0, -8 })
  Bench.spawn(self.app, { 11, 0, -3 })
  Crate.spawn(self.app, { 13, 0, -5 })
  Lamp.spawn(self.app, { 9, 0, -4 })
  Planter.spawn(self.app, { 12, 0, -2 })
  NPC.spawn(self.app, { 10, 0, -3 })
end

function TownScene:enter()
  ensureSpawn(self)
  if self.app.camera then
    local target = self.app.camera.target
    target[1], target[2], target[3] = 12, 0.5, -5
  end
end

function TownScene:update(dt)
end

function TownScene:draw(pass)
end

return setmetatable({}, TownScene)
