-- projectile.lua — Simple projectile spawner and updater.
--
-- Manages a pool of active projectiles with position, velocity, and lifetime.
-- Update and draw are separate calls (no rendering in update).
--
-- Usage:
--   local Projectile = require("love2d4me").projectile
--   Projectile.spawn({ x = 100, y = 200, dx = 300, dy = 0, lifetime = 2 })
--   -- In update:
--   Projectile.update(dt)
--   -- In draw:
--   Projectile.draw()

local Projectile = {}

local pool = {}
local default_radius = 4
local default_color = { 1, 1, 1, 1 }

function Projectile.spawn(opts)
    pool[#pool + 1] = {
        x = opts.x or 0,
        y = opts.y or 0,
        dx = opts.dx or 0,
        dy = opts.dy or 0,
        radius = opts.radius or default_radius,
        color = opts.color or default_color,
        lifetime = opts.lifetime or 3,
        age = 0,
        on_hit = opts.on_hit,
    }
end

function Projectile.update(dt)
    for i = #pool, 1, -1 do
        local p = pool[i]
        p.x = p.x + p.dx * dt
        p.y = p.y + p.dy * dt
        p.age = p.age + dt
        if p.age >= p.lifetime then
            table.remove(pool, i)
        end
    end
end

function Projectile.draw(camera_x, camera_y)
    local cx = camera_x or 0
    local cy = camera_y or 0
    for _, p in ipairs(pool) do
        love.graphics.setColor(p.color)
        love.graphics.circle("fill", p.x + cx, p.y + cy, p.radius)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function Projectile.get_all()
    return pool
end

function Projectile.clear()
    pool = {}
end

function Projectile.check_hits(target_x, target_y, target_w, target_h)
    for i = #pool, 1, -1 do
        local p = pool[i]
        if p.x >= target_x and p.x <= target_x + target_w
            and p.y >= target_y and p.y <= target_y + target_h then
            if p.on_hit then p.on_hit(p) end
            table.remove(pool, i)
            return true
        end
    end
    return false
end

return Projectile
