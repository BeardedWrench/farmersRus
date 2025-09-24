local Element = require 'ui.core.element'
local Anchor = require 'ui.core.anchor'

local Stack = setmetatable({}, { __index = Element })
Stack.__index = Stack

function Stack.new(manager)
  local self = Element.new(manager)
  setmetatable(self, Stack)
  self.direction = 'vertical'
  self.spacing = 8
  self.align = 'start'    -- cross axis ('start','center','end','stretch')
  self.justify = 'start'  -- main axis ('start','center','end','space_between','space_around','space_evenly')
  return self
end

function Stack:setDirection(direction)
  if direction == 'horizontal' or direction == 'vertical' then
    self.direction = direction
  end
  return self
end

function Stack:setSpacing(spacing)
  if spacing then
    self.spacing = spacing
  end
  return self
end

function Stack:setAlign(mode)
  self.align = mode or 'start'
  return self
end

function Stack:setJustify(mode)
  self.justify = mode or 'start'
  return self
end

local function childSize(child)
  local w, h = child:getBounds()
  return w or 0, h or 0
end

function Stack:getBounds()
  if #self.children == 0 then
    return Element.getBounds(self)
  end
  local width, height = 0, 0
  if self.direction == 'vertical' then
    for i = 1, #self.children do
      local child = self.children[i]
      local w, h = childSize(child)
      if w > width then
        width = w
      end
      height = height + h
    end
    if #self.children > 1 then
      height = height + self.spacing * (#self.children - 1)
    end
  else
    for i = 1, #self.children do
      local child = self.children[i]
      local w, h = childSize(child)
      width = width + w
      if h > height then
        height = h
      end
    end
    if #self.children > 1 then
      width = width + self.spacing * (#self.children - 1)
    end
  end
  return math.max(width, self.minSize.w), math.max(height, self.minSize.h)
end

local function distributeSpacing(mode, spacing, free, count)
  if count <= 1 or free <= 0 then
    return spacing, 0
  end
  if mode == 'space_between' then
    return spacing + free / (count - 1), 0
  elseif mode == 'space_around' then
    local extra = free / count
    return spacing + extra, extra * 0.5
  elseif mode == 'space_evenly' then
    local extra = free / (count + 1)
    return spacing + extra, extra
  end
  return spacing, 0
end

local function justifyOffset(mode, free)
  if free <= 0 then
    return 0
  end
  if mode == 'center' then
    return free * 0.5
  elseif mode == 'end' then
    return free
  end
  return 0
end

local function alignOffset(mode, available, size)
  if available <= size then
    return 0, size
  end
  if mode == 'center' then
    return (available - size) * 0.5, size
  elseif mode == 'end' then
    return available - size, size
  elseif mode == 'stretch' then
    return 0, available
  end
  return 0, size
end

function Stack:draw(pass, originX, originY)
  if not self.visible then
    return
  end

  local width, height = self:getBounds()
  local anchor = self.anchor or Anchor.resolve('top_left')
  local x = originX + self.position.x - (anchor.x or 0) * width
  local y = originY + self.position.y - (anchor.y or 0) * height

  if self.direction == 'vertical' then
    local childHeights, childWidths = {}, {}
    local totalHeight = 0
    for i = 1, #self.children do
      local w, h = childSize(self.children[i])
      childWidths[i] = w
      childHeights[i] = h
      totalHeight = totalHeight + h
    end
    if #self.children > 1 then
      totalHeight = totalHeight + self.spacing * (#self.children - 1)
    end
    local spacing = self.spacing
    local startGap = 0
    local freeSpace = height - totalHeight
    if freeSpace < 0 then
      freeSpace = 0
    end
    if freeSpace > 0 then
      spacing, startGap = distributeSpacing(self.justify, spacing, freeSpace, #self.children)
    end
    local cursorY = y + justifyOffset(self.justify, freeSpace) + startGap
    for i = 1, #self.children do
      local child = self.children[i]
      local childW = childWidths[i]
      local childH = childHeights[i]
      local alignShift, stretched = alignOffset(self.align, width, childW)
      local drawWidth = stretched or childW
      if stretched and self.align == 'stretch' and child.setSize then
        child:setSize(drawWidth, childH)
      end
      local childX = x + alignShift + child.position.x
      local childY = cursorY + child.position.y
      local childAnchor = child.anchor or Anchor.resolve('top_left')
      local drawX = childX - (childAnchor.x or 0) * childW
      local drawY = childY - (childAnchor.y or 0) * childH
      child:draw(pass, drawX, drawY)
      cursorY = childY + childH + spacing
    end
  else
    local childHeights, childWidths = {}, {}
    local totalWidth = 0
    for i = 1, #self.children do
      local w, h = childSize(self.children[i])
      childWidths[i] = w
      childHeights[i] = h
      totalWidth = totalWidth + w
    end
    if #self.children > 1 then
      totalWidth = totalWidth + self.spacing * (#self.children - 1)
    end
    local spacing = self.spacing
    local startGap = 0
    local freeSpace = width - totalWidth
    if freeSpace < 0 then
      freeSpace = 0
    end
    if freeSpace > 0 then
      spacing, startGap = distributeSpacing(self.justify, spacing, freeSpace, #self.children)
    end
    local cursorX = x + justifyOffset(self.justify, freeSpace) + startGap
    for i = 1, #self.children do
      local child = self.children[i]
      local childW = childWidths[i]
      local childH = childHeights[i]
      local alignShift, stretched = alignOffset(self.align, height, childH)
      local drawHeight = stretched or childH
      if stretched and self.align == 'stretch' and child.setSize then
        child:setSize(childW, drawHeight)
      end
      local childX = cursorX + child.position.x
      local childY = y + alignShift + child.position.y
      local childAnchor = child.anchor or Anchor.resolve('top_left')
      local drawX = childX - (childAnchor.x or 0) * childW
      local drawY = childY - (childAnchor.y or 0) * childH
      child:draw(pass, drawX, drawY)
      cursorX = childX + childW + spacing
    end
  end
end

return Stack
