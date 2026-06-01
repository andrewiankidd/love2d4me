-- rpg.lua â€” RPG stats: HP, XP, levels, death.
--
-- Manages player stats with configurable leveling formula.
-- Handles XP gain, level-up checks, and death detection.
--
-- Usage:
--   local RPG = require("love2d4me.src.rpg")
--   RPG.init({ hp = 10, dmg = 1, level = 1, xp = 0 })
--   RPG.take_damage(3)
--   RPG.gain_xp(5)
--   if RPG.is_dead() then ... end

local Log = require("love2d4me.src.log")
local Notification = require("love2d4me.src.notification")

local RPG = {}

local stats = {
    hp = 10,
    max_hp = 10,
    dmg = 1,
    level = 1,
    xp = 0,
    magic = {},
}
local on_death = nil
local on_levelup = nil

function RPG.init(opts)
    opts = opts or {}
    stats.hp = opts.hp or 10
    stats.max_hp = stats.hp
    stats.dmg = opts.dmg or 1
    stats.level = opts.level or 1
    stats.xp = opts.xp or 0
    stats.magic = opts.magic or {}
    on_death = opts.on_death
    on_levelup = opts.on_levelup
end

function RPG.get(key)
    return stats[key]
end

function RPG.set(key, value)
    stats[key] = value
end

function RPG.get_stats()
    return stats
end

function RPG.take_damage(amount)
    stats.hp = stats.hp - amount
    if stats.hp <= 0 then
        stats.hp = 0
        Log.info("RPG: player died")
        if on_death then on_death() end
    end
end

function RPG.heal(amount)
    stats.hp = math.min(stats.hp + amount, stats.max_hp)
end

function RPG.is_dead()
    return stats.hp <= 0
end

function RPG.xp_to_level()
    return math.floor((stats.level * 100) * 1.25)
end

function RPG.gain_xp(amount)
    stats.xp = stats.xp + amount
    Log.info("RPG: gained XP", { amount = amount, total = stats.xp })
    if stats.xp >= RPG.xp_to_level() then
        RPG.level_up()
    end
end

function RPG.level_up()
    stats.xp = stats.xp - RPG.xp_to_level()
    stats.level = stats.level + 1
    stats.max_hp = stats.level * 10
    stats.hp = stats.max_hp
    Notification.show("Level Up! Now level " .. stats.level)
    Log.info("RPG: level up", { level = stats.level, hp = stats.hp })
    if on_levelup then on_levelup() end
end

function RPG.serialize()
    return stats
end

function RPG.deserialize(data)
    if data then
        for k, v in pairs(data) do stats[k] = v end
    end
end

return RPG
