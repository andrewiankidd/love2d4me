# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- `input.lua` â€” unified input abstraction (keyboard + touch, auto-detection, virtual buttons)
- `conf.lua` â€” shared `love.conf` helper with saved-settings loading
- `storage.lua` â€” disk I/O abstraction with portable mode (`portable.txt` detection)
- `settings.lua` â€” persistent key-value settings backed by storage
- `camera.lua` â€” 2D camera with target tracking, bounds clamping, screen shake
- `collision.lua` â€” pixel-color collision map reader
- `animation.lua` â€” sprite sheet animation player (uniform grid, per-frame timing, callbacks)
- `compat.lua` â€” legacy legacy animation shim providing global `newAnimation()` via animation.lua
