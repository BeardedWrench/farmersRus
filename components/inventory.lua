local Inventory = {}

function Inventory.create(props)
  props = props or {}
  return {
    slots = props.slots or {},
    capacity = props.capacity or 40
  }
end

function Inventory.addItem(component, itemId, amount, options)
  amount = amount or 1
  options = options or {}
  for _, slot in ipairs(component.slots) do
    if slot.id == itemId and slot.stackable ~= false then
      slot.qty = slot.qty + amount
      return true
    end
  end
  if #component.slots >= component.capacity then
    return false
  end
  component.slots[#component.slots + 1] = {
    id = itemId,
    qty = amount,
    stackable = options.stackable ~= false,
    meta = options.meta
  }
  return true
end

function Inventory.removeItem(component, itemId, amount)
  amount = amount or 1
  for index, slot in ipairs(component.slots) do
    if slot.id == itemId then
      if slot.qty > amount then
        slot.qty = slot.qty - amount
        return true
      elseif slot.qty == amount then
        table.remove(component.slots, index)
        return true
      else
        return false
      end
    end
  end
  return false
end

function Inventory.hasItem(component, itemId, amount)
  amount = amount or 1
  for _, slot in ipairs(component.slots) do
    if slot.id == itemId and slot.qty >= amount then
      return true
    end
  end
  return false
end

return Inventory
