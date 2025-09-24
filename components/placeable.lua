local Placeable = {}

function Placeable.create(props)
  props = props or {}
  return {
    size = props.size or { 1, 1 },
    category = props.category or 'structure',
    cost = props.cost or 0,
    requiresTilled = props.requiresTilled or false,
    requiresEmpty = props.requiresEmpty ~= false,
    allowOverlap = props.allowOverlap or false,
    previewColor = props.previewColor or { 0, 1, 0, 0.4 }
  }
end

return Placeable
