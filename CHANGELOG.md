# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- `input.lua` -- unified input abstraction (keyboard + touch, auto-detection, virtual buttons)
- `conf.lua` -- shared `love.conf` helper with saved-settings loading
- `storage.lua` -- disk I/O abstraction with portable mode (`portable.txt` detection)
- `settings.lua` -- persistent key-value settings backed by storage
- `camera.lua` -- 2D camera with target tracking, bounds clamping, screen shake
- `collision.lua` -- pixel-color collision map reader
- `animation.lua` -- sprite sheet animation player (uniform grid, per-frame timing, callbacks)
- `compat.lua` -- legacy legacy animation shim providing global `newAnimation()` via animation.lua
