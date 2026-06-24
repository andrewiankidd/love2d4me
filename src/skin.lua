-- skin.lua -- Cross-platform skin system for LOVE2D games.
--
-- Wraps the game canvas in a decorative shell with functional buttons.
-- Skins are JSON-defined and work on all platforms: desktop, mobile, web.
--
-- Selection priority: --skin CLI arg > saved setting > config.json default_skin > none
-- Web builds pass ?skin=<name> as a LOVE arg via the HTML template.
--
-- Usage:
--   local Skin = require("love2d4me.src.skin")
--   Skin.init("gameboy", game_w, game_h)
--   -- In draw:
--   Skin.render(function() draw_game() end)

local JSON = require("love2d4me.src.json")
local Log = require("love2d4me.src.log")

local lg = love.graphics

local Skin = {}

local active_skin = nil
local game_canvas = nil
local shell_image = nil
local overlay_shader = nil
local skin_buttons = {}
local skin_font = nil

-- Picker state (declared early so Skin.init can populate picker_labels)
local picker_open = false
local picker_names = {}
local picker_labels = {}
local picker_index = 1
local picker_cached = false
local picker_geometry = nil  -- { px, py, panel_w, row_h, pad, count }

local SEARCH_PATHS = {
    "game/skins/%s/skin.json",
    "love2d4me/skins/%s/skin.json",
    "skins/%s/skin.json",
}

-- Dev mode: LOVE2D4ME_DEV points to the real repo on disk.
-- LOVE's VFS can't see it, so we fall back to io.open for data files.
local dev_base = nil
do
    local dev = os.getenv("LOVE2D4ME_DEV")
    if dev then dev_base = dev:gsub("\\", "/"):gsub("/$", "") end
end

local function hex_to_rgb(hex)
    if type(hex) ~= "string" or #hex < 7 then return 0, 0, 0 end
    local r = tonumber(hex:sub(2, 3), 16) / 255
    local g = tonumber(hex:sub(4, 5), 16) / 255
    local b = tonumber(hex:sub(6, 7), 16) / 255
    return r, g, b
end

