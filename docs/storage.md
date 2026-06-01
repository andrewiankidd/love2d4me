# storage.lua — API Reference

## Setup

```lua
local Storage = require("love2d4me.storage")
Storage.init("mygame")  -- call once at startup
```

## Portable Mode

Place a `portable.txt` file beside the game binary. Storage writes to `./<identity>/` instead of the home directory.

| File layout (portable) | File layout (normal) |
|------------------------|---------------------|
| `game.exe` | `game.exe` |
| `portable.txt` | |
| `mygame/settings.json` | `~/.mygame/settings.json` |
| `mygame/saves/slot1.json` | `~/.mygame/saves/slot1.json` |

## API

| Function | Returns | Description |
|----------|---------|-------------|
| `Storage.init(identity)` | — | Set app identity, detect portable mode, create base dir |
| `Storage.read(path)` | string or nil | Read a file relative to the storage root |
| `Storage.write(path, data)` | bool | Write a file (creates parent dirs) |
| `Storage.exists(path)` | bool | Check if a file exists |
| `Storage.delete(path)` | bool | Delete a file |
| `Storage.list(dir)` | table | List files in a directory |
| `Storage.resolve(path)` | string | Get the absolute path for a relative path |
| `Storage.is_portable()` | bool | Whether portable mode is active |
| `Storage.get_base_path()` | string | The resolved base directory |
