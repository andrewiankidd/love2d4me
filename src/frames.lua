-- frames.lua â€” Standard sprite sheet frame layouts.
--
-- Maps direction names to frame indices for common sprite sheet formats.
-- Games reference a layout by name instead of hardcoding frame numbers.
--
-- Usage:
--   local Frames = require("love2d4me").frames
--   local layout = Frames.get("4dir_3frame")
--   anim:seek(layout.face.south)  -- frame to show when facing south
--   -- layout.walk.north = {1, 3}  -- walk cycle frames for north

local Frames = {}

local layouts = {}

-- 4-direction, 3 frames per direction (12 total)
-- Row order: N, ?, E, ?, S, ?, W, ?  (common RPG sprite sheet layout)
layouts["4dir_3frame"] = {
    face = { north = 1, east = 4, south = 7, west = 10 },
    idle = { north = 2, east = 5, south = 8, west = 11 },
    walk = { north = {1, 3}, east = {4, 6}, south = {7, 9}, west = {10, 12} },
    face_player = { north = 8, south = 2, east = 11, west = 5 },
}

-- 8-direction, 6 frames per direction (48 total)
-- Row order: S, SE, E, NE, N, NW, W, SW
layouts["8dir_6frame"] = {
    face = {
        south = 1, southeast = 7, east = 13, northeast = 19,
        north = 25, northwest = 31, west = 37, southwest = 43,
    },
    walk = {
        south = {1, 6}, southeast = {7, 12}, east = {13, 18}, northeast = {19, 24},
        north = {25, 30}, northwest = {31, 36}, west = {37, 42}, southwest = {43, 48},
    },
}

-- Simple 2-direction (left/right or facing away)
layouts["2dir"] = {
    face = { left = 1, right = 1 },
    walk = { away = {25, 30} },
}

function Frames.get(name)
    return layouts[name]
end

function Frames.register(name, layout)
    layouts[name] = layout
end

function Frames.list()
    local names = {}
    for k in pairs(layouts) do names[#names + 1] = k end
    return names
end

return Frames
