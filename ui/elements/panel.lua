local Element = require 'ui.core.element'
local Theme = require 'ui.theme'
local Label = require 'ui/elements/label'
local Anchor = require 'ui.core.anchor'

local Panel = setmetatable({}, { __index = Element })
Panel.__index = Panel

local function cloneColor(color)
  if not color then
    return nil
  end
  return { color[1], color[2], color[3], color[4] or 1 }
end

function Panel.new(manager)
  local self = Element.new(manager)
  setmetatable(self, Panel)
  self.background = cloneColor(Theme.palette.panel)
  self.outline = cloneColor(Theme.palette.outline)
  self.autoWidth = true
  self.autoHeight = true
  self.titleLabel = nil
  self.titleSpacing = 12
  self.bodySpacing = 12
  return self
end

function Panel:setBackground(color)
  self.background = cloneColor(color or Theme.palette.panel)
  return self
end

function Panel:setOutline(color, alpha)
  if color == false then
    self.outline = nil
  else
    local outline = cloneColor(color or Theme.palette.outline)
    if alpha then
      outline[4] = alpha
    end
    self.outline = outline
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
    :setText(text)
    :setScale(0.7)
    :setAnchor('top_center')
  self.titleLabel = label
  return self
end

function Panel:setTitle(label)
  self.titleLabel = label
  if self.titleLabel then
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
  local width, height = 0, 0
  for i = 1, #children do
    local child = children[i]
    local w, h = child:getBounds()
    if w > width then
      width = w
    end
    height = height + h
  end
  return width, height
end

function Panel:getContentBounds()
  local bodyW, bodyH = measureChildren(self.children)
  if #self.children > 1 then
    bodyH = bodyH + self.bodySpacing * (#self.children - 1)
  end
  local width = bodyW
  local height = bodyH
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

local function drawOutline(pass, x, y, w, h, color)
  if not color then
    return
  end
  pass:setColor(color[1], color[2], color[3], color[4] or 1)
  pass:line(x, y, 0, x + w, y, 0)
  pass:line(x + w, y, 0, x + w, y + h, 0)
  pass:line(x + w, y + h, 0, x, y + h, 0)
  pass:line(x, y + h, 0, x, y, 0)
  pass:setColor(1, 1, 1, 1)
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

  local bg = self.background or cloneColor(Theme.palette.panel)
  pass:setColor(bg[1], bg[2], bg[3], bg[4] or 1)
  pass:plane(cx, cy, 0, width, height)

  drawOutline(pass, x, y, width, height, self.outline)

  local padding = self.padding
  local contentLeft = x + padding.left
  local contentTop = y + padding.top
  local innerWidth = width - padding.left - padding.right

  local cursorY = contentTop
  if self.titleLabel then
    local titleW, titleH = self.titleLabel:getBounds()
    local drawX = contentLeft + (innerWidth - titleW) * 0.5 + self.titleLabel.position.x
    local drawY = cursorY + self.titleLabel.position.y
    self.titleLabel:draw(pass, drawX, drawY)
    cursorY = cursorY + titleH + self.titleSpacing
  end

  for index = 1, #self.children do
    local child = self.children[index]
    if child.visible then
      local childW, childH = child:getBounds()
      local anchorChild = child.anchor or Anchor.resolve('top_left')
      local drawX = contentLeft + child.position.x - (anchorChild.x or 0) * childW
      local drawY = cursorY + child.position.y - (anchorChild.y or 0) * childH
      child:draw(pass, drawX, drawY)
      if index < #self.children then
        cursorY = cursorY + childH + self.bodySpacing
      else
        cursorY = cursorY + childH
      end
    end
  end
end

return Panel
