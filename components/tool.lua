local Tool = {}

function Tool.create(props)
  props = props or {}
  return {
    type = props.type or 'shovel',
    cooldown = props.cooldown or 0,
    ready = true
  }
end

return Tool
