-- tools/icon_maker/main.lua
-- Baseline: model-centric posing (no camera orbit), grid move, wheel zoom, in-place rotation, visible HUD.

local input = require 'tools.icon_maker.input'

-- Big, crisp HUD font (cached). No API reads elsewhere.
local _hud = { font = nil, px = nil }

local function ensureHudFont(px)
  px = px or 64            -- ← crank this up if you still want larger text
  if not _hud.font or _hud.px ~= px then
    _hud.font = lovr.graphics.newFont(px)
    _hud.px = px
  end
  return _hud.font
end

-- Picks a readable on-screen text height in pixels based on window height.
local function computeHudScalePx(h)
  -- ~3.2% of screen height, clamped to sane bounds
  local px = math.floor(h * 0.032 + 0.5)
  if px < 16 then px = 16 elseif px > 40 then px = 40 end
  return px
end

-- Approximate pixel width of a line at 'px' height (no font APIs needed).
local function approxTextWidthPx(s, px)
  -- avg glyph width ~ 0.56 * px; tweak if your font looks tighter/looser
  return math.floor(#s * px * 0.56 + 0.5)
end

-- Pick a pixel height that fits both screen height and available width.
local function pickHudSizeToFit(w, h, lines)
  local pad = math.max(12, math.floor(h * 0.02 + 0.5))   -- side/top padding in px
  local px  = math.floor(h * 0.032 + 0.5)                -- ~3.2% of screen height
  if px < 16 then px = 16 elseif px > 40 then px = 40 end

  local inner = w - pad * 2
  -- shrink px until the longest line fits inside the inner width
  while px > 10 do
    local longest = 0
    for _, s in ipairs(lines) do
      local lw = approxTextWidthPx(s, px)
      if lw > longest then longest = lw end
    end
    if longest <= inner then break end
    px = px - 1
  end
  return px, pad
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Config
-- ──────────────────────────────────────────────────────────────────────────────
local C = {
  fovDeg = 65, near = 0.05, far = 100.0,
  hudPx = 14,
  start = { distance = 3.0, x = 0.0, y = 1.0, yaw = 0.0, pitch = 0.0, roll = 0.0 },
  moveSpeed = 1.5,      -- units/sec (WASD: X/Y grid)
  rotSpeed  = 90.0,     -- deg/sec  (arrows)
  zoomStep  = 0.25,     -- m per wheel tick
  bounds    = { distance = { 0.25, 20.0 }, pitch = { -89.0, 89.0 } }
}

-- ──────────────────────────────────────────────────────────────────────────────
-- State
-- ──────────────────────────────────────────────────────────────────────────────
local model
local center = { x = 0, y = 0, z = 0 }   -- model geometric center (pivot)
local pose = { distance = C.start.distance, x = C.start.x, y = C.start.y, yaw = C.start.yaw, pitch = C.start.pitch, roll = C.start.roll }

-- ──────────────────────────────────────────────────────────────────────────────
-- Utilities (tiny, testable)
-- ──────────────────────────────────────────────────────────────────────────────
local function clamp(v, lo, hi) if v < lo then return lo elseif v > hi then return hi else return v end end

local function getWH()
  if lovr.system and lovr.system.getWindowDimensions then
    local w, h = lovr.system.getWindowDimensions(); if w and h then return w, h end
  end
  if lovr.graphics and lovr.graphics.getWidth and lovr.graphics.getHeight then
    local w, h = lovr.graphics.getWidth(), lovr.graphics.getHeight(); if w and h then return w, h end
  end
  if lovr.graphics and lovr.graphics.getDimensions then
    local w, h = lovr.graphics.getDimensions(); if w and h then return w, h end
  end
  return 1280, 720
end

local function parseModelPath()
  local a = _G.arg or {}
  for i = 1, #a do if a[i] == '--model' and a[i + 1] then return a[i + 1] end end
  for i = 1, #a do
    local s = a[i]
    if type(s) == 'string' and s:sub(1, 2) ~= '--' and (s:match('%.glb$') or s:match('%.gltf$')) then
      return s
    end
  end
  print('Usage: lovr tools/icon_maker/main.lua --model <path/to/model.glb|.gltf>')
  return nil
end

local function computeCenter(m)
  if m.getBoundingBox then
    local a,b,c,d,e,f = m:getBoundingBox()
    if type(a) == 'number' and type(d) == 'number' then
      return { x = (a + d) / 2, y = (b + e) / 2, z = (c + f) / 2 }
    elseif type(a) == 'table' and a.x and type(b) == 'table' and b.x then
      return { x = (a.x + b.x) / 2, y = (a.y + b.y) / 2, z = (a.z + b.z) / 2 }
    end
  end
  if m.getBounds then
    local minx,miny,minz,maxx,maxy,maxz = m:getBounds()
    if type(minx) == 'number' and type(maxx) == 'number' then
      return { x = (minx + maxx) / 2, y = (miny + maxy) / 2, z = (minz + maxz) / 2 }
    end
  end
  return { x = 0, y = 0, z = 0 }
end

local function resetPose()
  pose.distance = C.start.distance
  pose.x, pose.y = C.start.x, C.start.y
  pose.yaw, pose.pitch, pose.roll = C.start.yaw, C.start.pitch, C.start.roll
end

-- ──────────────────────────────────────────────────────────────────────────────
-- View/Projection helpers (keep camera pinned)
-- ──────────────────────────────────────────────────────────────────────────────
local function apply3DView(pass, w, h)
  local proj = lovr.math.newMat4():perspective(math.rad(C.fovDeg), w / h, C.near, C.far)
  pass:setProjection(1, proj)
  if pass.setViewPose then pass:setViewPose(1, 0, 0, 0, 0, 0, 0, 1) end -- identity view: no mouse orbit
end

local function applyHUDView(pass, w, h)
  -- Ortho: 1 unit == 1 pixel
  local ortho = lovr.math.newMat4():orthographic(0, w, h, 0, -1, 1)
  pass:setProjection(1, ortho)

  -- Pin camera & draw on top
  if pass.setViewPose  then pass:setViewPose(1, 0,0,0, 0,0,0,1) end
  if pass.setDepthTest then pass:setDepthTest(nil) end
  if pass.setCullMode  then pass:setCullMode(nil) end

  -- Use a large pixel font on this pass
  local font = ensureHudFont(16)  -- ← change to 80/96 if needed
  if pass.setFont then pass:setFont(font) end

  pass:setColor(1, 1, 1, 1)
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Transform builder (guarantees in-place rotation about model center)
-- math intent:  M = T(worldXY, -distanceZ) * R(yaw) * R(pitch) * R(roll) * T(-center)
-- (order written using LÖVR mat post-multiply mutators)
-- ──────────────────────────────────────────────────────────────────────────────
local function buildModelMatrix()
  local m = lovr.math.newMat4()
  -- world placement (X/Y grid, and Z purely from distance)
  m:translate(pose.x, pose.y, -pose.distance)
  -- rotations (natural feel): yaw L/R, pitch up/down, roll unused (kept for completeness)
  m:rotate(math.rad(pose.yaw),   0, 1, 0)
  m:rotate(math.rad(pose.pitch), 1, 0, 0)
  m:rotate(math.rad(pose.roll),  0, 0, 1)
  -- pivot to model center so rotations are about center, not corner/origin
  m:translate(-center.x, -center.y, -center.z)
  return m
end

-- ──────────────────────────────────────────────────────────────────────────────
-- HUD drawer
-- ──────────────────────────────────────────────────────────────────────────────
local function drawHUD(pass, w, h)
  applyHUDView(pass, w, h)

  -- fixed, readable size (no window autoscaling)
  local px   = 24          -- <-- bump to 32/36 if you want bigger
  local pad  = 16
  local gap  = 8
  local lineH = px + gap
  local windowWidth = lovr.system.getWindowWidth() 

  local lines = {
    string.format("dist: %.2f   pos: (x=%.2f, y=%.2f)   rot: (yaw=%.1f, pitch=%.1f, roll=%.1f)",
      pose.distance, pose.x, pose.y, pose.yaw, pose.pitch, pose.roll)
  }

  -- full-width top bar that contains all lines
  local barH = pad * 2 + lineH * #lines
  pass:setColor(0, 0, 0, 0.35)
  pass:plane(w * 0.5, barH * 0.5, 0, w, barH)
  pass:setColor(1, 1, 1, 1)

  -- left-align each line by placing the text's CENTER at (pad + width/2)
  local y = pad + px * 0.5
  for _, s in ipairs(lines) do
    local lw = approxTextWidthPx(s, px)
    -- local x  = pad + lw * 0.3              -- ← ensures left edge = pad
    pass:text(s, windowWidth / 2, y, 0, px)              -- scale = pixel height
    y = y + lineH
  end
end
-- ──────────────────────────────────────────────────────────────────────────────
-- Pose update (grid move, in-place rotation, zoom)
-- ──────────────────────────────────────────────────────────────────────────────
local function updatePose(dt)
  -- 2D grid on screen plane: A/D → X, W/S → Y
  local s = C.moveSpeed * dt
  if input.isDown('a') then pose.x = pose.x - s end
  if input.isDown('d') then pose.x = pose.x + s end
  if input.isDown('w') then pose.y = pose.y + s end
  if input.isDown('s') then pose.y = pose.y - s end

  -- rotation (natural): ← −yaw, → +yaw, ↑ tilt up (−pitch), ↓ tilt down (+pitch)
  local r = C.rotSpeed * dt
  if input.isDown('left')  then pose.yaw   = pose.yaw   - r end
  if input.isDown('right') then pose.yaw   = pose.yaw   + r end
  if input.isDown('up')    then pose.pitch = clamp(pose.pitch - r, C.bounds.pitch[1], C.bounds.pitch[2]) end
  if input.isDown('down')  then pose.pitch = clamp(pose.pitch + r, C.bounds.pitch[1], C.bounds.pitch[2]) end

  -- zoom: wheel adjusts camera distance only
  local dy = input.consumeWheelY()
  if dy ~= 0 then
    pose.distance = clamp(pose.distance - dy * C.zoomStep, C.bounds.distance[1], C.bounds.distance[2])
  end

  if input.wasPressed('space') then resetPose() end

  if input.wasPressed('return') or input.wasPressed('enter') then
    local snippet = string.format(
      "icon = {\n  distance = %.3f,\n  cameraY = %.3f,\n  targetY = %.3f,\n  orientation = { pitch = %.3f, yaw = %.3f, roll = %.3f },\n  offset = { x = %.3f, y = %.3f, z = %.3f }\n}",
      pose.distance, 1.0, pose.y, pose.pitch, pose.yaw, pose.roll, pose.x, 0.0, 0.0
    )
    print('\nCopy into your entity icon block:\n' .. snippet .. '\n')
  end
end

-- ──────────────────────────────────────────────────────────────────────────────
-- LÖVR callbacks
-- ──────────────────────────────────────────────────────────────────────────────
function lovr.load()
  local modelPath = parseModelPath(); if not modelPath then return end
  local ok, res = pcall(lovr.graphics.newModel, modelPath)
  if not ok then print('Failed to load model:', res); return end
  model = res
  center = computeCenter(model)
  lovr.graphics.setBackgroundColor(0.10, 0.11, 0.13)
end

function lovr.keypressed(key) input.keypressed(key) end
function lovr.wheelmoved(dx, dy) input.wheelmoved(dx, dy) end

function lovr.update(dt)
  updatePose(dt)
end

function lovr.draw(pass)
  if not model then return end
  local w, h = getWH()

  -- 3D
  apply3DView(pass, w, h)
  pass:setShader('normal')
  pass:draw(model, buildModelMatrix())
  pass:setShader()

  -- HUD
  drawHUD(pass, w, h)
end