-- Read a file from LOVE's VFS, falling back to the real filesystem in dev mode.
local function read_file(vfs_path)
    if love.filesystem.getInfo(vfs_path) then
        return love.filesystem.read(vfs_path)
    end
    if dev_base and vfs_path:match("^love2d4me/") then
        local real = dev_base .. "/" .. vfs_path:sub(#"love2d4me/" + 1)
        local f = io.open(real, "rb")
        if f then
            local data = f:read("*a")
            f:close()
            return data
        end
    end
    return nil
end

-- Load an image from VFS path, with dev mode fallback.
local function load_image(vfs_path)
    if love.filesystem.getInfo(vfs_path) then
        return lg.newImage(vfs_path)
    end
    local raw = read_file(vfs_path)
    if raw then
        local fd = love.filesystem.newFileData(raw, vfs_path)
        local id = love.image.newImageData(fd)
        return lg.newImage(id)
    end
    return nil
end

-- Load a shader from VFS path, with dev mode fallback.
local function load_shader(vfs_path)
    local src = read_file(vfs_path)
    if src then
        local ok, shader = pcall(lg.newShader, src)
        if ok then return shader end
        Log.warn("Skin overlay shader failed to compile: " .. tostring(shader))
    end
    return nil
end

local function find_skin(name)
    for _, pattern in ipairs(SEARCH_PATHS) do
        local path = pattern:format(name)
        local raw = read_file(path)
        if raw then
            local data = JSON.decode(raw)
            if data then
                local dir = path:gsub("/skin%.json$", "") .. "/"
                return data, dir
            end
        end
    end
    return nil, nil
end

function Skin.init(skin_name, game_w, game_h)
    active_skin = nil
    game_canvas = nil
    shell_image = nil
    overlay_shader = nil
    skin_buttons = {}

    if not skin_name or skin_name == "" or skin_name == "none" then
        return false
    end

    local data, dir = find_skin(skin_name)
    if not data then
        Log.warn("Skin not found: " .. tostring(skin_name))
        return false
    end

    if not data.width or not data.height or not data.viewport then
        Log.warn("Skin missing required fields (width, height, viewport): " .. skin_name)
        return false
    end

    active_skin = data
    active_skin._name = skin_name
    active_skin._dir = dir
    active_skin._game_w = game_w
    active_skin._game_h = game_h
    active_skin._render_scale = data.render_scale or 1

    local rs = active_skin._render_scale
    game_canvas = lg.newCanvas(game_w * rs, game_h * rs)
    game_canvas:setFilter("linear", "linear")

    if data.shell then
        shell_image = load_image(dir .. data.shell)
        if shell_image then
            shell_image:setFilter("linear", "linear")
        end
    end

    if data.overlay then
        overlay_shader = load_shader(dir .. data.overlay)
    end

    if data.buttons then
        for _, def in ipairs(data.buttons) do
            table.insert(skin_buttons, {
                action = def.action,
                x = def.x, y = def.y,
                w = def.w, h = def.h,
                label = def.label or "",
                shape = def.shape or "rect",
                color = def.color,
                held = false,
            })
        end
    end

    skin_font = lg.newFont(10)

    picker_labels[skin_name] = data.name or skin_name

    Log.info("Skin loaded", { name = data.name or skin_name, size = data.width .. "x" .. data.height })
    return true
end

function Skin.is_active()
    return active_skin ~= nil
end

function Skin.get_dimensions()
    if not active_skin then return nil, nil end
    return active_skin.width, active_skin.height
end

function Skin.get_buttons()
    return skin_buttons
end

function Skin.render(game_draw_fn, resolution_module)
    if not active_skin then
        if resolution_module then
            resolution_module.render(game_draw_fn)
        else
            game_draw_fn()
        end
        return
    end

    -- Render game to offscreen canvas (optionally at render_scale× resolution).
    -- Override getDimensions/getWidth/getHeight so UI code that centers
    -- relative to "screen size" uses the logical game size, not the canvas.
    local rs = active_skin._render_scale or 1
    lg.setCanvas(game_canvas)
    lg.clear(0, 0, 0, 1)
    lg.push()
    lg.origin()
    if rs > 1 then lg.scale(rs, rs) end
    local real_getDimensions = lg.getDimensions
    local real_getWidth = lg.getWidth
    local real_getHeight = lg.getHeight
    local gw, gh = active_skin._game_w, active_skin._game_h
    lg.getDimensions = function() return gw, gh end
    lg.getWidth = function() return gw end
    lg.getHeight = function() return gh end
    game_draw_fn()
    lg.getDimensions = real_getDimensions
    lg.getWidth = real_getWidth
    lg.getHeight = real_getHeight
    lg.pop()
    lg.setCanvas()

    -- Draw skin (Resolution scales the skin to the window)
    local function draw_skin()
        -- Background
        if active_skin.background then
            local r, g, b = hex_to_rgb(active_skin.background)
            lg.clear(r, g, b, 1)
        else
            lg.clear(0, 0, 0, 1)
        end

        -- Shell image or procedural frame
        lg.setColor(1, 1, 1, 1)
        if shell_image then
            local sx = active_skin.width / shell_image:getWidth()
            local sy = active_skin.height / shell_image:getHeight()
            lg.draw(shell_image, 0, 0, 0, sx, sy)
        end

        -- Game canvas in viewport
        local vp = active_skin.viewport
        if vp and game_canvas then
            -- Viewport border
            if active_skin.viewport_border ~= false then
                lg.setColor(0.1, 0.1, 0.1, 1)
                local pad = 2
                lg.rectangle("fill", vp.x - pad, vp.y - pad, vp.width + pad * 2, vp.height + pad * 2, 2, 2)
            end

            -- Scale game canvas to fit viewport (canvas may be render_scale× larger)
            local scale_x = vp.width / game_canvas:getWidth()
            local scale_y = vp.height / game_canvas:getHeight()

            if overlay_shader then
                lg.setShader(overlay_shader)
                if overlay_shader:hasUniform("screen_size") then
                    overlay_shader:send("screen_size", {vp.width, vp.height})
                end
                if overlay_shader:hasUniform("time") then
                    overlay_shader:send("time", love.timer.getTime())
                end
            end

            lg.setColor(1, 1, 1, 1)
            lg.draw(game_canvas, vp.x, vp.y, 0, scale_x, scale_y)

            if overlay_shader then
                lg.setShader()
            end
        end

        -- Buttons
        Skin._draw_buttons()
    end

    if resolution_module then
        resolution_module.render(draw_skin)
    else
        draw_skin()
    end
end

function Skin._draw_buttons()
    if #skin_buttons == 0 then return end
    local pr, pg, pb, pa = lg.getColor()

    for _, btn in ipairs(skin_buttons) do
        -- Fill
        if btn.held then
            lg.setColor(1, 1, 1, 0.4)
        elseif btn.color then
            local r, g, b = hex_to_rgb(btn.color)
            lg.setColor(r, g, b, 0.8)
        else
            lg.setColor(1, 1, 1, 0.15)
        end

        if btn.shape == "circle" then
            local cx = btn.x + btn.w / 2
            local cy = btn.y + btn.h / 2
            local radius = math.min(btn.w, btn.h) / 2
            lg.circle("fill", cx, cy, radius)
            lg.setColor(1, 1, 1, 0.5)
            lg.circle("line", cx, cy, radius)
        else
            lg.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 6, 6)
            lg.setColor(1, 1, 1, 0.5)
            lg.rectangle("line", btn.x, btn.y, btn.w, btn.h, 6, 6)
        end

        -- Label
        lg.setColor(1, 1, 1, 0.9)
        local prev_font = lg.getFont()
        if skin_font then lg.setFont(skin_font) end
        local font = lg.getFont()
        local tw = font:getWidth(btn.label)
        local th = font:getHeight()
        lg.print(btn.label, btn.x + (btn.w - tw) / 2, btn.y + (btn.h - th) / 2)
        if skin_font then lg.setFont(prev_font) end
    end

    lg.setColor(pr, pg, pb, pa)
