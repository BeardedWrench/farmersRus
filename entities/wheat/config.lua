return {
  id = 'wheat',
  sellPrice = 4,
  stages = {
    { model = 'entities/wheat/models/stage_1.glb', time = 10, sockets = {} },
    { model = 'entities/wheat/models/stage_2.glb', time = 16, sockets = {} },
    { model = 'entities/wheat/models/stage_3.glb', time = 20, sockets = {} },
    { model = 'entities/wheat/models/stage_4.glb', time = 24, sockets = { 'Socket_WheatA', 'Socket_WheatB', 'Socket_WheatC' } }
  },
  fruit = {
    model = 'entities/wheat/models/fruit_bundle.glb',
    itemId = 'crop:wheat',
    count = 3
  }
}
