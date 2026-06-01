-- dialog.lua -- NPC dialog overlay with portrait.
--
-- Shows a character portrait + paginated text at the bottom of the screen.
-- Advancing through pages with confirm key, closes after last page.
--
-- Usage:
--   local Dialog = require("love2d4me.src.dialog")
--   Dialog.open("Bob", portrait_image, {"Hello!", "How are you?", "Goodbye!"})
--
-- In love.update:  Dialog.update(dt)
-- In love.draw:    Dialog.draw()
-- In love.keypressed: Dialog.keypressed(key)


local Dialog = {}

local active = false
local speaker = ""
local portrait = nil
local pages = {}
local page_index = 1
local on_close = nil
local lines_per_page = 2

function Dialog.open(name, portrait_img, lines, opts)
    opts = opts or {}
    speaker = name or "???"
    portrait = portrait_img
    lines_per_page = opts.lines_per_page or 2
    on_close = opts.on_close

    -- Split lines into pages
    pages = {}
    local current_page = {}
    for i, line in ipairs(lines) do
        table.insert(current_page, line)
        if #current_page >= lines_per_page then
            table.insert(pages, current_page)
            current_page = {}
        end
    end
    if #current_page > 0 then
        table.insert(pages, current_page)
    end

    page_index = 1
    active = true
end

function Dialog.is_active()
    return active
end

function Dialog.advance()
    if not active then return end
    page_index = page_index + 1
    if page_index > #pages then
        active = false
        if on_close then on_close() end
    end
end

function Dialog.close()
    active = false
    if on_close then on_close() end
end

function Dialog.keypressed(key)
    if not active then return false end
    if key == "return" or key == "enter" or key == "space" then
        Dialog.advance()
        return true
    end
    if key == "escape" then
        Dialog.close()
        return true
    end
    return false
end

function Dialog.update(dt)
    -- Future: typewriter effect, etc.
end

function Dialog.draw()
    if not active or #pages == 0 then return end
    local sw, sh = love.graphics.getDimensions()
    local box_h = sh * 0.28
    local box_y = sh - box_h

    -- Box background
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, box_y, sw, box_h)
    love.graphics.setColor(1, 1, 1, 1)

    -- Portrait
    local text_x = 20
    if portrait then
        local pw, ph = portrait:getDimensions()
        local scale = math.min((box_h - 10) / ph, (sw * 0.15) / pw)
        love.graphics.draw(portrait, 10, box_y + 5, 0, scale, scale)
        text_x = 10 + pw * scale + 15
    end

    -- Speaker name
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.print(speaker, text_x, box_y + 8)
    love.graphics.setColor(1, 1, 1, 1)

    -- Dialog text
    local page = pages[page_index]
    if page then
        local ty = box_y + 30
        for _, line in ipairs(page) do
            love.graphics.print(line, text_x, ty)
            ty = ty + 20
        end
    end

    -- Page indicator
    if #pages > 1 then
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        love.graphics.printf(page_index .. "/" .. #pages, 0, sh - 20, sw - 10, "right")
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return Dialog
