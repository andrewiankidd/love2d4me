-- camera.lua â€” 2D camera with tracking, bounds, and shake.
--
-- Tracks a target position, clamps to map bounds, applies transform
-- so game code draws in world space without manual offset math.
--
-- Usage:
--   local Camera = require("love2d4me.src.camera")
--   local cam = Camera.new(800, 600)
--   cam:set_bounds(0, 0, map_width, map_height)
--
-- In love.update:
--   cam:follow(player_x, player_y, dt)
--
-- In love.draw:
--   cam:attach()
--   -- draw world here --
--   cam:detach()
--   -- draw HUD here (screen space) --

local Camera = {}
Camera.__index = Camera

function Camera.new(screen_w, screen_h)
    return setmetatable({
        x = 0,
        y = 0,
        screen_w = screen_w or love.graphics.getWidth(),
        screen_h = screen_h or love.graphics.getHeight(),
        -- Map bounds (nil = no clamping)
        bounds_x = nil,
        bounds_y = nil,
        bounds_w = nil,
        bounds_h = nil,
        -- Smoothing (1.0 = instant, lower = smoother)
        smoothing = 0.1,
        -- Shake
        shake_intensity = 0,
        shake_timer = 0,
        shake_ox = 0,
        shake_oy = 0,
    }, Camera)
end

function Camera:set_bounds(x, y, w, h)
    self.bounds_x = x
    self.bounds_y = y
    self.bounds_w = w
    self.bounds_h = h
end

function Camera:follow(target_x, target_y, dt)
    local goal_x = target_x - self.screen_w / 2
    local goal_y = target_y - self.screen_h / 2

    -- Smooth follow
    local smooth_factor = math.min(self.smoothing * (dt * 60), 1.0)
    self.x = self.x + (goal_x - self.x) * smooth_factor
    self.y = self.y + (goal_y - self.y) * smooth_factor

    -- Clamp to bounds
    if self.bounds_w then
        self.x = math.max(self.bounds_x, math.min(self.x, self.bounds_x + self.bounds_w - self.screen_w))
        self.y = math.max(self.bounds_y, math.min(self.y, self.bounds_y + self.bounds_h - self.screen_h))
    end

    -- Shake
    if self.shake_timer > 0 then
        self.shake_timer = self.shake_timer - dt
        self.shake_ox = (math.random() * 2 - 1) * self.shake_intensity
        self.shake_oy = (math.random() * 2 - 1) * self.shake_intensity
    else
        self.shake_ox = 0
        self.shake_oy = 0
    end
end

function Camera:shake(intensity, duration)
    self.shake_intensity = intensity or 4
    self.shake_timer = duration or 0.3
end

function Camera:snap(target_x, target_y)
    self.x = target_x - self.screen_w / 2
    self.y = target_y - self.screen_h / 2
    if self.bounds_w then
        self.x = math.max(self.bounds_x, math.min(self.x, self.bounds_x + self.bounds_w - self.screen_w))
        self.y = math.max(self.bounds_y, math.min(self.y, self.bounds_y + self.bounds_h - self.screen_h))
    end
end

function Camera:attach()
    love.graphics.push()
    love.graphics.translate(
        -math.floor(self.x + self.shake_ox),
        -math.floor(self.y + self.shake_oy)
    )
end

function Camera:detach()
    love.graphics.pop()
end

function Camera:world_to_screen(wx, wy)
    return wx - self.x, wy - self.y
end

function Camera:screen_to_world(sx, sy)
    return sx + self.x, sy + self.y
end

return Camera
