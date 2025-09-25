local M = {}

local pressed = {}
local wheelY = 0

function M.keypressed(key) pressed[key] = true end
function M.wasPressed(key)
  if pressed[key] then pressed[key] = nil; return true end
  return false
end

function M.wheelmoved(_, dy) wheelY = wheelY + (dy or 0) end
function M.consumeWheelY() local y = wheelY; wheelY = 0; return y end

function M.isDown(key)
  if lovr.keyboard and lovr.keyboard.isDown then return lovr.keyboard.isDown(key) end
  if lovr.system   and lovr.system.isKeyDown then return lovr.system.isKeyDown(key) end
  return false
end

return M