-- sprite.lua â€” Directional sprite sheet helper.
--
-- Wraps a sprite sheet with direction-aware frame ranges.
--
-- Usage:
--   local Sprite = require("love2d4me.src.sprite")
--   local protag = Sprite.load_sheet("game/npcs/protag/sprite.png", 36, 48, {
--       north = {1, 3}, south = {4, 6}, east = {7, 9}, west = {10, 12}
--   })
--   protag:set_direction("north")
--   protag:update(dt)
--   protag:draw(x, y)

local Animation = require("love2d4me.src.animation")

local Sprite = {}
Sprite.__index = Sprite

function Sprite.load_sheet(path, fw, fh, dir_ranges)
    local img = love.graphics.newImage(path)
    local anim = Animation.new(img, fw, fh, { duration = 0.1, loop = true })
    return setmetatable({
        anim = anim,
        directions = dir_ranges or {},
        current_dir = nil,
    }, Sprite)
end

function Sprite:set_direction(dir)
    if dir == self.current_dir then return end
    self.current_dir = dir
    if self.directions[dir] then
        local range = self.directions[dir]
        self.anim:set_frame(range[1])
    end
end

function Sprite:update(dt)
    if self.anim then self.anim:update(dt) end
end

function Sprite:draw(x, y, r, sx, sy)
    if self.anim then self.anim:draw(x, y, r, sx, sy) end
end

function Sprite:seek(frame)
    if self.anim then self.anim:set_frame(frame) end
end

function Sprite:get_frame()
    if self.anim then return self.anim:get_frame() end
    return 1
end

return Sprite
