local Util = {}

function Util.normalizePadding(padding)
  if not padding then
    return { top = 0, right = 0, bottom = 0, left = 0 }
  end
  if type(padding) == 'number' then
    return { top = padding, right = padding, bottom = padding, left = padding }
  end
  return {
    top = padding.top or padding[1] or 0,
    right = padding.right or padding[2] or padding.x or 0,
    bottom = padding.bottom or padding[3] or padding.y or padding[2] or 0,
    left = padding.left or padding[4] or padding.x or padding[1] or 0
  }
end

function Util.cloneColor(color, defaultAlpha)
  if not color then
    return nil
  end
  return {
    color[1],
    color[2],
    color[3],
    color[4] ~= nil and color[4] or defaultAlpha or 1
  }
end

function Util.measureLine(font, text, scale)
  if not font then
    return 0
  end
  return font:getWidth(text or '') * scale
end

function Util.measureBlock(font, lines, scale, spacing)
  if not font then
    return 0, 0
  end
  local height = 0
  local maxWidth = 0
  local lineHeight = font:getHeight() * scale
  lines = lines or {}
  for i = 1, #lines do
    local width = Util.measureLine(font, lines[i], scale)
    if width > maxWidth then
      maxWidth = width
    end
    height = height + lineHeight
    if i < #lines then
      height = height + (spacing or 0)
    end
  end
  return maxWidth, height
end

return Util
