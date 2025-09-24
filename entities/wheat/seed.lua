local seed = {
  id = 'seed:wheat',
  label = 'Wheat Seeds'
}

seed.inventory = {
  label = seed.label,
  model = 'entities/tools/models/seed_bag.glb',
  icon = {
    model = 'entities/tools/models/seed_bag.glb',
    distance = 2.8,
    cameraY = 0.55,
    targetY = 0.2,
    orientation = { pitch = -10, yaw = 15, roll = 0 }
  }
}

return seed
