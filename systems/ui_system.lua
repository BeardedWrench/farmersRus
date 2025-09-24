local InventoryLib = require 'components.inventory'
local WalletLib = require 'components.wallet'

return function(app)
  local events = app.events

  local system = {
    name = 'ui_system',
    updateOrder = 70,
    drawOrder = 120
  }

  local font
  local showInventory = false

  function system:init()
    if lovr.filesystem.isFile('assets/fonts/lucon.ttf') then
      font = lovr.graphics.newFont('assets/fonts/lucon.ttf', 32)
    else
      font = lovr.graphics.newFont(32)
    end
    if font then
      font:setPixelDensity(1)
    end
    self.viewMatrix = lovr.math.newMat4()
    self.projectionMatrix = lovr.math.newMat4()
    self.lastWidth, self.lastHeight = nil, nil

    events:on('input:keypressed', function(key)
      if key == 'i' then
        showInventory = not showInventory
      elseif key == 't' then
        local nextScene = app.scenes:getAlternate()
        if nextScene then
          events:emit('scene:travel', nextScene)
        end
      elseif key == 'escape' then
        -- Placeholder for pause menu toggle
      end
    end)
  end

  local function buildHotbarText(playerEntity)
    local tool = playerEntity and app.ecs:getComponent(playerEntity, 'tool')
    local current = tool and tool.type or 'shovel'
    local lines = {
      'Tools: [1] Shovel  [2] Watering  [3] Seed  [4] Harvest',
      ('Current: %s'):format(current)
    }
    local wallet = app.inventory and app.inventory:getWallet()
    if wallet then
      lines[#lines + 1] = ('Money: %d'):format(wallet.balance)
    end
    lines[#lines + 1] = 'Press I to view inventory'
    lines[#lines + 1] = 'Press T to travel between Farm and Town'
    return table.concat(lines, '\n')
  end

  function system:draw(pass)
    if not font then
      return
    end

    local width, height = lovr.system.getWindowDimensions()
    if width ~= self.lastWidth or height ~= self.lastHeight then
      self.projectionMatrix:orthographic(0, width, height, 0, -10, 10)
      self.viewMatrix:identity()
      self.lastWidth, self.lastHeight = width, height
    end

    pass:push('state')
    pass:setDepthTest()
    pass:setCullMode()
    self.viewMatrix:identity()
    pass:setViewPose(1, self.viewMatrix)
    pass:setProjection(1, self.projectionMatrix)

    local margin = 24
    local panelW, panelH = 320, 160
    local panelX = margin + panelW * 0.5
    local panelY = height - (margin + panelH * 0.5)
    pass:setColor(0.1, 0.1, 0.12, 0.9)
    pass:plane(panelX, panelY, 0, panelW, panelH)

    pass:setColor(1, 1, 1, 1)
    pass:setFont(font)
    local playerEntity = app.inventory and app.inventory:getPlayer() or nil
    local hudText = buildHotbarText(playerEntity)
    pass:text(hudText, panelX - panelW * 0.5 + 16, panelY - panelH * 0.5 + 28, 0, 0.65)

    if showInventory then
      local invPanelW, invPanelH = 360, 320
      local invX = width - (margin + invPanelW * 0.5)
      local invY = height - (margin + invPanelH * 0.5)
      pass:setColor(0.12, 0.12, 0.15, 0.92)
      pass:plane(invX, invY, 0, invPanelW, invPanelH)
      pass:setColor(1, 1, 1, 1)
      pass:setFont(font)
      local inv = app.inventory and app.inventory:getInventory()
      local y = invY - invPanelH * 0.5 + 48
      pass:text('Inventory', invX - invPanelW * 0.5 + 24, y, 0, 0.72)
      y = y + 34
      if inv and #inv.slots > 0 then
        for _, slot in ipairs(inv.slots) do
          local line = string.format('- %s x%d', slot.id, slot.qty)
          pass:text(line, invX - invPanelW * 0.5 + 24, y, 0, 0.6)
          y = y + 24
        end
      else
        pass:text('(empty)', invX - invPanelW * 0.5 + 24, y, 0, 0.6)
      end
    end

    pass:pop('state')
  end

  return system
end
