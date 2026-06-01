-- equipment.lua — Weapon and equipment system.
--
-- Register item types, equip/unequip, track stats.
-- Designed for melee weapons, ranged weapons, armor, tools.
--
-- Usage:
--   local Equipment = require("love2d4me").equipment
--   Equipment.register("fist", { damage = 1, range = 3, cooldown = 0.5, type = "melee" })
--   Equipment.register("bat", { damage = 3, range = 4, cooldown = 0.8, type = "melee" })
--   Equipment.equip("fist")
--   if Equipment.can_attack() then Equipment.attack() end

local Log = require("love2d4me.src.log")

local Equipment = {}

local registry = {}
local equipped = nil
local attack_timer = 0

function Equipment.register(name, stats)
    registry[name] = {
        name = name,
        damage = stats.damage or 1,
        range = stats.range or 3,
        cooldown = stats.cooldown or 0.5,
        type = stats.type or "melee",
        icon = stats.icon or nil,
    }
    Log.debug("Equipment.register", { name = name })
end

function Equipment.equip(name)
    if registry[name] then
        equipped = registry[name]
        Log.info("Equipment.equip", { name = name })
        return true
    end
    return false
end

function Equipment.get_equipped()
    return equipped
end

function Equipment.get_all()
    return registry
end

function Equipment.update(dt)
    if attack_timer > 0 then
        attack_timer = attack_timer - dt
    end
end

function Equipment.can_attack()
    return equipped and attack_timer <= 0
end

function Equipment.attack()
    if not Equipment.can_attack() then return nil end
    attack_timer = equipped.cooldown
    return {
        damage = equipped.damage,
        range = equipped.range,
        type = equipped.type,
        weapon = equipped.name,
    }
end

function Equipment.get_cooldown_ratio()
    if not equipped then return 0 end
    return math.max(0, attack_timer / equipped.cooldown)
end

return Equipment
