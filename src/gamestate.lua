-- gamestate.lua -- Shared game state machine for LOVE2D games.
--
-- Manages the lifecycle: splash â†’ menu â†’ gameplay â†’ pause.
-- Games provide a config file (game/config.json) and register
-- callbacks for gameplay update/draw.
--
-- Usage:
--   local GameState = require("love2d4me.src.gamestate")
--   GameState.init({
--       on_gameplay_update = function(dt) ... end,
--       on_gameplay_draw = function() ... end,
--       on_gameplay_keypressed = function(key) ... end,
--   })
--
-- The module takes over love.update, love.draw, love.keypressed.
-- It also auto-wires love.touchpressed and love.mousepressed so tap /
-- click works for splash skip, menu navigation, and gameplay (forwarded
-- to Input for on-screen virtual buttons). Games only implement
-- gameplay logic.

local Splash = require("love2d4me.src.splash")
local Menu = require("love2d4me.src.menu")
local Input = require("love2d4me.src.input")
local Log = require("love2d4me.src.log")
local Fonts = require("love2d4me.src.fonts")
local Storage = require("love2d4me.src.storage")
local Settings = require("love2d4me.src.settings")
local JSON = require("love2d4me.src.json")
local DayNight = require("love2d4me.src.daynight")
local Resolution = require("love2d4me.src.resolution")
local Skin = require("love2d4me.src.skin")

local GameState = {}

local state = "splash"
local config = {}
local callbacks = {}
local custom_states = {}
local loading_done = false
local loading_started = false
local loading_text = "Loading..."
local state_music = {}
local current_music = nil
local loading_dots = 0
local loading_timer = 0
local game_w, game_h = 0, 0
local _loading_bg_img = nil
local _death_bg_img = nil
local _death_bg_y = nil
local _next_frame_time = nil

local CONFIG_PATHS = {
    "game/config.json",
}

local function load_json(path)
    Log.debug("load_json: checking path", { path = path })
    local data = JSON.load(path)
    if data then
        Log.info("load_json: loaded", { path = path })
        return data
    end
    Log.warn("load_json: not found or empty", { path = path })
    return {}
end

local function load_config()
    for _, path in ipairs(CONFIG_PATHS) do
        local config_data = load_json(path)
        if next(config_data) then return config_data end
    end
    return {}
end

-- Forward declarations for mutual references
local build_options_menu
local build_video_menu
local build_controls_menu
local waiting_for_key = nil

local res_mode = "stretch"

build_video_menu = function()
    local fs = love.window.getFullscreen()
    return {
        title = "Video",
        entries = {
            { label = "Mode: " .. res_mode, action = function()
                if res_mode == "stretch" then res_mode = "fit"
                elseif res_mode == "fit" then res_mode = "nearest"
                elseif res_mode == "nearest" then res_mode = "center"
                else res_mode = "stretch" end
                Settings.set("res_mode", res_mode)
                Menu.pop()
                Menu.push(build_video_menu())
            end },
            { label = "Fullscreen: " .. (fs and "On" or "Off"), action = function()
                local new_fs = not fs
                love.window.setFullscreen(new_fs)
                Settings.set("fullscreen", new_fs)
                Menu.pop()
                Menu.push(build_video_menu())
            end },
            { label = "Back", action = function() Menu.pop() end },
        },
    }
end

build_controls_menu = function()
    local entries = {}
    local actions = Input.get_bound_actions()
    for _, action in ipairs(actions) do
        local label = Input.get_action_label(action) .. ": " .. Input.get_binding_display(action)
        table.insert(entries, { label = label, action = function()
            waiting_for_key = action
            Menu.pop()
            Menu.push({
                title = "Press a key for " .. Input.get_action_label(action) .. "...",
                entries = {
                    { label = "Cancel", action = function()
                        waiting_for_key = nil
                        Menu.pop()
                        Menu.push(build_controls_menu())
                    end },
                },
            })
        end })
    end
    table.insert(entries, { label = "Reset to Defaults", action = function()
        Input.reset_bindings()
        Menu.pop()
        Menu.push(build_controls_menu())
    end })
    table.insert(entries, { label = "Back", action = function() Menu.pop() end })
    return { title = "Controls", entries = entries }
