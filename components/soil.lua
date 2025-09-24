local Soil = {}

function Soil.create(props)
  props = props or {}
  return {
    tilled = props.tilled or false,
    wetness = props.wetness or 0,
    darkenTimer = props.darkenTimer or 0,
    hydrationLoss = props.hydrationLoss or 0.02
  }
end

return Soil
