local Element = require 'ui.core.element'

local Stack = setmetatable({}, { __index = Element })
Stack.__index = Stack

local function childSize(child)
  local w, h = child:getBounds()
  return w or 0, h or 0
end

local function sumHeights(children, spacing)
  local total = 0
  for i = 1, #children do
    local _, h = childSize(children[i])
    total = total + h
  end
  if #children > 1 then
    total = total + spacing * (#children - 1)
  end
  return total
end

local function sumWidths(children, spacing)
  local total = 0
  for i = 1, #children do
    local w = childSize(children[i])
    total = total + w
  end
  if #children > 1 then
    total = total + spacing * (#children - 1)
  end
  return total
end

function Stack.new(manager, props)
  props = props or {}
  local self = Element.new(manager, props)
  setmetatable(self, Stack)

  self.direction = props.direction or 'vertical'
  self.spacing = props.spacing or 8
  self.align = props.align or 'start'
  self.justify = props.justify or 'start'
  self.fill = props.fill or false

  return self
end

function Stack:getBounds()
  if #self.children == 0 then
    return self.size.w, self.size.h
  end

  if self.direction == 'vertical' then
    local width = 0
    local cursor = 0
    local maxBottom = 0
    for i = 1, #self.children do
      local child = self.children[i]
      local childW, childH = childSize(child)
      local childWidth = childW + math.max(0, child.position.x)
      if childWidth > width then
        width = childWidth
      end
      local top = cursor + (child.position.y or 0)
      local bottom = top + childH
      if bottom > maxBottom then
        maxBottom = bottom
      end
      cursor = cursor + childH + self.spacing
    end
    return width, maxBottom
  else
    local height = 0
    local cursor = 0
    local maxRight = 0
    for i = 1, #self.children do
      local child = self.children[i]
      local childW, childH = childSize(child)
      local childHeight = childH + math.max(0, child.position.y)
      if childHeight > height then
        height = childHeight
      end
      local left = cursor + (child.position.x or 0)
      local right = left + childW
      if right > maxRight then
        maxRight = right
      end
      cursor = cursor + childW + self.spacing
    end
    return maxRight, height
  end
end

local function resolveFreeSpace(total, available)
  if not available or available <= 0 then
    return 0
  end
  return math.max(0, available - total)
end

local function clampStartOffset(freeSpace)
  if freeSpace < 0 then
    return 0
  end
  return freeSpace
end

local function justifyOffset(mode, freeSpace)
  if mode == 'center' then
    return freeSpace * 0.5, nil
  elseif mode == 'end' then
    return clampStartOffset(freeSpace), nil
  end
  return 0, nil
end

local function adjustSpacing(mode, spacing, freeSpace, count)
  if count <= 1 then
    return spacing, 0
  end
  if mode == 'space_between' then
    local extra = freeSpace / (count - 1)
    return spacing + extra, 0
  elseif mode == 'space_around' then
    local extra = freeSpace / count
    return spacing + extra, extra * 0.5
  elseif mode == 'space_evenly' then
    local extra = freeSpace / (count + 1)
    return spacing + extra, extra
  end
  return spacing, 0
end

local function alignOffset(mode, available, childSize)
  if mode == 'center' then
    return math.max(0, (available - childSize) * 0.5)
  elseif mode == 'end' then
    return math.max(0, available - childSize)
  elseif mode == 'stretch' then
    return 0, available
  end
  return 0
end

function Stack:computeLayout(availableW, availableH)
  local children = self.children
  local layout = {}
  if #children == 0 then
    return layout
  end

  if self.direction == 'vertical' then
    local contentHeight = sumHeights(children, self.spacing)
    local free = resolveFreeSpace(contentHeight, availableH)
    local spacing = self.spacing
    local startShift
    spacing, startShift = adjustSpacing(self.justify, spacing, free, #children)
    local offset, override = justifyOffset(self.justify, free)
    if startShift then
      offset = startShift
    elseif override then
      offset = override
    end

    local width = availableW or self.size.w
    local cursorY = math.max(0, offset)
    for i = 1, #children do
      local child = children[i]
      local childW, childH = childSize(child)
      local alignBase = width or childW
      local alignShift, stretchedSize = alignOffset(self.align, alignBase, childW)
      local x = alignShift or 0
      local y = cursorY
      layout[i] = { x = x, y = y, width = stretchedSize or childW, height = childH }
      cursorY = cursorY + childH + spacing
    end
  else
    local contentWidth = sumWidths(children, self.spacing)
    local free = resolveFreeSpace(contentWidth, availableW)
    local spacing = self.spacing
    local startShift
    spacing, startShift = adjustSpacing(self.justify, spacing, free, #children)
    local offset, override = justifyOffset(self.justify, free)
    if startShift then
      offset = startShift
    elseif override then
      offset = override
    end

    local height = availableH or self.size.h
    local cursorX = math.max(0, offset)
    for i = 1, #children do
      local child = children[i]
      local childW, childH = childSize(child)
      local alignBase = height or childH
      local alignShift, stretchedSize = alignOffset(self.align, alignBase, childH)
      local x = cursorX
      local y = alignShift or 0
      layout[i] = { x = x, y = y, width = childW, height = stretchedSize or childH }
      cursorX = cursorX + childW + spacing
    end
  end

  return layout
end

function Stack:draw(pass, originX, originY)
  if not self.visible then
    return
  end

  local availableW = self.size.w > 0 and self.size.w or nil
  local availableH = self.size.h > 0 and self.size.h or nil
  local layout = self:computeLayout(availableW, availableH)

  for index = 1, #self.children do
    local child = self.children[index]
    local entry = layout[index]
    if entry then
      local childW, childH = childSize(child)
      if self.direction == 'vertical' and entry.width and entry.width ~= childW and self.align == 'stretch' and child.size then
        child.size.w = entry.width
      elseif self.direction == 'horizontal' and entry.height and entry.height ~= childH and self.align == 'stretch' and child.size then
        child.size.h = entry.height
      end
      child:draw(pass, originX + entry.x, originY + entry.y)
    end
  end
end

function Stack:add(child)
  return Element.add(self, child)
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

local function requireStack()
  return require 'ui/elements/stack'
end

function Stack:label(props)
  local Label = requireLabel()
  return self:add(Label.new(self.manager, props))
end

function Stack:button(props)
  local Button = requireButton()
  return self:add(Button.new(self.manager, props))
end

function Stack:slotGrid(props)
  local SlotGrid = requireSlotGrid()
  return self:add(SlotGrid.new(self.manager, props))
end

function Stack:stack(props)
  local StackClass = requireStack()
  props = props or {}
  if not props.anchor then
    props.anchor = 'top_left'
  end
  local child = StackClass.new(self.manager, props)
  return self:add(child)
end

return Stack
