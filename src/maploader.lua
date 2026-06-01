-- maploader.lua â€” Shared map loading for LOVE2D games.
--
-- Loads maps from game/maps/<name>/ with a standard file layout:
--
--   game/maps/town/
--     config.json      â€” warps, NPCs, items, mobs, metadata
--     background.png   â€” base layer
--     collision.png    â€” pixel-color collision (optional, preferred)
--     overlay.png      â€” drawn above sprites (optional)
--     lights.png       â€” light map for day/night (optional)
--     sky.png          â€” parallax sky layer (optional, platformer)
--     main.png         â€” main terrain layer (optional, platformer)
--
-- Collision: pixel-color via collision.png â€” red channel encodes permissions.
-- Use Collision module for structured access with named permission strings.
--
-- Usage:
--   local MapLoader = require("love2d4me.src.maploader")
--   local map = MapLoader.load("town")
--   -- map.background, map.collision, map.overlay, map.lights, map.config, etc.

local Log = require("love2d4me.src.log")
local JSON = require("love2d4me.src.json")

local MapLoader = {}

local BASE = "game/maps/"

local function file_exists(path)
    return love.filesystem.getInfo(path) ~= nil
end

local function load_json(path)
    local data = JSON.load(path)
    if data then return data end
    return t
end

-- Load a legacy map.lua file and capture the globals it sets
local function load_legacy_map_lua(path)
    if not file_exists(path) then return {} end
    -- Capture globals before and after
    local before = {}
    for k, v in pairs(_G) do before[k] = true end
    love.filesystem.load(path)()
    local result = {}
    for k, v in pairs(_G) do
        if not before[k] then
            result[k] = v
        end
    end
    return result
end

function MapLoader.load(mapname)
    local dir = BASE .. mapname .. "/"
    Log.info("MapLoader.load", { map = mapname, dir = dir })

    local map = {
        name = mapname,
        dir = dir,
        config = {},
        background = nil,
        collision = nil,
        collision_data = nil,
        overlay = nil,
        lights = nil,
        sky = nil,
        main_layer = nil,
        has_lights = false,
        has_sky = false,
    }

    -- Load config: prefer config.json, fall back to legacy map.lua
    local json_path = dir .. "config.json"
    local lua_path = dir .. "map.lua"
    if file_exists(json_path) then
        map.config = load_json(json_path)
        Log.debug("MapLoader: loaded config.json", { map = mapname })
    elseif file_exists(lua_path) then
        map.config = load_legacy_map_lua(lua_path)
        Log.debug("MapLoader: loaded legacy map.lua", { map = mapname })
    end

    -- Load images
    if file_exists(dir .. "background.png") then
        map.background = love.graphics.newImage(dir .. "background.png")
    end
    if file_exists(dir .. "collision.png") then
        map.collision = love.image.newImageData(dir .. "collision.png")
        map.collision_mode = "pixel"
    end
    if file_exists(dir .. "overlay.png") then
        map.overlay = love.graphics.newImage(dir .. "overlay.png")
    end
    if file_exists(dir .. "lights.png") then
        map.lights = love.graphics.newImage(dir .. "lights.png")
        map.has_lights = true
    end
    if file_exists(dir .. "sky.png") then
        map.sky = love.graphics.newImage(dir .. "sky.png")
        map.has_sky = true
    end
    if file_exists(dir .. "main.png") then
        map.main_layer = love.graphics.newImage(dir .. "main.png")
    end

    Log.info("MapLoader: loaded", {
        map = mapname,
        has_bg = map.background ~= nil,
        has_collision = map.collision ~= nil,
        has_overlay = map.overlay ~= nil,
        has_lights = map.has_lights,
        has_sky = map.has_sky,
    })

    return map
end

-- Read a pixel from the collision map (FotD-style).
-- Returns the red channel as 0-255.
function MapLoader.collision_at(map, x, y)
    if not map.collision then return 0 end
    x = math.floor(x)
    y = math.floor(y)
    if x < 0 or y < 0 or x >= map.collision:getWidth() or y >= map.collision:getHeight() then
        return 0
    end
    local red_channel = map.collision:getPixel(x, y)
    return math.floor(red_channel * 255 + 0.5)
end

return MapLoader
