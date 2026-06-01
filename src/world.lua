-- world.lua -- Overworld renderer.
--
-- Draws the game world: map background, NPCs, items, mobs, player, overlay.
-- Games pass their world state each frame. The module handles the draw order.
--
-- Usage:
--   local World = require("love2d4me.src.world")
--   World.draw({
--       map = map_image,
--       overlay = overlay_image,
--       cam_x = cameraoffsetx,
--       cam_y = cameraoffsety,
--       npcs = { { anim = anim, x = 100, y = 200 } },
--       items = { { img = img, x = 50, y = 60 } },
--       mobs = { { anim = anim, x = 300, y = 100 } },
--       protag = { anim = protag, x = px, y = py, prompt = prompt_img, interactable = true },
--   })

local World = {}

function World.draw(state)
    if not state then return end
    local cx = state.cam_x or 0
    local cy = state.cam_y or 0

    -- Background
    if state.map then
        love.graphics.draw(state.map, cx, cy)
    end

    -- NPCs
    if state.npcs then
        for _, npc in ipairs(state.npcs) do
            if npc.anim then
                npc.anim:draw(npc.x + cx, npc.y + cy)
            end
        end
    end

    -- Items
    if state.items then
        for _, item in ipairs(state.items) do
            if item.img then
                love.graphics.draw(item.img, item.x + cx, item.y + cy)
            end
        end
    end

    -- Mobs
    if state.mobs then
        for _, mob in ipairs(state.mobs) do
            if mob.anim then
                mob.anim:draw(mob.x + cx, mob.y + cy)
            end
        end
    end

    -- Protag
    if state.protag then
        local p = state.protag
        if p.anim then p.anim:draw(p.x, p.y) end
        if p.interactable and p.prompt then
            love.graphics.draw(p.prompt, p.x, p.y - 20)
        end
    end

    -- Overlay
    if state.overlay then
        love.graphics.draw(state.overlay, cx, cy)
    end
end

return World
