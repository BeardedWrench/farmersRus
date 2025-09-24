local tool = {
  id = 'tool:harvest',
  label = 'Harvest Sickle',
  model = 'entities/tools/models/sickle.glb',
  sound = 'entities/tools/sfx/harvest.wav'
}

tool.inventory = {
  label = tool.label,
  model = tool.model,
  icon = {
    model = tool.model,
    distance = 3.4,
    cameraY = 0.35,
    targetY = 0.1,
    orientation = { pitch = -15, yaw = 25, roll = 0 }
  }
}

return tool
