-- input.lua -- Portable input abstraction for LOVE2D games.
--
-- Drop this file into any LOVE2D project. It provides:
--   - Unified action mapping (semantic names like "up", "confirm" instead of raw keys)
--   - Keyboard + touch input from a single API
--   - Auto-detection of touch devices (sticky once a touch is seen, so
--     on-screen controls stay visible for the session on web/mobile)
--   - On-screen virtual buttons (rendered automatically on touch devices)
--   - Runtime switching between input modes
--
-- Usage:
--   local Input = require("input")
--   Input.init({ width = 800, height = 600 })
--   Input.bind("up",      { keys = {"up", "w"} })
--   Input.bind("down",    { keys = {"down", "s"} })
--   Input.bind("left",    { keys = {"left", "a"} })
--   Input.bind("right",   { keys = {"right", "d"} })
--   Input.bind("confirm", { keys = {"return", "space"} })
--   Input.bind("cancel",  { keys = {"escape"} })
--
-- In love.update:
--   if Input.held("up") then ... end
--   if Input.pressed("confirm") then ... end
--
-- In love.draw (after your game):
--   Input.draw()
--
-- Wire these into your main.lua:
--   function love.keypressed(key)  Input.keypressed(key)  end
--   function love.keyreleased(key) Input.keyreleased(key) end
--   function love.touchpressed(id, x, y)   Input.touchpressed(id, x, y)   end
--   function love.touchreleased(id, x, y)  Input.touchreleased(id, x, y)  end
--   function love.touchmoved(id, x, y)     Input.touchmoved(id, x, y)     end

local Input = {}

-- State
local bindings = {}        -- action -> { keys = {}, button = nil }
local held_actions = {}    -- action -> bool (continuous hold)
local pressed_actions = {} -- action -> bool (single frame)
local touch_active = {}    -- touch_id -> action
local config = { width = 800, height = 600 }
local is_touch = false
local buttons = {}         -- array of { action, x, y, w, h, label, held }
local mode = "auto"        -- "auto", "keyboard", "touch"
local coord_transform = nil -- function(x,y)->x,y for screen-to-game conversion
local external_buttons = false -- true when skin owns the button layout
local mouse_active = nil   -- action held by mouse click
local draw_enabled = true  -- false when skin handles button rendering

-- Detection

local function detect_touch()
    if mode == "keyboard" then return false end
    if mode == "touch" then return true end
    local os_name = love.system.getOS()
    if os_name == "Android" or os_name == "iOS" then return true end
    if love.mouse and love.mouse.isCursorSupported and not love.mouse.isCursorSupported() then
        return true
    end
    -- Sticky: once any touch has been seen this session, keep on-screen
    -- controls visible even when no fingers are currently down. Without
    -- this, mobile web users see the controls flash on tap and vanish
    -- on release, leaving the game unplayable.
    if is_touch then return true end
    local touch = love.touch
    if touch and touch.getTouches then
        local touches = touch.getTouches()
        if #touches > 0 then return true end
    end
    return false
end

-- Public API

-- Standard bindings -- games get these automatically on init.
-- Games can override individual actions with Input.bind() after init,
-- or pass custom_bindings to suppress defaults entirely.
local DEFAULT_BINDINGS = {
    move_up    = { keys = {"up", "w"} },
    move_down  = { keys = {"down", "s"} },
    move_left  = { keys = {"left", "a"} },
    move_right = { keys = {"right", "d"} },
    confirm    = { keys = {"return", "space"} },
    cancel     = { keys = {"escape"} },
    sprint     = { keys = {"lshift", "rshift"} },
    shoot      = { keys = {"x"} },
    interact   = { keys = {"e", "return"} },
    pause      = { keys = {"escape", "p"} },
    tab        = { keys = {"tab"} },
    skin_cycle = { keys = {"home"} },
}

-- Canonical display order — only bound actions appear in menus.
local ACTION_ORDER = {
    "move_up", "move_down", "move_left", "move_right",
    "confirm", "cancel", "sprint", "shoot", "interact", "pause", "tab", "skin_cycle",
}

-- Human-readable labels for actions.
local ACTION_LABELS = {
    move_up    = "Move Up",
    move_down  = "Move Down",
    move_left  = "Move Left",
    move_right = "Move Right",
    confirm    = "Confirm",
    cancel     = "Cancel",
    sprint     = "Sprint",
    shoot      = "Shoot",
    interact   = "Interact",
    pause      = "Pause",
    tab        = "Tab",
    skin_cycle = "Switch Skin",
}

-- Human-readable labels for LOVE key names.
local KEY_LABELS = {
    ["return"] = "Enter", space = "Space", escape = "Esc",
    lshift = "L.Shift", rshift = "R.Shift", lctrl = "L.Ctrl", rctrl = "R.Ctrl",
    lalt = "L.Alt", ralt = "R.Alt",
    up = "Up", down = "Down", left = "Left", right = "Right",
    tab = "Tab", backspace = "Backspace", home = "Home",
}

