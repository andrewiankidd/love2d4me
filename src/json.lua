-- json.lua â€” Minimal JSON parser for LOVE2D games.
--
-- Handles: objects, arrays, strings, numbers, booleans, null.
-- No external dependencies. Good enough for config files.
--
-- Usage:
--   local JSON = require("love2d4me.src.json")
--   local data = JSON.decode('{"name":"Bob","hp":10,"items":["sword","shield"]}')
--   local str = JSON.encode({ name = "Bob", hp = 10 })

local JSON = {}

local function skip_ws(s, i)
    while i <= #s do
        local c = s:sub(i, i)
        if c == ' ' or c == '\t' or c == '\n' or c == '\r' then
            i = i + 1
        else
            break
        end
    end
    return i
end

local parse_value -- forward declaration

local function parse_string(s, i)
    -- i points to opening "
    i = i + 1
    local result = {}
    while i <= #s do
        local c = s:sub(i, i)
        if c == '"' then
            return table.concat(result), i + 1
        elseif c == '\\' then
            i = i + 1
            local esc = s:sub(i, i)
            if esc == '"' then table.insert(result, '"')
            elseif esc == '\\' then table.insert(result, '\\')
            elseif esc == '/' then table.insert(result, '/')
            elseif esc == 'n' then table.insert(result, '\n')
            elseif esc == 'r' then table.insert(result, '\r')
            elseif esc == 't' then table.insert(result, '\t')
            else table.insert(result, esc) end
            i = i + 1
        else
            table.insert(result, c)
            i = i + 1
        end
    end
    return table.concat(result), i
end

local function parse_number(s, i)
    local start = i
    if s:sub(i, i) == '-' then i = i + 1 end
    while i <= #s and s:sub(i, i):match('[%d%.eE%+%-]') do
        i = i + 1
    end
    local num = tonumber(s:sub(start, i - 1))
    return num, i
end

local function parse_array(s, i)
    i = i + 1 -- skip [
    local arr = {}
    i = skip_ws(s, i)
    if s:sub(i, i) == ']' then return arr, i + 1 end
    while i <= #s do
        local val
        val, i = parse_value(s, i)
        table.insert(arr, val)
        i = skip_ws(s, i)
        local c = s:sub(i, i)
        if c == ',' then
            i = skip_ws(s, i + 1)
        elseif c == ']' then
            return arr, i + 1
        end
    end
    return arr, i
end

local function parse_object(s, i)
    i = i + 1 -- skip {
    local obj = {}
    i = skip_ws(s, i)
    if s:sub(i, i) == '}' then return obj, i + 1 end
    while i <= #s do
        i = skip_ws(s, i)
        local key
        key, i = parse_string(s, i)
        i = skip_ws(s, i)
        i = i + 1 -- skip :
        i = skip_ws(s, i)
        local val
        val, i = parse_value(s, i)
        obj[key] = val
        i = skip_ws(s, i)
        local c = s:sub(i, i)
        if c == ',' then
            i = i + 1
        elseif c == '}' then
            return obj, i + 1
        end
    end
    return obj, i
end

parse_value = function(s, i)
    i = skip_ws(s, i)
    local c = s:sub(i, i)
    if c == '"' then return parse_string(s, i)
    elseif c == '{' then return parse_object(s, i)
    elseif c == '[' then return parse_array(s, i)
    elseif c == 't' then return true, i + 4
    elseif c == 'f' then return false, i + 5
    elseif c == 'n' then return nil, i + 4
    else return parse_number(s, i) end
end

function JSON.decode(s)
    if not s or s == "" then return nil end
    local val, _ = parse_value(s, 1)
    return val
end

function JSON.encode(val)
    local t = type(val)
    if t == "nil" then return "null"
    elseif t == "boolean" then return val and "true" or "false"
    elseif t == "number" then return tostring(val)
    elseif t == "string" then
        return '"' .. val:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t') .. '"'
    elseif t == "table" then
        -- Check if array (sequential integer keys)
        local is_array = #val > 0
        if is_array then
            local parts = {}
            for _, v in ipairs(val) do
                table.insert(parts, JSON.encode(v))
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            local parts = {}
            for k, v in pairs(val) do
                table.insert(parts, JSON.encode(tostring(k)) .. ":" .. JSON.encode(v))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    end
    return "null"
end

-- Helper: load and parse a JSON file via love.filesystem
function JSON.load(path)
    if love and love.filesystem and love.filesystem.getInfo(path) then
        local raw = love.filesystem.read(path)
        if raw then return JSON.decode(raw) end
    end
    return nil
end

return JSON
