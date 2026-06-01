-- Shared Luacheck config for LOVE2D projects using love2d4me.
-- Projects symlink or copy this to their root .luacheckrc.

std = "lua51+love"

-- LOVE2D globals
read_globals = {
    "love",
}

-- Globals set by love2d4me modules
globals = {
    "Input",           -- lib.love2d4me.input (set as global in main.lua)
    "newAnimation",    -- lib.love2d4me.compat (legacy animation shim)
    "math.round",      -- lib.love2d4me.utils
    "stringsplit",     -- lib.love2d4me.utils
    "implode",         -- lib.love2d4me.utils
    "clamp",           -- lib.love2d4me.utils
    "lerp",            -- lib.love2d4me.utils
    "distance",        -- lib.love2d4me.utils
}

-- Don't warn about unused loop variables prefixed with _
unused_args = false

-- Max line length (0 = no limit, legacy code is messy)
max_line_length = false

-- Ignore whitespace warnings for now (StyLua handles formatting)
ignore = {
    "611", -- line contains only whitespace
    "612", -- trailing whitespace
    "614", -- trailing whitespace in comment
}

-- Exclude submodule and node_modules
exclude_files = {
    "src/lib/*",
    "node_modules/*",
    "love/*",
}
