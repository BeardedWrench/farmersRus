-- icon_maker.lua
-- A standalone tool for posing item models and generating icon metadata.
--
-- Usage:
--  lovr icon_maker.lua --model path/to/model.glb
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

-- Accept any file extension for the model.  If the --model flag is missing,
-- print usage and exit gracefully.  Note that LÖVR accepts both .glb and .gltf.
if not modelPath then
  print("Usage: lovr icon_maker.lua --model <path/to/model.glb or .gltf>")
  return function() end
end

local model
local iconRenderer

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
  -- Load the model.  If loading fails, the tool will fallback to showing nothing.
  local ok
  ok, model = pcall(lovr.graphics.newModel, modelPath)
  if not ok then
    print("Failed to load model at path: " .. tostring(modelPath))
    model = nil
  else
    -- Center the model on the origin for better framing; assumes unit scaling
    if model.getBoundingBox then
      local min, max = model:getBoundingBox()
      local center = (min + max) / 2
      model:translate(-center.x, -center.y, -center.z)
    end
  end

  -- Create an icon renderer for generating 2D icon previews.  The renderer
  -- comes from the game's UI module and expects an app table, which we omit.
  local okRenderer
  okRenderer, iconRenderer = pcall(require, 'farmersRus-main/ui/icon_renderer')
  if not okRenderer then
    -- Fallback: try requiring via relative path without the farmersRus-main prefix
    okRenderer, iconRenderer = pcall(require, 'ui/icon_renderer')
  end
  if not okRenderer then
    iconRenderer = nil
  else
    iconRenderer = iconRenderer.new(nil)
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
  -- Clear the background to the default UI color so the preview stands out.
  pass:setColor(0.12, 0.14, 0.18, 1)
  pass:clear()

  -- Compute an icon preview if the renderer and model are available.  We call
  -- IconRenderer:renderModelIcon each frame with the current pose to get a
  -- material containing a texture of the model rendered at the given
  -- orientation and camera settings.  We then draw that texture inside a
  -- slot-sized panel so you can see exactly how the icon will appear in the
  -- game inventory UI.
  local iconSize = 128
  local iconMaterial = nil
  if iconRenderer and model then
    local descriptor = {
      model = modelPath,
      iconSize = iconSize,
      distance = distance,
      cameraY = cameraY,
      targetY = targetY,
      orientation = { pitch = math.deg(pitch), yaw = math.deg(yaw), roll = 0 },
      offset = { offsetX or 0, offsetY or 0, 0 }
    }
    local icon = iconRenderer:getIcon('__preview__', descriptor)
    if icon and icon.material then
      iconMaterial = icon.material
    end
  end

  -- Determine window dimensions; fallback to 800x600 if unavailable.
  local width, height = lovr.graphics.getDimensions()
  width = width or 800
  height = height or 600

  -- Draw a panel for the preview.  We mimic the slot background and border
  -- colors from the theme to provide an accurate preview.  The slot will be
  -- centered in the window.
  local slotSize = 128
  local slotX = (width - slotSize) * 0.5
  local slotY = (height - slotSize) * 0.5
  -- Background
  pass:setColor(0.2, 0.21, 0.27, 0.92) -- Theme.palette.slotBackground
  pass:plane(slotX + slotSize * 0.5, slotY + slotSize * 0.5, 0, slotSize, slotSize)
  -- Border
  pass:setColor(1, 1, 1, 0.1) -- Theme.palette.slotOutline
  pass:line(slotX, slotY, 0, slotX + slotSize, slotY, 0)
  pass:line(slotX + slotSize, slotY, 0, slotX + slotSize, slotY + slotSize, 0)
  pass:line(slotX + slotSize, slotY + slotSize, 0, slotX, slotY + slotSize, 0)
  pass:line(slotX, slotY + slotSize, 0, slotX, slotY, 0)
  pass:setColor(1, 1, 1, 1)

  -- Draw the icon texture into the slot if available.
  if iconMaterial then
    pass:setMaterial(iconMaterial)
    pass:plane(slotX + slotSize * 0.5, slotY + slotSize * 0.5, 0.001, slotSize - 20, slotSize - 20)
    pass:setMaterial()
  end

  -- Draw parameter labels and values below the preview for reference.  These
  -- update live as you adjust the pose.  We use an orthographic projection
  -- here since we're drawing flat UI elements.
  local textScale = 24 / height
  local baseY = slotY - 50
  local function drawText(label, value)
    pass:text(label .. string.format("%.2f", value), 10, baseY, 0, textScale)
    baseY = baseY - 24
  end
  pass:text("Controls: ←/→ yaw, ↑/↓ pitch, W/S zoom, Q/E cameraY, A/D targetY, Space reset, Enter copy", 10, height - 30, 0, textScale)
  drawText("Yaw: ", math.deg(yaw))
  drawText("Pitch: ", math.deg(pitch))
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
