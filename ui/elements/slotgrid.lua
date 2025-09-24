local Element = require 'ui.core.element'
local Slot = require 'ui/elements/slot'
local Theme = require 'ui.theme'
local Util = require 'ui.core.util'

local SlotGrid = setmetatable({}, { __index = Element })
SlotGrid.__index = SlotGrid

function SlotGrid.new(manager, props)
  props = props or {}
  local self = Element.new(manager, props)
  setmetatable(self, SlotGrid)

  self.items = props.items or {}
  self.columns = props.columns or Theme.layout.inventory.grid.columns
  self.slotSize = props.slotSize or Theme.layout.inventory.grid.slotSize
  self.spacing = props.spacing or Theme.layout.inventory.grid.spacing
  self.iconRenderer = props.iconRenderer
  self.textScale = props.textScale or Theme.layout.inventory.grid.textScale
  self.showLabels = props.showLabels ~= false
  self.showCounts = props.showCounts ~= false
  self.emptyMessage = props.emptyMessage or '(empty)'
  self.labelPadding = props.labelPadding or 8
  self.labelOffset = props.labelOffset or 8
  self.countPadding = props.countPadding or 6
  self.iconPadding = props.iconPadding or Theme.layout.inventory.grid.iconPadding
  self.slotColor = Util.cloneColor(props.slotColor or Theme.palette.slotBackground)
  self.outlineColor = Util.cloneColor(props.outlineColor or Theme.palette.slotOutline)
  self.textColor = props.textColor and Util.cloneColor(props.textColor) or Theme.palette.text
  self.countColor = props.countColor and Util.cloneColor(props.countColor) or Theme.palette.text
  self.countScale = self.textScale * 0.9
  return self
end

function SlotGrid:setItems(items)
  self.items = items or {}
end

local function computeGridDimensions(self)
  local columns = math.max(1, self.columns)
  local count = #self.items
  local rows = count > 0 and math.ceil(count / columns) or 1
  return columns, rows
end

function SlotGrid:getBounds()
  local width = self.size.w
  local height = self.size.h
  if (not width or width == 0) or (not height or height == 0) then
    local columns, rows = computeGridDimensions(self)
    local totalWidth = columns * self.slotSize + math.max(0, columns - 1) * self.spacing
    local totalHeight = rows * self.slotSize + math.max(0, rows - 1) * self.spacing
    if not width or width == 0 then
      width = totalWidth
    end
    if not height or height == 0 then
      height = totalHeight
    end
  end
  return width, height
end

local function drawEmptyState(self, pass, font, x, y)
  pass:setColor(Theme.palette.mutedText[1], Theme.palette.mutedText[2], Theme.palette.mutedText[3], Theme.palette.mutedText[4])
  local scale = self.textScale
  local width = font:getWidth(self.emptyMessage) * scale
  local height = font:getHeight() * scale
  local areaWidth = self.size.w > 0 and self.size.w or width
  local areaHeight = self.size.h > 0 and self.size.h or height
  local centerX = x + areaWidth * 0.5
  local centerY = y + areaHeight * 0.5
  pass:text(self.emptyMessage, centerX, centerY, 0, scale)
  pass:setColor(1, 1, 1, 1)
end

local function computeColumns(self)
  local columns = math.max(1, self.columns)
  local w = self.size.w
  if w and w > 0 then
    local maxCols = math.max(1, math.floor((w + self.spacing) / (self.slotSize + self.spacing)))
    columns = math.min(columns, maxCols)
  end
  return columns
end

local function computeMaxRows(self)
  local h = self.size.h
  if not h or h <= 0 then
    return math.huge
  end
  return math.max(1, math.floor((h + self.spacing) / (self.slotSize + self.spacing)))
end

function SlotGrid:draw(pass, originX, originY)
  if not self.visible then
    return
  end
  local font = self.manager.font
  if not font then
    return
  end

  local items = self.items or {}
  local count = #items
  local columns = computeColumns(self)
  local maxRows = computeMaxRows(self)

  local startX, startY = self:getAbsolutePosition(originX, originY)

  if count == 0 then
    drawEmptyState(self, pass, font, startX, startY)
    return
  end

  for index = 1, count do
    local item = items[index]
    local col = (index - 1) % columns
    local row = math.floor((index - 1) / columns)
    if row >= maxRows then
      break
    end

    local x = startX + col * (self.slotSize + self.spacing)
    local y = startY + row * (self.slotSize + self.spacing)

    Slot.draw(pass, font, self.iconRenderer, item, {
      x = x,
      y = y,
      size = self.slotSize,
      bgColor = self.slotColor,
      outlineColor = self.outlineColor,
      iconPadding = self.iconPadding,
      showLabels = self.showLabels,
      showCounts = self.showCounts,
      textScale = self.textScale,
      textColor = self.textColor,
      labelPadding = self.labelPadding,
      labelOffset = self.labelOffset,
      countPadding = self.countPadding,
      countColor = self.countColor,
      countScale = self.countScale
    })
  end
end

return SlotGrid
