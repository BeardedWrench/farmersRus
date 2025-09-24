local util = {}

function util.clamp(value, minValue, maxValue)
  if value < minValue then
    return minValue
  elseif value > maxValue then
    return maxValue
  end
  return value
end

function util.lerp(a, b, t)
  return a + (b - a) * t
end

function util.round(value)
  if value >= 0 then
    return math.floor(value + 0.5)
  else
    return math.ceil(value - 0.5)
  end
end

function util.remap(value, inMin, inMax, outMin, outMax)
  if inMax - inMin == 0 then
    return outMin
  end
  local t = (value - inMin) / (inMax - inMin)
  return outMin + (outMax - outMin) * t
end

function util.shallowCopy(source)
  local copy = {}
  for k, v in pairs(source) do
    copy[k] = v
  end
  return copy
end

function util.deepCopy(source)
  local copy = {}
  for k, v in pairs(source) do
    if type(v) == 'table' then
      copy[k] = util.deepCopy(v)
    else
      copy[k] = v
    end
  end
  return copy
end

function util.merge(target, source)
  for k, v in pairs(source) do
    target[k] = v
  end
  return target
end

function util.sign(value)
  if value > 0 then
    return 1
  elseif value < 0 then
    return -1
  end
  return 0
end

function util.vec3(x, y, z)
  return { x or 0, y or 0, z or 0 }
end

function util.rayPlane(origin, direction, planePoint, planeNormal)
  local denom = planeNormal[1] * direction[1] + planeNormal[2] * direction[2] + planeNormal[3] * direction[3]
  if math.abs(denom) < 1e-6 then
    return nil
  end
  local diff = {
    planePoint[1] - origin[1],
    planePoint[2] - origin[2],
    planePoint[3] - origin[3]
  }
  local t = (diff[1] * planeNormal[1] + diff[2] * planeNormal[2] + diff[3] * planeNormal[3]) / denom
  if t < 0 then
    return nil
  end
  return {
    origin[1] + direction[1] * t,
    origin[2] + direction[2] * t,
    origin[3] + direction[3] * t
  }, t
end

function util.worldToGrid(x, z, cellSize)
  local size = cellSize or 1
  local gx = math.floor((x + size * 0.5) / size)
  local gz = math.floor((z + size * 0.5) / size)
  return gx, gz
end

function util.gridToWorld(gx, gz, cellSize, y)
  local size = cellSize or 1
  return gx * size, y or 0, gz * size
end

function util.snapToGrid(x, z, cellSize)
  local gx, gz = util.worldToGrid(x, z, cellSize)
  return util.gridToWorld(gx, gz, cellSize)
end

function util.colorLerp(a, b, t)
  return {
    util.lerp(a[1], b[1], t),
    util.lerp(a[2], b[2], t),
    util.lerp(a[3], b[3], t),
    util.lerp(a[4] or 1, b[4] or 1, t)
  }
end

return util
