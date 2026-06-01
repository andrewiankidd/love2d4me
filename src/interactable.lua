-- interactable.lua â€” Generic in-world interactable object registry.
--
-- A flat registry for any object the player can interact with: vehicles,
-- pickups, doors, NPCs, switches. Composition-based â€” an interactable is
-- just a table with position + radius + any extra fields the game needs.
--
-- Usage:
--   local Interactable = require("love2d4me.src.interactable")
--
--   local door = Interactable.new({ x = 100, y = 200, radius = 3, prompt = "Open" })
--   local nearest = Interactable.nearest(player_x, player_y)
--   if nearest then print(nearest.prompt) end

local Interactable = {}

local registry = {}

function Interactable.new(opts)
    local o = opts or {}
    o.x = o.x or 0
    o.y = o.y or 0
    o.radius = o.radius or 3
    registry[#registry + 1] = o
    return o
end

function Interactable.all()
    return registry
end

function Interactable.reset()
    registry = {}
end

function Interactable.remove(obj)
    for i = #registry, 1, -1 do
        if registry[i] == obj then
            table.remove(registry, i)
            return true
        end
    end
    return false
end

function Interactable.nearest(x, y, filter)
    local best, best_dist
    for _, o in ipairs(registry) do
        if (not filter) or filter(o) then
            local dx, dy = o.x - x, o.y - y
            local d = dx * dx + dy * dy
            if d <= o.radius * o.radius and ((not best_dist) or d < best_dist) then
                best, best_dist = o, d
            end
        end
    end
    return best
end

return Interactable
