-- toolbar.lua -- D-pad navigable action bar with cooldowns and submenus.
--
-- Renders a horizontal bar of labelled items at the bottom of the screen.
-- Supports item types: action, submenu, back. Cooldown timers per action.
-- Navigation via left/right, confirm to activate, cancel to go back.
--
-- Usage:
--   local Toolbar = require("love2d4me.src.toolbar")
--   Toolbar.init(game_w, game_h)
--   Toolbar.set_menu({
--       { label = "Feed",   kind = "action",  id = "feed" },
--       { label = "Tricks", kind = "submenu", submenu = tricks_menu },
--   })
--   Toolbar.update(dt, input)  -- pass Input module
--   Toolbar.draw()
--
--   Toolbar.on_activate = function(item) ... end
--   Toolbar.start_cooldown("feed", 5)

local Fonts = require("love2d4me.src.fonts")

local lg = love.graphics
local floor = math.floor

local Toolbar = {}

local menu_stack = {}
local current_menu = {}
local index = 1
local cooldowns = {}
local on_navigate = nil

local L = {}
local colors = {
    bg       = { 0, 0, 0, 0.35 },
    cell     = { 1, 1, 1, 0.08 },
    selected = { 1, 1, 1, 0.30 },
    cooldown = { 0.3, 0.3, 0.3, 0.6 },
    border   = { 1, 1, 1, 0.85 },
    text     = { 1, 1, 1, 0.9 },
    text_cd  = { 1, 1, 1, 0.35 },
    label    = { 0.2, 0.2, 0.2, 0.7 },
}

function Toolbar.init(game_w, game_h, opts)
    opts = opts or {}
    L.game_w = game_w
    L.game_h = game_h
    L.height = opts.height or floor(game_h * 0.15)
    L.margin = opts.margin or floor(game_w * 0.013)
    L.pad = opts.pad or 2
    L.gap = opts.gap or 2
    L.corner = opts.corner or floor(game_h * 0.017)
    L.font = opts.font or math.max(10, floor(game_h * 0.038))
    L.font_sm = opts.font_sm or math.max(8, floor(game_h * 0.032))
    L.label_font = opts.label_font or floor(game_h * 0.042)
    L.label_above = opts.label_above or floor(game_h * 0.058)
    L.sel_lw = opts.sel_lw or 2
    if opts.colors then
        for k, v in pairs(opts.colors) do colors[k] = v end
    end
end

function Toolbar.set_menu(items)
    current_menu = items or {}
    index = 1
    menu_stack = {}
end

function Toolbar.push_menu(items, start_index)
    table.insert(menu_stack, { menu = current_menu, index = index })
    current_menu = items or {}
    index = start_index or 1
end

function Toolbar.pop_menu()
    if #menu_stack == 0 then return false end
    local prev = table.remove(menu_stack)
    current_menu = prev.menu
    index = prev.index
    return true
end

function Toolbar.get_selected()
    return current_menu[index]
end

function Toolbar.get_index()
    return index
end

function Toolbar.set_on_navigate(fn)
    on_navigate = fn
end

function Toolbar.start_cooldown(id, duration)
    cooldowns[id] = duration
end

function Toolbar.is_on_cooldown(id)
    return cooldowns[id] and cooldowns[id] > 0
end

function Toolbar.get_cooldown(id)
    return cooldowns[id] or 0
end

function Toolbar.update(dt, input)
    for k, t in pairs(cooldowns) do
        cooldowns[k] = t - dt
        if cooldowns[k] <= 0 then cooldowns[k] = nil end
    end

    if not input then return nil end

    if input.pressed("move_left") then
        index = index - 1
        if index < 1 then index = #current_menu end
        if on_navigate then on_navigate() end
    end
    if input.pressed("move_right") then
        index = index + 1
        if index > #current_menu then index = 1 end
        if on_navigate then on_navigate() end
    end

    if input.pressed("confirm") then
        local item = current_menu[index]
        if item then
            if item.kind == "submenu" and item.submenu then
                Toolbar.push_menu(item.submenu, 2)
                return nil
            elseif item.kind == "back" then
                Toolbar.pop_menu()
                return nil
            else
                return item
            end
        end
    end

    if input.pressed("cancel") then
        if Toolbar.pop_menu() then return nil end
    end

    return nil
end

function Toolbar.draw()
    if #current_menu == 0 then return end

    local bar_y = L.game_h - L.height - L.margin
    local count = #current_menu

    lg.setColor(colors.bg)
    lg.rectangle("fill", L.margin, bar_y, L.game_w - L.margin * 2, L.height, L.corner, L.corner)

    local inner_w = L.game_w - L.margin * 2 - L.pad * 2
    local item_w = (inner_w - (count - 1) * L.gap) / count
    local item_h = L.height - L.pad * 2

    local font_size = count > 6 and L.font_sm or L.font
    lg.setFont(Fonts.get(nil, font_size))

    for i, item in ipairs(current_menu) do
        local ix = L.margin + L.pad + (i - 1) * (item_w + L.gap)
        local iy = bar_y + L.pad
        local selected = (i == index)
        local cd = item.id and Toolbar.is_on_cooldown(item.id)

        lg.setColor(cd and colors.cooldown or (selected and colors.selected or colors.cell))
        lg.rectangle("fill", ix, iy, item_w, item_h, 3, 3)

        if selected then
            lg.setColor(colors.border)
            lg.setLineWidth(L.sel_lw)
            lg.rectangle("line", ix, iy, item_w, item_h, 3, 3)
            lg.setLineWidth(1)
        end

        lg.setColor(cd and colors.text_cd or colors.text)
        local font = lg.getFont()
        lg.printf(item.label, ix, iy + (item_h - font:getHeight()) / 2, item_w, "center")
    end

    local sel = current_menu[index]
    if sel then
        lg.setFont(Fonts.get(nil, L.label_font))
        lg.setColor(colors.label)
        local label = sel.label
        if sel.id and Toolbar.is_on_cooldown(sel.id) then
            label = label .. " (" .. floor(cooldowns[sel.id]) .. "s)"
        end
        lg.printf(label, 0, bar_y - L.label_above, L.game_w, "center")
    end
end

return Toolbar
