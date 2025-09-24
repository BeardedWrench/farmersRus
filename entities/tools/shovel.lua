local tool = {
  id = 'tool:shovel',
  label = 'Shovel',
  model = 'entities/tools/models/shovel.glb',
  sound = 'entities/tools/sfx/shovel_dig.wav'
}

tool.inventory = {
  label = tool.label,
  model = tool.model,
  icon = {
    model = tool.model,
    distance = 3.2,
    cameraY = 0.35,
    targetY = 0.1,
    orientation = { pitch = -20, yaw = 40, roll = 0 }
  }
}

return tool
