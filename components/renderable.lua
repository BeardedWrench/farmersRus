local Renderable = {}

function Renderable.create(props)
  props = props or {}
  return {
    model = props.model,
    tint = props.tint or { 1, 1, 1, 1 },
    material = props.material,
    primitive = props.primitive or 'box',
    visible = props.visible ~= false,
    emissive = props.emissive or 0,
    roughness = props.roughness or 0.8,
    size = props.size
  }
end

return Renderable
