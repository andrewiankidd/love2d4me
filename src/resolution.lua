-- resolution.lua -- Resolution scaling for LOVE2D games.
--
-- Renders the game at a fixed logical size regardless of window dimensions.
-- Supports fit, stretch, center, and nearest-integer scaling modes.
--
-- Usage:
--   local Resolution = require("love2d4me.src.resolution")
--
--   function love.load()
--       Resolution.set("fit", 800, 600, love.graphics.getDimensions())
--   end
--
--   function love.draw()
--       Resolution.render(function()
--           -- draw your game at 800x600 logical
--       end)
--   end
--
--   -- Convert screen coords to game coords (e.g. for mouse input)
--   local gx, gy = Resolution.to_game(love.mouse.getPosition())

local lg = love.graphics
local min, max = math.min, math.max

local dx = 0
local dy = 0
local xscale = 1
local yscale = 1
local rw, rh
local render_scale = 1
local render_canvas = nil

local Resolution = {}

function Resolution.set(mode, game_width, game_height, screen_width, screen_height, opts)
    if mode == "fit" then
        local aspect = game_width / game_height
        local gw, gh = aspect * screen_height, screen_height
        local gw2, gh2 = screen_width, screen_width / aspect
        rw, rh = gw, gh
        if gw * gh >= gw2 * gh2 then
            rw, rh = gw2, gh2
        end
        dx, dy = (screen_width - rw) / 2, (screen_height - rh) / 2
        xscale = min(screen_width / game_width, screen_height / game_height)
        yscale = xscale
    elseif mode == "nearest" then
        local aspect = game_width / game_height
        local gw, gh = aspect * screen_height, screen_height
        local gw2, gh2 = screen_width, screen_width / aspect
        rw, rh = gw, gh
        if gw * gh >= gw2 * gh2 then
            rw, rh = gw2, gh2
        end
        xscale = min(screen_width / game_width, screen_height / game_height)
        yscale = xscale
        local integer_scale = math.floor(xscale)
        if xscale > 1 and xscale ~= integer_scale then
            xscale = integer_scale
            yscale = xscale
            rw, rh = xscale * game_width, yscale * game_height
        end
        dx, dy = (screen_width - rw) / 2, (screen_height - rh) / 2
    elseif mode == "stretch" then
        dx, dy = 0, 0
        xscale = screen_width / game_width
        yscale = screen_height / game_height
        rw = game_width * xscale
        rh = game_height * yscale
    elseif mode == "center" then
        dx, dy = (screen_width - game_width) / 2, (screen_height - game_height) / 2
        xscale = 1
        yscale = 1
        rw = game_width
        rh = game_height
    end

    opts = opts or {}
    render_scale = opts.render_scale or 1
    if render_scale > 1 then
        render_canvas = lg.newCanvas(game_width * render_scale, game_height * render_scale)
        render_canvas:setFilter("linear", "linear")
    else
        render_canvas = nil
    end

    return Resolution
end

function Resolution.render(draw, ...)
    if render_canvas then
        lg.setCanvas(render_canvas)
        lg.clear(0, 0, 0, 1)
        lg.push()
        lg.origin()
        lg.scale(render_scale, render_scale)
        draw(...)
        lg.pop()
        lg.setCanvas()

        lg.push()
        lg.setScissor(dx, dy, rw, rh)
        lg.translate(dx, dy)
        lg.scale(xscale / render_scale, yscale / render_scale)
        lg.draw(render_canvas, 0, 0)
        lg.setScissor()
        lg.pop()
    else
        lg.push()
        lg.setScissor(dx, dy, rw, rh)
        lg.translate(dx, dy)
        lg.scale(xscale, yscale)
        draw(...)
        lg.setScissor()
        lg.pop()
    end
    return Resolution
end

function Resolution.to_game(sx, sy)
    local cx = min(max(sx, dx), dx + rw)
    local cy = min(max(sy, dy), dy + rh)
    return (cx - dx) / xscale, (cy - dy) / yscale
end

function Resolution.to_screen(gx, gy)
    return gx * xscale + dx, gy * yscale + dy
end

function Resolution.get_offset()
    return dx, dy
end

function Resolution.get_scale()
    return xscale, yscale
end

return Resolution
