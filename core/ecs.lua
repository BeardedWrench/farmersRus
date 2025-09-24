local ECS = {}
ECS.__index = ECS

local World = {}
World.__index = World

local function sortSignature(components)
  local copy = {}
  for i = 1, #components do
    copy[i] = components[i]
  end
  table.sort(copy)
  local signature = table.concat(copy, '|')
  return signature, copy
end

local function removeFromList(list, value)
  for i = 1, #list do
    if list[i] == value then
      list[i] = list[#list]
      list[#list] = nil
      return
    end
  end
end

function ECS.new()
  local world = {
    app = nil,
    nextId = 1,
    freeIds = {},
    entities = {},
    entityComponents = {},
    components = {},
    queries = {},
    componentQueries = {},
    systems = {
      update = {},
      draw = {}
    },
    systemByName = {}
  }
  return setmetatable(world, World)
end

function World:bind(app)
  self.app = app
end

function World:createEntity()
  local id
  local freeIds = self.freeIds
  if #freeIds > 0 then
    id = freeIds[#freeIds]
    freeIds[#freeIds] = nil
  else
    id = self.nextId
    self.nextId = self.nextId + 1
  end
  self.entities[id] = true
  self.entityComponents[id] = {}
  if self.app and self.app.events then
    self.app.events:emit('ecs:entityCreated', id)
  end
  return id
end

function World:destroyEntity(id)
  if not self.entities[id] then
    return
  end
  local components = self.entityComponents[id]
  if components then
    local names = {}
    for name in pairs(components) do
      names[#names + 1] = name
    end
    for i = 1, #names do
      self:removeComponent(id, names[i])
    end
  end
  self.entities[id] = nil
  self.entityComponents[id] = nil
  local freeIds = self.freeIds
  freeIds[#freeIds + 1] = id
  for _, query in pairs(self.queries) do
    if query.entities[id] then
      query.entities[id] = nil
      removeFromList(query.list, id)
    end
  end
  if self.app and self.app.events then
    self.app.events:emit('ecs:entityDestroyed', id)
  end
end

function World:registerComponent(name)
  if self.components[name] then
    return self.components[name]
  end
  local store = {
    data = {}
  }
  self.components[name] = store
  return store
end

function World:addComponent(entity, name, data)
  assert(self.entities[entity], 'Invalid entity id')
  local store = self:registerComponent(name)
  store.data[entity] = data or {}
  local entityComponents = self.entityComponents[entity]
  entityComponents[name] = true
  self:_syncQueriesAdd(entity, name)
  if self.app and self.app.events then
    self.app.events:emit('ecs:componentAdded', entity, name, data)
  end
  return data
end

function World:ensureComponent(entity, name, defaults)
  local store = self:registerComponent(name)
  local data = store.data[entity]
  if not data then
    if defaults then
      if type(defaults) == 'function' then
        data = defaults(entity)
      else
        if type(defaults) == 'table' then
          local copy = {}
          for k, v in pairs(defaults) do
            copy[k] = v
          end
          data = copy
        else
          data = defaults
        end
      end
    else
      data = {}
    end
    self:addComponent(entity, name, data)
  end
  return data
end

function World:getComponent(entity, name)
  local store = self.components[name]
  if not store then
    return nil
  end
  return store.data[entity]
end

function World:hasComponent(entity, name)
  local components = self.entityComponents[entity]
  return components and components[name] or false
end

function World:removeComponent(entity, name)
  local store = self.components[name]
  if not store or not store.data[entity] then
    return
  end
  store.data[entity] = nil
  local components = self.entityComponents[entity]
  if components then
    components[name] = nil
  end
  local queries = self.componentQueries[name]
  if queries then
    for i = 1, #queries do
      local query = queries[i]
      if query.entities[entity] then
        query.entities[entity] = nil
        removeFromList(query.list, entity)
      end
    end
  end
  if self.app and self.app.events then
    self.app.events:emit('ecs:componentRemoved', entity, name)
  end
end

function World:hasComponents(entity, components)
  local entityComponents = self.entityComponents[entity]
  if not entityComponents then
    return false
  end
  for i = 1, #components do
    if not entityComponents[components[i]] then
      return false
    end
  end
  return true
end

function World:_syncQueriesAdd(entity, componentName)
  local queries = self.componentQueries[componentName]
  if not queries then
    return
  end
  for i = 1, #queries do
    local query = queries[i]
    if not query.entities[entity] and self:hasComponents(entity, query.components) then
      query.entities[entity] = true
      query.list[#query.list + 1] = entity
      if query.onEntityAdded then
        query.onEntityAdded(entity)
      end
    end
  end
end

function World:_buildQuery(components)
  local signature, sorted = sortSignature(components)
  local existing = self.queries[signature]
  if existing then
    return existing
  end
  local query = {
    signature = signature,
    components = sorted,
    entities = {},
    list = {}
  }
  for entity in pairs(self.entities) do
    if self:hasComponents(entity, sorted) then
      query.entities[entity] = true
      query.list[#query.list + 1] = entity
    end
  end
  self.queries[signature] = query
  for i = 1, #sorted do
    local component = sorted[i]
    local map = self.componentQueries[component]
    if not map then
      map = {}
      self.componentQueries[component] = map
    end
    map[#map + 1] = query
  end
  return query
end

function World:getQuery(components)
  return self:_buildQuery(components)
end

function World:each(components, fn)
  local query = self:getQuery(components)
  local list = query.list
  local count = #components
  local scratch = {}
  for i = 1, #list do
    local entity = list[i]
    for c = 1, count do
      scratch[c] = self:getComponent(entity, components[c])
    end
    fn(entity, table.unpack(scratch, 1, count))
  end
end

local function sortSystems(systems, key)
  table.sort(systems, function(a, b)
    local orderA = a[key] or 0
    local orderB = b[key] or 0
    if orderA == orderB then
      return a.name < b.name
    end
    return orderA < orderB
  end)
end

function World:addSystem(system)
  assert(system.name, 'System requires name field')
  local name = system.name
  if self.systemByName[name] then
    error(('System "%s" already registered'):format(name))
  end
  system.world = self
  system.app = self.app
  self.systemByName[name] = system
  if system.init then
    system:init(self.app)
  end
  if system.update then
    local updateSystems = self.systems.update
    updateSystems[#updateSystems + 1] = system
    sortSystems(updateSystems, 'updateOrder')
  end
  if system.draw then
    local drawSystems = self.systems.draw
    drawSystems[#drawSystems + 1] = system
    sortSystems(drawSystems, 'drawOrder')
  end
end

function World:getSystem(name)
  return self.systemByName[name]
end

function World:setSystemEnabled(name, enabled)
  local system = self.systemByName[name]
  if system then
    system.enabled = enabled and true or false
  end
end

function World:update(dt)
  local systems = self.systems.update
  for i = 1, #systems do
    local system = systems[i]
    if system.enabled ~= false then
      system:update(dt)
    end
  end
end

function World:draw(pass)
  local systems = self.systems.draw
  for i = 1, #systems do
    local system = systems[i]
    if system.enabled ~= false then
      system:draw(pass)
    end
  end
end

return ECS
