local Theme = require 'ui.theme'
local Util = require 'ui.core.util'

local Hud = {}
Hud.__index = Hud

function Hud.create(app)
  local instance = {
    app = app,
    visible = true,
    theme = Theme
  }
  return setmetatable(instance, Hud)
end

local function currentTool(app, playerEntity)
  if not playerEntity then
    return 'shovel'
  end
  local tool = app.ecs:getComponent(playerEntity, 'tool')
  return (tool and tool.type) or 'shovel'
end

local function hudLines(app, playerEntity)
  local lines = {
    'Tools: [1] Shovel  [2] Watering  [3] Seed  [4] Harvest',
    ('Current: %s'):format(currentTool(app, playerEntity))
  }

  local walletSystem = app.inventory and app.inventory:getWallet()
  if walletSystem then
    lines[#lines + 1] = ('Money: %d'):format(walletSystem.balance or 0)
  end

  lines[#lines + 1] = 'Press I to toggle inventory'
  lines[#lines + 1] = 'Press T to travel between Farm and Town'
  return lines
end

function Hud:render(ui)
  if not self.visible then
    return
  end

  local margin = self.theme.layout.margin
  local layout = self.theme.layout.hud
  local padding = layout.padding

  local font = ui:getFont()
  local lines = hudLines(self.app, self.app.inventory and self.app.inventory:getPlayer())
  local textWidth, textHeight = Util.measureBlock(font, lines, layout.textScale, layout.lineSpacing)
  local panelWidth = math.max(layout.size.w, textWidth + padding.left + padding.right)
  local panelHeight = math.max(layout.size.h, textHeight + padding.top + padding.bottom)

  local panel = ui:panel({
    x = margin,
    y = margin,
    width = panelWidth,
    height = panelHeight,
    padding = padding,
    color = self.theme.palette.hudPanel,
    outline = { color = self.theme.palette.outline, thickness = 1 }
  })

  panel:label({
    text = lines,
    x = 0,
    y = 0,
    scale = layout.textScale,
    spacing = layout.lineSpacing,
    color = self.theme.palette.text
  })
end

return Hud
