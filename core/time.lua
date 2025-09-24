local Time = {}
Time.__index = Time

function Time.new()
  local instance = {
    scale = 1.0,
    rawDt = 0,
    dt = 0,
    elapsed = 0,
    accumulators = {}
  }
  return setmetatable(instance, Time)
end

function Time:update(dt)
  self.rawDt = dt
  local scaled = dt * self.scale
  self.dt = scaled
  self.elapsed = self.elapsed + scaled
  for _, accumulator in pairs(self.accumulators) do
    accumulator.value = accumulator.value + scaled
  end
end

function Time:setScale(scale)
  self.scale = scale or 1.0
end

function Time:getScale()
  return self.scale
end

function Time:getDt()
  return self.dt
end

function Time:getElapsed()
  return self.elapsed
end

function Time:track(name)
  local acc = self.accumulators[name]
  if not acc then
    acc = { value = 0 }
    self.accumulators[name] = acc
  end
  return acc.value
end

function Time:tick(name, interval)
  local acc = self.accumulators[name]
  if not acc then
    acc = { value = 0 }
    self.accumulators[name] = acc
  end
  if acc.value >= interval then
    acc.value = acc.value - interval
    return true
  end
  return false
end

function Time:consume(name)
  local acc = self.accumulators[name]
  if not acc then
    return 0
  end
  local value = acc.value
  acc.value = 0
  return value
end

return Time
