-- settings.lua â€” Persistent game settings backed by storage.lua.
--
-- Saves to <storage_root>/settings.json. Loads on init, writes on change.
-- Games define their own defaults; saved values override them.
--
-- Usage:
--   local Settings = require("love2d4me.src.settings")
--   Settings.init({
--       volume     = 0.8,
--       fullscreen = false,
--       width      = 800,
--       height     = 600,
--       vsync      = true,
--       controls   = "auto",
--   })
--
--   Settings.get("volume")          --> 0.8
--   Settings.set("volume", 0.5)     --> saves immediately
--   Settings.apply_window()         --> applies width/height/fullscreen/vsync

local Storage = require("love2d4me.src.storage")

local Settings = {}

local FILENAME = "settings.json"
local defaults = {}
local current = {}
local dirty = false

-- Minimal JSON encode/decode (no external deps)

local function json_encode(t)
    local parts = {}
    for k, v in pairs(t) do
        local val
        if type(v) == "string" then
            val = '"' .. v:gsub('"', '\\"') .. '"'
        elseif type(v) == "boolean" then
            val = v and "true" or "false"
        else
            val = tostring(v)
        end
        table.insert(parts, '"' .. k .. '":' .. val)
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

local function json_decode(str)
    if not str or str == "" then return {} end
    local t = {}
    for k, v in str:gmatch('"([^"]+)"%s*:%s*(".-"|[^,}]+)') do
        v = v:match("^%s*(.-)%s*$") -- trim
        if v == "true" then
            t[k] = true
        elseif v == "false" then
            t[k] = false
        elseif v:match('^".*"$') then
            t[k] = v:sub(2, -2)
        elseif tonumber(v) then
            t[k] = tonumber(v)
        else
            t[k] = v
        end
    end
    return t
end

-- Public API

function Settings.init(game_defaults)
    defaults = game_defaults or {}

    -- Start with defaults
    for k, v in pairs(defaults) do
        current[k] = v
    end

    -- Overlay saved values
    local raw = Storage.read(FILENAME)
    if raw then
        local saved = json_decode(raw)
        for k, v in pairs(saved) do
            current[k] = v
        end
    end
end

function Settings.get(key)
    return current[key]
end

function Settings.set(key, value)
    if current[key] == value then return end
    current[key] = value
    Settings.save()
end

function Settings.save()
    Storage.write(FILENAME, json_encode(current))
end

function Settings.reset()
    for k, v in pairs(defaults) do
        current[k] = v
    end
    Settings.save()
end

function Settings.all()
    local copy = {}
    for k, v in pairs(current) do copy[k] = v end
    return copy
end

-- Apply window settings (call after love.load or on settings change)
function Settings.apply_window()
    if not love or not love.window then return end
    local w = current.width or 800
    local h = current.height or 600
    local fs = current.fullscreen or false
    local vs = current.vsync ~= false
    love.window.setMode(w, h, {
        fullscreen = fs,
        vsync = vs and 1 or 0,
        resizable = true,
    })
end

return Settings
