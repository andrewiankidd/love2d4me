# love2d4me

Shared LOVE2D game framework extracted from legacy game projects undergoing revival.

## Architecture

All modules live in `src/`. Games add this repo as a git submodule at `src/love2d4me/` and require everything through a single entry point:

```lua
local Love2D4Me = require("love2d4me")
local GameState = Love2D4Me.gamestate
local NPC = Love2D4Me.npc
```

The one exception is `conf.lua`, which must be required directly because it runs before `love.load`:

```lua
-- conf.lua
local Conf = require("love2d4me.src.conf")
function love.conf(t) Conf.apply(t) end
```

All game config lives in `game/config.json` -- title, resolution, starting map, music, RPG stats, death screen, FPS limit, and more. See the README for the full schema.

## Module Categories

### Core
`gamestate`, `input`, `conf`, `fonts`, `resolution`, `settings`, `storage`, `log`, `json`, `utils`, `compat`

### World
`collision` (pixel-color + warps), `polygon` (point-in-polygon, clipping, depth sort), `projection` (orthographic, mode7, oblique), `maploader`

### Entity
`player` (state container), `npc` (entity system with aggro, stun, chase, hp), `interactable` (proximity registry), `vehicle` (enter/exit/drive with bounce physics)

### Combat
`equipment` (weapon registry with cooldown), `hud` (health bar, weapon display, control hints, damage flash)

### Visual
`parallax`, `projectile`, `frames` (sprite direction layouts), `splash`, `menu`, `daynight`, `sprite`, `animation`, `camera`, `notification`, `world`

### RPG
`dialog`, `inventory`, `quests`, `battle`, `rpg`, `interact`, `savegame`

## Game Types Supported

- **Top-down RPG** -- orthographic projection, pixel collision, entities with dialog
- **Side-scroller** -- orthographic, pixel collision with hazard/grapple, projectiles
- **Mode 7** -- scanline perspective, pixel collision, combat
- **2.5D city** -- oblique projection, polygon collision, vehicles, traffic, pedestrians

## Dev Workflow

```
npm run setup    # install deps + download LOVE 11.5
npm start        # launch with embedded submodule
npm run dev      # launch with sibling love2d4me repo (no push needed)
npm run lint     # check for single-letter variables
npm run build    # pack .love + compile to Web via love.js
npm run serve    # serve Web/ at localhost:8080
```

## Detailed API

- [input.md](input.md) -- input binding API
- [storage.md](storage.md) -- disk I/O and portable mode
