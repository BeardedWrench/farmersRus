local GridCell = {}

function GridCell.create(props)
  props = props or {}
  return {
    x = props.x or 0,
    y = props.y or 0,
    occupied = props.occupied or false,
    blocking = props.blocking or false,
    highlight = props.highlight or 'none'
  }
end

return GridCell
