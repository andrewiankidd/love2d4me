-- projection.lua -- World-to-screen coordinate transforms.
--
-- Three projection modes for different game types:
--   orthographic -- flat 2D with camera offset (top-down, platformer)
--   mode7        -- retro-style scanline perspective (pseudo-3D ground plane)
--   oblique      -- ground-plane perspective with horizon (2.5D city, racing)
--
-- Usage:
--   local Projection = require("love2d4me.src.projection")
--
--   -- Orthographic (top-down / platformer)
--   local sx, sy = Projection.orthographic(world_x, world_y, cam_x, cam_y)
--
--   -- Mode7 (scanline ground plane)
--   Projection.mode7(cam_x, cam_y, texture, { ox=0, oy=0, r=0, s=0.0075 })
--
--   -- Oblique (2.5D perspective)
--   local proj = Projection.oblique_camera({ x=0, y=0, angle=0, height=9,
--       focal=400, horizon=0.4, near=3 })
--   local sx, sy, depth = proj:project(world_x, world_y, world_z)

local Projection = {}

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- Orthographic -- direct mapping with camera offset
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

function Projection.orthographic(wx, wy, cam_x, cam_y)
    return wx + (cam_x or 0), wy + (cam_y or 0)
end

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- Mode7 -- retro-style scanline perspective
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

function Projection.mode7(cam_x, cam_y, texture, opts)
    opts = opts or {}
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()
    local ox = opts.ox or 0
    local oy = opts.oy or 0
    local r = opts.r or 0
    local s = opts.s or 0.0075
    for scanline = 1, sh do
        love.graphics.setScissor(0, scanline, sw, 1)
        love.graphics.draw(texture, sw / 2 + ox, sh / 2 + oy, r,
            scanline * s, scanline * s, cam_x, cam_y)
    end
    love.graphics.setScissor()
end

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- Oblique -- ground-plane perspective with horizon line
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

local ObliqueCamera = {}
ObliqueCamera.__index = ObliqueCamera

function Projection.oblique_camera(opts)
    return setmetatable({
        x = opts.x or 0,
        y = opts.y or 0,
        angle = opts.angle or 0,
        height = opts.height or 9,
        focal = opts.focal or 400,
        horizon_frac = opts.horizon or 0.4,
        near = opts.near or 3,
        anchor = opts.anchor or 0.84,
    }, ObliqueCamera)
end

function ObliqueCamera:camera_space(wx, wy)
    local dx, dy = wx - self.x, wy - self.y
    local ca, sa = math.cos(self.angle), math.sin(self.angle)
    return dx * ca + dy * sa, -dx * sa + dy * ca
end

function ObliqueCamera:project(wx, wy, wz)
    local right, fwd = self:camera_space(wx, wy)
    if fwd <= self.near then return nil, nil, fwd end
    local sw, sh = love.graphics.getDimensions()
    local scale = self.focal / fwd
    local sx = sw / 2 + right * scale
    local sy = sh * self.horizon_frac + (self.height - (wz or 0)) * scale
    return sx, sy, fwd
end

function ObliqueCamera:forward_dir()
    return -math.sin(self.angle), math.cos(self.angle)
end

function ObliqueCamera:ground_distance()
    local sh = love.graphics.getHeight()
    return self.height * self.focal / (sh * (self.anchor - self.horizon_frac))
end

return Projection
