-- parallax.lua — Multi-layer parallax scrolling.
--
-- Each layer has an image and a depth factor (0 = static, 1 = moves with camera).
--
-- Usage:
--   local Parallax = require("love2d4me").parallax
--   local layers = Parallax.new()
--   layers:add("game/maps/spawn/sky.png", 0.5)
--   layers:add("game/maps/spawn/background.png", 1.0)
--   layers:draw(camera_x, camera_y)

local Parallax = {}
Parallax.__index = Parallax

function Parallax.new()
    return setmetatable({ layers = {} }, Parallax)
end

function Parallax:add(image_or_path, depth, offset_y)
    local img = image_or_path
    if type(img) == "string" then
        if love.filesystem.getInfo(img) then
            img = love.graphics.newImage(img)
        else
            return
        end
    end
    if not img then return end
    self.layers[#self.layers + 1] = {
        image = img,
        depth = depth or 1.0,
        offset_y = offset_y or 0,
    }
end

function Parallax:draw(camera_x, camera_y)
    for _, layer in ipairs(self.layers) do
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(layer.image,
            (camera_x or 0) * layer.depth,
            (camera_y or 0) * layer.depth + layer.offset_y)
    end
end

function Parallax:clear()
    self.layers = {}
end

return Parallax