function Input.init(opts)
    opts = opts or {}
    config.width = opts.width or love.graphics.getWidth()
    config.height = opts.height or love.graphics.getHeight()
    is_touch = detect_touch()
    -- Apply defaults unless suppressed
    if opts.bindings then
        for action, bind_opts in pairs(opts.bindings) do
            Input.bind(action, bind_opts)
        end
    else
        for action, default_bind in pairs(DEFAULT_BINDINGS) do
            if not bindings[action] then
                Input.bind(action, default_bind)
            end
        end
    end
end

function Input.set_mode(m)
    mode = m
    is_touch = detect_touch()
end

function Input.is_touch_active()
    return is_touch
end

function Input.set_coord_transform(fn)
    coord_transform = fn
end

function Input.set_buttons(btns)
    buttons = btns
    external_buttons = true
end

function Input.set_draw_enabled(enabled)
    draw_enabled = enabled
end

function Input.set_action(action, is_held, is_pressed)
    held_actions[action] = is_held
    if is_pressed then pressed_actions[action] = true end
end

function Input.bind(action, opts)
    opts = opts or {}
    bindings[action] = {
        keys = opts.keys or {},
    }
    held_actions[action] = false
    pressed_actions[action] = false
end

-- Get the display name for an action's primary key (for UI hints).
function Input.get_key_name(action)
    local binding = bindings[action]
    if binding and binding.keys and #binding.keys > 0 then
        return binding.keys[1]
    end
    return ""
end

-- Get all bound keys for an action.
function Input.get_keys(action)
    local binding = bindings[action]
    return binding and binding.keys or {}
end

-- Rebind an action to new keys. Persists via Settings if available.
function Input.rebind(action, keys)
    if not bindings[action] then
        bindings[action] = {}
        held_actions[action] = false
        pressed_actions[action] = false
    end
    bindings[action].keys = keys
    -- Try to persist via settings module
    local ok, Settings = pcall(require, "love2d4me.src.settings")
    if ok and Settings and Settings.set then
        Settings.set("input_" .. action, table.concat(keys, ","))
    end
end

-- Load saved rebindings from settings (call after Settings.init).
function Input.load_bindings()
    local ok, Settings = pcall(require, "love2d4me.src.settings")
    if not ok or not Settings then return end
    for action, _ in pairs(bindings) do
        local saved = Settings.get("input_" .. action)
        if saved and saved ~= "" then
            local keys = {}
            for k in saved:gmatch("[^,]+") do
                table.insert(keys, k)
            end
            bindings[action].keys = keys
        end
    end
end

function Input.held(action)
    if held_actions[action] then return true end
    local binding = bindings[action]
    if binding then
        for _, key in ipairs(binding.keys) do
            if love.keyboard.isDown(key) then return true end
        end
    end
    return false
end

function Input.pressed(action)
    return pressed_actions[action] == true
end

function Input.update()
    -- Clear single-frame presses
    for action, _ in pairs(pressed_actions) do
        pressed_actions[action] = false
    end
    -- Re-check touch detection periodically
    is_touch = detect_touch()
end

-- Keyboard callbacks

function Input.keypressed(key)
    for action, binding in pairs(bindings) do
        for _, k in ipairs(binding.keys) do
            if k == key then
                pressed_actions[action] = true
            end
        end
    end
end

function Input.keyreleased(key)
    -- No-op for now; held() checks live keyboard state
end

-- Touch callbacks

local function find_button(x, y)
    for _, btn in ipairs(buttons) do
        if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            return btn
        end
    end
    return nil
end

local function transform(x, y)
    if coord_transform then return coord_transform(x, y) end
    return x, y
end

function Input.touchpressed(id, x, y)
    is_touch = true
    local tx, ty = transform(x, y)
    local btn = find_button(tx, ty)
    if btn then
        touch_active[id] = btn.action
        held_actions[btn.action] = true
        pressed_actions[btn.action] = true
        btn.held = true
        return btn.action
    end
    return nil
end

function Input.touchreleased(id, x, y)
    local action = touch_active[id]
    if action then
        held_actions[action] = false
        for _, btn in ipairs(buttons) do
            if btn.action == action then btn.held = false end
        end
        touch_active[id] = nil
    end
end

function Input.touchmoved(id, x, y)
    local tx, ty = transform(x, y)
    local prev_action = touch_active[id]
    local btn = find_button(tx, ty)
    local new_action = btn and btn.action or nil

    if prev_action ~= new_action then
        if prev_action then
            held_actions[prev_action] = false
            for _, button in ipairs(buttons) do
                if button.action == prev_action then button.held = false end
            end
        end
        if new_action then
            held_actions[new_action] = true
            btn.held = true
            touch_active[id] = new_action
        else
            touch_active[id] = nil
        end
    end
