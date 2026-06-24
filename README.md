# love2d4me

A shared LOVE2D game framework extracted from several legacy game projects (originally written ~2011) undergoing varying levels of revival and modernization. The framework centralizes common patterns -- state management, input, collision, entity systems, projection, and more -- so each game carries only its own game-specific logic.

## Quick Start

```bash
git submodule add https://github.com/andrewiankidd/love2d4me.git src/love2d4me
```

```lua
-- conf.lua (direct require -- conf runs before love.load, so init.lua
-- can't be used here as it loads modules that need love.graphics)
local Conf = require("love2d4me.src.conf")
function love.conf(t) Conf.apply(t) end

-- main.lua (single require gives access to all modules)
local Love2D4Me = require("love2d4me")
local GameState = Love2D4Me.gamestate

function love.load()
    GameState.init({
        on_gameplay_init = function() ... end,
        on_gameplay_update = function(dt) ... end,
        on_gameplay_draw = function() ... end,
    })
end

function love.update(dt) GameState.update(dt) end
function love.draw() GameState.draw() end
function love.keypressed(key) GameState.keypressed(key) end
function love.keyreleased(key) GameState.keyreleased(key) end
```

All game config lives in `game/config.json`:
```json
{
    "title": "My Game",
    "width": 800,
    "height": 600,
    "play_label": "Play",
    "starting_map": "spawn"
}
```

## Modules

### Core

| Module | Description |
|--------|-------------|
| `gamestate` | Lifecycle state machine: splash, menu, loading, gameplay, pause, dead. Reads `game/config.json` for all settings. Applies window title, resolution, default filter, FPS limit, menu/gameplay music. Built-in death screen with `GameState.die()` / `GameState.respawn()`. |
| `input` | Unified keyboard + touch input. Action bindings (`move_up`, `confirm`, `sprint`, etc.), auto-detect touch devices, virtual on-screen buttons, runtime rebinding with settings persistence. |
| `conf` | Minimal `love.conf` shim. Sets sensible window defaults. All real config comes from `config.json` at runtime. |
| `fonts` | Auto-discovers TTF fonts from `game/fonts/`. Loads at standard sizes. `Fonts.get(name, size)` with lazy loading. Supports bitmap pixel fonts. |
| `resolution` | Resolution scaling: stretch, fit, nearest-integer, center. `Resolution.render(draw_fn)` wraps gameplay drawing. |
| `settings` | Persistent key-value settings (volume, fullscreen, res_mode). Backed by storage. |
| `storage` | Disk I/O abstraction. Portable mode (beside binary) or home directory. |
| `log` | Structured logging with levels (DEBUG, INFO, WARN, ERROR). File output. |
| `json` | Full recursive JSON parser. `JSON.load(path)`, `JSON.parse(str)`. |
| `utils` | Global helpers: `lerp`, `clamp`, `distance`, `stringsplit`, `implode`, `math.round`, `table.maxn`, `get_image`. |
| `compat` | Legacy animation shim. Injects global `newAnimation()` backed by `animation.lua`. |

### World

| Module | Description |
|--------|-------------|
| `collision` | Pixel-color collision maps. Red channel encodes permissions. Named color maps, warp support via `get_warp()`. |
| `polygon` | Polygon geometry: point-in-polygon, Sutherland-Hodgman near-plane clipping, depth sorting, centroid, bounding radius. |
| `projection` | World-to-screen transforms. Three modes: **orthographic** (top-down, platformer), **mode7** (retro scanline perspective), **oblique** (2.5D ground-plane with horizon). |
| `maploader` | Convention-based map loading from `game/maps/<name>/`. Loads background, collision, overlay, lights, sky, main layer, config.json. |

### Entity

| Module | Description |
|--------|-------------|
| `npc` | Unified entity system. `NPC.load(name)` loads character data from `game/npcs/` or `game/mobs/`. `NPC.create_entity(config)` spawns entities with behavior (static, patrol) and interaction type (button, collision, seen). |
| `interactable` | Generic in-world object registry. Proximity queries with `nearest(x, y, filter)`. Composition-based -- objects are plain tables. |
| `vehicle` | Enter/exit/drive pattern. Register presets per game. Builds on interactable registry. |

### Visual

| Module | Description |
|--------|-------------|
| `splash` | Splash screen with logo animation and optional audio. |
| `menu` | Stack-based menu system. Main menu, pause menu, options, video settings. |
| `daynight` | Day/night cycle overlay with light map compositing. Named time constants. |
| `sprite` | Directional sprite sheet with frame-range direction mapping. |
| `animation` | Sprite sheet animation. Uniform grid, per-frame timing, loop control. |
| `camera` | 2D camera with target tracking and bounds clamping. |
| `notification` | Timed notification popups. |
| `world` | ECS-like world container. |

