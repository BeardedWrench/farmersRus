local Slot = {}

local function drawFrame(pass, x, y, size, bgColor, outlineColor)
  local cx = x + size * 0.5
  local cy = y + size * 0.5
  pass:setColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4])
  pass:plane(cx, cy, 0, size, size)
  pass:setColor(outlineColor[1], outlineColor[2], outlineColor[3], outlineColor[4])
  pass:line(x, y, 0, x + size, y, 0)
  pass:line(x + size, y, 0, x + size, y + size, 0)
  pass:line(x + size, y + size, 0, x, y + size, 0)
  pass:line(x, y + size, 0, x, y, 0)
  pass:setColor(1, 1, 1, 1)
end

local function drawIcon(pass, iconRenderer, item, cx, cy, size, padding)
  if not iconRenderer or not item or not item.icon then
    return
  end
  local descriptor = {
    model = item.model,
    iconSize = size,
    icon = item.icon
  }
  local iconOptions = item.iconOptions
  if iconOptions then
    for key, value in pairs(iconOptions) do
      descriptor[key] = value
    end
  end
  local icon = iconRenderer:getIcon(item.icon, descriptor)
  if not icon or not icon.material then
    return
  end
  local extent = math.max(0, size - padding * 2)
  pass:push('state')
  pass:setMaterial(icon.material)
  pass:plane(cx, cy, 0.001, extent, extent)
  pass:pop('state')
end

local function drawText(pass, font, text, x, y, scale)
  if not text or text == '' then
    return
  end
  local width = font:getWidth(text) * scale
  local height = font:getHeight() * scale
  pass:text(text, x + width * 0.5, y + height * 0.5, 0, scale)
end

function Slot.draw(pass, font, iconRenderer, item, layout)
  drawFrame(pass, layout.x, layout.y, layout.size, layout.bgColor, layout.outlineColor)

  local cx = layout.x + layout.size * 0.5
  local cy = layout.y + layout.size * 0.5
  drawIcon(pass, iconRenderer, item, cx, cy, layout.size, layout.iconPadding)

  if layout.showLabels and item then
    pass:setColor(layout.textColor[1], layout.textColor[2], layout.textColor[3], layout.textColor[4])
    local scale = layout.textScale
    local width = font:getWidth(item.label or '') * scale
    local labelX = layout.x + math.max(layout.labelPadding, (layout.size - width) * 0.5)
    drawText(pass, font, item.label, labelX, layout.y + layout.labelOffset, scale)
    pass:setColor(1, 1, 1, 1)
  end

  if layout.showCounts and item then
    local qtyText = (item.count and ('x' .. tostring(item.count))) or nil
    pass:setColor(layout.countColor[1], layout.countColor[2], layout.countColor[3], layout.countColor[4])
    local scale = layout.countScale
    local width = font:getWidth(qtyText or '') * scale
    local height = font:getHeight() * scale
    local x = layout.x + layout.size - layout.countPadding - width
    local y = layout.y + layout.size - layout.countPadding - height
    drawText(pass, font, qtyText, x, y, scale)
    pass:setColor(1, 1, 1, 1)
  end
end

return Slot