end

function Input.mousepressed(x, y, button)
    if button ~= 1 then return nil end
    local tx, ty = transform(x, y)
    local btn = find_button(tx, ty)
    if btn then
        mouse_active = btn.action
        held_actions[btn.action] = true
        pressed_actions[btn.action] = true
        btn.held = true
        return btn.action
    end
    return nil
end

function Input.mousereleased(x, y, button)
    if button ~= 1 or not mouse_active then return end
    held_actions[mouse_active] = false
    for _, btn in ipairs(buttons) do
        if btn.action == mouse_active then btn.held = false end
    end
    mouse_active = nil
end

-- Controls menu helpers

-- Human-readable label for a LOVE key name.
function Input.get_key_label(key)
    if KEY_LABELS[key] then return KEY_LABELS[key] end
    if #key == 1 then return key:upper() end
    return key
end

-- Human-readable label for an action.
function Input.get_action_label(action)
    return ACTION_LABELS[action] or action
end

-- Formatted display string for an action's bound keys (e.g. "W, Up").
function Input.get_binding_display(action)
    local keys = Input.get_keys(action)
    if #keys == 0 then return "—" end
    local parts = {}
    for _, k in ipairs(keys) do
        table.insert(parts, Input.get_key_label(k))
    end
    return table.concat(parts, ", ")
end

-- Ordered list of currently-bound action names (for building menus).
function Input.get_bound_actions()
    local result = {}
    for _, action in ipairs(ACTION_ORDER) do
        if bindings[action] then
            table.insert(result, action)
        end
    end
    -- Include any custom actions not in the canonical order
    for action, _ in pairs(bindings) do
        local found = false
        for _, ordered in ipairs(ACTION_ORDER) do
            if ordered == action then found = true; break end
        end
        if not found then table.insert(result, action) end
    end
    return result
end

-- Reset all bindings to defaults and clear saved overrides.
function Input.reset_bindings()
    for action, default_bind in pairs(DEFAULT_BINDINGS) do
        bindings[action] = { keys = {} }
        for _, k in ipairs(default_bind.keys) do
            table.insert(bindings[action].keys, k)
        end
        held_actions[action] = false
        pressed_actions[action] = false
    end
    local ok, Settings = pcall(require, "love2d4me.src.settings")
    if ok and Settings and Settings.set then
        for action, _ in pairs(DEFAULT_BINDINGS) do
            Settings.set("input_" .. action, nil)
        end
    end
end

-- Virtual button layout

function Input.auto_layout()
    buttons = {}
    local w, h = config.width, config.height
    local bw, bh = 64, 64
    local pad = 12
    local left_x = pad
    local left_y = h - bh * 3 - pad * 3

    -- D-pad (bottom-left)
    local cx = left_x + bw + pad
    local cy = left_y
    table.insert(buttons, { action = "up",    x = cx,              y = cy,              w = bw, h = bh, label = "^",  held = false })
    table.insert(buttons, { action = "left",  x = cx - bw - pad,   y = cy + bh + pad,   w = bw, h = bh, label = "<",  held = false })
    table.insert(buttons, { action = "right", x = cx + bw + pad,   y = cy + bh + pad,   w = bw, h = bh, label = ">",  held = false })
    table.insert(buttons, { action = "down",  x = cx,              y = cy + (bh + pad) * 2, w = bw, h = bh, label = "v",  held = false })

    -- Action buttons (bottom-right)
    local rx = w - bw * 2 - pad * 2
    local ry = h - bh * 2 - pad * 2
    table.insert(buttons, { action = "confirm", x = rx + bw + pad, y = ry,           w = bw, h = bh, label = "A", held = false })
    table.insert(buttons, { action = "cancel",  x = rx,            y = ry + bh + pad, w = bw, h = bh, label = "B", held = false })
end

-- Drawing

function Input.draw()
    if not draw_enabled then return end
    if not is_touch then return end
    if #buttons == 0 and not external_buttons then Input.auto_layout() end

    local r, g, b, a = love.graphics.getColor()
    for _, btn in ipairs(buttons) do
        if btn.held then
            love.graphics.setColor(1, 1, 1, 0.5)
        else
            love.graphics.setColor(1, 1, 1, 0.2)
        end
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 8, 8)
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 8, 8)

        local font = love.graphics.getFont()
        local tw = font:getWidth(btn.label)
        local th = font:getHeight()
        love.graphics.print(btn.label, btn.x + (btn.w - tw) / 2, btn.y + (btn.h - th) / 2)
    end
    love.graphics.setColor(r, g, b, a)
end

return Input
