local Hud = {}

function Hud.create(app)
  return {
    app = app,
    visible = true
  }
end

function Hud:update(state)
  -- Placeholder: logic handled in ui_system.lua
end

return Hud
