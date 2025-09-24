local Compost = {}

function Compost.create(props)
  props = props or {}
  return {
    input = props.input or {},
    progress = props.progress or 0,
    required = props.required or 30,
    ready = props.ready or false
  }
end

return Compost
