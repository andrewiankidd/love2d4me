-- splash.lua â€” Animated splash screen.
--
-- Plays a sprite-sheet splash centered on screen, then calls on_complete.
--
-- Image resolution order (no config needed):
--   1. game/pictures/splash.png  â€” game provides its own
--   2. love2d4me/assets/splash.png â€” default andrewkidd logo
--
-- Usage:
--   local Splash = require("love2d4me.src.splash")
--   Splash.init({ on_complete = function() gamemode = "menu" end })

local Animation = require("love2d4me.src.animation")

local Splash = {}

local anim = nil
local active = false
local callback = nil
local splash_audio = nil

local SEARCH_PATHS = {
    "game/pictures/splash.png",
    "love2d4me/assets/splash.png",
}

local function find_splash_image()
    for _, path in ipairs(SEARCH_PATHS) do
        if love.filesystem.getInfo(path) then
            return path
        end
    end
    return nil
end

function Splash.init(opts)
    opts = opts or {}
    callback = opts.on_complete

    local image_path = find_splash_image()
    if not image_path then
        active = false
        if callback then callback() end
        return
    end

    local fw = opts.frame_w or 280
    local fh = opts.frame_h or 280
    local img = love.graphics.newImage(image_path)

    anim = Animation.new(img, fw, fh, {
        duration = opts.duration or 0.05,
        loop = false,
        on_complete = function()
            active = false
            if callback then callback() end
        end,
    })
    active = true

    -- Splash audio: game override or default from submodule
    local audio_paths = { "game/sound/splash.ogg", "love2d4me/assets/splash.ogg" }
    for _, ap in ipairs(audio_paths) do
        if love.filesystem.getInfo(ap) then
            splash_audio = love.audio.newSource(ap, "static")
            splash_audio:play()
            break
        end
    end
end

function Splash.update(dt)
    if not active or not anim then return end
    anim:update(dt)
end

function Splash.draw()
    if not active or not anim then return end
    local w, h = anim:get_dimensions()
    local sw, sh = love.graphics.getDimensions()
    love.graphics.clear(0, 0, 0, 1)
    anim:draw(math.floor((sw - w) / 2), math.floor((sh - h) / 2))
end

function Splash.is_active()
    return active
end

function Splash.skip()
    active = false
    if splash_audio then splash_audio:stop() end
    if callback then callback() end
end

return Splash