end

build_options_menu = function()
    local vol = math.floor(love.audio.getVolume() * 100 + 0.5)
    return {
        title = "Options",
        entries = {
            { label = "Volume: " .. vol .. "%", action = function()
                local v = love.audio.getVolume()
                if v >= 0.95 then v = 0
                else v = math.min(v + 0.25, 1) end
                love.audio.setVolume(v)
                Settings.set("volume", v)
                Menu.pop()
                Menu.push(build_options_menu())
            end },
            { label = "Video Settings", action = function()
                Menu.push(build_video_menu())
            end },
            { label = "Controls", action = function()
                Menu.push(build_controls_menu())
            end },
            { label = "Back", action = function() Menu.pop() end },
        },
    }
end

local function build_credits_menu()
    local entries = {}
    for _, line in ipairs(config.credits or {}) do
        table.insert(entries, { label = line })
    end
    table.insert(entries, { label = "" })
    table.insert(entries, { label = "Back", action = function() Menu.pop() end })
    return {
        title = "Credits",
        entries = entries,
        on_cancel = function() Menu.pop() end,
    }
end

local function menu_cfg(prefix, key)
    return config[prefix .. "_" .. key] or config["menu_" .. key]
end

local function build_main_menu()
    Log.info("build_main_menu", { title = tostring(config.title) })
    local entries = {}
    table.insert(entries, {
        label = config.play_label or "Play",
        action = function()
            Menu.clear()
            loading_done = false
            loading_started = false
            loading_text = config.loading_text or "Loading..."
            state = "loading"
            Log.info("Entering loading state")
        end,
    })
    if config.options ~= false then
        table.insert(entries, {
            label = "Options",
            action = function() Menu.push(build_options_menu()) end,
        })
    end
    if config.credits then
        table.insert(entries, {
            label = "Credits",
            action = function() Menu.push(build_credits_menu()) end,
        })
    end
    table.insert(entries, {
        label = "Quit",
        action = function() love.event.quit() end,
    })
    local font_path = menu_cfg("menu_main", "font")
    local font_size = menu_cfg("menu_main", "font_size")
    local entry_font_path = menu_cfg("menu_main", "entry_font")
    local entry_font_size = menu_cfg("menu_main", "entry_font_size")
    local tfont = nil
    if font_path and font_size then
        tfont = love.graphics.newFont(font_path, font_size)
    elseif font_size then
        tfont = love.graphics.newFont(font_size)
    end
    local efont = nil
    if entry_font_path and entry_font_size then
        efont = love.graphics.newFont(entry_font_path, entry_font_size)
    elseif entry_font_size then
        efont = love.graphics.newFont(entry_font_size)
    end
    local bg_path = menu_cfg("menu_main", "bg")
    local logo_path = menu_cfg("menu_main", "logo")
    return {
        title = config.title or "LOVE2D Game",
        entries = entries,
        background = bg_path and love.graphics.newImage(bg_path) or nil,
        logo = logo_path and love.graphics.newImage(logo_path) or nil,
        title_font = tfont,
        entry_font = efont,
    }
end

local function build_pause_menu()
    return {
        title = "Paused",
        entries = {
            { label = "Resume", action = function()
                Menu.clear()
                state = "gameplay"
            end },
            { label = "Options", action = function()
                Menu.push(build_options_menu())
            end },
            { label = "Main Menu", action = function()
                Menu.clear()
                state = "menu"
                Menu.push(build_main_menu())
            end },
            { label = "Quit", action = function() love.event.quit() end },
        },
    }
end

