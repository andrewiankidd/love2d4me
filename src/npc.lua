-- npc.lua -- Entity registry, loader, and runtime.
--
-- Unified system for all map entities: NPCs, mobs, trainers, etc.
-- Each entity has a character (sprite source), position, behavior,
-- and interaction type.
--
-- Character data lives in game/npcs/<name>/ or game/mobs/<name>/:
--   sprite.png   -- overworld sprite sheet (rows: S, ?, E, ?, N, ?, W, ?)
--   picture.png  -- portrait for dialog
--   battle.png   -- battle sprite (optional)
--   prompt.png   -- interaction prompt icon (optional)
--   config.json  -- stats, metadata (optional)
--
-- Entity config in map config.json:
--   "entities": [
--       { "character": "Alice", "x": 100, "y": 200, "behavior": "static", "interaction": "button" },
--       { "character": "Skeleton", "x": 500, "y": 300, "behavior": "patrol",
--         "patrol": { "distance": 50, "direction": "down" }, "interaction": "collision" },
--       { "character": "Trainer", "x": 300, "y": 150, "behavior": "static", "interaction": "seen",
--         "seen_range": 100 }
--   ]
--
-- Usage:
--   local NPC = require("love2d4me.src.npc")
--   local bob = NPC.load("Bob")
--   -- bob.sprite, bob.portrait, bob.battle_sprite, bob.prompt
--
--   -- Entity runtime:
--   local entity = NPC.create_entity(config_entry, sprite_w, sprite_h)
--   NPC.update_entity(entity, dt)
--   NPC.draw_entity(entity, camera_x, camera_y)

local Log = require("love2d4me.src.log")

local NPC = {}

local SEARCH_PATHS = { "game/npcs/", "game/mobs/" }
local cache = {}

function NPC.load(name)
    if cache[name] then return cache[name] end

    local dir = nil
    for _, base in ipairs(SEARCH_PATHS) do
        if love.filesystem.getInfo(base .. name .. "/sprite.png") then
            dir = base .. name .. "/"
            break
        end
    end
    if not dir then
        for _, base in ipairs(SEARCH_PATHS) do
            if love.filesystem.getInfo(base .. name) then
                dir = base .. name .. "/"
                break
            end
        end
    end
    if not dir then
        dir = "game/npcs/" .. name .. "/"
    end

    local npc = {
        name = name,
        dir = dir,
        sprite = nil,
        portrait = nil,
        battle_sprite = nil,
        prompt = nil,
    }

    if love.filesystem.getInfo(dir .. "sprite.png") then
        npc.sprite = love.graphics.newImage(dir .. "sprite.png")
    end
    if love.filesystem.getInfo(dir .. "picture.png") then
        npc.portrait = love.graphics.newImage(dir .. "picture.png")
    end
    if love.filesystem.getInfo(dir .. "battle.png") then
        npc.battle_sprite = love.graphics.newImage(dir .. "battle.png")
    end
    if love.filesystem.getInfo(dir .. "prompt.png") then
        npc.prompt = love.graphics.newImage(dir .. "prompt.png")
    end

    Log.debug("NPC.load", { name = name, dir = dir, has_sprite = npc.sprite ~= nil })
    cache[name] = npc
    return npc
end

function NPC.get(name)
    return cache[name]
end

function NPC.clear_cache()
    cache = {}
end

