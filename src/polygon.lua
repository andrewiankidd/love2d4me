-- polygon.lua â€” Polygon geometry utilities.
--
-- Point-in-polygon, near-plane clipping, and depth sorting for
-- games with polygon-based world geometry (buildings, zones, terrain).
--
-- Polygons are flat arrays: { x1, y1, x2, y2, ... }
--
-- Usage:
--   local Polygon = require("love2d4me.src.polygon")
--
--   if Polygon.contains(ring, px, py) then ... end
--
--   local clipped = Polygon.clip_near(ring, camera, near_dist)
--   -- clipped = { {x, y, fwd}, ... } or nil if fully behind
--
--   local sorted = Polygon.depth_sort(objects, camera)

local Polygon = {}

-- Ray-cast point-in-polygon test against a flat {x,y,...} ring.
function Polygon.contains(ring, px, py)
    local inside = false
    local n = #ring
    local jx, jy = ring[n - 1], ring[n]
    for i = 1, n, 2 do
        local ix, iy = ring[i], ring[i + 1]
        if ((iy > py) ~= (jy > py)) and
           (px < (jx - ix) * (py - iy) / (jy - iy) + ix) then
            inside = not inside
        end
        jx, jy = ix, iy
    end
    return inside
end

-- Remove duplicate closing vertex if ring is explicitly closed.
function Polygon.open_ring(pts)
    local n = #pts
    if n >= 4 and pts[1] == pts[n - 1] and pts[2] == pts[n] then
        local out = {}
        for i = 1, n - 2 do out[i] = pts[i] end
        return out
    end
    return pts
end

-- Compute centroid of a flat {x, y, ...} ring.
function Polygon.centroid(pts)
    local sx, sy, count = 0, 0, 0
    for i = 1, #pts, 2 do
        sx = sx + pts[i]
        sy = sy + pts[i + 1]
        count = count + 1
    end
    if count == 0 then return 0, 0 end
    return sx / count, sy / count
end

-- Bounding radius from centroid.
function Polygon.bounding_radius(pts, cx, cy)
    local r2 = 0
    for i = 1, #pts, 2 do
        local dx, dy = pts[i] - cx, pts[i + 1] - cy
        local d2 = dx * dx + dy * dy
        if d2 > r2 then r2 = d2 end
    end
    return math.sqrt(r2)
end

-- Sutherland-Hodgman clip: cut a world-space ring to the half-plane
-- fwd >= clip_dist. camera_space_fn(wx, wy) must return (right, fwd).
-- Returns array of {x, y, fwd} vertices (>= 3), or nil if fully behind.
function Polygon.clip_near(ring, camera_space_fn, clip_dist)
    local verts = {}
    for i = 1, #ring, 2 do
        local _, f = camera_space_fn(ring[i], ring[i + 1])
        verts[#verts + 1] = { ring[i], ring[i + 1], f }
    end
    local n = #verts
    if n < 3 then return nil end
    local out = {}
    for i = 1, n do
        local cur = verts[i]
        local nxt = verts[i % n + 1]
        local cur_in = cur[3] >= clip_dist
        local nxt_in = nxt[3] >= clip_dist
        if cur_in then out[#out + 1] = cur end
        if cur_in ~= nxt_in then
            local t = (clip_dist - cur[3]) / (nxt[3] - cur[3])
            local lx = cur[1] + (nxt[1] - cur[1]) * t
            local ly = cur[2] + (nxt[2] - cur[2]) * t
            out[#out + 1] = { lx, ly, clip_dist }
        end
    end
    if #out < 3 then return nil end
    return out
end

-- Depth-sort objects by nearest point to camera. Each object needs a
-- flat ring (pts field) and uses camera_space_fn for depth.
-- Returns sorted array (far to near) of { object, depth }.
function Polygon.depth_sort(objects, camera_space_fn)
    local sorted = {}
    for _, obj in ipairs(objects) do
        local near_depth = math.huge
        local ring = obj.ring or obj.pts
        if ring then
            for i = 1, #ring, 2 do
                local _, f = camera_space_fn(ring[i], ring[i + 1])
                if f < near_depth then near_depth = f end
            end
        end
        sorted[#sorted + 1] = { obj = obj, depth = near_depth }
    end
    table.sort(sorted, function(a, b) return a.depth > b.depth end)
    return sorted
end

return Polygon
