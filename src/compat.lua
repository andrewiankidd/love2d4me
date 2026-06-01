-- compat.lua â€” Legacy animation compatibility shim.
--
-- Exposes a global newAnimation() that matches the Legacy animation API but uses
-- lib/animation.lua under the hood. Drop-in replacement so legacy code
-- doesn't need rewriting.
--
-- Legacy animation API: newAnimation(image, frame_w, frame_h, delay, num_frames)
--   - image: love Image
--   - frame_w, frame_h: frame dimensions
--   - delay: seconds per frame
--   - num_frames: 0 = all frames in sheet
--
-- The returned object supports :draw(x, y), :update(dt), :seek(n),
-- :setMode("loop"|"once"|"bounce"), matching the legacy interface.

local Animation = require("love2d4me.src.animation")

local AnimCompat = {}
AnimCompat.__index = AnimCompat

function newAnimation(image, frame_w, frame_h, delay, num_frames)
    local anim = Animation.new(image, frame_w, frame_h, {
        duration = delay or 0.1,
        loop = true,
    })

    -- If num_frames specified and > 0, trim the frame list
    if num_frames and num_frames > 0 then
        local trimmed = {}
        for i = 1, math.min(num_frames, #anim.frames) do
            trimmed[i] = anim.frames[i]
        end
        anim.frames = trimmed
    end

    -- Wrap in legacy-compatible interface
    local wrapper = setmetatable({ _anim = anim }, AnimCompat)
    return wrapper
end

function AnimCompat:draw(x, y, r, sx, sy, ox, oy)
    self._anim:draw(x, y, r, sx, sy, ox, oy)
end

function AnimCompat:update(dt)
    self._anim:update(dt)
end

function AnimCompat:seek(frame)
    self._anim:set_frame(frame)
end

function AnimCompat:getCurrentFrame()
    return self._anim:get_frame()
end

function AnimCompat:setMode(mode)
    if mode == "loop" then
        self._anim.loop = true
        self._anim.playing = true
    elseif mode == "once" then
        self._anim.loop = false
    elseif mode == "bounce" then
        self._anim.loop = true
    end
end

function AnimCompat:play()
    self._anim:resume()
end

function AnimCompat:stop()
    self._anim:stop()
end

function AnimCompat:reset()
    self._anim:reset()
end

function AnimCompat:getWidth()
    return self._anim.frame_w
end

function AnimCompat:getHeight()
    return self._anim.frame_h
end
