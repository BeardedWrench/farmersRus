local Events = {}
Events.__index = Events

local unpack = table.unpack or _G.unpack

function Events.new()
  local instance = {
    listeners = {},
    queue = {},
    depth = 0
  }
  return setmetatable(instance, Events)
end

local function sortListeners(list)
  table.sort(list, function(a, b)
    if a.priority == b.priority then
      return a.id < b.id
    end
    return a.priority > b.priority
  end)
end

local nextListenerId = 0

function Events:on(name, handler, priority)
  assert(type(handler) == 'function', 'Event handler must be a function')
  local listeners = self.listeners[name]
  if not listeners then
    listeners = {}
    self.listeners[name] = listeners
  end
  nextListenerId = nextListenerId + 1
  local record = {
    id = nextListenerId,
    handler = handler,
    priority = priority or 0
  }
  listeners[#listeners + 1] = record
  sortListeners(listeners)
  return record.id
end

function Events:off(name, token)
  local listeners = self.listeners[name]
  if not listeners then
    return
  end
  for i = 1, #listeners do
    if listeners[i].id == token then
      table.remove(listeners, i)
      return
    end
  end
end

function Events:emit(name, ...)
  local queue = self.queue
  queue[#queue + 1] = { name = name, args = { ... } }
end

function Events:dispatch(name, ...)
  local listeners = self.listeners[name]
  if not listeners then
    return
  end
  self.depth = self.depth + 1
  for i = 1, #listeners do
    listeners[i].handler(...)
  end
  self.depth = self.depth - 1
end

function Events:flush()
  local queue = self.queue
  if #queue == 0 then
    return
  end
  local i = 1
  while i <= #queue do
    local item = queue[i]
    self:dispatch(item.name, unpack(item.args))
    i = i + 1
  end
  for j = 1, #queue do
    queue[j] = nil
  end
end

return Events
