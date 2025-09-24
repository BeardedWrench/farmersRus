print('[DEBUG] main chunk start')
local ECS = require 'core.ecs'
local Events = require 'core.events'
local Time = require 'core.time'
local Util = require 'core.util'
local Input = require 'core.input'
local Resources = require 'core.resources'
local SceneManager = require 'scene.manager'
local Save = require 'io.save'
local Log = require 'core.log'

local app

local function loadSystems()
  local factories = {
    require 'systems.camera_system',
    require 'systems.grid_system',
    require 'systems.placement_system',
    require 'systems.tool_system',
    require 'systems.crop_growth_system',
    require 'systems.hydration_system',
    require 'systems.fertility_system',
    require 'systems.harvest_system',
    require 'systems.inventory_system',
    require 'systems.economy_system',
    require 'systems.audio_system',
    require 'systems.ui_system',
    require 'systems.scene_system',
    require 'systems.save_system',
    require 'systems.render_system',
    require 'systems.fx_system'
  }

  for _, factory in ipairs(factories) do
    local system = factory(app)
    if system then
      if app.log then
        app.log:info(('Registering system %s'):format(system.name or tostring(system)))
      end
      app.ecs:addSystem(system)
    else
      if app.log then
        app.log:error('System factory returned nil')
      end
    end
  end
end

local function loadScenes()
  local farmScene = require 'scene.farm'
  local townScene = require 'scene.town'

  app.scenes:register('farm', farmScene)
  app.scenes:register('town', townScene)
end

local function loadGameplay()
  local starter = require 'gameplay.starter_pack'
  app.gameplay = {
    crops = require 'gameplay.crops_db',
    shops = require 'gameplay.shop_db',
    balance = require 'gameplay.balance',
    starter = starter
  }
end

function lovr.load(args)
  print('[DEBUG] lovr.load start')
  lovr.graphics.setBackgroundColor(0.62, 0.78, 0.94)
  print('[DEBUG] save dir', lovr.filesystem.getSaveDirectory())
  app = {
    events = Events.new(),
    time = Time.new(),
    util = Util,
    input = Input.new(),
    resources = Resources.new(),
    ecs = ECS.new(),
    scenes = SceneManager.new(),
    args = args,
    log = Log.new('boot.log')
  }

  app.log:info('Binding subsystems')
  app.ecs:bind(app)
  app.resources:bind(app)
  app.scenes:bind(app)
  app.log:info('Preloading global assets')
  app.resources:preloadGlobal()
  app.log:info('Loading gameplay database')
  loadGameplay()
  app.log:info('Registering scenes')
  loadScenes()
  app.log:info('Registering systems')
  loadSystems()
  app.log:info('Activating farm scene')
  app.scenes:activate('farm')

  local saveData = Save.tryLoad()
  if saveData then
    app.log:info('Save file detected, emitting load event')
    app.events:emit('save:load', saveData)
  end
  app.events:emit('game:start')
  app.events:flush()
  if app.log then app.log:info('Startup sequence complete') end
  print('[DEBUG] lovr.load end')
end

function lovr.update(dt)
  if not app then
    return
  end

  app.time:update(dt)
  app.input:beginFrame(app.time:getDt())
  app.scenes:update(app.time:getDt())
  app.ecs:update(app.time:getDt())
  app.events:flush()
  app.input:endFrame()
end

function lovr.draw(pass)
  if not app then
    return
  end

  app.scenes:draw(pass)
  app.ecs:draw(pass)
end

function lovr.keypressed(key, scancode, repeating)
  if not app then
    return
  end
  app.input:keypressed(key)
  app.events:emit('input:keypressed', key, scancode, repeating)
end

function lovr.keyreleased(key)
  if not app then
    return
  end
  app.input:keyreleased(key)
  app.events:emit('input:keyreleased', key)
end

function lovr.mousepressed(x, y, button)
  if not app then
    return
  end
  app.input:mousepressed(x, y, button)
  app.events:emit('input:mousepressed', x, y, button)
end

function lovr.mousereleased(x, y, button)
  if not app then
    return
  end
  app.input:mousereleased(x, y, button)
  app.events:emit('input:mousereleased', x, y, button)
end

function lovr.mousemoved(x, y, dx, dy)
  if not app then
    return
  end
  app.input:mousemoved(x, y, dx, dy)
  app.events:emit('input:mousemoved', x, y, dx, dy)
end

function lovr.wheelmoved(dx, dy)
  if not app then
    return
  end
  app.input:wheelmoved(dx, dy)
  app.events:emit('input:wheelmoved', dx, dy)
end

function lovr.quit()
  if app then
    local payload = {}
    app.events:emit('save:collect', payload)
    app.events:flush()
    if next(payload) then
      Save.write(payload)
    end
    if app.log and app.log.close then
      app.log:close()
    end
  end
end
