-- Shared Luacheck config for LOVE2D projects using love2d4me.
-- Projects symlink or copy this to their root .luacheckrc.

std = "lua51+love"

read_globals = {
    "package.searchers",
}

globals = {
    "love",
    "Input",
    "newAnimation",
    "math.round",
    "stringsplit",
    "implode",
    "clamp",
    "lerp",
    "distance",
    "get_image",
    "table.maxn",
    "loadmap",
    "interact",
    "start_battle",
    "chat",
    "newobjective",
    "loadintro",
    "movementcontrols",
    "othercontrols",
    "dobullets",
    "load_collision",
    "get_trigger_index",
    "playersize",
    "playerfacing",
    "defaultmovespeed",
    "collision",
    "mode7",
    "player",
    "screen",
    "pixelfont",
    "pixelfontlarge",
    "pixelfontlargew",
    "pixelfonthuge",
    "gw",
    "gh",
    "protagX",
    "protagY",
    "cameraoffsetx",
    "cameraoffsety",
    "calcx",
    "calcy",
    "dead",
    "paused",
}

unused_args = false
max_line_length = false

ignore = {
    "611",
    "612",
    "614",
}

exclude_files = {
    "src/lib/*",
    "node_modules/*",
    "love/*",
}
