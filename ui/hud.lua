local Theme = require 'ui.theme'
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

  local panel = ui:createPanel()
    :setPosition(margin, margin)
    :setPadding(padding)
    :setMinSize(layout.minWidth, layout.minHeight)
    :setAnchor('top_left')
    :setBackground(self.theme.palette.hudPanel)
    :setOutline(self.theme.palette.outline, 1)
    :setAutoSize(true, true)
    :setBodySpacing(0)

  local stack = ui:createStack()
    :setDirection('vertical')
    :setSpacing(layout.lineSpacing + 4)
    :setAnchor('top_left')

  local lines = hudLines(self.app, self.app.inventory and self.app.inventory:getPlayer())
  for i = 1, #lines do
    local lineLabel = ui:createLabel()
      :setText(lines[i])
      :setScale(layout.textScale)
      :setAnchor('top_left')
    stack:addChild(lineLabel)
  end

  panel:addChild(stack)

  ui:add(panel)
end

return Hud
