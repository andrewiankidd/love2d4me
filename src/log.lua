-- log.lua â€” Structured logger for LOVE2D games.
--
-- Outputs structured log lines to console and optionally to disk.
-- Format is LGTM-shaped: timestamp, level, message, key=value attributes.
-- Disk output goes through storage.lua if available.
--
-- Usage:
--   local Log = require("love2d4me.src.log")
--   Log.info("Menu loaded", { title = "Mode 7", entries = 3 })
--   Log.warn("Config key missing", { key = "menu_logo" })
--   Log.error("Failed to load image", { path = "game/logo.png" })
--   Log.debug("Parser result", { raw = "..." })

local Log = {}

local level_names = { "DEBUG", "INFO", "WARN", "ERROR" }
local level_values = { DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4 }
local min_level = 1 -- DEBUG by default
local log_file = nil
local log_buffer = {}
local flush_interval = 1.0
local flush_timer = 0

local function timestamp()
    if love and love.timer then
        return string.format("%.3f", love.timer.getTime())
    end
    return os.clock and string.format("%.3f", os.clock()) or "0.000"
end

local function format_attrs(attrs)
    if not attrs or not next(attrs) then return "" end
    local parts = {}
    for k, v in pairs(attrs) do
        table.insert(parts, k .. "=" .. tostring(v))
    end
    return " " .. table.concat(parts, " ")
end

local function emit(level_name, msg, attrs)
    local line = string.format("[%s] [%s] %s%s", timestamp(), level_name, msg, format_attrs(attrs))
    -- No print() â€” avoids spawning console windows on Windows.
    -- Logs go to the buffer and flush to disk via Storage.
    table.insert(log_buffer, line)
end

function Log.init(opts)
    opts = opts or {}
    if opts.level then
        min_level = level_values[opts.level:upper()] or 1
    end
    if opts.file then
        log_file = opts.file
    end
end

function Log.debug(msg, attrs)
    if min_level <= 1 then emit("DEBUG", msg, attrs) end
end

function Log.info(msg, attrs)
    if min_level <= 2 then emit("INFO", msg, attrs) end
end

function Log.warn(msg, attrs)
    if min_level <= 3 then emit("WARN", msg, attrs) end
end

function Log.error(msg, attrs)
    if min_level <= 4 then emit("ERROR", msg, attrs) end
end

function Log.update(dt)
    if not log_file then return end
    flush_timer = flush_timer + dt
    if flush_timer >= flush_interval and #log_buffer > 0 then
        flush_timer = 0
        Log.flush()
    end
end

function Log.flush()
    if not log_file or #log_buffer == 0 then return end
    local ok, Storage = pcall(require, "love2d4me.src.storage")
    if ok and Storage then
        local existing = Storage.read(log_file) or ""
        Storage.write(log_file, existing .. table.concat(log_buffer, "\n") .. "\n")
    end
    log_buffer = {}
end

return Log
