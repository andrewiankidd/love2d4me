# love2d-common

Shared Lua modules for LOVE2D game projects.

## Architecture

Each module is a single `.lua` file with no dependencies beyond LOVE2D itself (and optionally other modules in this library). Games add this repo as a git submodule at `src/lib/` and require what they need.

## Modules

### input.lua
Unified input abstraction. Bind semantic action names to keys, auto-detect touch devices, render virtual buttons on mobile. Single API for both keyboard and touch.

See [input.md](input.md) for full API reference.

### conf.lua
Shared `love.conf` helper. Applies sensible defaults and loads saved window preferences (resolution, fullscreen, vsync) from `settings.json` before the window opens.

### storage.lua
All disk I/O goes through this module. Detects portable mode via a `portable.txt` file beside the binary -- if present, reads/writes to `./<identity>/`. Otherwise uses the user's home directory.

See [storage.md](storage.md) for full API reference.

### settings.lua
Persistent key-value settings. Games define defaults; saved values overlay on init. Changes save immediately to `settings.json` via storage.lua.

### camera.lua
2D camera with smooth target following, map bounds clamping, and screen shake. Wraps `love.graphics.push/pop` so game code draws in world space.

### collision.lua
Reads a collision image and maps pixel colors to permission strings (walk, solid, hazard, warp, etc). Supports point checks, rectangle checks, and try-move helpers.

### animation.lua
Sprite sheet animation player. Loads a uniform grid from an image, plays frame sequences with configurable timing, looping, and completion callbacks.

### compat.lua
Drop-in replacement for the legacy animation library. Exposes a global `newAnimation()` function matching the legacy animation API, backed by animation.lua internally. Legacy game code works without rewriting.
