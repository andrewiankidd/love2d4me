-- vehicle.lua -- Driveable/rideable entity support.
--
-- Vehicles are interactable objects the player can enter and drive.
-- Composition-based: a vehicle is just a table with driving stats.
-- Games define presets; the module handles enter/exit/drive logic.
--
-- Usage:
--   local Vehicle = require("love2d4me.src.vehicle")
--   local Interactable = require("love2d4me.src.interactable")
--
--   -- Define presets in game code:
--   Vehicle.register("car",  { speed = 22, turn = 1.5, w = 4.0, h = 8.0, color = {0.75, 0.22, 0.20} })
--   Vehicle.register("bike", { speed = 18, turn = 2.4, w = 1.4, h = 4.0, color = {0.20, 0.20, 0.26} })
--   Vehicle.register("horse", { speed = 12, turn = 2.0, w = 1.5, h = 3.0, color = {0.55, 0.35, 0.20} })
--
--   -- Spawn on the map:
--   Vehicle.spawn("car", x, y, angle)
--
--   -- In update loop:
--   local entered = Vehicle.update(player_x, player_y, interact_pressed)
--   if Vehicle.is_driving() then
--       -- use Vehicle.get_current().speed for movement
--   end

local Interactable = require("love2d4me.src.interactable")
local Log = require("love2d4me.src.log")

local Vehicle = {}

local presets = {}
local current = nil

function Vehicle.register(kind, stats)
    presets[kind] = stats
    Log.debug("Vehicle.register", { kind = kind })
end

function Vehicle.spawn(kind, x, y, angle)
    local p = presets[kind] or { speed = 10, turn = 1.5, w = 3, h = 6, color = {0.5, 0.5, 0.5}, weight = 1000 }
    return Interactable.new({
        kind = kind,
        driveable = true,
        x = x, y = y,
        angle = angle or 0,
        radius = 5,
        speed = p.speed,
        turn = p.turn,
        w = p.w,
        h = p.h,
        color = p.color,
        weight = p.weight or 1000,
        vx = 0, vy = 0,
    })
end

function Vehicle.enter(vehicle)
    if vehicle and vehicle.driveable then
        current = vehicle
        Log.info("Vehicle.enter", { kind = vehicle.kind })
        return true
    end
    return false
end

function Vehicle.exit(px, py, angle)
    if current then
        current.x = px
        current.y = py
        current.angle = angle or 0
        local ca, sa = math.cos(angle or 0), math.sin(angle or 0)
        local offset = (current.w or 4) / 2 + 2
        local exit_x = px + ca * offset
        local exit_y = py + sa * offset
        Log.info("Vehicle.exit", { kind = current.kind })
        current = nil
        return true, exit_x, exit_y
    end
    return false
end

function Vehicle.is_driving()
    return current ~= nil
end

function Vehicle.get_current()
    return current
end

function Vehicle.try_interact(px, py, angle)
    if current then
        return Vehicle.exit(px, py, angle)
    else
        local nearest = Interactable.nearest(px, py, function(o) return o.driveable end)
        if nearest then
            return Vehicle.enter(nearest)
        end
    end
    return false
end

function Vehicle.get_presets()
    return presets
end

function Vehicle.reset()
    current = nil
end

local function vehicles_overlap(a, b)
    local dx = b.x - a.x
    local dy = b.y - a.y
    local dist = math.sqrt(dx * dx + dy * dy)
    local max_reach = (a.h + b.h) / 2 + (a.w + b.w) / 4
    if dist > max_reach then return false, 0, 0, 0 end
    if Vehicle.contains(a, b.x, b.y, 0.5)
        or Vehicle.contains(b, a.x, a.y, 0.5)
        or Vehicle.contains(a, b.x + (b.w or 4) * 0.3, b.y, 0.5)
        or Vehicle.contains(a, b.x - (b.w or 4) * 0.3, b.y, 0.5)
        or Vehicle.contains(b, a.x + (a.w or 4) * 0.3, a.y, 0.5)
        or Vehicle.contains(b, a.x - (a.w or 4) * 0.3, a.y, 0.5) then
        if dist < 0.1 then dist = 0.1 end
        return true, dx / dist, dy / dist, dist
    end
    return false, 0, 0, 0
end

function Vehicle.check_collisions(dt, blocked_fn)
    local all = Interactable.all()
    for i = 1, #all do
        local a = all[i]
        if a.driveable then
            for j = i + 1, #all do
                local b = all[j]
                if b.driveable then
                    local hit, nx, ny = vehicles_overlap(a, b)
                    if hit then
                        local total_weight = (a.weight or 1000) + (b.weight or 1000)
                        local a_ratio = (b.weight or 1000) / total_weight
                        local b_ratio = (a.weight or 1000) / total_weight
                        local bounce = 4
                        if a ~= current then
                            a.vx = (a.vx or 0) - nx * bounce * a_ratio
                            a.vy = (a.vy or 0) - ny * bounce * a_ratio
                        end
                        if b ~= current then
                            b.vx = (b.vx or 0) + nx * bounce * b_ratio
                            b.vy = (b.vy or 0) + ny * bounce * b_ratio
                        end
                    end
                end
            end
        end
    end
    for _, v in ipairs(all) do
        if v.driveable and v ~= current then
            local vx = v.vx or 0
            local vy = v.vy or 0
            if math.abs(vx) > 0.01 or math.abs(vy) > 0.01 then
                local new_x = v.x + vx * dt
                local new_y = v.y + vy * dt
                if blocked_fn and blocked_fn(new_x, new_y) then
                    v.vx = 0
                    v.vy = 0
                else
                    v.x = new_x
                    v.y = new_y
                    v.vx = vx * 0.85
                    v.vy = vy * 0.85
                end
            end
        end
    end
end

function Vehicle.contains(vehicle, px, py, margin)
    margin = margin or 0
    local dx, dy = px - vehicle.x, py - vehicle.y
    local ca, sa = math.cos(vehicle.angle), math.sin(vehicle.angle)
    local fwd = -dx * sa + dy * ca
    local side = dx * ca + dy * sa
    return math.abs(fwd) <= vehicle.h / 2 + margin and math.abs(side) <= vehicle.w / 2 + margin
end

return Vehicle
