local Element = require 'ui.core.element'
local Theme = require 'ui.theme'
local Util = require 'ui.core.util'

local Panel = setmetatable({}, { __index = Element })
Panel.__index = Panel

local DEFAULT_COLOR = Theme.palette.panel
local DEFAULT_OUTLINE = Theme.palette.outline

function Panel.new(manager, props)
  props = props or {}
  local self = Element.new(manager, props)
  setmetatable(self, Panel)
  local explicitWidth = props.width or props.w
  local explicitHeight = props.height or props.h
  self.minWidth = props.minWidth or 0
  self.minHeight = props.minHeight or 0
  local autoWidthFlag = props.autoWidth
  local autoHeightFlag = props.autoHeight
  self.autoWidth = (props.autoSize ~= false) and (autoWidthFlag ~= false)
  if autoWidthFlag == nil then
    self.autoWidth = self.autoWidth and (explicitWidth == nil)
  else
    self.autoWidth = self.autoWidth and autoWidthFlag
  end
  self.autoHeight = (props.autoSize ~= false) and (autoHeightFlag ~= false)
  if autoHeightFlag == nil then
    self.autoHeight = self.autoHeight and (explicitHeight == nil)
  else
    self.autoHeight = self.autoHeight and autoHeightFlag
  end
  if explicitWidth then
    self.size.w = explicitWidth
  elseif self.autoWidth then
    self.size.w = math.max(self.size.w or 0, self.minWidth)
  end
  if explicitHeight then
    self.size.h = explicitHeight
  elseif self.autoHeight then
    self.size.h = math.max(self.size.h or 0, self.minHeight)
  end
  self.style.color = Util.cloneColor(props.color or DEFAULT_COLOR)
  if props.outline then
    self.style.outline = {
      color = Util.cloneColor(props.outline.color or DEFAULT_OUTLINE),
      thickness = props.outline.thickness or 1
    }
  elseif props.outline == false then
    self.style.outline = nil
  end
  self.rounding = props.rounding or 0
  return self
end

function Panel:updateAutoSize()
  if not self.autoWidth and not self.autoHeight then
    return
  end
  local maxWidth, maxHeight = 0, 0
  for i = 1, #self.children do
    local child = self.children[i]
    local childWidth, childHeight = child:getBounds()
    local right = child.position.x + (childWidth or 0)
    local bottom = child.position.y + (childHeight or 0)
    if right > maxWidth then
      maxWidth = right
    end
    if bottom > maxHeight then
      maxHeight = bottom
    end
  end
  if self.autoWidth then
    local padded = maxWidth + self.padding.left + self.padding.right
    self.size.w = math.max(self.minWidth, padded)
  end
  if self.autoHeight then
    local padded = maxHeight + self.padding.top + self.padding.bottom
    self.size.h = math.max(self.minHeight, padded)
  end
end

function Panel:getRenderColor()
  if self.renderColor then
    return self.renderColor
  end
  return self.style.color or DEFAULT_COLOR
end

function Panel:setRenderColor(color)
  if color then
    self.renderColor = Util.cloneColor(color)
  else
    self.renderColor = nil
  end
end

local function drawOutline(pass, x, y, w, h, color)
  pass:setColor(color[1], color[2], color[3], color[4] or 1)
  pass:line(x, y, 0, x + w, y, 0)
  pass:line(x + w, y, 0, x + w, y + h, 0)
  pass:line(x + w, y + h, 0, x, y + h, 0)
  pass:line(x, y + h, 0, x, y, 0)
end

function Panel:draw(pass, originX, originY)
  if not self.visible then
    return
  end
  self:updateAutoSize()
  local x, y = self:getAbsolutePosition(originX, originY)
  local w, h = self.size.w, self.size.h
  local cx = x + w * 0.5
  local cy = y + h * 0.5

  local color = self:getRenderColor()
  pass:setColor(color[1], color[2], color[3], color[4] or 1)
  pass:plane(cx, cy, 0, w, h)

  if self.style.outline then
    drawOutline(pass, x, y, w, h, self.style.outline.color)
    pass:setColor(1, 1, 1, 1)
  end

  local contentX, contentY = self:getContentOrigin(originX, originY)
  for i = 1, #self.children do
    self.children[i]:draw(pass, contentX, contentY)
  end

  self.renderColor = nil
end

function Panel:add(child)
  Element.add(self, child)
  self:updateAutoSize()
  return child
end

function Panel:panel(props)
  local child = Panel.new(self.manager, props)
  return self:add(child)
end

function Panel:label(props)
  local Label = require 'ui/elements/label'
  local child = Label.new(self.manager, props)
  return self:add(child)
end

function Panel:button(props)
  local Button = require 'ui/elements/button'
  local child = Button.new(self.manager, props)
  return self:add(child)
end

function Panel:slotGrid(props)
  local SlotGrid = require 'ui/elements/slotgrid'
  local child = SlotGrid.new(self.manager, props)
  return self:add(child)
end

return Panel
