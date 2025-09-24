-- icon_maker.lua
-- A standalone tool for posing item models and generating icon metadata.
--
-- Usage:
--  lovr icon_maker.lua --model path/to/model.gltf
--
-- Controls:
--  Left/Right: rotate model around Y axis (yaw)
--  Up/Down: adjust camera pitch
--  W/S: move the camera in/out (zoom)
--  Q/E: raise/lower camera height
--  A/D: raise/lower target height
--  Space: reset pose to defaults
--  Return: print a Lua table snippet with the current pose values
--
-- The printed snippet can be copied into an entity definition under an
-- `icon` field to control how the item is rendered in the inventory.  The tool
-- outputs the pose values in degrees for the orientation structure.

local lovr = require 'lovr'

local args = {...}

local modelPath = nil
for i = 1, #args do
  if args[i] == '--model' and args[i + 1] then
    modelPath = args[i + 1]
    break
  end
end

if not modelPath then
  print("Usage: lovr icon_maker.lua --model path/to/model.gltf")
  return function() end
end

local model

-- Pose parameters
local yaw = 0.0
local pitch = 0.0
local distance = 3.0
local cameraY = 1.0
local targetY = 1.0
local offsetX = 0.0
local offsetY = 0.0

-- Default values for reset
local defaults = {
  yaw = yaw,
  pitch = pitch,
  distance = distance,
  cameraY = cameraY,
  targetY = targetY,
  offsetX = offsetX,
  offsetY = offsetY
}

function lovr.load()
  model = lovr.graphics.newModel(modelPath)
  -- Center the model on the origin for better framing; assumes unit scaling
  if model.getBoundingBox then
    local min, max = model:getBoundingBox()
    local center = (min + max) / 2
    model:translate(-center.x, -center.y, -center.z)
  end
end

-- Handle key presses for adjustments
function lovr.update(dt)
  local speed = 1.0
  local slow = lovr.keyboard.isDown('lshift', 'rshift')
  local factor = slow and 0.5 or 1.0

  if lovr.keyboard.isDown('left') then yaw = yaw + speed * dt * factor end
  if lovr.keyboard.isDown('right') then yaw = yaw - speed * dt * factor end
  if lovr.keyboard.isDown('up') then pitch = math.max(-math.pi/2, pitch + speed * dt * factor) end
  if lovr.keyboard.isDown('down') then pitch = math.min(math.pi/2, pitch - speed * dt * factor) end
  if lovr.keyboard.isDown('w') then distance = math.max(0.5, distance - speed * dt * factor) end
  if lovr.keyboard.isDown('s') then distance = distance + speed * dt * factor end
  if lovr.keyboard.isDown('q') then cameraY = cameraY + speed * dt * factor end
  if lovr.keyboard.isDown('e') then cameraY = cameraY - speed * dt * factor end
  if lovr.keyboard.isDown('a') then targetY = targetY + speed * dt * factor end
  if lovr.keyboard.isDown('d') then targetY = targetY - speed * dt * factor end

  -- Reset pose to defaults
  if lovr.keyboard.wasPressed('space') then
    yaw = defaults.yaw
    pitch = defaults.pitch
    distance = defaults.distance
    cameraY = defaults.cameraY
    targetY = defaults.targetY
    offsetX = defaults.offsetX
    offsetY = defaults.offsetY
  end

  -- Print the snippet
  if lovr.keyboard.wasPressed('return') or lovr.keyboard.wasPressed('enter') then
    -- Convert radians to degrees for human-readable orientation values.  The game
    -- data uses degrees for the orientation fields in the `icon` table.
    local yawDeg = math.deg(yaw)
    local pitchDeg = math.deg(pitch)
    -- Build a snippet matching the Farmer's Rus metadata structure.  Include
    -- the model path so the snippet can be pasted directly into the entity
    -- definition.
    local snippet = string.format(
      "icon = {\n  model = '%s',\n  distance = %.3f,\n  cameraY = %.3f,\n  targetY = %.3f,\n  orientation = { pitch = %.3f, yaw = %.3f, roll = 0 }\n}",
      modelPath, distance, cameraY, targetY, pitchDeg, yawDeg
    )
    print("Copy the following snippet into your item definition:")
    print(snippet)
  end
end

-- Render the model from the current pose
function lovr.draw(pass)
  if not model then return end

  -- Setup perspective; using 70° FOV and 1:1 aspect ratio
  pass:setProjection(1, lovr.math.newMat4():perspective(math.rad(70), 1.0, 0.01, 100.0))

  -- Compute camera position
  local cx = offsetX + distance * math.sin(yaw) * math.cos(pitch)
  local cy = cameraY
  local cz = offsetY + distance * math.cos(yaw) * math.cos(pitch)

  local tx = offsetX
  local ty = targetY
  local tz = offsetY

  local up = lovr.math.newVec3(0, 1, 0)
  local eye = lovr.math.newVec3(cx, cy, cz)
  local target = lovr.math.newVec3(tx, ty, tz)
  pass:setViewMatrix(1, lovr.math.newMat4():lookAt(eye, target, up))

  -- Draw coordinate axes for reference
  pass:line(0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0) -- X axis red
  pass:line(0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 1) -- Y axis green
  pass:line(0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0) -- Z axis blue

  pass:draw(model)

  -- Display instructions and current values on screen
  local yPosition = 0.8
  local function drawText(label, value)
    pass:text(label .. tostring(value), -0.95, yPosition, -1.0, .03)
    yPosition = yPosition - .05
  end
  drawText("Yaw: ", yaw)
  drawText("Pitch: ", pitch)
  drawText("Distance: ", distance)
  drawText("CameraY: ", cameraY)
  drawText("TargetY: ", targetY)
end

-- Provide keyboard.wasPressed for single press detection
local pressed = {}
function lovr.keypressed(key)
  pressed[key] = true
end
function lovr.keyboard.wasPressed(key)
  if pressed[key] then
    pressed[key] = false
    return true
  end
  return false
end
