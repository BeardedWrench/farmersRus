local InventoryUI = {}

local Theme = require 'ui.theme'

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
  local panel = ui:panel({
    x = width - margin - layout.minWidth,
    y = margin,
    minWidth = layout.minWidth,
    minHeight = layout.minHeight,
    padding = layout.padding,
    color = self.theme.palette.inventoryPanel,
    outline = { color = self.theme.palette.outlineStrong, thickness = 1 },
    autoWidth = true,
    autoHeight = true,
    contentSpacing = layout.bodySpacing or 16,
    title = {
      text = 'Inventory',
      scale = layout.titleScale,
      spacing = layout.headerSpacing or 16
    }
  })

  local wallet = self.app.inventory and self.app.inventory:getWallet()
  if wallet then
    panel:label({
      text = ('Wallet: %d'):format(wallet.balance or 0),
      scale = layout.walletScale,
      spacing = 0,
      color = self.theme.palette.text
    })
  end

  local items = toItemList(self.app.inventory and self.app.inventory:getInventory())
  panel:slotGrid({
    y = layout.walletSpacing,
    items = items,
    columns = layout.grid.columns,
    slotSize = layout.grid.slotSize,
    spacing = layout.grid.spacing,
    iconRenderer = icons,
    textScale = layout.grid.textScale,
    iconPadding = layout.grid.iconPadding,
    labelPadding = 8,
    labelOffset = 8,
    countPadding = 6
  })

  panel:updateAutoSize()
  panel.position.x = width - margin - panel.size.w
end

return InventoryUI
