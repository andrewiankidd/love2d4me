-- love2d4me — shared LOVE2D game framework.
--
-- Single-require entry point. All modules available via:
--   local L = require("love2d4me")
--   local Collision = L.collision
--   local GameState = L.gamestate
--
-- Or require individual modules directly (if package.path includes src/):
--   local Collision = require("love2d4me.src.collision")

local BASE = (...):gsub("%.init$", "") .. ".src."

return {
    -- Core
    gamestate     = require(BASE .. "gamestate"),
    input         = require(BASE .. "input"),
    conf          = require(BASE .. "conf"),
    fonts         = require(BASE .. "fonts"),
    resolution    = require(BASE .. "resolution"),
    settings      = require(BASE .. "settings"),
    storage       = require(BASE .. "storage"),
    log           = require(BASE .. "log"),
    json          = require(BASE .. "json"),
    utils         = require(BASE .. "utils"),
    compat        = require(BASE .. "compat"),

    -- World
    collision     = require(BASE .. "collision"),
    polygon       = require(BASE .. "polygon"),
    projection    = require(BASE .. "projection"),
    maploader     = require(BASE .. "maploader"),

    -- Entity
    player        = require(BASE .. "player"),
    npc           = require(BASE .. "npc"),
    interactable  = require(BASE .. "interactable"),
    vehicle       = require(BASE .. "vehicle"),

    -- Combat
    equipment     = require(BASE .. "equipment"),
    hud           = require(BASE .. "hud"),

    -- Visual
    parallax      = require(BASE .. "parallax"),
    projectile    = require(BASE .. "projectile"),
    frames        = require(BASE .. "frames"),
    splash        = require(BASE .. "splash"),
    menu          = require(BASE .. "menu"),
    daynight      = require(BASE .. "daynight"),
    sprite        = require(BASE .. "sprite"),
    animation     = require(BASE .. "animation"),
    camera        = require(BASE .. "camera"),
    notification  = require(BASE .. "notification"),
    world         = require(BASE .. "world"),

    -- RPG
    dialog        = require(BASE .. "dialog"),
    inventory     = require(BASE .. "inventory"),
    quests        = require(BASE .. "quests"),
    battle        = require(BASE .. "battle"),
    rpg           = require(BASE .. "rpg"),
    interact      = require(BASE .. "interact"),
    savegame      = require(BASE .. "savegame"),
}