function GameState.init(opts)
    opts = opts or {}
    callbacks = opts
    Log.init({ level = "DEBUG", file = "log.txt" })
    Log.info("GameState.init starting")
    config = load_config()
    Log.info("Config loaded", { has_keys = next(config) ~= nil })

    -- Window title from config
    love.window.setTitle(config.title or "LOVE2D Game")

    -- Window resolution from config (overrides conf.lua defaults).
    -- On the web build we override again with the actual page viewport so the
    -- game renders at native resolution and aspect — otherwise the canvas is
    -- stuck at the conf'd size and gets CSS-stretched to fit the viewport.
    local cfg_w = config.width or 800
    local cfg_h = config.height or 600
    if love.system.getOS() == "Web" then
        local dw, dh = love.window.getDesktopDimensions(1)
        if dw and dh and dw > 0 and dh > 0 then
            cfg_w, cfg_h = dw, dh
        end
    end
    love.window.setMode(cfg_w, cfg_h, { resizable = true })

    -- Identity derived from title (save directory per game)
    local identity = config.identity or config.title or "love2d-game"
    identity = identity:lower():gsub("%s+", "-"):gsub("[^%w%-]", "")
    love.filesystem.setIdentity(identity)
    Storage.init(identity)
    Settings.init({
        volume = 0.8,
        fullscreen = false,
        res_mode = "stretch",
    })
    love.audio.setVolume(Settings.get("volume") or 0.8)
    if Settings.get("fullscreen") then
        love.window.setFullscreen(true)
    end
    res_mode = Settings.get("res_mode") or "stretch"
    Log.info("Settings applied", { volume = Settings.get("volume"), fullscreen = Settings.get("fullscreen"), res_mode = res_mode })

    -- Default texture filter from config
    local filter = config.default_filter or {}
    love.graphics.setDefaultFilter(filter.min or "nearest", filter.mag or "nearest")

    if config.daynight_start then
        DayNight.set_time(config.daynight_start)
    end

    -- Window icon from config or convention path
    local icon_path = config.icon or "game/pictures/icon.png"
    if love.filesystem.getInfo(icon_path) then
        local icon_data = love.image.newImageData(icon_path)
        love.window.setIcon(icon_data)
    end

    -- Per-state music: config keys are music_<state> = "path.ogg"
    -- e.g. music_menu = "game/sound/theme.ogg", music_gameplay = "game/sound/battle.ogg"
    -- Legacy: menu_main_music maps to "menu" state, gameplay_music maps to "gameplay" state
    local music_map = {}
    for key, val in pairs(config) do
        local music_state = key:match("^music_(.+)$")
        if music_state and type(val) == "string" then
            music_map[music_state] = val
        end
    end
    -- Legacy compat
    if config.menu_main_music then music_map.menu = config.menu_main_music end
    if config.menu_pause_music then music_map.pause = config.menu_pause_music end
    if config.gameplay_music then music_map.gameplay = config.gameplay_music end
    -- Default: look for theme.ogg as menu music
    if not music_map.menu then
        for _, bp in ipairs({ "game/sound/menu.ogg", "game/sound/theme.ogg" }) do
            if love.filesystem.getInfo(bp) then music_map.menu = bp; break end
        end
    end
    -- Load all tracks
    for s, path in pairs(music_map) do
        if love.filesystem.getInfo(path) then
            local src = love.audio.newSource(path, "stream")
            src:setLooping(true)
            state_music[s] = src
            Log.info("Music loaded", { state = s, path = path })
        end
    end

    -- Resolution scaling (game logical size â†’ screen size)
    game_w = config.width or love.graphics.getWidth()
    game_h = config.height or love.graphics.getHeight()

    -- Skin: CLI arg > saved setting > platform default > config default > none
    local function platform_default_skin()
        local ps = config.platform_skins
        if not ps then return nil end
        local os_name = love.system.getOS()
        if os_name == "Android" or os_name == "iOS" then
            return ps.mobile
        end
        if os_name == "Web" then
            local w, h = love.graphics.getDimensions()
            if w <= 800 or h <= 600 then return ps.mobile end
            return ps.desktop
        end
        return ps.desktop
    end
    local skin_name = Skin.parse_args()
        or Settings.get("skin")
        or platform_default_skin()
        or config.default_skin
    if skin_name and Skin.init(skin_name, game_w, game_h) then
        local skin_w, skin_h = Skin.get_dimensions()
        -- Expand the window to fit the skin's bezel — game resolution stays the same
        love.window.setMode(skin_w, skin_h, { resizable = true })
        Resolution.set(res_mode, skin_w, skin_h, skin_w, skin_h)
        -- Skin owns button rendering and coordinate transform
        Input.set_buttons(Skin.get_buttons())
        Input.set_draw_enabled(false)
        Input.set_coord_transform(function(sx, sy)
            return Resolution.to_game(sx, sy)
        end)
        Log.info("Resolution initialized (skin)", { mode = res_mode, skin = skin_w .. "x" .. skin_h, game = game_w .. "x" .. game_h })
    else
        Resolution.set(res_mode, game_w, game_h, love.graphics.getDimensions())
        Log.info("Resolution initialized", { mode = res_mode, w = game_w, h = game_h })
    end

    -- Force a black frame so the window doesn’t appear frozen during init
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.present()

    Input.init()

    -- Update skin button labels to show actual key bindings
    if Skin.is_active() then
        for _, btn in ipairs(Skin.get_buttons()) do
            local key = Input.get_key_name(btn.action)
            if key ~= "" then
                btn.label = Input.get_key_label(key)
            end
        end
    end

    Skin.warm_picker_cache()

    Fonts.init()
    Splash.init({
        on_complete = function()
            state = "menu"
            Menu.push(build_main_menu())
        end,
    })

    -- Auto-wire tap / click dispatch. Games using GameState don't need to add
    -- love.touchpressed / love.mousepressed in their main.lua; if they want
    -- custom handling they can reassign these after calling GameState.init.
    love.touchpressed = function(id, x, y) GameState.touchpressed(id, x, y) end
    love.mousepressed = function(x, y, button) GameState.mousepressed(x, y, button) end
