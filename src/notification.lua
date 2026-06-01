-- notification.lua -- Timed text notification overlay.
--
-- Shows a message at the top of the screen that fades out.
-- Multiple notifications queue and display one at a time.
--
-- Usage:
--   local Notification = require("love2d4me.src.notification")
--   Notification.show("New Quest - Talk to Bob")
--   Notification.show("Item collected!", 3.0)
--
-- In love.update:  Notification.update(dt)
-- In love.draw:    Notification.draw()

local Notification = {}

local queue = {}
local current = nil
local timer = 0
local fade = 1

local DEFAULT_DURATION = 3.0

function Notification.show(text, duration)
    table.insert(queue, {
        text = text,
        duration = duration or DEFAULT_DURATION,
    })
end

function Notification.update(dt)
    if current then
        timer = timer - dt
        if timer <= 0.5 then
            fade = math.max(0, timer / 0.5)
        end
        if timer <= 0 then
            current = nil
        end
    end
    if not current and #queue > 0 then
        current = table.remove(queue, 1)
        timer = current.duration
        fade = 1
    end
end

function Notification.draw()
    if not current then return end
    local sw = love.graphics.getDimensions()
    love.graphics.setColor(1, 1, 1, fade)
    love.graphics.printf(current.text, 0, 40, sw, "center")
    love.graphics.setColor(1, 1, 1, 1)
end

function Notification.clear()
    current = nil
    queue = {}
end

return Notification
