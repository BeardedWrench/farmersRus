local Theme = require 'ui.theme'
local Panel = require 'ui/elements/panel'
local Label = require 'ui/elements/label'

local Button = setmetatable({}, { __index = Panel })
Button.__index = Button

function Button.new(manager, props)
  props = props or {}
  props.padding = props.padding or 8
  props.color = props.color or Theme.palette.panel
  props.outline = props.outline or { color = Theme.palette.outline, thickness = 1 }
  local self = Panel.new(manager, props)
  setmetatable(self, Button)
  self.onClick = props.onClick
  self.enabled = props.enabled ~= false
  self.hovered = false
  self.pressed = false

  if props.text then
    self.label = self:add(Label.new(manager, {
      text = props.text,
      x = 0,
      y = 0,
      width = self.size.w - (self.padding.left + self.padding.right),
      align = 'center',
      scale = props.textScale or 0.6,
      color = props.textColor
    }))
  end

  return self
end

function Button:setText(text)
  if self.label then
    self.label:setText(text)
  end
end

-- Input handling stubs for future interaction expansion.
function Button:handleCursor(x, y, pressed)
  self.hovered = false
  self.pressed = false
  if not self.enabled then
    return
  end
  local left = self.position.x
  local top = self.position.y
  local w, h = self.size.w, self.size.h
  if x >= left and x <= left + w and y >= top and y <= top + h then
    self.hovered = true
    if pressed and self.onClick then
      self.onClick()
      self.pressed = true
    end
  end
end

function Button:draw(pass, originX, originY)
  if not self.visible then
    return
  end
  local baseColor = self.style.color
  if self.hovered and self.enabled then
    self:setRenderColor({
      math.min(1, baseColor[1] + 0.06),
      math.min(1, baseColor[2] + 0.06),
      math.min(1, baseColor[3] + 0.06),
      baseColor[4] or 1
    })
  elseif not self.enabled then
    self:setRenderColor({
      baseColor[1] * 0.6,
      baseColor[2] * 0.6,
      baseColor[3] * 0.6,
      baseColor[4] or 1
    })
  else
    self:setRenderColor(nil)
  end
  Panel.draw(self, pass, originX, originY)
end

return Button