end

function GameState.get_state()
    return state
end

function GameState.set_state(s)
    Log.debug("GameState.set_state", { from = state, to = s })
    state = s
end

function GameState.get_config()
    return config
end

function GameState.get_game_size()
    return game_w, game_h
end

-- Register a custom game state with handlers.
-- Usage: GameState.register("battle", { update=fn, draw=fn, keypressed=fn, keyreleased=fn })
function GameState.register(name, handlers)
    custom_states[name] = handlers or {}
    Log.info("GameState.register", { state = name })
end

function GameState.update(dt)
    Log.update(dt)
    -- Per-state music: play the track for the current state, stop all others
    local wanted = state_music[state]
    if wanted ~= current_music then
        if current_music and current_music:isPlaying() then current_music:stop() end
        current_music = wanted
        if current_music then current_music:play() end
    end
    if state == "splash" then
        Splash.update(dt)
    elseif state == "loading" then
        -- First frame: draw the loading screen. Second frame: do the heavy init.
        -- This ensures the loading screen is visible before blocking.
        if not loading_started then
            loading_started = true
        elseif not loading_done then
            Log.info("Loading: calling on_gameplay_init")
            if callbacks.on_gameplay_init then
                callbacks.on_gameplay_init()
            end
            loading_done = true
            Log.info("Loading: init complete, entering gameplay")
            if callbacks.on_gameplay_start then
                callbacks.on_gameplay_start()
            else
                state = "gameplay"
            end
        end
        -- Animate loading dots
        loading_timer = loading_timer + dt
        if loading_timer > 0.3 then
            loading_timer = 0
            loading_dots = (loading_dots + 1) % 4
        end
    elseif state == "menu" or state == "pause" then -- luacheck: ignore 542
        if not Skin.is_picker_open() then
            -- menu is idle, waits for keypressed
        end
    elseif state == "gameplay" then
        if not Skin.is_picker_open() then
            if callbacks.on_gameplay_update then
                callbacks.on_gameplay_update(dt)
            end
        end
    elseif custom_states[state] and custom_states[state].update then
        if not Skin.is_picker_open() then
            custom_states[state].update(dt)
        end
    end
    if Skin.is_picker_open() then
        Skin.picker_update(Input, game_w, game_h, Resolution)
    elseif Input.pressed("skin_cycle") then
        Skin.open_picker()
    end
    -- Clear single-frame presses AFTER all state updates have read them
    Input.update()
