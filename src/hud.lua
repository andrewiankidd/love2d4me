-- hud.lua — Heads-up display for combat games.
--
-- Draws player health bar, weapon icon, and cooldown indicator.
-- Position and style configurable. Call HUD.draw() in your gameplay_draw.
--
-- Usage:
--   local HUD = require("love2d4me").hud
--   HUD.set_health(80, 100)
--   HUD.set_weapon("fist", cooldown_ratio)
--   HUD.draw()

local HUD = {}

local health = 0
local max_health = 0
local weapon_name = nil
local cooldown_ratio = 0
local damage_flash = 0
local control_hints = nil
local money = nil

function HUD.set_health(current, maximum)
    health = current or health
    max_health = maximum or max_health
end

function HUD.set_weapon(name, cd_ratio)
    weapon_name = name
    cooldown_ratio = cd_ratio or 0
end

function HUD.set_money(value)
    money = value
end

function HUD.flash_damage()
    damage_flash = 0.2
end

function HUD.update(dt)
    if damage_flash > 0 then
        damage_flash = damage_flash - dt
    end
end

function HUD.set_controls(lines)
    control_hints = lines
end

function HUD.draw()
    local sw, sh = love.graphics.getDimensions()

    -- Damage flash overlay
    if damage_flash > 0 then
        love.graphics.setColor(1, 0, 0, damage_flash * 2)
        love.graphics.rectangle("fill", 0, 0, sw, sh)
    end

    -- Health bar (top left, only if health is set)
    if max_health > 0 then
        local bar_x, bar_y = 12, 12
        local bar_w, bar_h = 120, 14
        local ratio = health / max_health

        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", bar_x - 2, bar_y - 2, bar_w + 4, bar_h + 4, 2, 2)
        love.graphics.setColor(0.6, 0.1, 0.1, 1)
        love.graphics.rectangle("fill", bar_x, bar_y, bar_w, bar_h)
        love.graphics.setColor(0.1, 0.8, 0.1, 1)
        love.graphics.rectangle("fill", bar_x, bar_y, bar_w * ratio, bar_h)
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.print(math.floor(health) .. "/" .. math.floor(max_health), bar_x + 4, bar_y)

        -- Weapon display (below health)
        if weapon_name then
            local wx, wy = 12, bar_y + bar_h + 8
            love.graphics.setColor(0, 0, 0, 0.6)
            love.graphics.rectangle("fill", wx - 2, wy - 2, 80, 24, 2, 2)
            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.print(weapon_name, wx + 4, wy + 2)
            if cooldown_ratio > 0 then
                love.graphics.setColor(1, 1, 1, 0.3)
                love.graphics.rectangle("fill", wx, wy + 18, 76 * cooldown_ratio, 3)
            end
        end

        -- Money display (below weapon)
        if money then
            local my = bar_y + bar_h + 8 + (weapon_name and 32 or 0)
            local label = "$" .. money
            love.graphics.setColor(0, 0, 0, 0.6)
            love.graphics.rectangle("fill", 10, my - 2, 80, 20, 2, 2)
            love.graphics.setColor(0.4, 1, 0.4, 1)
            love.graphics.rectangle("fill", 14, my + 4, 8, 8)
            love.graphics.setColor(1, 1, 1, 0.95)
            love.graphics.print(label, 28, my + 2)
        end
    end

    -- Control hints (bottom-right, grows upward)
    if control_hints and #control_hints > 0 then
        local hint_font = love.graphics.getFont()
        local line_h = hint_font:getHeight()
        local pad = 5
        local max_w = 0
        for _, line in ipairs(control_hints) do
            local line_w = hint_font:getWidth(line)
            if line_w > max_w then max_w = line_w end
        end
        local box_w = max_w + pad * 2
        local box_h = #control_hints * (line_h + 2) + pad * 2
        local bx = sw - box_w - 8
        local by = sh - box_h - 8
        love.graphics.setColor(0, 0, 0, 0.45)
        love.graphics.rectangle("fill", bx, by, box_w, box_h, 3, 3)
        love.graphics.setColor(1, 1, 1, 0.65)
        for idx, line in ipairs(control_hints) do
            love.graphics.print(line, bx + pad, by + pad + (idx - 1) * (line_h + 2))
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return HUD
