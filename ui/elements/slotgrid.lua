local Element = require 'ui.core.element'
local Theme = require 'ui.theme'
local Theme = require 'ui.theme'

local SlotGrid = setmetatable({}, { __index = Element })
SlotGrid.__index = SlotGrid

local DEFAULT_SLOT_BG = { 0.2, 0.21, 0.27, 0.92 }
local DEFAULT_SLOT_OUTLINE = { 1, 1, 1, 0.1 }

function SlotGrid.new(manager)
  local self = Element.new(manager)
  setmetatable(self, SlotGrid)
  self.items = {}
  self.columns = 4
  self.slotSize = 72
  self.spacing = 16
  self.iconPadding = 10
  self.showLabels = true
  self.showCounts = true
  self.textScale = 0.45
  self.slotColor = {
    DEFAULT_SLOT_BG[1],
    DEFAULT_SLOT_BG[2],
    DEFAULT_SLOT_BG[3],
    DEFAULT_SLOT_BG[4]
  }
  self.outlineColor = {
    DEFAULT_SLOT_OUTLINE[1],
    DEFAULT_SLOT_OUTLINE[2],
    DEFAULT_SLOT_OUTLINE[3],
    DEFAULT_SLOT_OUTLINE[4]
  }
  self.emptyMessage = '(empty)'
  return self
end

function SlotGrid:setItems(items)
  self.items = items or {}
  return self
end

function SlotGrid:setColumns(columns)
  if columns and columns > 0 then
    self.columns = columns
  end
  return self
end

function SlotGrid:setSlotSize(size)
  if size then
    self.slotSize = size
  end
  return self
end

function SlotGrid:setSpacing(spacing)
  if spacing then
    self.spacing = spacing
  end
  return self
end

function SlotGrid:setTextScale(scale)
  if scale then
    self.textScale = scale
  end
  return self
end

function SlotGrid:setIconPadding(padding)
  if padding then
    self.iconPadding = padding
  end
  return self
end

function SlotGrid:setIconRenderer(renderer)
  self.iconRenderer = renderer
  return self
end

function SlotGrid:setEmptyMessage(message)
  if message then
    self.emptyMessage = message
  end
  return self
end

function SlotGrid:setSlotColors(background, outline)
  if background then
    self.slotColor = { background[1], background[2], background[3], background[4] or 1 }
  end
  if outline then
    self.outlineColor = { outline[1], outline[2], outline[3], outline[4] or 1 }
  end
  return self
end

function SlotGrid:setShowLabels(enabled)
  self.showLabels = enabled ~= false
  return self
end

function SlotGrid:setShowCounts(enabled)
  self.showCounts = enabled ~= false
  return self
end

function SlotGrid:getBounds()
  local count = #self.items
  if count == 0 then
    return self.slotSize, self.slotSize
  end
  local columns = math.max(1, self.columns)
  local rows = math.ceil(count / columns)
  local width = columns * self.slotSize + (columns - 1) * self.spacing
  local height = rows * self.slotSize + (rows - 1) * self.spacing
  return width, height
end

local function drawSlot(pass, x, y, size, bg, outline)
  local cx = x + size * 0.5
  local cy = y + size * 0.5
  pass:setColor(bg[1], bg[2], bg[3], bg[4])
  pass:plane(cx, cy, 0, size, size)
  pass:setColor(outline[1], outline[2], outline[3], outline[4])
  pass:line(x, y, 0, x + size, y, 0)
  pass:line(x + size, y, 0, x + size, y + size, 0)
  pass:line(x + size, y + size, 0, x, y + size, 0)
  pass:line(x, y + size, 0, x, y, 0)
  pass:setColor(1, 1, 1, 1)
end

local function drawLabel(pass, font, text, x, y, scale)
  if not text or text == '' then
    return
  end
  local width = font:getWidth(text) * scale
  local height = font:getHeight() * scale
  pass:text(text, x + width * 0.5, y + height * 0.5, 0, scale)
end

function SlotGrid:draw(pass, originX, originY)
  if not self.visible then
    return
  end
  local font = self.manager and self.manager.font
  local columns = math.max(1, self.columns)
  local items = self.items or {}
  local count = #items
  if count == 0 then
    if font then
      pass:setColor(Theme.palette.mutedText[1], Theme.palette.mutedText[2], Theme.palette.mutedText[3], Theme.palette.mutedText[4])
      drawLabel(pass, font, self.emptyMessage, originX, originY, self.textScale)
      pass:setColor(1, 1, 1, 1)
    end
    return
  end

  for index = 1, count do
    local item = items[index]
    local col = (index - 1) % columns
    local row = math.floor((index - 1) / columns)
    local slotX = originX + col * (self.slotSize + self.spacing)
    local slotY = originY + row * (self.slotSize + self.spacing)

    drawSlot(pass, slotX, slotY, self.slotSize, self.slotColor, self.outlineColor)

    if self.iconRenderer and item and item.icon then
      local descriptor = {
        model = item.model,
        iconSize = self.slotSize,
        icon = item.icon
      }
      local icon = self.iconRenderer:getIcon(item.icon, descriptor)
      if icon and icon.material then
        local extent = math.max(0, self.slotSize - self.iconPadding * 2)
        local cx = slotX + self.slotSize * 0.5
        local cy = slotY + self.slotSize * 0.5
        pass:push('state')
        pass:setMaterial(icon.material)
        pass:plane(cx, cy, 0.001, extent, extent)
        pass:pop('state')
      end
    end

    if font and self.showLabels and item and item.label then
      local labelY = slotY + self.slotSize - font:getHeight() * self.textScale - 6
      drawLabel(pass, font, item.label, slotX + 6, labelY, self.textScale)
    end

    if font and self.showCounts and item and item.count then
      local qtyText = ('x%d'):format(item.count)
      local qtyScale = self.textScale * 0.9
      local width = font:getWidth(qtyText) * qtyScale
      local height = font:getHeight() * qtyScale
      local qtyX = slotX + self.slotSize - width - 6
      local qtyY = slotY + self.slotSize - height - 6
      drawLabel(pass, font, qtyText, qtyX, qtyY, qtyScale)
    end
  end
end

return SlotGrid
