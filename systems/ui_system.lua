local Theme = require 'ui.theme'
local UIManager = require 'ui.manager'
local IconRenderer = require 'ui.icon_renderer'
local HudUI = require 'ui.hud'
local InventoryUI = require 'ui.inventory'

return function(app)
  local events = app.events

  local system = {
    name = 'ui_system',
    updateOrder = 70,
    drawOrder = 120
  }

  local font

  local function loadFont()
    local fontPath = Theme.font
    if fontPath and lovr.filesystem.isFile(fontPath) then
      return lovr.graphics.newFont(fontPath, 32)
    end
    return lovr.graphics.newFont(32)
  end

  function system:init()
    font = loadFont()
    if font then
      font:setPixelDensity(1)
    end

    self.viewMatrix = lovr.math.newMat4()
    self.projectionMatrix = lovr.math.newMat4()
    self.lastWidth, self.lastHeight = nil, nil

    self.ui = UIManager.new(app)
    self.icons = IconRenderer.new(app)
    self.hud = HudUI.create(app)
    self.inventoryUI = InventoryUI.create(app)
    if font then
      self.ui:setFont(font)
    end

    events:on('input:keypressed', function(key)
      if key == 'i' then
        self.inventoryUI:toggle()
      elseif key == 't' then
        local nextScene = app.scenes:getAlternate()
        if nextScene then
          events:emit('scene:travel', nextScene)
        end
      end
    end)
  end

  local function ensureProjection(self, width, height)
    if width ~= self.lastWidth or height ~= self.lastHeight then
      self.projectionMatrix:orthographic(0, width, height, 0, -10, 10)
      self.viewMatrix:identity()
      self.lastWidth, self.lastHeight = width, height
    end
  end

  function system:draw(pass)
    if not font then
      return
    end

    local width, height = lovr.system.getWindowDimensions()
    ensureProjection(self, width, height)

    pass:push('state')
    pass:setDepthTest()
    pass:setCullMode()
    self.viewMatrix:identity()
    pass:setViewPose(1, self.viewMatrix)
    pass:setProjection(1, self.projectionMatrix)
    pass:setFont(font)

    self.ui:begin(width, height)

    self.hud:render(self.ui)
    self.inventoryUI:render(self.ui, self.icons, width)

    self.ui:draw(pass)
    pass:pop('state')
  end

  return system
end
