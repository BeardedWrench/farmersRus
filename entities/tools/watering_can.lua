local tool = {
  id = 'tool:watering',
  label = 'Watering Can',
  model = 'entities/tools/models/watering_can.glb',
  sound = 'entities/tools/sfx/water_pour.wav'
}

tool.inventory = {
  label = tool.label,
  model = tool.model,
  icon = {
    model = tool.model,
    distance = 3.0,
    cameraY = 0.45,
    targetY = 0.05,
    orientation = { pitch = -25, yaw = 30, roll = 0 }
  }
}

return tool
