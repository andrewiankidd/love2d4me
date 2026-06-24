-- stats.lua -- Generic named meter/stat system with decay and thresholds.
--
-- Define named stats with min/max/default/decay rates. Tick decay over time.
-- Query thresholds (critical/full). Serialize/deserialize for save games.
--
-- Usage:
--   local Stats = require("love2d4me.src.stats")
--   Stats.define("hunger",  { min = 0, max = 100, default = 30, decay = 1/60, invert = true })
--   Stats.define("energy",  { min = 0, max = 100, default = 70, decay = -0.8/60 })
--   Stats.reset()
--   Stats.tick(dt)
--   Stats.add("hunger", -30)
--   if Stats.is_critical("energy") then ... end
--   if Stats.is_full("hunger") then ... end

local Stats = {}

local defs = {}
local values = {}
local order = {}

local default_critical = 5
local default_full_normal = 90
local default_full_invert = 10

function Stats.define(name, opts)
    opts = opts or {}
    defs[name] = {
        min = opts.min or 0,
        max = opts.max or 100,
        default = opts.default or 50,
        decay = opts.decay or 0,
        invert = opts.invert or false,
        critical = opts.critical,
        full = opts.full,
        label = opts.label or name,
        color = opts.color,
        icon = opts.icon,
    }
    local exists = false
    for _, k in ipairs(order) do
        if k == name then exists = true; break end
    end
    if not exists then table.insert(order, name) end
end

function Stats.reset()
    for name, def in pairs(defs) do
        values[name] = def.default
    end
end

function Stats.get(name)
    return values[name]
end

function Stats.set(name, val)
    local def = defs[name]
    if not def then return end
    values[name] = math.max(def.min, math.min(def.max, val))
end

function Stats.add(name, delta)
    local def = defs[name]
    if not def then return end
    values[name] = math.max(def.min, math.min(def.max, (values[name] or def.default) + delta))
end

function Stats.tick(dt)
    for name, def in pairs(defs) do
        if def.decay ~= 0 then
            local v = (values[name] or def.default) + def.decay * dt
            values[name] = math.max(def.min, math.min(def.max, v))
        end
    end
end

function Stats.is_critical(name)
    local def = defs[name]
    if not def then return false end
    local v = values[name] or def.default
    if def.invert then
        local threshold = def.critical or (def.max - default_critical)
        return v >= threshold
    else
        local threshold = def.critical or default_critical
        return v <= threshold
    end
end

function Stats.is_full(name)
    local def = defs[name]
    if not def then return false end
    local v = values[name] or def.default
    if def.invert then
        local threshold = def.full or default_full_invert
        return v <= threshold
    else
        local threshold = def.full or default_full_normal
        return v >= threshold
    end
end

function Stats.get_fill(name)
    local def = defs[name]
    if not def then return 0 end
    local v = values[name] or def.default
    local ratio = (v - def.min) / (def.max - def.min)
    if def.invert then ratio = 1 - ratio end
    return ratio
end

function Stats.get_def(name)
    return defs[name]
end

function Stats.get_names()
    return order
end

function Stats.get_average()
    local sum, count = 0, 0
    for name, def in pairs(defs) do
        local v = values[name] or def.default
        local ratio = (v - def.min) / (def.max - def.min)
        if def.invert then ratio = 1 - ratio end
        sum = sum + ratio
        count = count + 1
    end
    if count == 0 then return 0.5 end
    return sum / count
end

function Stats.serialize()
    local data = {}
    for name, v in pairs(values) do
        data[name] = v
    end
    return data
end

function Stats.deserialize(data)
    if not data then return end
    for name, def in pairs(defs) do
        values[name] = data[name] or def.default
    end
end

return Stats
