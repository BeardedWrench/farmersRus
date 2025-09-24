local Theme = require 'ui.theme'
local Element = require 'ui.core.element'
local Util = require 'ui.core.util'

local Label = setmetatable({}, { __index = Element })
Label.__index = Label

local function normaliseLines(text)
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

function Label.new(manager)
  local self = Element.new(manager)
  setmetatable(self, Label)
  self.text = ''
  self.lines = { '' }
  self.scale = 0.55
  self.spacing = 4
  self.align = 'left'
  self.color = Util.cloneColor(Theme.palette.text)
  return self
end

function Label:setText(text)
  self.text = text
  self.lines = normaliseLines(text)
  return self
end

function Label:setLines(lines)
  self.lines = normaliseLines(lines)
  return self
end

function Label:setScale(scale)
  if scale then
    self.scale = scale
  end
  return self
end

function Label:setSpacing(spacing)
  if spacing then
    self.spacing = spacing
  end
  return self
end

function Label:setAlign(mode)
  self.align = mode or 'left'
  return self
end

function Label:setColor(color)
  self.color = Util.cloneColor(color or Theme.palette.text)
  return self
end

local function lineHeight(font, scale)
  return font:getHeight() * scale * 1.1
end

function Label:getBounds()
  local font = self.manager and self.manager.font
  if not font then
    return self.size.w, self.size.h
  end
  local width, height = Util.measureBlock(font, self.lines, self.scale, self.spacing)
  if self.size.w > 0 then
    width = self.size.w
  end
  if self.size.h > 0 then
    height = self.size.h
  end
  return width, height
end

function Label:draw(pass, originX, originY)
  if not self.visible then
    return
  end
  local font = self.manager and self.manager.font
  if not font then
    return
  end

  local x = originX
  local y = originY
  local areaWidth = self.size.w > 0 and self.size.w or nil
  local lh = lineHeight(font, self.scale)

  pass:setColor(self.color[1], self.color[2], self.color[3], self.color[4] or 1)

  for i = 1, #self.lines do
    local line = self.lines[i]
    local width = font:getWidth(line) * self.scale
    local drawX = x
    if self.align == 'center' and areaWidth then
      drawX = x + (areaWidth - width) * 0.5
    elseif self.align == 'right' and areaWidth then
      drawX = x + areaWidth - width
    end
    local centerX = drawX + width * 0.5
    local centerY = y + lh * 0.5
    pass:text(line, centerX, centerY, 0, self.scale)
    if i < #self.lines then
      y = y + lh + self.spacing
    end
  end

  pass:setColor(1, 1, 1, 1)
end

return Label