end

function GameState.draw()
    -- All state rendering goes through the skin so menus, splash, loading
    -- all appear inside the skin viewport (e.g. the Game Boy screen).
    local function draw_content()
        if state == "splash" then
            Splash.draw()
        elseif state == "loading" then
            local sw, sh = love.graphics.getDimensions()
            love.graphics.clear(0, 0, 0, 1)
            if config.loading_bg and not _loading_bg_img then
                if love.filesystem.getInfo(config.loading_bg) then
                    _loading_bg_img = love.graphics.newImage(config.loading_bg)
                end
            end
            if _loading_bg_img then
                love.graphics.setColor(1, 1, 1, 1)
                draw_fullscreen(_loading_bg_img)
            end
            love.graphics.setColor(1, 1, 1, 1)
            local dots = string.rep(".", loading_dots)
            local text = loading_text .. dots
            local font = love.graphics.getFont()
            local tw = font:getWidth(text)
            love.graphics.print(text, (sw - tw) / 2, sh * 0.5)
            local bar_w = sw * 0.3
            local bar_h = 4
            local bar_x = (sw - bar_w) / 2
            local bar_y = sh * 0.55
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
            love.graphics.rectangle("fill", bar_x, bar_y, bar_w, bar_h)
            local fill = (math.sin(love.timer.getTime() * 3) + 1) / 2
            love.graphics.setColor(1, 1, 1, 0.8)
            love.graphics.rectangle("fill", bar_x, bar_y, bar_w * fill, bar_h)
        elseif state == "menu" or state == "pause" then
            if state == "pause" and callbacks.on_gameplay_draw then
                callbacks.on_gameplay_draw()
            end
            Menu.draw()
        elseif state == "gameplay" then
            if callbacks.on_gameplay_draw then
                callbacks.on_gameplay_draw()
            end
        elseif state == "dead" and not custom_states["dead"] then
            local sw, sh = love.graphics.getDimensions()
            love.graphics.clear(0, 0, 0, 1)
            if config.death_bg then
                if not _death_bg_img then
                    if love.filesystem.getInfo(config.death_bg) then
                        _death_bg_img = love.graphics.newImage(config.death_bg)
                    end
                end
                if _death_bg_img then
                    love.graphics.setColor(1, 1, 1, 1)
                    if config.death_bg_animate == "slide_down" then
                        _death_bg_y = math.min((_death_bg_y or -sh) + 15, 0)
                        love.graphics.draw(_death_bg_img, 0, _death_bg_y)
                    else
                        draw_fullscreen(_death_bg_img)
                    end
                end
            end
            love.graphics.setColor(0.5, 0.5, 0.5, 1)
            love.graphics.setFont(_G["pixelfonthuge"] or Fonts.get(nil, config.death_font_size or 64))
            love.graphics.printf(config.death_text or "Game Over", 0, sh * 0.3, sw, "center")
            local can_respawn = not config.death_bg_animate or not _death_bg_y or _death_bg_y >= 0
            if can_respawn then
                love.graphics.setFont(_G["pixelfontlarge"] or Fonts.get(nil, 24))
                love.graphics.printf(config.death_respawn_text or ("Press " .. Input.get_key_name("confirm") .. " to continue"), 0, sh * 0.6, sw, "center")
            end
            love.graphics.setColor(1, 1, 1, 1)
        elseif custom_states[state] and custom_states[state].draw then
            custom_states[state].draw()
        end
    end

    Skin.render(draw_content, Resolution)
    if Skin.is_picker_open() then
        Resolution.render(function() Skin.picker_draw() end)
    end
    Input.draw()

    -- FPS throttle (skip on web where sleep blocks the browser)
    if config.fps_limit and love.system.getOS() ~= "Web" then
        local target_dt = 1 / config.fps_limit
        local cur = love.timer.getTime()
        if _next_frame_time and _next_frame_time > cur then
            love.timer.sleep(_next_frame_time - cur)
        end
        _next_frame_time = love.timer.getTime() + target_dt
    end
end