### RPG

| Module | Description |
|--------|-------------|
| `dialog` | NPC dialog with portrait, paginated text, close callbacks. |
| `inventory` | Item registry with add/remove, visibility toggle, overlay draw. Auto-loads from `game/items/<id>/`. |
| `quests` | Objective tracking with conditions (talkto, hasitem), auto-chain via `next`. Auto-loads from `game/objectives/<id>/`. |
| `battle` | Turn-based combat: Attack/Defend/Magic/Run. Auto-loads background from convention path. |
| `rpg` | HP/XP/level stats. Damage, healing, XP gain, level-up with callbacks. |
| `interact` | Interaction prompt system. |
| `savegame` | Save/load with slot management. |

## Game Types Supported

| Type | Projection | Collision | Example |
|------|-----------|-----------|---------|
| **Top-down RPG** | orthographic | pixel-color + collrect | Fear of the Dark |
| **Side-scroller** | orthographic | pixel-color (solid/walk/hazard/grapple) | Platformer |
| **Mode 7** | mode7 (scanline) | pixel-color | Mode 7 |
| **2.5D city** | oblique (ground-plane) | polygon (point-in-ring) | G-Town |

## Convention Paths

```
game/
  config.json           -- game config (title, resolution, starting_map, etc.)
  fonts/                -- TTF fonts (auto-discovered)
  sound/                -- menu.ogg / theme.ogg / gameplay music
  pictures/
    icon.png            -- window icon
    battle/             -- battlebackground.png, rbg.png, death.png, levelup.png
    inventory/          -- inventoryoverlay.png
    msg/                -- msgoverlay.png
  items/<id>/           -- config.json, image.png, sprite.png
  npcs/<name>/          -- sprite.png, picture.png, battle.png, prompt.png, dialog.json
  mobs/<name>/          -- sprite.png, config.json
  objectives/<id>/      -- config.json, icon.png
  maps/<name>/
    config.json         -- spawn, entities, items, warps
    background.png      -- base layer
    collision.png       -- red channel = permission
    overlay.png         -- drawn above sprites
    lights.png          -- day/night light map
    sky.png             -- parallax sky (platformer)
    main.png            -- main terrain (platformer)
```

## Collision Color Contract

| Red Channel | Permission | Usage |
|-------------|-----------|-------|
| 0 | solid | Black -- impassable wall/boundary |
| 64 | grapple | Dark -- grapple/hook point |
| 128 | hazard | Medium -- instant death |
| 150--154 | warp | Warp zones (index 0--4, mapped to config warps) |
| 255 | walk | White -- freely walkable |

## Entity Config Schema

```json
{
    "entities": [
        {
            "character": "Alice",
            "x": 255, "y": 145,
            "behavior": "static",
            "interaction": "button"
        },
        {
            "character": "Skeleton",
            "x": 500, "y": 300,
            "behavior": "patrol",
            "patrol": { "distance": 50, "direction": "down" },
            "interaction": "collision"
        }
    ]
}
```

**Behaviors:** `static` (stands in place), `patrol` (walks back and forth)

**Interactions:** `button` (press confirm to interact), `collision` (triggers on contact), `seen` (triggers when within range)

## Portable Mode

Place a `portable.txt` file beside the game binary. All data writes go to `./<identity>/` instead of the home directory.

## Projects

| Game | Type | Play |
|------|------|------|
| [Pocket Artemis](https://github.com/andrewiankidd/pocket-artemis) | Tamagotchi | [Web](https://tiltedcartridge.co.uk/pocket-artemis/Web/) |
| [Fear of the Dark](https://github.com/andrewiankidd/legacy-lua-fotd) | Top-down RPG | [Web](https://andrewiankidd.github.io/legacy-lua-fotd/Web/) |
| [Platformer](https://github.com/andrewiankidd/legacy-lua-platformer) | 2D side-scroller | [Web](https://andrewiankidd.github.io/legacy-lua-platformer/Web/) |
| [Mode 7](https://github.com/andrewiankidd/legacy-lua-mode7) | Retro perspective | [Web](https://andrewiankidd.github.io/legacy-lua-mode7/Web/) |
| [G-Town](https://github.com/andrewiankidd/legacy-lua-25d) | 2.5D driving | [Web](https://andrewiankidd.github.io/legacy-lua-25d/Web/) |