end

function Skin.get_name()
    if not active_skin then return nil end
    return active_skin._name
end

function Skin.switch(skin_name, game_w, game_h, resolution_module, input_module)
    if not skin_name or skin_name == "" then return false end
    local current = active_skin and active_skin._name
    if current == skin_name then return true end

    if not Skin.init(skin_name, game_w, game_h) then return false end

    if resolution_module then
        local skin_w, skin_h = Skin.get_dimensions()
        local win_w, win_h = love.graphics.getDimensions()
        resolution_module.set("stretch", skin_w, skin_h, win_w, win_h)
    end

    if input_module then
        input_module.set_buttons(Skin.get_buttons())
        for _, btn in ipairs(Skin.get_buttons()) do
            local key = input_module.get_key_name(btn.action)
            if key ~= "" then
                btn.label = input_module.get_key_label(key)
            end
        end
    end

    Log.info("Skin switched", { name = skin_name })
    return true
end

local function cache_skin_list()
    if picker_cached then return end
    local available = Skin.list()
    picker_names = {}
    picker_labels = {}
    for name, _ in pairs(available) do
        table.insert(picker_names, name)
    end
    table.sort(picker_names)
    for _, name in ipairs(picker_names) do
        picker_labels[name] = name
    end
    picker_cached = true
end

function Skin.warm_picker_cache()
    cache_skin_list()
end

function Skin.open_picker()
    cache_skin_list()
    if #picker_names < 2 then return end
    picker_open = true
    local current = Skin.get_name()
    for i, name in ipairs(picker_names) do
        if name == current then
            picker_index = i
            break
        end
    end
end

function Skin.close_picker()
    picker_open = false
end

function Skin.is_picker_open()
    return picker_open
end

function Skin.picker_update(input_module, game_w, game_h, resolution_module)
    if not picker_open then return end
    if input_module.pressed("move_up") then
        picker_index = picker_index - 1
        if picker_index < 1 then picker_index = #picker_names end
    end
    if input_module.pressed("move_down") then
        picker_index = picker_index + 1
        if picker_index > #picker_names then picker_index = 1 end
    end
    if input_module.pressed("confirm") then
        local chosen = picker_names[picker_index]
        if chosen ~= Skin.get_name() then
            Skin.switch(chosen, game_w, game_h, resolution_module, input_module)
            cache_skin_list()
        end
        picker_open = false
    end
    if input_module.pressed("cancel") or input_module.pressed("skin_cycle") then
        picker_open = false
    end
end

