-- player.lua — Player state container.
--
-- Replaces scattered globals (protagX, protagY, cameraoffsetx, etc.)
-- with a single state table passed to movement functions.
--
-- Usage:
--   local Player = require("love2d4me").player
--   local state = Player.new({ x = 200, y = 200, w = 26, h = 45 })
--   -- In update:  movement_update(dt, state)
--   -- In draw:    state.anim:draw(state.x, state.y)

local Player = {}

function Player.new(opts)
    opts = opts or {}
    return {
        x = opts.x or 0,
        y = opts.y or 0,
        w = opts.w or 32,
        h = opts.h or 32,

        -- Camera
        camera_x = opts.camera_x or 0,
        camera_y = opts.camera_y or 0,

        -- Derived (updated by movement)
        calc_x = 0,
        calc_y = 0,

        -- Movement state
        direction = opts.direction or "south",
        speed = opts.speed or 4,
        velocity = 0,
        facing = opts.facing or "right",
        moving = false,

        -- Collision
        collision = nil,

        -- Animation
        anim = opts.anim or nil,

        -- Flags
        dead = false,
        debug = false,
    }
end

function Player.update_calc(state)
    state.calc_x = state.x - state.camera_x
    state.calc_y = state.y - state.camera_y
end

return Player
