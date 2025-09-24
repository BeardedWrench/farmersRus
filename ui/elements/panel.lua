local Element = require 'ui.core.element'
local Theme = require 'ui.theme'
local Util = require 'ui.core.util'
local Stack = require 'ui/elements/stack'
local Anchor = require 'ui.core.anchor'

local Panel = setmetatable({}, { __index = Element })
Panel.__index = Panel

local DEFAULT_COLOR = Theme.palette.panel
local DEFAULT_OUTLINE = Theme.palette.outline

local function explicitSize(props)
  return props.width or props.w, props.height or props.h
end

local function resolveTitle(title)
  if not title then
    return nil
  end
  if type(title) == 'string' then
    return { text = title }
  end
  return title
end

function Panel.new(manager, props)
  props = props or {}
  local self = Element.new(manager, props)
  setmetatable(self, Panel)

  local explicitW, explicitH = explicitSize(props)

  self.minWidth = props.minWidth or 0
  self.minHeight = props.minHeight or 0
  self.autoWidth = (props.autoWidth ~= false) and (props.autoSize ~= false) and (explicitW == nil)
  self.autoHeight = (props.autoHeight ~= false) and (props.autoSize ~= false) and (explicitH == nil)

  self.size.w = explicitW or math.max(self.size.w or 0, self.minWidth)
  self.size.h = explicitH or math.max(self.size.h or 0, self.minHeight)

  self.style.color = Util.cloneColor(props.color or DEFAULT_COLOR)
  if props.outline ~= false then
    self.style.outline = {
      color = Util.cloneColor((props.outline and props.outline.color) or DEFAULT_OUTLINE),
      thickness = (props.outline and props.outline.thickness) or 1
    }
  end

  self.titleSpacing = props.titleSpacing or 12
  self.titleOffsetX = 0
  self.titleOffsetY = 0
  self.headerAnchor = Anchor.resolve('top_center')
  self.headerElement = nil

  self.content = Stack.new(manager, {
    direction = props.direction or 'vertical',
    spacing = props.contentSpacing or 12,
    anchor = 'top_left'
  })
  Element.add(self, self.content)

  local title = resolveTitle(props.title)
  if title then
    self:setTitle(title)
  end

  if self.autoWidth or self.autoHeight then
    self:updateAutoSize()
  end

  return self
end

function Panel:setTitle(options)
  local settings = resolveTitle(options)
  if not settings then
    self.headerElement = nil
    return
  end

  local Label = require 'ui/elements/label'
  local props = {
    text = settings.text,
    scale = settings.scale or 0.68,
    color = settings.color or Theme.palette.text,
    anchor = settings.anchor or 'top_center',
    x = settings.x or 0,
    y = settings.y or 0
  }
  self.titleSpacing = settings.spacing or self.titleSpacing
  self.titleOffsetX = settings.offsetX or 0
  self.titleOffsetY = settings.offsetY or 0
  self.headerAnchor = Anchor.resolve(props.anchor)

  self.headerElement = Label.new(self.manager, props)
  if self.autoWidth or self.autoHeight then
    self:updateAutoSize()
  end
end

local function stackHelpers(stack)
  local helper = {}

  function helper:label(props)
    return stack:label(props)
  end

  function helper:button(props)
    return stack:button(props)
  end

  function helper:slotGrid(props)
    return stack:slotGrid(props)
  end

  function helper:stack(props)
    return stack:stack(props)
  end

  return helper
end

function Panel:contentArea()
  local innerW, innerH = self:getContentSize()
  local headerSpace = 0
  if self.headerElement then
    local _, titleHeight = self.headerElement:getBounds()
    headerSpace = titleHeight + self.titleSpacing
  end
  return innerW, math.max(0, innerH - headerSpace), headerSpace
end

function Panel:measureContent()
  local bodyW, bodyH = self.content:getBounds()
  local titleW, titleH = 0, 0
  if self.headerElement then
    titleW, titleH = self.headerElement:getBounds()
    titleH = titleH + self.titleSpacing
  end
  local width = math.max(bodyW, titleW)
  local height = bodyH + titleH
  return width, height
end

function Panel:updateAutoSize()
  local contentW, contentH = self:measureContent()
  if self.autoWidth then
    self.size.w = math.max(self.minWidth, contentW + self.padding.left + self.padding.right)
  end
  if self.autoHeight then
    self.size.h = math.max(self.minHeight, contentH + self.padding.top + self.padding.bottom)
  end
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

  local color = self.style.color or DEFAULT_COLOR
  pass:setColor(color[1], color[2], color[3], color[4] or 1)
  pass:plane(cx, cy, 0, w, h)

  if self.style.outline then
    drawOutline(pass, x, y, w, h, self.style.outline)
    pass:setColor(1, 1, 1, 1)
  end

  local innerW, innerH = self:contentArea()
  local contentX = x + self.padding.left
  local contentY = y + self.padding.top

  if self.headerElement then
    local headerW, headerH = self.headerElement:getBounds()
    local offsetX = (innerW - headerW) * (self.headerAnchor.x or 0)
    local headerX = contentX + offsetX + self.titleOffsetX
    local headerY = contentY + self.titleOffsetY
    self.headerElement:draw(pass, headerX, headerY)
    contentY = contentY + headerH + self.titleSpacing
    innerH = math.max(0, innerH - (headerH + self.titleSpacing))
  end

  if #self.content.children > 0 then
    self.content.size.w = innerW
    self.content.size.h = innerH
    self.content:draw(pass, contentX, contentY)
  end
end

function Panel:add(child)
  return self.content:add(child)
end

function Panel:label(props)
  return self.content:label(props)
end

function Panel:button(props)
  return self.content:button(props)
end

function Panel:slotGrid(props)
  return self.content:slotGrid(props)
end

function Panel:stack(props)
  return self.content:stack(props)
end

function Panel:content()
  return stackHelpers(self.content)
end

return Panel
