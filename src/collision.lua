-- collision.lua â€” Pixel-color collision map reader.
--
-- Reads pixel colors at world coordinates to determine walkability,
-- warps, hazards, etc. Red channel encodes permission type.
--
-- Usage:
--   local Collision = require("love2d4me.src.collision")
--   local col = Collision.new(image_data_or_path, {
--       [0]   = "solid",
--       [255] = "walk",
--       [128] = "hazard",
--       [64]  = "grapple",
--   }, {
--       [150] = { target = "town", spawn = { x = 100, y = 200 } },
--       [151] = { target = "cave", spawn = { x = 50, y = 300 } },
--   })
--
--   local perm = col:check(world_x, world_y)
--   if perm == "warp" then
--       local warp = col:get_warp(world_x, world_y)
--       loadmap(warp.target, warp.spawn)
--   end

local Collision = {}
Collision.__index = Collision

function Collision.new(source, color_map, warps)
    local img
    if type(source) == "string" then
        img = love.image.newImageData(source)
    else
        img = source
    end
    return setmetatable({
        data = img,
        w = img:getWidth(),
        h = img:getHeight(),
        color_map = color_map or {},
        warps = warps or {},
    }, Collision)
end

function Collision:color_at(px, py)
    px = math.floor(px)
    py = math.floor(py)
    if px < 0 or py < 0 or px >= self.w or py >= self.h then
        return -1
    end
    local r = self.data:getPixel(px, py)
    return math.floor(r * 255 + 0.5)
end

function Collision:check(x, y)
    local color_index = self:color_at(x, y)
    if color_index == -1 then return "solid" end
    if self.warps[color_index] then return "warp" end
    return self.color_map[color_index] or "unknown"
end

function Collision:get_warp(x, y)
    local color_index = self:color_at(x, y)
    return self.warps[color_index]
end

function Collision:check_rect(x, y, w, h)
    local tl = self:check(x, y)
    local tr = self:check(x + w, y)
    local bl = self:check(x, y + h)
    local br = self:check(x + w, y + h)
    if tl == tr and tr == bl and bl == br then
        return tl
    end
    for _, perm in ipairs({tl, tr, bl, br}) do
        if perm == "warp" then return "warp" end
        if perm == "solid" then return "solid" end
        if perm == "hazard" then return "hazard" end
    end
    return tl
end

function Collision:get_warp_rect(x, y, w, h)
    for _, pos in ipairs({{x,y}, {x+w,y}, {x,y+h}, {x+w,y+h}}) do
        local warp = self:get_warp(pos[1], pos[2])
        if warp then return warp end
    end
    return nil
end

function Collision:try_move(x, y, w, h, dx, dy)
    local nx, ny = x + dx, y + dy
    local perm = self:check_rect(nx, ny, w, h)
    return perm, nx, ny
end

return Collision
