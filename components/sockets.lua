local Sockets = {}

function Sockets.create()
  return {
    attachments = {},
    dirty = true
  }
end

function Sockets.attach(component, socketName, entityId)
  component.attachments[socketName] = entityId
  component.dirty = true
end

function Sockets.detach(component, socketName)
  local id = component.attachments[socketName]
  component.attachments[socketName] = nil
  component.dirty = true
  return id
end

return Sockets
