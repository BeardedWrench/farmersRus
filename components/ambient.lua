local Ambient = {}

function Ambient.create(props)
  props = props or {}
  return {
    kind = props.kind or 'prop'
  }
end

return Ambient
