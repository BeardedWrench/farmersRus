local Element = require 'ui.core.element'
local Theme = require 'ui.theme'
local Label = require 'ui/elements/label'
local Anchor = require 'ui.core.anchor'

local Panel = setmetatable({}, { __index = Element })
Panel.__index = Panel

local DEFAULT_COLOR = Theme.palette.panel
local DEFAULT_OUTLINE = Theme.palette.outline

local function cloneColor(color)
  if not color then
    return nil
  end
  return { color[1], color[2], color[3], color[4] or 1 }
end

function Panel.new(manager)
  local self = Element.new(manager)
  setmetatable(self, Panel)
  self.background = cloneColor(DEFAULT_COLOR)
  self.outline = cloneColor(DEFAULT_OUTLINE)
  self.autoWidth = true
  self.autoHeight = true
  self.titleLabel = nil
  self.titleSpacing = 12
  self.bodySpacing = 12
  return self
end

function Panel:setBackground(color)
  self.background = cloneColor(color or DEFAULT_COLOR)
  return self
end

function Panel:setOutline(color, alpha)
  if color == false then
    self.outline = nil
  else
    local outlineColor = color or DEFAULT_OUTLINE
    self.outline = cloneColor(outlineColor)
    if alpha then
      self.outline[4] = alpha
    end
  end
  return self
end

function Panel:setAutoSize(width, height)
  if width ~= nil then self.autoWidth = width end
  if height ~= nil then self.autoHeight = height end
  return self
end

function Panel:setTitleText(text)
  if not text or text == '' then
    self.titleLabel = nil
    return self
  end
  local label = Label.new(self.manager)
  label:setText(text)
  label:setScale(0.7)
  label:setAnchor('top_center')
  self.titleLabel = label
  return self
end

function Panel:setTitle(label)
  self.titleLabel = label
  if self.titleLabel then
    self.titleLabel.parent = self
    self.titleLabel:setAnchor('top_center')
  end
  return self
end

function Panel:setTitleSpacing(spacing)
  if spacing then
    self.titleSpacing = spacing
  end
  return self
end

function Panel:setBodySpacing(spacing)
  if spacing then
    self.bodySpacing = spacing
  end
  return self
end

local function measureChildren(children)
  local maxRight, maxBottom = 0, 0
  for i = 1, #children do
    local child = children[i]
    local w, h = child:getBounds()
    local right = child.position.x + w
    local bottom = child.position.y + h
    if right > maxRight then
      maxRight = right
    end
    if bottom > maxBottom then
      maxBottom = bottom
    end
  end
  return maxRight, maxBottom
end

function Panel:getContentBounds()
  local measuredW, measuredH = measureChildren(self.children)
  local sumHeight = 0
  local maxWidth = 0
  local count = #self.children
  for i = 1, count do
    local child = self.children[i]
    local w, h = child:getBounds()
    if w > maxWidth then
      maxWidth = w
    end
    sumHeight = sumHeight + h
  end
  if count > 1 then
    sumHeight = sumHeight + self.bodySpacing * (count - 1)
  end
  local width = math.max(measuredW, maxWidth)
  local height = math.max(measuredH, sumHeight)
  if self.titleLabel then
    local titleW, titleH = self.titleLabel:getBounds()
    height = height + titleH + self.titleSpacing
    if titleW > width then
      width = titleW
    end
  end
  return width, height
end

function Panel:getBounds()
  local contentW, contentH = self:getContentBounds()
  local padding = self.padding
  local desiredW = contentW + padding.left + padding.right
  local desiredH = contentH + padding.top + padding.bottom
  local width = self.autoWidth and math.max(desiredW, self.minSize.w) or math.max(self.size.w, self.minSize.w)
  local height = self.autoHeight and math.max(desiredH, self.minSize.h) or math.max(self.size.h, self.minSize.h)
  self.size.w = width
  self.size.h = height
  return width, height
end

function Panel:draw(pass, originX, originY)
  if not self.visible then
    return
  end

  local width, height = self:getBounds()
  local anchor = self.anchor or Anchor.resolve('top_left')
  local x = originX + self.position.x - (anchor.x or 0) * width
  local y = originY + self.position.y - (anchor.y or 0) * height
  local cx = x + width * 0.5
  local cy = y + height * 0.5

  local bg = self.background or cloneColor(DEFAULT_COLOR)
  pass:setColor(bg[1], bg[2], bg[3], bg[4] or 1)
  pass:plane(cx, cy, 0, width, height)

  if self.outline then
    pass:setColor(self.outline[1], self.outline[2], self.outline[3], self.outline[4] or 1)
    pass:line(x, y, 0, x + width, y, 0)
    pass:line(x + width, y, 0, x + width, y + height, 0)
    pass:line(x + width, y + height, 0, x, y + height, 0)
    pass:line(x, y + height, 0, x, y, 0)
    pass:setColor(1, 1, 1, 1)
  end

  local padding = self.padding
  local contentLeft = x + padding.left
  local contentTop = y + height - padding.top
  local innerWidth = width - padding.left - padding.right

  local cursorTop = contentTop
  if self.titleLabel then
    local titleW, titleH = self.titleLabel:getBounds()
    local titleX = contentLeft + (innerWidth - titleW) * 0.5 + self.titleLabel.position.x
    local titleY = cursorTop - titleH + self.titleLabel.position.y
    self.titleLabel:draw(pass, titleX, titleY)
    cursorTop = titleY - self.titleSpacing
  end

  for index = 1, #self.children do
    local child = self.children[index]
    if child.visible then
      local childW, childH = child:getBounds()
      local anchorChild = child.anchor or Anchor.resolve('top_left')
      local baseTop = cursorTop - child.position.y
      local drawX = contentLeft + child.position.x - (anchorChild.x or 0) * childW
      local drawY = baseTop - childH + (anchorChild.y or 0) * childH
      child:draw(pass, drawX, drawY)
      cursorTop = baseTop - childH - (index < #self.children and self.bodySpacing or 0)
    end
  end
end

return Panel
