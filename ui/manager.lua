local Theme = require 'ui.theme'
local Panel = require 'ui/elements/panel'
local Label = require 'ui/elements/label'
local Button = require 'ui/elements/button'
local SlotGrid = require 'ui/elements/slotgrid'

local UIManager = {}
UIManager.__index = UIManager

function UIManager.new(app)
  local self = {
    app = app,
    elements = {},
    font = nil,
    theme = Theme,
    width = 0,
    height = 0
  }
  return setmetatable(self, UIManager)
end

function UIManager:setFont(font)
  self.font = font
end

function UIManager:getFont()
  return self.font
end

function UIManager:begin(width, height)
  self.elements = {}
  self.width = width or self.width
  self.height = height or self.height
end

function UIManager:add(element)
  table.insert(self.elements, element)
  return element
end

function UIManager:panel(props)
  props = props or {}
  props.manager = self
  local panel = Panel.new(self, props)
  return self:add(panel)
end

function UIManager:label(props)
  props = props or {}
  local label = Label.new(self, props)
  return self:add(label)
end

function UIManager:button(props)
  props = props or {}
  local button = Button.new(self, props)
  return self:add(button)
end

function UIManager:slotGrid(props)
  props = props or {}
  local grid = SlotGrid.new(self, props)
  return self:add(grid)
end

function UIManager:draw(pass)
  for i = 1, #self.elements do
    self.elements[i]:draw(pass, 0, 0)
  end
end

return UIManager
