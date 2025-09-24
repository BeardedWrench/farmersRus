-- icon_maker.lua
--
-- A standalone tool for posing item models and generating icon metadata.
-- This version integrates a simple UI with sliders and live preview so you can
-- visualise how the icon will look inside a slot.  The tool relies on the
-- existing `ui/icon_renderer` module to render the model into a 2D texture,
-- matching the behaviour of the in‑game inventory.  It uses plain LÖVR
-- primitives to draw sliders and text; if you wish to replace these with
-- custom UI widgets from your framework, the slider definitions and
-- interaction code can be adapted accordingly.
--
-- Usage:
--   lovr tools/icon_maker.lua --model path/to/model.glb
--
-- The script accepts both `.glb` and `.gltf` files.  You may also omit the
-- `--model` flag and supply a single argument containing the path to the
-- model.  If no model is provided or loading fails, the preview will be
-- blank and a usage message will print to the console.
--
-- Controls:
--   • Use the sliders at the bottom of the window to adjust the yaw, pitch,
--     distance, camera height and target height.  Click and drag the knob
--     horizontally to change the value, or click anywhere on the track to
--     jump.  Values update live in the preview.
--   • Press Space to reset all parameters to their defaults.
--   • Press Return/Enter to print a Lua table snippet that you can copy
--     directly into your entity definition under the `icon` field.
--
-- The snippet includes the model path, distance, cameraY, targetY and an
-- orientation table containing pitch and yaw in degrees.  Roll is always
-- zero.  If you wish to include offsets or other parameters, you can add
-- them manually.

local lovr = require 'lovr'

-- Parse command line arguments.  LÖVR populates both the varargs (`...`)
-- and a global `arg` table (indexed from 0) with the passed arguments.
local args = {...}
local fallbackArgs = _G.arg or {}

local modelPath

-- Search through varargs for the --model flag and path
for i = 1, #args do
  if args[i] == '--model' and args[i + 1] then
    modelPath = args[i + 1]
    break
  end
end

