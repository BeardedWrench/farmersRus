return function(app)
  local ecs = app.ecs
  local resources = app.resources
  local events = app.events

  local system = {
    name = 'audio_system',
    updateOrder = 80
  }

  local emitterQuery
  local musicSource
  local ambientSource

  local function playOneShot(path, volume)
    local source = resources:getSound(path)
    if not source then
      return
    end
    local clone = source:clone()
    clone:setVolume(volume or 1)
    clone:play()
  end

  function system:init()
    emitterQuery = ecs:getQuery({ 'audio_emitter' })
    -- musicSource = resources:getSound('assets/music/cozy_piano.ogg', 'stream')
    -- if musicSource then
    --   musicSource:setLooping(true)
    --   musicSource:setVolume(0.45)
    --   musicSource:play()
    -- end

    -- ambientSource = resources:getSound('assets/sfx/ambient_farm.wav', 'static')
    -- if ambientSource then
    --   ambientSource:setLooping(true)
    --   ambientSource:setVolume(0.35)
    --   ambientSource:play()
    -- end

    -- events:on('audio:play', function(path, volume)
    --   playOneShot(path, volume)
    -- end)
  end

  function system:update(dt)
    local list = emitterQuery.list
    for i = 1, #list do
      local entity = list[i]
      local emitter = ecs:getComponent(entity, 'audio_emitter')
      if emitter and emitter.sound then
        if emitter.playing and not emitter._source then
          local source = resources:getSound(emitter.sound)
          if source then
            local clone = source:clone()
            clone:setLooping(emitter.looping)
            clone:setVolume(emitter.volume)
            clone:setPitch(emitter.pitch)
            clone:play()
            emitter._source = clone
          end
        elseif not emitter.playing and emitter._source then
          emitter._source:stop()
          emitter._source = nil
        end
      end
    end
  end

  return system
end
