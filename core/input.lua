local Input = {}
Input.__index = Input

function Input.new()
  local instance = {
    dt = 0,
    keysDown = {},
    keysPressed = {},
    keysReleased = {},
    mouse = {
      x = 0,
      y = 0,
      dx = 0,
      dy = 0,
      buttonsDown = {},
      buttonsPressed = {},
      buttonsReleased = {},
      wheelDx = 0,
      wheelDy = 0
    }
  }
  return setmetatable(instance, Input)
end

function Input:beginFrame(dt)
  self.dt = dt or 0
end

local function clearTable(t)
  for k in pairs(t) do
    t[k] = nil
  end
end

function Input:endFrame()
  clearTable(self.keysPressed)
  clearTable(self.keysReleased)
  local mouse = self.mouse
  mouse.dx = 0
  mouse.dy = 0
  clearTable(mouse.buttonsPressed)
  clearTable(mouse.buttonsReleased)
  mouse.wheelDx = 0
  mouse.wheelDy = 0
end

function Input:keypressed(key)
  self.keysDown[key] = true
  self.keysPressed[key] = true
end

function Input:keyreleased(key)
  self.keysDown[key] = nil
  self.keysReleased[key] = true
end

function Input:mousepressed(x, y, button)
  local mouse = self.mouse
  mouse.x = x
  mouse.y = y
  mouse.buttonsDown[button] = true
  mouse.buttonsPressed[button] = true
end

function Input:mousereleased(x, y, button)
  local mouse = self.mouse
  mouse.x = x
  mouse.y = y
  mouse.buttonsDown[button] = nil
  mouse.buttonsReleased[button] = true
end

function Input:mousemoved(x, y, dx, dy)
  local mouse = self.mouse
  mouse.x = x
  mouse.y = y
  mouse.dx = (mouse.dx or 0) + dx
  mouse.dy = (mouse.dy or 0) + dy
end

function Input:wheelmoved(dx, dy)
  local mouse = self.mouse
  mouse.wheelDx = (mouse.wheelDx or 0) + dx
  mouse.wheelDy = (mouse.wheelDy or 0) + dy
end

function Input:isDown(key)
  return self.keysDown[key] == true
end

function Input:pressed(key)
  return self.keysPressed[key] == true
end

function Input:released(key)
  return self.keysReleased[key] == true
end

function Input:mouseDown(button)
  return self.mouse.buttonsDown[button] == true
end

function Input:mousePressed(button)
  return self.mouse.buttonsPressed[button] == true
end

function Input:mouseReleased(button)
  return self.mouse.buttonsReleased[button] == true
end

function Input:getMousePosition()
  return self.mouse.x, self.mouse.y
end

function Input:getMouseDelta()
  return self.mouse.dx, self.mouse.dy
end

function Input:getWheel()
  return self.mouse.wheelDx, self.mouse.wheelDy
end

return Input
