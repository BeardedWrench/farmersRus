local Theme = require 'ui.theme'
local Element = require 'ui.core.element'
local Util = require 'ui.core.util'

local Label = setmetatable({}, { __index = Element })
Label.__index = Label

local function normalizeLines(text)
  if type(text) == 'table' then
    return text
  end
  local lines = {}
  for line in tostring(text or ''):gmatch('[^\n]+') do
    lines[#lines + 1] = line
  end
  if #lines == 0 then
    lines[1] = ''
  end
  return lines
end

function Label.new(manager, props)
  props = props or {}
  local self = Element.new(manager, props)
  setmetatable(self, Label)
  self.lines = normalizeLines(props.text or '')
  self.scale = props.scale or 0.55
  self.align = props.align or 'left'
  self.wrap = props.wrap
  self.spacing = props.spacing or 4
  self.color = Util.cloneColor(props.color or Theme.palette.text)
  return self
end

local function computeLineHeight(font, scale)
  return font:getHeight() * scale * 1.1
end

function Label:setText(text)
  self.lines = normalizeLines(text)
end

function Label:getHeight()
  local font = self.manager.font
  if not font then
    return 0
  end
  local lineHeight = computeLineHeight(font, self.scale)
  local count = #self.lines
  if count == 0 then
    return 0
  end
  return lineHeight * count + self.spacing * math.max(0, count - 1)
end

function Label:getBounds()
  local font = self.manager.font
  if not font then
    return self.size.w, self.size.h
  end
  local width, height = Util.measureBlock(font, self.lines, self.scale, self.spacing)
  if self.size.w and self.size.w > 0 then
    width = self.size.w
  end
  if self.size.h and self.size.h > 0 then
    height = self.size.h
  end
  return width, height
end

function Label:draw(pass, originX, originY)
  if not self.visible then
    return
  end
  local font = self.manager.font
  if not font then
    return
  end
  local baseX, baseY = self:getAbsolutePosition(originX, originY)
  local areaWidth = self.size.w > 0 and self.size.w or nil
  local y = baseY
  local lineHeight = computeLineHeight(font, self.scale)
  pass:setColor(self.color[1], self.color[2], self.color[3], self.color[4] or 1)

  for i = 1, #self.lines do
    local line = self.lines[i]
    local width = font:getWidth(line) * self.scale
    local drawX = baseX
    if self.align == 'center' and areaWidth then
      drawX = baseX + (areaWidth - width) * 0.5
    elseif self.align == 'right' and areaWidth then
      drawX = baseX + areaWidth - width
    end
    local centerX = drawX + width * 0.5
    local centerY = y + lineHeight * 0.5
    pass:text(line, centerX, centerY, 0, self.scale)
    if i < #self.lines then
      y = y + lineHeight + self.spacing
    end
  end
  pass:setColor(1, 1, 1, 1)
end

return Label
