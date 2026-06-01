-- battle.lua -- Turn-based combat system.
--
-- Generic RPG battle: player vs N enemies, Attack/Defend/Magic/Run.
-- Games configure via callbacks for damage formulas, sprites, rewards.
--
-- Usage:
--   local Battle = require("love2d4me.src.battle")
--   Battle.start({
--       player = { hp = 10, dmg = 1, sprite = anim, portrait = img },
--       enemies = { { name = "Skeleton", hp = 2, atk = 1, sprite = anim } },
--       on_win = function(xp) ... end,
--       on_lose = function() ... end,
--       on_run = function() ... end,
--   })

local Log = require("love2d4me.src.log")

local Battle = {}

local BG_PATH = "game/pictures/battle/battlebackground.png"
local bg_image = nil

local active = false
local player = {}
local enemies = {}
local selected_enemy = 1
local selected_option = 1
local player_turn = true
local battle_state = "main"
local options = {"Attack", "Defend", "Magic", "Run"}
local callbacks = {}
local hit_anim = false

function Battle.start(opts)
    callbacks = opts
    player = opts.player or { hp = 10, dmg = 1 }
    enemies = {}
    for i, enemy_def in ipairs(opts.enemies or {}) do
        enemies[i] = {
            name = enemy_def.name or "Enemy",
            hp = enemy_def.hp or 1,
            max_hp = enemy_def.hp or 1,
            atk = enemy_def.atk or 1,
            sprite = enemy_def.sprite,
        }
    end
    selected_enemy = 1
    selected_option = 1
    player_turn = true
    battle_state = "main"
    hit_anim = false
    active = true
    Log.info("Battle: started", { enemies = #enemies })
end

function Battle.is_active()
    return active
end

function Battle.get_player()
    return player
end

local function count_alive()
    local n = 0
    for _, e in ipairs(enemies) do
        if e.hp > 0 then n = n + 1 end
    end
    return n
end

local function next_alive(from, dir)
    local n = #enemies
    local i = from
    for _ = 1, n do
        i = i + (dir or 1)
        if i > n then i = 1 end
        if i < 1 then i = n end
        if enemies[i] and enemies[i].hp > 0 then return i end
    end
    return from
end

function Battle.update(dt)
    if not active then return end
    -- Enemy turn
    if not player_turn then
        local alive = {}
        for i, e in ipairs(enemies) do
            if e.hp > 0 then table.insert(alive, i) end
        end
        if #alive > 0 then
            local attacker = enemies[alive[math.random(#alive)]]
            local dmg = attacker.atk
            if battle_state == "defend" then dmg = math.floor(dmg / 2) end
            player.hp = player.hp - dmg
            Log.debug("Battle: enemy attacks", { dmg = dmg, player_hp = player.hp })
        end
        if player.hp <= 0 then
            active = false
            if callbacks.on_lose then callbacks.on_lose() end
            return
        end
        player_turn = true
        battle_state = "main"
    end
    -- Update player sprite animation
    if hit_anim and player.sprite then
        player.sprite:update(dt)
        local frame = player.sprite.getCurrentFrame and player.sprite:getCurrentFrame()
            or player.sprite.get_frame and player.sprite:get_frame()
            or 0
        if frame > 3 then
            if player.sprite.reset then player.sprite:reset()
            elseif player.sprite.seek then player.sprite:seek(1) end
            hit_anim = false
        end
    end
end

function Battle.keypressed(key)
    if not active or not player_turn then return false end

    if battle_state == "main" then
        if key == "left" or key == "a" then
            selected_option = selected_option - 1
            if selected_option < 1 then selected_option = #options end
            return true
        elseif key == "right" or key == "d" then
            selected_option = selected_option + 1
            if selected_option > #options then selected_option = 1 end
            return true
        elseif key == "return" or key == "enter" then
            if selected_option == 1 then
                battle_state = "attack"
                selected_enemy = next_alive(0, 1)
            elseif selected_option == 2 then
                battle_state = "defend"
                player_turn = false
            elseif selected_option == 3 then
                battle_state = "magic"
            elseif selected_option == 4 then
                active = false
                if callbacks.on_run then callbacks.on_run() end
            end
            return true
        end
    elseif battle_state == "attack" then
        if key == "up" or key == "w" then
            selected_enemy = next_alive(selected_enemy, -1)
            return true
        elseif key == "down" or key == "s" then
            selected_enemy = next_alive(selected_enemy, 1)
            return true
        elseif key == "return" or key == "enter" then
            -- Deal damage
            local enemy = enemies[selected_enemy]
            if enemy and enemy.hp > 0 then
                enemy.hp = enemy.hp - (player.dmg or 1)
                hit_anim = true
                Log.debug("Battle: player attacks", { target = enemy.name, hp = enemy.hp })
                if enemy.hp <= 0 then
                    -- Check if all dead
                    if count_alive() == 0 then
                        local xp = 0
                        for _, en in ipairs(enemies) do xp = xp + en.max_hp end
                        active = false
                        if callbacks.on_win then callbacks.on_win(xp) end
                        return true
                    end
                    selected_enemy = next_alive(selected_enemy, 1)
                end
            end
            player_turn = false
            return true
        end
    elseif battle_state == "magic" then
        battle_state = "main"
        return true
    end
    return false
end

function Battle.draw()
    if not active then return end
    local sw, sh = love.graphics.getDimensions()

    -- Background (auto-loaded from convention path)
    if not bg_image and love.filesystem.getInfo(BG_PATH) then
        bg_image = love.graphics.newImage(BG_PATH)
    end
    if bg_image then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(bg_image, 0, 0)
    end

    -- Player sprite
    if player.sprite then
        player.sprite:draw(sw * 0.25, sh * 0.4)
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("HP: " .. player.hp, sw * 0.25, sh * 0.35)

    -- Enemies
    local ey = sh * 0.08
    for i, e in ipairs(enemies) do
        if e.hp > 0 then
            local ex = (i == 2) and sw * 0.75 or sw * 0.7
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print("HP: " .. e.hp, ex - 10, ey + 50)
            if i == selected_enemy and battle_state == "attack" then
                love.graphics.setColor(1, 1, 0, 1)
                love.graphics.print(">>>", ex - 30, ey - 10)
                love.graphics.rectangle("line", ex - 5, ey - 5, 50, 60)
            end
            if e.sprite then
                love.graphics.setColor(1, 1, 1, 1)
                e.sprite:draw(ex, ey)
            end
        end
        ey = ey + sh * 0.25
    end

    -- Battle menu overlay
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, sh * 0.72, sw, sh * 0.28)
    love.graphics.setColor(1, 1, 1, 1)

    local labels
    if battle_state == "main" then labels = options
    elseif battle_state == "attack" then labels = {"Attacking...", "", "", ""}
    elseif battle_state == "defend" then labels = {"Defending...", "", "", ""}
    elseif battle_state == "magic" then labels = {"No spells!", "", "", ""}
    end

    if labels then
        local bx = sw * 0.03
        local spacing = sw * 0.24
        for i, label in ipairs(labels) do
            if i == selected_option and battle_state == "main" then
                love.graphics.setColor(1, 1, 0, 1)
                love.graphics.print("* " .. label, bx + (i - 1) * spacing, sh * 0.86)
            else
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.print("  " .. label, bx + (i - 1) * spacing, sh * 0.86)
            end
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return Battle
