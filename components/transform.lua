local Transform = {}

function Transform.create(props)
  props = props or {}
  return {
    position = props.position or { 0, 0, 0 },
    rotation = props.rotation or { 0, 0, 0, 1 },
    scale = props.scale or { 1, 1, 1 }
  }
end

function Transform.setPosition(component, x, y, z)
  component.position[1] = x
  component.position[2] = y
  component.position[3] = z
end

function Transform.setScale(component, x, y, z)
  component.scale[1] = x
  component.scale[2] = y
  component.scale[3] = z
end

return Transform
