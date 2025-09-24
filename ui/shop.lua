local ShopUI = {}

function ShopUI.create(app)
  return {
    app = app,
    visible = false,
    activeShop = nil
  }
end

function ShopUI:openShop(shopId)
  self.visible = true
  self.activeShop = shopId
end

function ShopUI:close()
  self.visible = false
  self.activeShop = nil
end

return ShopUI
