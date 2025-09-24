local Theme = require 'ui.theme'

local Widgets = {}

function Widgets.panel(pass, x, y, z, width, height)
  pass:setColor(table.unpack(Theme.palette.panel))
  pass:plane(x, y, z, width, height)
  pass:setColor(1, 1, 1, 1)
end

function Widgets.label(pass, font, text, x, y, z, scale)
  pass:text(font, text, x, y, z, scale or 0.6)
end

return Widgets
