-- menu.lua -- Generic menu system for LOVE2D games.
--
-- Data-driven menus: define entries with labels and callbacks.
-- Handles rendering (centered, highlighted selection) and input
-- (up/down/confirm/cancel). Supports stacking (push/pop) for
-- submenus like options â†’ video â†’ back.
--
-- Usage:
--   local Menu = require("love2d4me.src.menu")
--
--   Menu.push({
--       title = "My Game",
--       entries = {
--           { label = "New Game",  action = function() gamemode = "gameplay" end },
--           { label = "Options",   action = function() Menu.push(options_menu) end },
--           { label = "Quit",      action = function() love.event.quit() end },
--       },
--       background = love.graphics.newImage("assets/menu_bg.png"),  -- optional
--       on_cancel = function() end,  -- optional, escape key
--   })
--
-- In love.keypressed:
--   Menu.keypressed(key)
--
-- In love.draw:
--   Menu.draw()
--
-- Menu.is_active() returns true if any menu is showing.

local Menu = {}

local stack = {}

local function current()
    return stack[#stack]
end

function Menu.push(def)
    def.index = 1
    table.insert(stack, def)
end

function Menu.pop()
    table.remove(stack)
end

function Menu.clear()
    stack = {}
end

function Menu.is_active()
    return #stack > 0
end

function Menu.keypressed(key)
    local current_menu = current()
    if not current_menu then return false end

    -- Grid layout: spatial navigation (left/right within a row, up/down by row).
    if current_menu.layout == "grid" then
        local n = #current_menu.entries
        local cols = current_menu.columns or 2
        if key == "left" or key == "a" then
            if current_menu.index % cols ~= 1 then current_menu.index = current_menu.index - 1 end
        elseif key == "right" or key == "d" then
            if current_menu.index % cols ~= 0 and current_menu.index < n then current_menu.index = current_menu.index + 1 end
        elseif key == "up" or key == "w" then
            if current_menu.index - cols >= 1 then current_menu.index = current_menu.index - cols end
        elseif key == "down" or key == "s" then
            if current_menu.index + cols <= n then current_menu.index = current_menu.index + cols end
        elseif key == "return" or key == "enter" or key == "space" then
            local entry = current_menu.entries[current_menu.index]
            if entry and entry.action then entry.action() end
        elseif key == "escape" then
            if current_menu.on_cancel then current_menu.on_cancel() else Menu.pop() end
        end
        return true
    end

    if key == "up" or key == "w" then
        current_menu.index = current_menu.index - 1
        if current_menu.index < 1 then current_menu.index = #current_menu.entries end
        return true
    elseif key == "down" or key == "s" then
        current_menu.index = current_menu.index + 1
        if current_menu.index > #current_menu.entries then current_menu.index = 1 end
        return true
    elseif key == "return" or key == "enter" or key == "space" then
        local entry = current_menu.entries[current_menu.index]
        if entry and entry.action then
            entry.action()
        end
        return true
    elseif key == "escape" then
        if current_menu.on_cancel then
            current_menu.on_cancel()
        else
            Menu.pop()
        end
        return true
    end
    return false
end

-- Grid layout: a row/column of coloured tiles (cartridge-select style).
-- Entries may carry an `color` ({r,g,b}); the menu may set `columns`, `hint`,
-- `title_color`. Title + tile labels use title_font / entry_font.
local function draw_grid(m, sw, sh)
    local title_font = m.title_font or love.graphics.getFont()
    local entry_font = m.entry_font or love.graphics.getFont()

    if m.background then
        love.graphics.setColor(1, 1, 1, 1)
        local bw, bh = m.background:getDimensions()
        love.graphics.draw(m.background, 0, 0, 0, sw / bw, sh / bh)
    end

    local tc = m.title_color or { 0.95, 0.82, 0.18 }
    love.graphics.setFont(title_font)
    love.graphics.setColor(tc[1], tc[2], tc[3], 1)
    love.graphics.print(m.title or "", sw * 0.05, sh * 0.05)

    local cols = m.columns or 2
    local tw, th = sw * 0.40, sh * 0.15
    local gx, gy = sw * 0.05, sh * 0.24
    local gapx, gapy = sw * 0.06, sh * 0.04
    love.graphics.setFont(entry_font)
    for i, entry in ipairs(m.entries) do
        local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
        local x = gx + col * (tw + gapx)
        local y = gy + row * (th + gapy)
        local c = entry.color or { 0.4, 0.4, 0.4 }
        local sel = (i == m.index)
        local mul = sel and 1 or 0.45
        love.graphics.setColor(c[1] * mul, c[2] * mul, c[3] * mul, 1)
        love.graphics.rectangle("fill", x, y, tw, th, 10, 10)
        if sel then love.graphics.setColor(1, 1, 1, 1) else love.graphics.setColor(0, 0, 0, 0.4) end
        love.graphics.setLineWidth(4)
        love.graphics.rectangle("line", x, y, tw, th, 10, 10)
        love.graphics.setColor(1, 1, 1, sel and 1 or 0.85)
        love.graphics.print(entry.label,
            math.floor(x + (tw - entry_font:getWidth(entry.label)) / 2),
            math.floor(y + (th - entry_font:getHeight()) / 2))
        entry._rect = { x = x, y = y, w = tw, h = th }
    end

    if m.hint then
        love.graphics.setColor(0.5, 0.52, 0.58, 1)
        love.graphics.print(m.hint, sw * 0.05, sh * 0.92)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function Menu.draw()
    local current_menu = current()
    if not current_menu then return end

    local sw, sh = love.graphics.getDimensions()

    if current_menu.layout == "grid" then
        draw_grid(current_menu, sw, sh)
        return
    end

    -- Background (stretch to fill canvas)
    if current_menu.background then
        love.graphics.setColor(1, 1, 1, 1)
        local bw, bh = current_menu.background:getDimensions()
        love.graphics.draw(current_menu.background, 0, 0, 0, sw / bw, sh / bh)
    end

    local prev_font = love.graphics.getFont()
    local title_font = current_menu.title_font or prev_font
    local entry_font = current_menu.entry_font or prev_font
    local spacing = current_menu.spacing or math.ceil(entry_font:getHeight() * 1.6)

    -- Measure total content height to center vertically
    local logo_h = 0
    local logo_scale = 1
    if current_menu.logo then
        local lw, lh = current_menu.logo:getDimensions()
        logo_scale = math.min(sh * 0.25 / lh, sw * 0.4 / lw)
        logo_h = lh * logo_scale + 20
    end
    local title_h = title_font:getHeight() + 20
    local entries_h = #current_menu.entries * spacing
    local total_h = logo_h + title_h + entries_h
    local top_y = math.max(20, (sh - total_h) / 2)

    -- Logo
    if current_menu.logo then
        love.graphics.setColor(1, 1, 1, 1)
        local lw, _ = current_menu.logo:getDimensions()
        local lx = (sw - lw * logo_scale) / 2
        love.graphics.draw(current_menu.logo, lx, top_y, 0, logo_scale, logo_scale)
        top_y = top_y + logo_h
    end

    -- Title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(title_font)
    love.graphics.printf(current_menu.title or "", 0, top_y, sw, "center")
    top_y = top_y + title_h

    -- Entries (scrollable when they exceed available height)
    love.graphics.setFont(entry_font)
    local start_y = current_menu.entries_y or top_y
    local bottom_margin = 20
    local available_h = sh - start_y - bottom_margin
    local n = #current_menu.entries
    local visible = math.max(1, math.floor(available_h / spacing))

    local scroll_offset = 0
    if n > visible then
        scroll_offset = math.min(current_menu.index - 1, n - visible)
        scroll_offset = math.max(0, scroll_offset)
    end

    local first = scroll_offset + 1
    local last = math.min(n, scroll_offset + visible)

    -- Scroll indicator above
    if scroll_offset > 0 then
        love.graphics.setColor(1, 1, 1, 0.4)
        love.graphics.printf("...", 0, start_y - spacing * 0.6, sw, "center")
    end

    for i = first, last do
        local entry = current_menu.entries[i]
        if i == current_menu.index then
            love.graphics.setColor(1, 1, 0, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        local entry_y = start_y + (i - first) * spacing
        love.graphics.printf(entry.label, 0, entry_y, sw, "center")
        entry._rect = { x = 0, y = entry_y, w = sw, h = spacing }
    end

    -- Scroll indicator below
    if last < n then
        love.graphics.setColor(1, 1, 1, 0.4)
        love.graphics.printf("...", 0, start_y + (last - first + 1) * spacing * 0.7, sw, "center")
    end

    love.graphics.setFont(prev_font)
    love.graphics.setColor(1, 1, 1, 1)
end

function Menu.get_index()
    local current_menu = current()
    return current_menu and current_menu.index or 0
end

-- Tap / click activation. Hit-tests the entry rectangles captured during
-- Menu.draw (entry._rect). On match: select that entry and run its action.
-- Coordinates are in screen-space — Menu draws outside Resolution.render so
-- the rects are stored in the same space as love.touchpressed / mousepressed.
function Menu.touchpressed(x, y)
    local current_menu = current()
    if not current_menu then return false end
    for i, entry in ipairs(current_menu.entries) do
        local r = entry._rect
        if r and x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h then
            current_menu.index = i
            if entry.action then entry.action() end
            return true
        end
    end
    return false
end

function Menu.mousepressed(x, y, button)
    if button ~= 1 then return false end
    return Menu.touchpressed(x, y)
end

return Menu