-- If not found, search the global arg table.  This accounts for cases
-- where the script is invoked as `lovr script.lua /path/to/model.glb`.
if not modelPath and type(fallbackArgs) == 'table' then
  for i = 1, #fallbackArgs do
    if fallbackArgs[i] == '--model' and fallbackArgs[i + 1] then
      modelPath = fallbackArgs[i + 1]
      break
    end
  end
  -- If there is a single argument that looks like a model path, use it.
  if not modelPath then
    local extras = {}
    for i = 1, #fallbackArgs do
      local a = fallbackArgs[i]
      if type(a) == 'string' and a:sub(1, 2) ~= '--' then
        extras[#extras + 1] = a
      end
    end
    if #extras == 2 then
      local candidate = extras[2]
      if candidate:match('%.glb$') or candidate:match('%.gltf$') then
        modelPath = candidate
      end
    elseif #extras == 1 then
      local candidate = extras[1]
      if candidate:match('%.glb$') or candidate:match('%.gltf$') then
        modelPath = candidate
      end
    end
  end
end

-- If a model path still hasn't been found, print usage and exit gracefully.
if not modelPath then
  print('Usage: lovr tools/icon_maker.lua --model <path/to/model.glb or .gltf>')
  return function() end
end

-- Attempt to load the model when the script starts.  If loading fails, the
-- model variable remains nil and the preview will be blank.  We also try
-- loading the IconRenderer module from the repository; if unavailable, the
-- script still runs but the preview will not show the icon.
local model
local iconRenderer

-- Pose parameters (radians and units)
local yaw = 0.0
local pitch = 0.0
local distance = 3.0
local cameraY = 1.0
local targetY = 1.0

-- Slider interaction state
local sliders = {}
local activeSlider = nil

-- Reset defaults for the Space key
local defaults = {
  yaw = yaw,
  pitch = pitch,
  distance = distance,
  cameraY = cameraY,
  targetY = targetY
}

-- Build the slider definitions.  Each slider has a label, min/max range,
-- accessor functions to get/set the value in the correct units, and a
-- placeholder for its UI geometry (filled in each frame).  You can
-- adjust the ranges here if you find yourself needing more extreme
-- positions.
local sliderDefs = {
  {
    label = 'Yaw', min = -180, max = 180,
    get = function() return math.deg(yaw) end,
    set = function(v) yaw = math.rad(v) end
  },
  {
    label = 'Pitch', min = -90, max = 90,
    get = function() return math.deg(pitch) end,
    set = function(v) pitch = math.rad(v) end
  },
  {
    label = 'Distance', min = 0.5, max = 6,
    get = function() return distance end,
    set = function(v) distance = v end
  },
  {
    label = 'CameraY', min = 0, max = 4,
    get = function() return cameraY end,
    set = function(v) cameraY = v end
  },
  {
    label = 'TargetY', min = 0, max = 4,
    get = function() return targetY end,
    set = function(v) targetY = v end
  }
}

-- Utility to clamp a value between min and max
local function clamp(v, min, max)
  if v < min then return min elseif v > max then return max else return v end
end

function lovr.load()
  -- Load the model
  local ok
  ok, model = pcall(lovr.graphics.newModel, modelPath)
  if not ok then
    print('Failed to load model: ' .. tostring(modelPath))
    model = nil
  else
    -- Center the model for better framing
    if model.getBoundingBox then
      local min, max = model:getBoundingBox()
      local center = (min + max) / 2
      model:translate(-center.x, -center.y, -center.z)
    end
  end

  -- Try to require the icon renderer module.  We attempt both relative
  -- paths to accommodate running from inside and outside the repository root.
  local okRenderer
  okRenderer, iconRenderer = pcall(require, 'farmersRus-main/ui/icon_renderer')
  if not okRenderer then
    okRenderer, iconRenderer = pcall(require, 'ui/icon_renderer')
  end
  if okRenderer and iconRenderer then
    iconRenderer = iconRenderer.new(nil)
  else
    iconRenderer = nil
  end
end

-- Update function handles slider interactions and keyboard shortcuts.  We
-- compute slider geometries based on the window dimensions each frame so
-- detection works even when the window is resized.  Dragging is handled by
-- storing which slider is active when the mouse is pressed.
function lovr.update(dt)
  local width, height = lovr.graphics.getDimensions()
  width = width or 800
  height = height or 600

  -- Layout for sliders
  local sliderWidth = math.min(300, width * 0.5)
  local sliderHeight = 16
  local sliderSpacing = 40
  local startX = 20
  local startY = height - (#sliderDefs * sliderSpacing) - 20

  -- Update slider geometry and assign coordinates for interaction
  for i, def in ipairs(sliderDefs) do
    local x = startX
    local y = startY + (i - 1) * sliderSpacing
    def._px = x
    def._py = y
    def._pw = sliderWidth
    def._ph = sliderHeight
    def._knobRadius = 6
  end

  -- Handle mouse input for sliders
  local mx, my = lovr.mouse.getPosition()
  local mouseDown = lovr.mouse.isDown(1)

  -- Begin drag: if no slider is active and mouse just pressed
  if mouseDown and not activeSlider then
    for i, def in ipairs(sliderDefs) do
      local x, y, w, h = def._px, def._py, def._pw, def._ph
      -- Expand vertical hitbox slightly to make it easier to click
      local hitYMin = y - h
      local hitYMax = y + h
      if mx >= x and mx <= x + w and my >= hitYMin and my <= hitYMax then
        activeSlider = def
        break
      end
    end
  end

  -- During drag: update the active slider's value
  if mouseDown and activeSlider then
    local s = activeSlider
    local t = clamp((mx - s._px) / s._pw, 0.0, 1.0)
    local v = s.min + (s.max - s.min) * t
    s.set(v)
  end

  -- When the mouse button is released, clear the active slider
  if not mouseDown then
    activeSlider = nil
  end

  -- Keyboard shortcuts for quick adjustments and printing
  local speed = 1.0
  local slow = lovr.keyboard.isDown('lshift', 'rshift')
  local factor = slow and 0.5 or 1.0

  if lovr.keyboard.isDown('left') then yaw = yaw + speed * dt * factor end
  if lovr.keyboard.isDown('right') then yaw = yaw - speed * dt * factor end
  if lovr.keyboard.isDown('up') then pitch = clamp(pitch + speed * dt * factor, -math.pi/2, math.pi/2) end
  if lovr.keyboard.isDown('down') then pitch = clamp(pitch - speed * dt * factor, -math.pi/2, math.pi/2) end
  if lovr.keyboard.isDown('w') then distance = clamp(distance - speed * dt * factor, 0.2, 10) end
  if lovr.keyboard.isDown('s') then distance = distance + speed * dt * factor end
  if lovr.keyboard.isDown('q') then cameraY = cameraY + speed * dt * factor end
  if lovr.keyboard.isDown('e') then cameraY = cameraY - speed * dt * factor end
  if lovr.keyboard.isDown('a') then targetY = targetY + speed * dt * factor end
  if lovr.keyboard.isDown('d') then targetY = targetY - speed * dt * factor end

  -- Reset all parameters to their defaults
  if lovr.keyboard.wasPressed('space') then
    yaw = defaults.yaw
    pitch = defaults.pitch
    distance = defaults.distance
    cameraY = defaults.cameraY
    targetY = defaults.targetY
  end

  -- Print snippet on Return/Enter
  if lovr.keyboard.wasPressed('return') or lovr.keyboard.wasPressed('enter') then
    local snippet = string.format(
      "icon = {\n  model = '%s',\n  distance = %.3f,\n  cameraY = %.3f,\n  targetY = %.3f,\n  orientation = { pitch = %.3f, yaw = %.3f, roll = 0 }\n}",
      modelPath, distance, cameraY, targetY, math.deg(pitch), math.deg(yaw)
    )
    print('Copy the following snippet into your item definition:')
    print(snippet)
  end
end

-- Draw the preview, sliders and instructions.  We build the icon
-- descriptor each frame using the current pose values and ask the
-- IconRenderer for a texture.  When no renderer is available, we
-- simply display the axes and model in a perspective view (as a fallback).
function lovr.draw(pass)
  local width, height = lovr.graphics.getDimensions()
  width = width or 800
  height = height or 600

  -- Clear to a dark neutral colour
  pass:setColor(0.12, 0.14, 0.18, 1)
  pass:clear()

  -- Determine slot preview area (centered horizontally, placed toward the top)
  local slotSize = 128
  local slotX = (width - slotSize) * 0.5
  local slotY = height * 0.2

  -- Render icon if we have a renderer and model; otherwise, skip
  local iconMaterial
  if iconRenderer and model then
    local descriptor = {
      model = modelPath,
      iconSize = slotSize,
      distance = distance,
      cameraY = cameraY,
      targetY = targetY,
      orientation = { pitch = math.deg(pitch), yaw = math.deg(yaw), roll = 0 },
      offset = { 0, 0, 0 }
    }
    local icon = iconRenderer:getIcon('__preview__', descriptor)
    if icon and icon.material then
      iconMaterial = icon.material
    end
  end

  -- Draw slot background and outline (approximate theme colours)
  pass:setColor(0.2, 0.21, 0.27, 0.92)
  pass:plane(slotX + slotSize * 0.5, slotY + slotSize * 0.5, 0, slotSize, slotSize)
  pass:setColor(1, 1, 1, 0.1)
  pass:line(slotX, slotY, 0, slotX + slotSize, slotY, 0)
  pass:line(slotX + slotSize, slotY, 0, slotX + slotSize, slotY + slotSize, 0)
  pass:line(slotX + slotSize, slotY + slotSize, 0, slotX, slotY + slotSize, 0)
  pass:line(slotX, slotY + slotSize, 0, slotX, slotY, 0)
  pass:setColor(1, 1, 1, 1)

  -- Draw the rendered icon inside the slot
  if iconMaterial then
    pass:setMaterial(iconMaterial)
    pass:plane(slotX + slotSize * 0.5, slotY + slotSize * 0.5, 0.001, slotSize - 20, slotSize - 20)
    pass:setMaterial()
  elseif model then
    -- Fallback: draw the model in a 3D perspective view if iconRenderer is missing
    -- Setup projection
    pass:setProjection(1, lovr.math.newMat4():perspective(math.rad(70), 1.0, 0.01, 100.0))
    -- Camera position
    local cx = distance * math.sin(yaw) * math.cos(pitch)
    local cy = cameraY
    local cz = distance * math.cos(yaw) * math.cos(pitch)
    local eye = lovr.math.newVec3(cx, cy, cz)
    local target = lovr.math.newVec3(0, targetY, 0)
    local up = lovr.math.newVec3(0, 1, 0)
    pass:setViewMatrix(1, lovr.math.newMat4():lookAt(eye, target, up))
    -- Draw axes for reference
    pass:line(0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0)
    pass:line(0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 1)
    pass:line(0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0)
    pass:draw(model)
  end

  -- Draw sliders and labels.  We recompute geometry inside update, so we can
  -- rely on the fields `_px`, `_py`, `_pw` and `_ph` being up‑to‑date.
  local function drawSlider(def)
    local x, y, w, h = def._px, def._py, def._pw, def._ph
    -- Background track
    pass:setColor(0.25, 0.27, 0.32, 1)
    pass:line(x, y, 0, x + w, y, 0)
    -- Knob position ratio
    local t = (def.get() - def.min) / (def.max - def.min)
    local knobX = x + w * t
    -- Draw knob as a small circle using a plane (approximate)
    local r = 6
    pass:setColor(0.8, 0.82, 0.86, 1)
    pass:circle(knobX, y, 0.002, r)
    -- Label and value text
    local textScale = 14 / height
    pass:setColor(1, 1, 1, 1)
    pass:text(def.label .. ':', x - 70, y - 5, 0, textScale)
    pass:text(string.format('%.2f', def.get()), x + w + 10, y - 5, 0, textScale)
  end
  for i, def in ipairs(sliderDefs) do
    drawSlider(def)
  end

  -- Draw instructions at the bottom
  local instrScale = 12 / height
  pass:text('Click and drag sliders or use arrow/WASD/QE keys.  Space resets.  Enter copies snippet.', 20, 10, 0, instrScale)
end

-- Single key press detection helper
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