function GameState.die()
    Log.info("GameState.die called")
    _death_bg_y = nil
    _death_bg_img = nil
    if callbacks.on_death then callbacks.on_death() end
    state = "dead"
end

function GameState.respawn()
    Log.info("GameState.respawn called")
    if callbacks.on_respawn then
        callbacks.on_respawn()
    end
    state = "gameplay"
end

function GameState.keypressed(key)
    -- Key capture for controls rebinding — intercept before menu navigation
    if waiting_for_key then
        if key ~= "escape" then
            Input.rebind(waiting_for_key, { key })
        end
        waiting_for_key = nil
        Menu.pop()
        Menu.push(build_controls_menu())
        return
    end
    Input.keypressed(key)
    if Skin.is_picker_open() then
        return
    end
    if state == "splash" then
        Splash.skip()
    elseif state == "menu" or state == "pause" then
        Menu.keypressed(key)
    elseif state == "gameplay" then
        if key == "escape" or key == "p" then
            state = "pause"
            Menu.push(build_pause_menu())
        elseif callbacks.on_gameplay_keypressed then
            callbacks.on_gameplay_keypressed(key)
        end
    elseif state == "dead" and not custom_states["dead"] then
        local can_respawn = not config.death_bg_animate or not _death_bg_y or _death_bg_y >= 0
        if can_respawn and (key == "return" or key == "space") then
            GameState.respawn()
        end
    elseif custom_states[state] and custom_states[state].keypressed then
        custom_states[state].keypressed(key)
    end
end

function GameState.keyreleased(key)
    Input.keyreleased(key)
    if state == "gameplay" and callbacks.on_gameplay_keyreleased then
        callbacks.on_gameplay_keyreleased(key)
    elseif custom_states[state] and custom_states[state].keyreleased then
        custom_states[state].keyreleased(key)
    end
end

-- Map Input actions to the raw keys that Menu.keypressed expects
local ACTION_TO_MENU_KEY = {
    move_up = "up", move_down = "down", move_left = "left", move_right = "right",
    confirm = "return", cancel = "escape",
}

local function forward_action_to_menu(action)
    if not action then return end
    if not (state == "menu" or state == "pause" or state == "splash") then return end
    if waiting_for_key then return end
    if state == "splash" then
        Splash.skip()
        return
    end
    local key = ACTION_TO_MENU_KEY[action]
    if key then Menu.keypressed(key) end
end

function GameState.mousepressed(x, y, button)
    if Skin.is_picker_open() then
        local gx, gy = Resolution.to_game(x, y)
        Skin.picker_click(gx, gy, game_w, game_h, Resolution, Input)
        return
    end
    local action = Input.mousepressed(x, y, button)
    forward_action_to_menu(action)
end

function GameState.mousereleased(x, y, button)
    Input.mousereleased(x, y, button)
end

function GameState.touchpressed(id, x, y)
    if Skin.is_picker_open() then
        local gx, gy = Resolution.to_game(x, y)
        Skin.picker_click(gx, gy, game_w, game_h, Resolution, Input)
        return
    end
    local action = Input.touchpressed(id, x, y)
    forward_action_to_menu(action)
end

function GameState.touchreleased(id, x, y)
    Input.touchreleased(id, x, y)
end

function GameState.touchmoved(id, x, y)
    Input.touchmoved(id, x, y)
end

function GameState.resize(w, h)
    local ori_skins = config.orientation_skins
    if ori_skins then
        local os_name = love.system.getOS()
        local is_mobile = os_name == "Android" or os_name == "iOS"
            or (os_name == "Web" and (w <= 800 or h <= 600))
        if is_mobile then
            local orientation = w > h and "landscape" or "portrait"
            local target = ori_skins[orientation]
            if target and target ~= Skin.get_name() then
                Skin.switch(target, game_w, game_h, Resolution, Input)
            end
        end
    end

    if Skin.is_active() then
        local skin_w, skin_h = Skin.get_dimensions()
        Resolution.set(res_mode, skin_w, skin_h, w, h)
    else
        Resolution.set(res_mode, game_w, game_h, w, h)
    end
end

return GameState
