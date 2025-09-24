return {
  id = 'corn',
  sellPrice = 6,
  stages = {
    { model = 'entities/corn/models/stage_1.glb', time = 12, sockets = {} },
    { model = 'entities/corn/models/stage_2.glb', time = 18, sockets = {} },
    { model = 'entities/corn/models/stage_3.glb', time = 24, sockets = {} },
    { model = 'entities/corn/models/stage_4.glb', time = 30, sockets = { 'Socket_CornA', 'Socket_CornB' } }
  },
  fruit = {
    model = 'entities/corn/models/fruit_cob.glb',
    itemId = 'crop:corn',
    count = 2
  }
}
