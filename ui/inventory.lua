local InventoryUI = {}

function InventoryUI.create(app)
  return {
    app = app,
    open = false
  }
end

function InventoryUI:toggle()
  self.open = not self.open
end

return InventoryUI
