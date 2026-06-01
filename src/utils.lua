-- utils.lua â€” Common utility functions for LOVE2D games.
--
-- Adds missing standard-library helpers (math.round, string split/join).
-- Require once at startup â€” functions are injected globally for convenience.
--
-- Usage:
--   require("love2d4me.src.utils")
--   math.round("up", 3.4)   --> 4
--   math.round("down", 3.7) --> 3
--   stringsplit("a,b,c", ",") --> {"a","b","c"}
--   implode(",", {"a","b","c"}) --> "a,b,c"

if not table.maxn then
    function table.maxn(tbl)
        local m = 0
        for k in pairs(tbl) do if type(k) == "number" and k > m then m = k end end
        return m
    end
end

function math.round(dir, num)
    if dir == "up" then
        return math.floor(num + 0.5)
    elseif dir == "down" then
        return math.floor(num)
    else
        return 0
    end
end

function stringsplit(str, pat)
    local t = {}
    local fpat = "(.-)" .. pat
    local last_end = 1
    local s, e, cap = str:find(fpat, 1)
    while s do
        if s ~= 1 or cap ~= "" then
            table.insert(t, cap)
        end
        last_end = e + 1
        s, e, cap = str:find(fpat, last_end)
    end
    if last_end <= #str then
        table.insert(t, str:sub(last_end))
    end
    return t
end

function implode(delimiter, parts)
    if #parts == 0 then return "" end
    if #parts == 1 then return parts[1] end
    local result = ""
    for i = 1, #parts - 1 do
        result = result .. parts[i] .. delimiter
    end
    return result .. parts[#parts]
end

function clamp(val, lo, hi)
    return math.max(lo, math.min(hi, val))
end

function lerp(a, b, t)
    return a + (b - a) * t
end

function distance(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

local _image_cache = {}
function get_image(path)
    if _image_cache[path] == nil then
        if love.filesystem.getInfo(path) then
            _image_cache[path] = love.graphics.newImage(path)
        else
            _image_cache[path] = false
        end
    end
    return _image_cache[path] or nil
end
