-- fonts.lua -- Font loader for LOVE2D games.
--
-- Auto-discovers fonts from game/fonts/ and love2d4me/assets/fonts/.
-- TTF fonts are available at standard sizes via Fonts.get("name", size).
-- Pixel (image) fonts are loaded from the pixel/ subdirectory.
--
-- Usage:
--   local Fonts = require("love2d4me.src.fonts")
--   Fonts.init()
--   local font = Fonts.get("verdana", 36)
--   love.graphics.setFont(Fonts.get("twotrees", 48))

local Log = require("love2d4me.src.log")

local Fonts = {}

-- Standard sizes auto-loaded for each TTF
local STANDARD_SIZES = { 8, 12, 14, 16, 18, 24, 28, 32, 36, 48, 64, 72 }

-- Pixel font character map
local PIXEL_CHAR_MAP = " abcdefghijklmnopqrstuvwxyz"
    .. "ABCDEFGHIJKLMNOPQRSTUVWXYZ0"
    .. "123456789.,!?-+/():;%&`'*#=[]\""

-- Pixel font definitions (image fonts)
local PIXEL_DEFS = {
    { global = "pixelfont",       game = "game/fonts/pixelfont.png",       default = "love2d4me/assets/fonts/pixel/regular.png" },
    { global = "pixelfontlarge",  game = "game/fonts/pixelfontlarge.png",  default = "love2d4me/assets/fonts/pixel/large.png" },
    { global = "pixelfontlargew", game = "game/fonts/pixelfontlargew.png", default = "love2d4me/assets/fonts/pixel/large_white.png" },
    { global = "pixelfonthuge",   game = "game/fonts/pixelfonthuge.png",   default = "love2d4me/assets/fonts/pixel/huge.png" },
}

-- Cache: font_name -> { size -> Font object }
local ttf_cache = {}
-- Cache: font_name -> file path
local ttf_paths = {}

local function find_pixel_font(def)
    if love.filesystem.getInfo(def.game) then return def.game end
    if love.filesystem.getInfo(def.default) then return def.default end
    return nil
end

local function discover_ttf_fonts()
    local search_dirs = { "game/fonts" }
    for _, dir in ipairs(search_dirs) do
        local items = love.filesystem.getDirectoryItems(dir)
        if items then
            for _, filename in ipairs(items) do
                if filename:match("%.ttf$") or filename:match("%.otf$") then
                    local font_name = filename:gsub("%.ttf$", ""):gsub("%.otf$", ""):lower()
                    local font_path = dir .. "/" .. filename
                    ttf_paths[font_name] = font_path
                    ttf_cache[font_name] = {}
                    Log.debug("fonts: discovered TTF", { name = font_name, path = font_path })
                end
            end
        end
    end
end

local function preload_standard_sizes()
    for font_name, font_path in pairs(ttf_paths) do
        for _, size in ipairs(STANDARD_SIZES) do
            ttf_cache[font_name][size] = love.graphics.newFont(font_path, size)
        end
        Log.debug("fonts: preloaded sizes", { name = font_name, sizes = #STANDARD_SIZES })
    end
end

function Fonts.init()
    -- Load pixel (image) fonts
    for _, def in ipairs(PIXEL_DEFS) do
        local path = find_pixel_font(def)
        if path then
            _G[def.global] = love.graphics.newImageFont(path, PIXEL_CHAR_MAP)
        end
    end
    if _G["pixelfont"] then
        love.graphics.setFont(_G["pixelfont"])
        Log.info("fonts: default font set to pixelfont")
    end

    -- Discover and preload TTF fonts
    discover_ttf_fonts()
    preload_standard_sizes()

    local count = 0
    for _ in pairs(ttf_paths) do count = count + 1 end
    Log.info("fonts: loaded", { pixel = #PIXEL_DEFS, ttf = count })
end

-- Get a TTF font at a specific size. Lazy-loads if not preloaded.
-- Pass nil for font_name to get the LOVE default font at the given size.
function Fonts.get(font_name, size)
    if not font_name then
        if not ttf_cache["_default"] then ttf_cache["_default"] = {} end
        if not ttf_cache["_default"][size] then
            ttf_cache["_default"][size] = love.graphics.newFont(size)
        end
        return ttf_cache["_default"][size]
    end
    font_name = font_name:lower()
    if not ttf_cache[font_name] then
        Log.warn("fonts: unknown font", { name = font_name })
        return love.graphics.getFont()
    end
    if not ttf_cache[font_name][size] then
        local path = ttf_paths[font_name]
        if path then
            ttf_cache[font_name][size] = love.graphics.newFont(path, size)
        else
            return love.graphics.getFont()
        end
    end
    return ttf_cache[font_name][size]
end

-- List all available font names
function Fonts.list()
    local names = {}
    for name in pairs(ttf_paths) do
        table.insert(names, name)
    end
    return names
end

return Fonts
