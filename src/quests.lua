-- quests.lua -- Quest/objective tracking system.
--
-- Quests live in game/objectives/<id>/config.json with:
--   title, description, type, next
--   icon.png (optional)
--
-- Quest types: "talkto:<npc>", "hasitem:<item>", "goto:<map>"
--
-- Usage:
--   local Quests = require("love2d4me.src.quests")
--   Quests.add("001")
--   Quests.check("talkto", "Bob")

local Log = require("love2d4me.src.log")
local JSON = require("love2d4me.src.json")
local Notification = require("love2d4me.src.notification")

local Quests = {}

local active = {}
local completed = {}
local quest_cache = {}
local BASE = "game/objectives/"
local OVERLAY_PATH = "game/pictures/inventory/inventoryoverlay.png"
local overlay_image = nil
local selected = 1
local visible = false
local current_id = nil
local current_data = {}

local function load_quest(id)
    if quest_cache[id] then return quest_cache[id] end
    local data = { id = id, title = "", description = "", type = "", next = nil }
    local cfg = JSON.load(BASE .. id .. "/config.json")
    if cfg then
        data.title = cfg.title or ""
        data.description = cfg.description or ""
        data.type = cfg.type or ""
        data.next = cfg["next"]
    end
    if love.filesystem.getInfo(BASE .. id .. "/icon.png") then
        data.image = love.graphics.newImage(BASE .. id .. "/icon.png")
    end
    quest_cache[id] = data
    return data
end

function Quests.add(id)
    current_id = id
    table.insert(active, id)
    current_data = load_quest(id)
    Notification.show("New Quest - " .. (current_data.title or id))
    Log.info("Quests: added", { id = id, title = current_data.title })
end

function Quests.check(condition_type, condition_value)
    for i = #active, 1, -1 do
        local data = load_quest(active[i])
        if data.type then
            local ctype, cval = data.type:match("([^:]+):(.+)")
            if ctype == condition_type and cval == condition_value then
                Quests.complete(active[i])
                return true
            end
        end
    end
    return false
end

function Quests.complete(id)
    for i = #active, 1, -1 do
        if active[i] == id then
            table.insert(completed, active[i])
            table.remove(active, i)
            local data = load_quest(id)
            Log.info("Quests: completed", { id = id })
            if data.next then
                Quests.add(data.next)
            end
            return true
        end
    end
    return false
end

function Quests.get_current_id()
    return current_id
end

function Quests.get_current_data()
    return current_data
end

function Quests.get_current_type()
    return current_data and current_data.type or ""
end

function Quests.get_active()
    return active
end

function Quests.get_completed()
    return completed
end

function Quests.get_data(id)
    return load_quest(id)
end

function Quests.set_visible(v) visible = v end
function Quests.is_visible() return visible end
function Quests.toggle() visible = not visible end
function Quests.get_selected() return selected end

function Quests.keypressed(key)
    if not visible then return false end
    if key == "escape" or key == "q" or key == "tab" then
        visible = false
        return true
    end
    local n = #active + #completed
    if n == 0 then return true end
    if key == "up" or key == "w" then
        selected = selected - 1
        if selected < 1 then selected = n end
        return true
    elseif key == "down" or key == "s" then
        selected = selected + 1
        if selected > n then selected = 1 end
        return true
    end
    return true
end

function Quests.draw()
    if not visible then return end
    local sw, sh = love.graphics.getDimensions()
    if not overlay_image and love.filesystem.getInfo(OVERLAY_PATH) then
        overlay_image = love.graphics.newImage(OVERLAY_PATH)
    end
    if overlay_image then
        love.graphics.setColor(1, 1, 1, 1)
        draw_fullscreen(overlay_image)
    end

    local left_w = sw * 0.45
    local right_x = sw * 0.5
    local right_w = sw * 0.45
    local draw_y = 35

    -- Quest list (left panel)
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.printf("JOURNAL", 50, draw_y, left_w, 'left')
    draw_y = draw_y + 25

    local n_active = #active
    if n_active > 0 then
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        love.graphics.printf("Active:", 50, draw_y, left_w, 'left')
        draw_y = draw_y + 20
    end
    for i, id in ipairs(active) do
        local data = load_quest(id)
        if i == selected then
            love.graphics.setColor(0.2, 0.15, 0, 1)
            love.graphics.printf("> " .. (data.title ~= "" and data.title or id), 50, draw_y, left_w, 'left')
        else
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
            love.graphics.printf("  " .. (data.title ~= "" and data.title or id), 50, draw_y, left_w, 'left')
        end
        draw_y = draw_y + 20
    end

    if #completed > 0 then
        draw_y = draw_y + 10
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        love.graphics.printf("Completed:", 50, draw_y, left_w, 'left')
        draw_y = draw_y + 20
        for j, id in ipairs(completed) do
            local data = load_quest(id)
            if n_active + j == selected then
                love.graphics.setColor(0.4, 0.35, 0, 1)
            else
                love.graphics.setColor(0.5, 0.5, 0.5, 1)
            end
            love.graphics.printf("  " .. (data.title ~= "" and data.title or id), 50, draw_y, left_w, 'left')
            draw_y = draw_y + 20
        end
    end

    -- Selected quest detail (right panel)
    local all_quests = {}
    for _, id in ipairs(active) do all_quests[#all_quests + 1] = id end
    for _, id in ipairs(completed) do all_quests[#all_quests + 1] = id end
    local sel_id = all_quests[selected]
    if sel_id then
        local data = load_quest(sel_id)
        if data.image then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(data.image, right_x + right_w / 2 - 32, 43)
        end
        love.graphics.setColor(0.2, 0.15, 0, 1)
        love.graphics.printf(data.title ~= "" and data.title or sel_id, right_x, sh * 0.45, right_w, 'left')
        love.graphics.setColor(0.3, 0.3, 0.3, 1)
        love.graphics.printf(data.description, right_x, sh * 0.52, right_w, 'left')
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.printf("Type: " .. (data.type or ""), right_x, sh * 0.7, right_w, 'left')
    end

    -- Close hint
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.printf("Q / Esc to close  |  Up/Down to navigate", 0, sh * 0.92, sw, 'center')
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(selected .. " / " .. (#active + #completed), sw * 0.37, sh * 0.9, sw, 'left')
end

function Quests.serialize()
    return { active = active, completed = completed, current = current_id }
end

function Quests.deserialize(data)
    active = data and data.active or {}
    completed = data and data.completed or {}
    current_id = data and data.current
    if current_id then current_data = load_quest(current_id) end
end

return Quests
