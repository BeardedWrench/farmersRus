local Transform = require 'components.transform'

local CAMERA_SETTINGS = {
  target = { 0, 0, 0 },
  yaw = math.pi * 0.25,
  pitch = math.rad(62),
  distance = 14,
  moveSpeed = 9
}

local function copyVec(vec)
  local result = {}
  for i = 1, #vec do
    result[i] = vec[i]
  end
  return result
end

return function(app)
  local input = app.input

  local camera = {
    target = copyVec(CAMERA_SETTINGS.target),
    position = { 0, 0, 0 },
    yaw = CAMERA_SETTINGS.yaw,
    pitch = CAMERA_SETTINGS.pitch,
    distance = CAMERA_SETTINGS.distance,
    moveSpeed = CAMERA_SETTINGS.moveSpeed
  }

  local function updatePosition()
    local cosPitch = math.cos(camera.pitch)
    local sinPitch = math.sin(camera.pitch)
    local sinYaw = math.sin(camera.yaw)
    local cosYaw = math.cos(camera.yaw)

    camera.position[1] = camera.target[1] + cosPitch * sinYaw * camera.distance
    camera.position[2] = camera.target[2] + sinPitch * camera.distance
    camera.position[3] = camera.target[3] + cosPitch * cosYaw * camera.distance
  end

  local function getForward()
    local fx = camera.target[1] - camera.position[1]
    local fy = camera.target[2] - camera.position[2]
    local fz = camera.target[3] - camera.position[3]
    local length = math.sqrt(fx * fx + fy * fy + fz * fz)
    if length == 0 then
      return 0, 0, -1
    end
    return fx / length, fy / length, fz / length
  end

  local function getRight()
    local fx, fy, fz = getForward()
    local rx = fy * 0 - fz * 1
    local ry = fz * 0 - fx * 0
    local rz = fx * 1 - fy * 0
    local length = math.sqrt(rx * rx + ry * ry + rz * rz)
    if length == 0 then
      return 1, 0, 0
    end
    return rx / length, ry / length, rz / length
  end

  updatePosition()
  app.camera = camera

  local system = {
    name = 'camera_system',
    updateOrder = -100
  }

  function system:init()
    local entity = app.ecs:createEntity()
    app.ecs:addComponent(entity, 'transform', Transform.create({
      position = copyVec(camera.position)
    }))
    camera.entity = entity
    self.eyeVec = lovr.math.newVec3()
    self.targetVec = lovr.math.newVec3()
    self.upVec = lovr.math.newVec3(0, 1, 0)
    self.poseMatrix = lovr.math.newMat4()
  end

  function system:update(dt)
    input:getMouseDelta()

    local moveX, moveZ = 0, 0
    if input:isDown('w') or input:isDown('up') then moveZ = moveZ + 1 end
    if input:isDown('s') or input:isDown('down') then moveZ = moveZ - 1 end
    if input:isDown('a') or input:isDown('left') then moveX = moveX - 1 end
    if input:isDown('d') or input:isDown('right') then moveX = moveX + 1 end

    if moveX ~= 0 or moveZ ~= 0 then
      local fx, _, fz = getForward()
      local rx, _, rz = getRight()
      local forwardLength = math.sqrt(fx * fx + fz * fz)
      if forwardLength < 1e-6 then
        fx, fz = 0, -1
      else
        fx, fz = fx / forwardLength, fz / forwardLength
      end
      local speed = camera.moveSpeed * dt
      local dirX = fx * moveZ + rx * moveX
      local dirZ = fz * moveZ + rz * moveX
      camera.target[1] = camera.target[1] + dirX * speed
      camera.target[3] = camera.target[3] + dirZ * speed
    end

    updatePosition()
  end

  function system:draw(pass)
    if not pass.setViewPose then
      return
    end
    self.eyeVec:set(camera.position[1], camera.position[2], camera.position[3])
    self.targetVec:set(camera.target[1], camera.target[2], camera.target[3])
    self.poseMatrix:identity():target(self.eyeVec, self.targetVec, self.upVec)
    pass:setViewPose(1, self.poseMatrix)
  end

  return system
end
