local Anchor = {}

local defaults = {
  top_left = { x = 0.0, y = 0.0 },
  top_center = { x = 0.5, y = 0.0 },
  top_right = { x = 1.0, y = 0.0 },
  center_left = { x = 0.0, y = 0.5 },
  center = { x = 0.5, y = 0.5 },
  center_right = { x = 1.0, y = 0.5 },
  bottom_left = { x = 0.0, y = 1.0 },
  bottom_center = { x = 0.5, y = 1.0 },
  bottom_right = { x = 1.0, y = 1.0 }
}

local function clone(vec)
  return { x = vec.x, y = vec.y }
end

local function fromTable(value)
  if value.x or value.y then
    return { x = value.x or 0, y = value.y or 0 }
  end
  return { x = value[1] or 0, y = value[2] or 0 }
end

function Anchor.resolve(anchor)
  if type(anchor) == 'table' then
    return fromTable(anchor)
  end
  if type(anchor) == 'string' then
    local preset = defaults[anchor]
    if preset then
      return clone(preset)
    end
  end
  return clone(defaults.top_left)
end

return Anchor
