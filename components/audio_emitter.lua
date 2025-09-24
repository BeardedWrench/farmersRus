local AudioEmitter = {}

function AudioEmitter.create(props)
  props = props or {}
  return {
    sound = props.sound,
    looping = props.looping or false,
    volume = props.volume or 1.0,
    pitch = props.pitch or 1.0,
    positional = props.positional or false,
    playing = props.playing or false
  }
end

return AudioEmitter
