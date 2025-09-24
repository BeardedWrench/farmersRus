local Element = require 'ui.core.element'
local Theme = require 'ui.theme'
local Util = require 'ui.core.util'

local Panel = setmetatable({}, { __index = Element })
Panel.__index = Panel

local DEFAULT_COLOR = Theme.palette.panel
local DEFAULT_OUTLINE = Theme.palette.outline

local function explicitSize(props)
  return props.width or props.w, props.height or props.h
end

local function resolveAutoFlag(explicit, override, autoSizeOpt)
  if autoSizeOpt == false then
    return false
  end
  if override ~= nil then
    return override
  end
  return explicit == nil
end

local function initOutline(style, outline)
  if outline == false then
    return
  end
  local color = outline and outline.color or DEFAULT_OUTLINE
  local thickness = outline and outline.thickness or 1
  style.outline = {
    color = Util.cloneColor(color),
    thickness = thickness
  }
end

function Panel.new(manager, props)
  props = props or {}
  local self = Element.new(manager, props)
  setmetatable(self, Panel)

  local explicitW, explicitH = explicitSize(props)

  self.minWidth = props.minWidth or 0
  self.minHeight = props.minHeight or 0
  self.autoWidth = resolveAutoFlag(explicitW, props.autoWidth, props.autoSize)
  self.autoHeight = resolveAutoFlag(explicitH, props.autoHeight, props.autoSize)

  self.size.w = explicitW or math.max(self.size.w or 0, self.minWidth)
  self.size.h = explicitH or math.max(self.size.h or 0, self.minHeight)

  self.style.color = Util.cloneColor(props.color or DEFAULT_COLOR)
  initOutline(self.style, props.outline)
  self.rounding = props.rounding or 0

  if self.autoWidth or self.autoHeight then
    self:updateAutoSize()
  end

  return self
end

function Panel:measureChildren()
  local maxRight, maxBottom = 0, 0
  for i = 1, #self.children do
    local child = self.children[i]
    local childW, childH = child:getBounds()
    local right = child.position.x + (childW or 0)
    local bottom = child.position.y + (childH or 0)
    if right > maxRight then
      maxRight = right
    end
    if bottom > maxBottom then
      maxBottom = bottom
    end
  end
  return maxRight, maxBottom
end

function Panel:updateAutoSize()
  if not self.autoWidth and not self.autoHeight then
    return
  end
  local contentW, contentH = self:measureChildren()
  if self.autoWidth then
    self.size.w = math.max(self.minWidth, contentW + self.padding.left + self.padding.right)
  end
  if self.autoHeight then
    self.size.h = math.max(self.minHeight, contentH + self.padding.top + self.padding.bottom)
  end
end

function Panel:getBounds()
  return self.size.w, self.size.h
end

function Panel:getRenderColor()
  if self.renderColor then
    return self.renderColor
  end
  return self.style.color or DEFAULT_COLOR
end

function Panel:setRenderColor(color)
  self.renderColor = color and Util.cloneColor(color) or nil
end

local function drawOutline(pass, x, y, w, h, outline)
  pass:setColor(outline.color[1], outline.color[2], outline.color[3], outline.color[4] or 1)
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
    drawOutline(pass, x, y, w, h, self.style.outline)
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

local function requireLabel()
  return require 'ui/elements/label'
end

local function requireButton()
  return require 'ui/elements/button'
end

local function requireSlotGrid()
  return require 'ui/elements/slotgrid'
end

function Panel:panel(props)
  return self:add(Panel.new(self.manager, props))
end

function Panel:label(props)
  local Label = requireLabel()
  return self:add(Label.new(self.manager, props))
end

function Panel:button(props)
  local Button = requireButton()
  return self:add(Button.new(self.manager, props))
end

function Panel:slotGrid(props)
  local SlotGrid = requireSlotGrid()
  return self:add(SlotGrid.new(self.manager, props))
end

return Panel
