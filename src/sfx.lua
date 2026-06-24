-- sfx.lua -- Named sound effect registry with procedural generation helpers.
--
-- Register sounds by name — either from audio files or procedurally generated
-- waveforms. Play by name. Supports volume per-sound and global volume scaling.
--
-- Usage:
--   local SFX = require("love2d4me.src.sfx")
--   SFX.load("bark", "game/sounds/bark.wav", { volume = 0.5 })
--   SFX.generate("beep", 0.1, function(t, d) return SFX.square(800, t) * SFX.fade(t, d) end)
--   SFX.play("bark")
--   SFX.play("beep")

local SFX = {}

local sources = {}
local sample_rate = 22050

-- Waveform helpers (exposed for use in generate callbacks)

function SFX.square(freq, t)
    return math.sin(2 * math.pi * freq * t) > 0 and 0.4 or -0.4
end

function SFX.sine(freq, t)
    return math.sin(2 * math.pi * freq * t) * 0.4
end

function SFX.noise()
    return (math.random() * 2 - 1) * 0.3
end

function SFX.fade(t, dur)
    local env = 1 - t / dur
    return env * env
end

function SFX.generate(name, duration, fn, opts)
    opts = opts or {}
    local rate = opts.sample_rate or sample_rate
    local samples = math.floor(rate * duration)
    local sd = love.sound.newSoundData(samples, rate, 16, 1)
    for i = 0, samples - 1 do
        local t = i / rate
        sd:setSample(i, fn(t, duration))
    end
    local src = love.audio.newSource(sd, "static")
    src:setVolume(opts.volume or 0.35)
    sources[name] = src
    return src
end

function SFX.load(name, path, opts)
    opts = opts or {}
    if not love.filesystem.getInfo(path) then return nil end
    local src = love.audio.newSource(path, "static")
    src:setVolume(opts.volume or 0.5)
    sources[name] = src
    return src
end

function SFX.play(name)
    local src = sources[name]
    if not src then return end
    src:stop()
    src:play()
end

function SFX.stop(name)
    local src = sources[name]
    if src then src:stop() end
end

function SFX.set_volume(name, vol)
    local src = sources[name]
    if src then src:setVolume(vol) end
end

function SFX.has(name)
    return sources[name] ~= nil
end

return SFX
