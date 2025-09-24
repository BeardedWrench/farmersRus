local tool = {
  id = 'tool:seed',
  label = 'Seed Bag',
  model = 'entities/tools/models/seed_bag.glb',
  sound = 'assets/sfx/ui_click.wav'
}

tool.inventory = {
  label = tool.label,
  model = tool.model,
  icon = {
    model = tool.model,
    distance = 2.8,
    cameraY = 0.5,
    targetY = 0.15,
    orientation = { pitch = -15, yaw = 20, roll = 0 }
  }
}

return tool
