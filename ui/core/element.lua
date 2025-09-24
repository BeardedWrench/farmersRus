local Anchor = require 'ui.core.anchor'

local Element = {}
Element.__index = Element

local function normalizePadding(value)
  if not value then
    return { top = 0, right = 0, bottom = 0, left = 0 }
  end
  if type(value) == 'number' then
    return { top = value, right = value, bottom = value, left = value }
  end
  return {
    top = value.top or value[1] or 0,
    right = value.right or value[2] or value.x or 0,
    bottom = value.bottom or value[3] or value.y or value[2] or 0,
    left = value.left or value[4] or value.x or value[1] or 0
  }
end

function Element.new(manager)
  local self = setmetatable({}, Element)
  self.manager = manager
  self.parent = nil
  self.children = {}
  self.visible = true
  self.position = { x = 0, y = 0 }
  self.size = { w = 0, h = 0 }
  self.minSize = { w = 0, h = 0 }
  self.anchor = Anchor.resolve('top_left')
  self.padding = normalizePadding(0)
  return self
end

function Element:setPosition(x, y)
  if x then self.position.x = x end
  if y then self.position.y = y end
  return self
end

function Element:setSize(w, h)
  if w then self.size.w = w end
  if h then self.size.h = h end
  return self
end

function Element:setMinSize(w, h)
  if w then self.minSize.w = w end
  if h then self.minSize.h = h end
  return self
end

function Element:setPadding(padding)
  self.padding = normalizePadding(padding)
  return self
end

function Element:setAnchor(anchor)
  self.anchor = Anchor.resolve(anchor)
  return self
end

function Element:setVisible(visible)
  self.visible = visible ~= false
  return self
end

function Element:addChild(child)
  if not child then
    return nil
  end
  child.parent = self
  table.insert(self.children, child)
  return child
end

function Element:getBounds()
  local width = math.max(self.size.w, self.minSize.w)
  local height = math.max(self.size.h, self.minSize.h)
  return width, height
end

function Element:draw(pass, originX, originY)
  if not self.visible then
    return
  end
  for i = 1, #self.children do
    local child = self.children[i]
    if child.visible then
      local childW, childH = child:getBounds()
      local anchor = child.anchor or Anchor.resolve('top_left')
      local drawX = originX + child.position.x - (anchor.x or 0) * childW
      local drawY = originY + child.position.y - (anchor.y or 0) * childH
      child:draw(pass, drawX, drawY)
    end
  end
end

return Element
