-- daynight.lua -- Day/night cycle overlay.
--
-- Draws a darkness overlay that varies with time. Optionally composites
-- a light map (additive blend) for localized lighting effects.
--
-- Usage:
--   local DayNight = require("love2d4me.src.daynight")
--   DayNight.set_time(50)  -- 0=bright day, 127=darkest night
--
-- In love.draw (after world, before HUD):
--   DayNight.draw(camera_x, camera_y, light_map_image)

local DayNight = {}

-- Named time constants (0 = bright day, 127 = darkest night)
DayNight.BRIGHT_DAY = 0
DayNight.MORNING    = 20
DayNight.DUSK       = 50
DayNight.EVENING    = 75
DayNight.NIGHT      = 100
DayNight.MIDNIGHT   = 127

local world_time = 0   -- 0-127, higher = darker
local cycle_speed = 0  -- units per second (0 = manual)

function DayNight.set_time(t)
    world_time = math.max(0, math.min(127, t))
end

function DayNight.get_time()
    return world_time
end

function DayNight.set_cycle_speed(speed)
    cycle_speed = speed
end

function DayNight.update(dt)
    if cycle_speed ~= 0 then
        world_time = world_time + cycle_speed * dt
        if world_time > 127 then world_time = 0
        elseif world_time < 0 then world_time = 127 end
    end
end

function DayNight.draw(cam_x, cam_y, lightmap)
    if world_time <= 0 then return end
    local sw, sh = love.graphics.getDimensions()
    local alpha = world_time / 127

    -- Darkness overlay
    love.graphics.setColor(0, 0, 0, alpha)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    -- Light map (additive blend)
    if lightmap then
        love.graphics.setBlendMode('add')
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.draw(lightmap, cam_x or 0, cam_y or 0)
        love.graphics.setBlendMode('alpha')
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return DayNight
