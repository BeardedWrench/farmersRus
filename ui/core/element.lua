local Util = require 'ui.core.util'
local Anchor = require 'ui.core.anchor'

local Element = {}
Element.__index = Element

function Element.new(manager, props)
  props = props or {}
  local element = {
    manager = manager,
    id = props.id,
    position = {
      x = props.x or 0,
      y = props.y or 0
    },
    size = {
      w = props.w or props.width or 0,
      h = props.h or props.height or 0
    },
    padding = Util.normalizePadding(props.padding),
    visible = props.visible ~= false,
    style = props.style or {},
    children = {},
    parent = nil,
    anchor = Anchor.resolve(props.anchor or 'top_left')
  }
  return setmetatable(element, Element)
end

function Element:add(child)
  child.parent = self
  table.insert(self.children, child)
  return child
end

function Element:eachChild(callback)
  for i = 1, #self.children do
    callback(self.children[i])
  end
end

function Element:getAbsolutePosition(originX, originY)
  local x = (originX or 0) + self.position.x
  local y = (originY or 0) + self.position.y
  return x, y
end

function Element:getContentOrigin(originX, originY)
  local x, y = self:getAbsolutePosition(originX, originY)
  return x + self.padding.left, y + self.padding.top
end

function Element:getContentSize()
  local w = self.size.w - (self.padding.left + self.padding.right)
  local h = self.size.h - (self.padding.top + self.padding.bottom)
  return math.max(0, w), math.max(0, h)
end

function Element:getBounds()
  return self.size.w, self.size.h
end

function Element:anchorOffset(areaW, areaH, boundsW, boundsH)
  local anchor = self.anchor
  local offsetX = (areaW - boundsW) * (anchor.x or 0)
  local offsetY = (areaH - boundsH) * (anchor.y or 0)
  return offsetX, offsetY
end

function Element:draw(pass, originX, originY)
  if not self.visible then
    return
  end
  for i = 1, #self.children do
    self.children[i]:draw(pass, originX, originY)
  end
end

return Element
