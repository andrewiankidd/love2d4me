-- animation.lua -- Sprite sheet animation player.
--
-- Replaces the legacy animation library with a simpler, project-consistent API.
-- Supports sprite sheets (uniform grid), per-frame duration, looping,
-- and callbacks on completion.
--
-- Usage:
--   local Animation = require("love2d4me.src.animation")
--   local walk = Animation.new(spritesheet, 32, 32, {
--       frames = {1, 2, 3, 4},
--       duration = 0.15,
--       loop = true,
--   })
--
-- In love.update:
--   walk:update(dt)
--
-- In love.draw:
--   walk:draw(x, y)
--   walk:draw(x, y, 0, -1, 1)  -- flipped horizontally

local Animation = {}
Animation.__index = Animation

function Animation.new(image, frame_w, frame_h, opts)
    opts = opts or {}
    local img = type(image) == "string" and love.graphics.newImage(image) or image
    local cols = math.floor(img:getWidth() / frame_w)
    local rows = math.floor(img:getHeight() / frame_h)

    -- Build quads for all frames in the sheet
    local quads = {}
    for row = 0, rows - 1 do
        for col = 0, cols - 1 do
            table.insert(quads, love.graphics.newQuad(
                col * frame_w, row * frame_h,
                frame_w, frame_h,
                img:getDimensions()
            ))
        end
    end

    local frame_list = opts.frames
    if not frame_list then
        frame_list = {}
        for i = 1, #quads do frame_list[i] = i end
    end

    return setmetatable({
        image = img,
        quads = quads,
        frames = frame_list,
        frame_w = frame_w,
        frame_h = frame_h,
        duration = opts.duration or 0.1,
        loop = opts.loop ~= false,
        current = 1,
        timer = 0,
        playing = true,
        on_complete = opts.on_complete,
    }, Animation)
end

function Animation:update(dt)
    if not self.playing then return end
    self.timer = self.timer + dt
    if self.timer >= self.duration then
        self.timer = self.timer - self.duration
        self.current = self.current + 1
        if self.current > #self.frames then
            if self.loop then
                self.current = 1
            else
                self.current = #self.frames
                self.playing = false
                if self.on_complete then self.on_complete() end
            end
        end
    end
end

function Animation:draw(x, y, r, sx, sy, ox, oy)
    local idx = self.frames[self.current]
    local quad = self.quads[idx]
    if quad then
        love.graphics.draw(self.image, quad, x, y, r or 0, sx or 1, sy or 1, ox or 0, oy or 0)
    end
end

function Animation:reset()
    self.current = 1
    self.timer = 0
    self.playing = true
end

function Animation:stop()
    self.playing = false
end

function Animation:resume()
    self.playing = true
end

function Animation:is_playing()
    return self.playing
end

function Animation:get_frame()
    return self.current
end

function Animation:set_frame(n)
    self.current = math.max(1, math.min(n, #self.frames))
end

function Animation:get_dimensions()
    return self.frame_w, self.frame_h
end

return Animation
