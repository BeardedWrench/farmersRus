local Crop = {}

function Crop.create(props)
  props = props or {}
  return {
    id = props.id or 'unknown',
    stage = props.stage or 1,
    progress = props.progress or 0,
    stats = props.stats or {
      growth = props.growthSpeed or 1.0,
      hydration = props.hydration or 1.0,
      health = props.health or 1.0,
      fertilizer = props.fertilizer or 0
    },
    hydrated = props.hydrated or false,
    ready = props.ready or false
  }
end

return Crop