-- Create a runtime entity from a map config entry.
-- anim_fn: function(sprite_img) that returns an animation object (game provides this)
function NPC.create_entity(cfg, anim_fn)
    local char_data = NPC.load(cfg.character or cfg.name or cfg.type)
    local entity = {
        character = char_data,
        x = tonumber(cfg.x) or 0,
        y = tonumber(cfg.y) or 0,
        origin_x = tonumber(cfg.x) or 0,
        origin_y = tonumber(cfg.y) or 0,
        behavior = cfg.behavior or "static",
        interaction = cfg.interaction or "button",
        alive = true,
        hp = cfg.hp or nil,
        max_hp = cfg.hp or nil,
        hit_flash = 0,

        -- Patrol state
        patrol_distance = cfg.patrol and cfg.patrol.distance or 50,
        patrol_direction = cfg.patrol and cfg.patrol.direction or "down",

        -- Frame layout override (per-entity, for non-standard sprite sheets)
        dir_frames = cfg.dir_frames or nil,

        -- Chase (only active when seen_range is explicitly set)
        seen_range = cfg.seen_range or nil,
        chase_speed = cfg.chase_speed or 1.5,
        follow_distance = cfg.follow_distance or 40,

        -- Aggro system (overrides normal behavior when active)
        aggro = 0,
        aggro_decay = cfg.aggro_decay or 0.3,
        aggro_threshold = cfg.aggro_threshold or 1,

        -- Animation (created by game's anim_fn)
        anim = nil,
    }

    if char_data.sprite and anim_fn then
        entity.anim = anim_fn(char_data.sprite)
    end

    return entity
end

local PATROL_REVERSE = {
    up = "down", down = "up", left = "right", right = "left",
}

local DIRECTION_TO_SPRITE = {
    up = "north", down = "south", left = "west", right = "east",
}

local Frames = require("love2d4me.src.frames")
local DEFAULT_DIR_FRAMES = (Frames.get("4dir_3frame") or {}).walk or {
    north = {1, 3}, east = {4, 6}, south = {7, 9}, west = {10, 12},
}

function NPC.stun(entity, duration)
    entity.stun_timer = duration or 3
end

function NPC.aggro(entity, amount)
    entity.aggro = (entity.aggro or 0) + (amount or 5)
end

function NPC.is_aggro(entity)
    return (entity.aggro or 0) >= (entity.aggro_threshold or 1)
end

function NPC.update_entity(entity, dt, target_x, target_y)
    if not entity.alive then return end

    if entity.hit_flash and entity.hit_flash > 0 then
        entity.hit_flash = entity.hit_flash - dt
    end

    if entity.stun_timer and entity.stun_timer > 0 then
        entity.stun_timer = entity.stun_timer - dt
        return
    end

    -- Aggro decay
    if entity.aggro > 0 then
        entity.aggro = entity.aggro - (entity.aggro_decay or 0.3) * dt
        if entity.aggro < 0 then entity.aggro = 0 end
    end

    local chasing = false
    local aggro_active = entity.aggro >= (entity.aggro_threshold or 1)

    -- Aggro chase: unlimited range, always pursues target
    if aggro_active and target_x and target_y then
        local dx = target_x - entity.x
        local dy = target_y - entity.y
        local dist_sq = dx * dx + dy * dy
        local follow_dist = entity.follow_distance or 40
        if dist_sq > (follow_dist * follow_dist) then
            chasing = true
        end
    end

    -- Normal seen_range chase (only when not aggro'd)
    if not chasing and entity.seen_range and target_x and target_y then
        local dx = target_x - entity.x
        local dy = target_y - entity.y
        local dist_sq = dx * dx + dy * dy
        local follow_dist = entity.follow_distance or 40
        local resume_dist = follow_dist * 1.5
        local threshold = entity._was_following and resume_dist or follow_dist
        if dist_sq < (entity.seen_range * entity.seen_range) and dist_sq > (threshold * threshold) then
            chasing = true
            entity._was_following = true
        else
            entity._was_following = false
        end
    end

    if chasing and target_x and target_y then
        local dx = target_x - entity.x
        local dy = target_y - entity.y
        local speed = aggro_active and (entity.chase_speed or 1.5) * 1.5 or (entity.chase_speed or 1.5)
        if math.abs(dx) > math.abs(dy) then
            if dx > 0 then
                entity.x = entity.x + speed
                entity.patrol_direction = "right"
            else
                entity.x = entity.x - speed
                entity.patrol_direction = "left"
            end
        else
            if dy > 0 then
                entity.y = entity.y + speed
                entity.patrol_direction = "down"
            else
                entity.y = entity.y - speed
                entity.patrol_direction = "up"
            end
        end
    end

    if not chasing and entity.behavior == "patrol" then
        local dir = entity.patrol_direction
        local dist = entity.patrol_distance
        if dir == "up" then
            entity.y = entity.y - 1
            if entity.y < entity.origin_y - dist then
                entity.patrol_direction = PATROL_REVERSE[dir]
            end
        elseif dir == "down" then
            entity.y = entity.y + 1
            if entity.y > entity.origin_y + dist then
                entity.patrol_direction = PATROL_REVERSE[dir]
            end
        elseif dir == "left" then
            entity.x = entity.x - 1
            if entity.x < entity.origin_x - dist then
                entity.patrol_direction = PATROL_REVERSE[dir]
            end
        elseif dir == "right" then
            entity.x = entity.x + 1
            if entity.x > entity.origin_x + dist then
                entity.patrol_direction = PATROL_REVERSE[dir]
            end
        end
    end

    if entity.anim and (entity.behavior == "patrol" or chasing) then
        local sprite_dir = DIRECTION_TO_SPRITE[entity.patrol_direction] or "south"
        local dir_frames = entity.dir_frames or DEFAULT_DIR_FRAMES
        local range = dir_frames[sprite_dir]
        if range then
            entity.anim:update(dt)
            local f = entity.anim:getCurrentFrame()
            if f < range[1] or f > range[2] then
                entity.anim:seek(range[1])
            end
        end
    end
end

function NPC.draw_entity(entity, cam_x, cam_y)
    if not entity.alive then return end
    local flashing = entity.hit_flash and entity.hit_flash > 0
    if flashing then
        love.graphics.setColor(1, 1, 1, 1)
    end
    if entity.anim then
        entity.anim:draw(entity.x + cam_x, entity.y + cam_y)
    else
        love.graphics.setColor(flashing and {1, 1, 1, 1} or {0.8, 0.2, 0.2, 1})
        love.graphics.rectangle("fill", entity.x + cam_x, entity.y + cam_y, 36, 48)
    end
    if flashing then
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.rectangle("fill", entity.x + cam_x, entity.y + cam_y, 36, 48)
    end
    if entity.hp and entity.max_hp and entity.hp < entity.max_hp then
        local bar_w = 32
        local bar_h = 4
        local bx = entity.x + cam_x + 2
        local by = entity.y + cam_y - bar_h - 3
        local ratio = entity.hp / entity.max_hp
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", bx - 1, by - 1, bar_w + 2, bar_h + 2)
        love.graphics.setColor(0.8, 0.1, 0.1, 1)
        love.graphics.rectangle("fill", bx, by, bar_w, bar_h)
        love.graphics.setColor(0.1, 0.8, 0.1, 1)
        love.graphics.rectangle("fill", bx, by, bar_w * ratio, bar_h)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function NPC.check_collision(entity, px, py, pw, ph)
    if not entity.alive then return false end
    local sw, sh = 36, 48
    return px + pw > entity.x and px < entity.x + sw
        and py + ph > entity.y and py < entity.y + sh
end

function NPC.check_seen(entity, px, py)
    if not entity.alive or entity.interaction ~= "seen" then return false end
    local dx = entity.x - px
    local dy = entity.y - py
    return (dx * dx + dy * dy) < (entity.seen_range * entity.seen_range)
end

return NPC
