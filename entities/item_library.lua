local Util = require 'core.util'

local ItemLibrary = {}

local cachedDefinitions

local function loadDefinitions()
  if cachedDefinitions then
    return cachedDefinitions
  end

  local definitions = {}

  local okTools, tools = pcall(require, 'entities.tools')
  if okTools and type(tools) == 'table' then
    for id, def in pairs(tools) do
      definitions[id] = def
    end
  end

  local okSeeds, seeds = pcall(require, 'entities.seeds')
  if okSeeds and type(seeds) == 'table' then
    for id, def in pairs(seeds) do
      definitions[id] = def
    end
  end

  cachedDefinitions = definitions
  return cachedDefinitions
end

local function toInventory(definition)
  if not definition then
    return nil
  end
  if definition.inventory then
    return Util.deepCopy(definition.inventory)
  end
  local fallback = {
    label = definition.label or definition.id,
    model = definition.model,
    icon = definition.icon and Util.deepCopy(definition.icon) or nil
  }
  return fallback
end

function ItemLibrary.get(id)
  if not id then
    return nil
  end
  local definitions = loadDefinitions()
  local def = definitions[id]
  if not def then
    return nil
  end
  local inventory = toInventory(def)
  if inventory then
    inventory.id = id
  end
  return inventory
end

function ItemLibrary.list()
  local definitions = loadDefinitions()
  local items = {}
  for id, def in pairs(definitions) do
    local inventory = toInventory(def)
    if inventory then
      inventory.id = id
      inventory.label = inventory.label or def.label or id
      items[#items + 1] = inventory
    end
  end
  table.sort(items, function(a, b)
    return (a.label or a.id) < (b.label or b.id)
  end)
  return items
end

return ItemLibrary
