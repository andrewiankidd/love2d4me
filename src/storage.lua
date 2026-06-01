-- storage.lua â€” Portable/home-dir storage abstraction for LOVE2D games.
--
-- All disk I/O goes through this module. On init it detects portable mode
-- (a `portable.txt` file beside the binary) and routes reads/writes to
-- either a relative directory or the user's home directory.
--
-- Portable mode:
--   fotd.exe
--   portable.txt
--   fotd/settings.json
--   fotd/saves/...
--
-- Normal mode:
--   ~/.<identity>/settings.json
--   ~/.<identity>/saves/...
--
-- Usage:
--   local Storage = require("love2d4me.src.storage")
--   Storage.init("fotd")  -- call once at startup
--
--   Storage.write("settings.json", '{"volume":0.8}')
--   local data = Storage.read("settings.json")
--   Storage.write("saves/slot1.json", save_data)
--   local files = Storage.list("saves")

local Storage = {}

local identity = "love2d-game"
local base_path = nil
local portable = false

-- Raw file helpers (no love.filesystem dependency)

local function file_exists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

local function read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local data = f:read("*a")
    f:close()
    return data
end

local function write_file(path, data)
    local f = io.open(path, "w")
    if not f then return false end
    f:write(data)
    f:close()
    return true
end

local function mkdir_p(path)
    -- Use love.filesystem if available (no shell spawn)
    if love and love.filesystem and love.filesystem.createDirectory then
        love.filesystem.createDirectory(path)
        return
    end
    -- Fallback: single os.execute call (not per-segment)
    local sep = package.config:sub(1, 1)
    if sep == "\\" then
        os.execute('mkdir "' .. path .. '" 2>nul')
    else
        os.execute('mkdir -p "' .. path .. '" 2>/dev/null')
    end
end

local function get_exe_dir()
    -- Best-effort: works on desktop, returns "." on web/unknown
    if love and love.filesystem and love.filesystem.getSourceBaseDirectory then
        local dir = love.filesystem.getSourceBaseDirectory()
        if dir and dir ~= "" then return dir end
    end
    return "."
end

local function get_home_dir()
    return os.getenv("HOME") or os.getenv("USERPROFILE") or "."
end

-- Public API

function Storage.init(app_identity)
    identity = app_identity or "love2d-game"

    local exe_dir = get_exe_dir()
    local portable_path = exe_dir .. "/portable.txt"

    if file_exists(portable_path) then
        portable = true
        base_path = exe_dir .. "/" .. identity
    else
        portable = false
        local home = get_home_dir()
        local sep = package.config:sub(1, 1)
        if sep == "\\" then
            base_path = home .. "\\" .. identity
        else
            base_path = home .. "/." .. identity
        end
    end

    mkdir_p(base_path)
end

function Storage.is_portable()
    return portable
end

function Storage.get_base_path()
    return base_path
end

function Storage.resolve(relative_path)
    if not base_path then
        Storage.init(identity)
    end
    return base_path .. "/" .. relative_path
end

function Storage.read(relative_path)
    return read_file(Storage.resolve(relative_path))
end

function Storage.write(relative_path, data)
    local full = Storage.resolve(relative_path)
    -- Ensure parent directory exists
    local dir = full:match("^(.*)[/\\]")
    if dir then mkdir_p(dir) end
    return write_file(full, data)
end

function Storage.exists(relative_path)
    return file_exists(Storage.resolve(relative_path))
end

function Storage.delete(relative_path)
    local full = Storage.resolve(relative_path)
    return os.remove(full)
end

function Storage.list(relative_dir)
    local full = Storage.resolve(relative_dir)
    local files = {}
    -- Use love.filesystem.getDirectoryItems if available (no shell spawn)
    if love and love.filesystem and love.filesystem.getDirectoryItems then
        -- love.filesystem works relative to save/source dir, so try both
        local items = love.filesystem.getDirectoryItems(relative_dir)
        if items then return items end
    end
    -- Lua 5.1 fallback using lfs if available (no shell)
    local ok, lfs = pcall(require, "lfs")
    if ok then
        for entry in lfs.dir(full) do
            if entry ~= "." and entry ~= ".." then
                table.insert(files, entry)
            end
        end
        return files
    end
    return files
end

return Storage
