local Theme = require 'ui.theme'

local InventoryUI = {}
InventoryUI.__index = InventoryUI

function InventoryUI.create(app)
  local instance = {
    app = app,
    open = false,
    theme = Theme
  }
  return setmetatable(instance, InventoryUI)
end

function InventoryUI:toggle()
  self.open = not self.open
end

local function formatName(id)
  if not id then
    return 'Unknown'
  end
  local label = tostring(id):gsub('_', ' ')
  if label == '' then
    return 'Item'
  end
  return label:sub(1, 1):upper() .. label:sub(2)
end

local function toItemList(inventory)
  if not inventory then
    return {}
  end
  local result = {}
  for i = 1, #inventory.slots do
    local slot = inventory.slots[i]
    result[#result + 1] = {
      icon = slot.id,
      label = slot.meta and slot.meta.label or formatName(slot.id),
      count = slot.qty,
      model = slot.meta and slot.meta.model
    }
  end
  return result
end

function InventoryUI:render(ui, icons, width)
  if not self.open then
    return
  end

  local layout = self.theme.layout.inventory
  local margin = self.theme.layout.margin

  local panel = ui:createPanel()
    :setPosition(width - margin, margin)
    :setAnchor('top_right')
    :setPadding(layout.padding)
    :setMinSize(layout.minWidth, layout.minHeight)
    :setBackground(self.theme.palette.inventoryPanel)
    :setOutline(self.theme.palette.outlineStrong, 1)
    :setAutoSize(true, true)
    :setTitleSpacing(layout.headerSpacing or 16)
    :setTitleText('Inventory')
    :setBodySpacing(0)

  local stack = ui:createStack()
    :setDirection('vertical')
    :setSpacing(layout.bodySpacing or 18)
    :setAnchor('top_left')

  local wallet = self.app.inventory and self.app.inventory:getWallet()
  if wallet then
    local walletLabel = ui:createLabel()
      :setText(('Wallet: %d'):format(wallet.balance or 0))
      :setScale(layout.walletScale)
      :setAnchor('top_left')
    stack:addChild(walletLabel)
  end

  local grid = ui:createSlotGrid()
    :setColumns(layout.grid.columns)
    :setSlotSize(layout.grid.slotSize)
    :setSpacing(layout.grid.spacing)
    :setTextScale(layout.grid.textScale)
    :setIconPadding(layout.grid.iconPadding)
    :setIconRenderer(icons)
    :setShowLabels(false)
    :setItems(toItemList(self.app.inventory and self.app.inventory:getInventory()))
    :setAnchor('top_left')

  stack:addChild(grid)

  panel:addChild(stack)
  ui:add(panel)
end

return InventoryUI
