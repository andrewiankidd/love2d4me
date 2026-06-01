-- conf.lua -- Minimal LOVE2D configuration shim.
--
-- Sets sensible window defaults. Identity and all game config
-- are applied at runtime by GameState.init() from game/config.json.
--
-- This file is IDENTICAL across all games using love2d4me.
--
-- Usage (in your conf.lua):
--   local Conf = require("love2d4me.src.conf")
--   function love.conf(t) Conf.apply(t) end

local Conf = {}

function Conf.apply(t)
    t.identity = "love2d-game"
    t.window.title = "Loading..."
    t.window.width = 800
    t.window.height = 600
    t.window.resizable = true
    t.window.vsync = 1
    t.modules.joystick = true
    t.modules.physics = true
end

return Conf
