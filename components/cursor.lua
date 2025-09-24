local Cursor = {}

function Cursor.create(props)
  props = props or {}
  return {
    cellX = props.cellX or 0,
    cellY = props.cellY or 0,
    worldHit = props.worldHit or { 0, 0, 0 },
    state = props.state or 'invalid',
    tool = props.tool or 'shovel',
    previewModel = props.previewModel,
    previewColor = props.previewColor or { 1, 0, 0, 0.4 }
  }
end

return Cursor
