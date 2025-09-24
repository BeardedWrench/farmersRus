local Theme = require 'ui.theme'
local Panel = require 'ui/elements/panel'
local Label = require 'ui/elements/label'
local Stack = require 'ui/elements/stack'
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
  return self
end

function UIManager:createPanel()
  return Panel.new(self)
end

function UIManager:createLabel()
  return Label.new(self)
end

function UIManager:createStack()
  return Stack.new(self)
end

function UIManager:createSlotGrid()
  return SlotGrid.new(self)
end

function UIManager:add(element)
  if not element then
    return nil
  end
  table.insert(self.elements, element)
  return element
end

function UIManager:begin(width, height)
  self.elements = {}
  self.width = width or self.width
  self.height = height or self.height
end

function UIManager:draw(pass)
  for i = 1, #self.elements do
    local element = self.elements[i]
    element:draw(pass, 0, 0)
  end
end

return UIManager
