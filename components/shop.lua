local Shop = {}

function Shop.create(props)
  props = props or {}
  return {
    id = props.id or 'shop',
    stock = props.stock or {},
    restockTimer = props.restockTimer or 0,
    category = props.category or 'general'
  }
end

return Shop
