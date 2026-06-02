-- scoring.lua -- Generic score tracking with display.
--
-- Usage:
--   local Scoring = require("love2d4me").scoring
--   Scoring.reset()
--   Scoring.add("player", 1)
--   Scoring.add("opponent", 1)
--   Scoring.draw()  -- draws scoreboard at top of screen

local Scoring = {}

local scores = {}
local display_order = {}

function Scoring.reset()
    scores = {}
    display_order = {}
end

function Scoring.add(name, amount)
    if not scores[name] then
        scores[name] = 0
        display_order[#display_order + 1] = name
    end
    scores[name] = scores[name] + (amount or 1)
end

function Scoring.get(name)
    return scores[name] or 0
end

function Scoring.set(name, value)
    if not scores[name] then
        display_order[#display_order + 1] = name
    end
    scores[name] = value
end

function Scoring.get_all()
    return scores
end

function Scoring.get_winner()
    local best_name, best_score = nil, -1
    for name, score in pairs(scores) do
        if score > best_score then
            best_name = name
            best_score = score
        end
    end
    return best_name, best_score
end

function Scoring.draw(position)
    local sw, sh = love.graphics.getDimensions()
    local parts = {}
    for _, name in ipairs(display_order) do
        parts[#parts + 1] = name .. ": " .. (scores[name] or 0)
    end
    local text = table.concat(parts, "    ")
    local font = love.graphics.getFont()
    local text_w = font:getWidth(text)
    local text_h = font:getHeight()
    local draw_y = (position == "bottom") and (sh - text_h - 12) or 4
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", (sw - text_w) / 2 - 10, draw_y, text_w + 20, text_h + 8, 3, 3)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(text, (sw - text_w) / 2, draw_y + 4)
end

return Scoring
