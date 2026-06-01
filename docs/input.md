# input.lua — API Reference

## Setup

```lua
local Input = require("love2d4me.input")
Input.init({ width = 800, height = 600 })
Input.bind("up",      { keys = {"up", "w"} })
Input.bind("down",    { keys = {"down", "s"} })
Input.bind("confirm", { keys = {"return", "space"} })
```

## Querying

| Function | Returns | Description |
|----------|---------|-------------|
| `Input.held(action)` | bool | True while the action's key is held or virtual button is pressed |
| `Input.pressed(action)` | bool | True for one frame when the action fires |
| `Input.is_touch_active()` | bool | Whether touch mode is currently active |

## Callbacks

Wire these into your `main.lua`:

```lua
function love.keypressed(key)         Input.keypressed(key) end
function love.keyreleased(key)        Input.keyreleased(key) end
function love.touchpressed(id, x, y)  Input.touchpressed(id, x, y) end
function love.touchreleased(id, x, y) Input.touchreleased(id, x, y) end
function love.touchmoved(id, x, y)    Input.touchmoved(id, x, y) end
```

## Per-frame

```lua
function love.update(dt)
    Input.update()  -- clears single-frame presses, re-checks touch detection
end

function love.draw()
    -- draw your game
    Input.draw()    -- renders virtual buttons (only on touch devices)
end
```

## Modes

| Mode | Behaviour |
|------|-----------|
| `"auto"` | Detects platform + first touch event |
| `"keyboard"` | Force keyboard only, no virtual buttons |
| `"touch"` | Force touch, always show virtual buttons |

```lua
Input.set_mode("touch")  -- force touch controls
```