function Skin.picker_click(x, y, game_w, game_h, resolution_module, input_module)
    if not picker_open or not picker_geometry then return false end
    local g = picker_geometry
    local lx = x - g.px
    local ly = y - g.py
    if lx < 0 or lx > g.panel_w or ly < 0 or ly > g.count * g.row_h + g.pad * 2 then
        picker_open = false
        return true
    end
    local row = math.floor((ly - g.pad) / g.row_h) + 1
    if row >= 1 and row <= g.count then
        picker_index = row
        local chosen = picker_names[picker_index]
        if chosen ~= Skin.get_name() then
            Skin.switch(chosen, game_w, game_h, resolution_module, input_module)
        end
        picker_open = false
    end
    return true
end

function Skin.picker_draw()
    if not picker_open or #picker_names == 0 then return end
    if not active_skin then return end

    local font = skin_font or lg.getFont()
    local row_h = font:getHeight() + 8
    local pad = 6
    local count = #picker_names
    local panel_h = count * row_h + pad * 2
    local panel_w = 0
    for _, name in ipairs(picker_names) do
        local label = picker_labels[name] or name
        local w = font:getWidth(label)
        if w > panel_w then panel_w = w end
    end
    panel_w = panel_w + pad * 4

    local skin_w = active_skin.width
    local skin_h = active_skin.height
    local px = math.floor((skin_w - panel_w) / 2)
    local py = math.floor((skin_h - panel_h) / 2)

    picker_geometry = { px = px, py = py, panel_w = panel_w, row_h = row_h, pad = pad, count = count }

    lg.setColor(0, 0, 0, 0.85)
    lg.rectangle("fill", px, py, panel_w, panel_h, 4, 4)
    lg.setColor(1, 1, 1, 0.4)
    lg.rectangle("line", px, py, panel_w, panel_h, 4, 4)

    local prev_font = lg.getFont()
    if skin_font then lg.setFont(skin_font) end

    for i, name in ipairs(picker_names) do
        local label = picker_labels[name] or name
        local ry = py + pad + (i - 1) * row_h
        local is_current = (name == Skin.get_name())
        local is_selected = (i == picker_index)

        if is_selected then
            lg.setColor(1, 1, 1, 0.2)
            lg.rectangle("fill", px + pad, ry, panel_w - pad * 2, row_h, 3, 3)
        end

        if is_current then
            lg.setColor(0.5, 1, 0.5, 1)
        elseif is_selected then
            lg.setColor(1, 1, 1, 1)
        else
            lg.setColor(0.7, 0.7, 0.7, 1)
        end
        lg.print(label, px + pad * 2, ry + 4)
    end

    if skin_font then lg.setFont(prev_font) end
end

-- Parse --skin from LOVE's arg table (covers CLI and web query params)
function Skin.parse_args()
    if not arg then return nil end
    for i = 1, #arg do
        if arg[i] == "--skin" and arg[i + 1] then
            return arg[i + 1]
        end
    end
    return nil
end

-- List available skins by scanning known directories
function Skin.list()
    local skins = {}
    local dirs = { "game/skins", "love2d4me/skins", "skins" }
    for _, dir in ipairs(dirs) do
        local items = love.filesystem.getDirectoryItems(dir)
        if items then
            for _, name in ipairs(items) do
                local info = love.filesystem.getInfo(dir .. "/" .. name)
                if info and info.type == "directory" then
                    local json_path = dir .. "/" .. name .. "/skin.json"
                    if love.filesystem.getInfo(json_path) then
                        skins[name] = dir .. "/" .. name
                    end
                end
            end
        end
        if dev_base and dir:match("^love2d4me/") then
            local real_dir = dev_base .. "/" .. dir:sub(#"love2d4me/" + 1)
            local sep = package.config:sub(1, 1)
            local cmd = sep == "\\" and ('dir "' .. real_dir:gsub("/", "\\") .. '" /b /ad 2>nul')
                                     or ("ls -1 '" .. real_dir .. "' 2>/dev/null")
            local p = io.popen(cmd)
            if p then
                for name in p:lines() do
                    local real_json = real_dir .. "/" .. name .. "/skin.json"
                    local f = io.open(real_json, "r")
                    if f then
                        f:close()
                        skins[name] = dir .. "/" .. name
                    end
                end
                p:close()
            end
        end
    end
    return skins
end

return Skin
