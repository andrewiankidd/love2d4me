-- inventory.lua â€” Item registry and inventory management.
--
-- Items live in game/items/<id>/ with:
--   config.json  â€” name, description, price
--   image.png    â€” inventory icon
--   sprite.png   â€” overworld sprite
--
-- Usage:
--   local Inventory = require("love2d4me.src.inventory")
--   Inventory.add("bobskey")
--   Inventory.remove("bobskey")
--   local data = Inventory.get_item_data("bobskey")
--   Inventory.draw_list()  -- renders inventory overlay

local Log = require("love2d4me.src.log")
local JSON = require("love2d4me.src.json")
local Notification = require("love2d4me.src.notification")

local Inventory = {}

local items = {}      -- array of item IDs
local item_cache = {} -- id -> { name, description, price, image, sprite }
local BASE = "game/items/"
local OVERLAY_PATH = "game/pictures/inventory/inventoryoverlay.png"
local overlay_image = nil
local selected = 1
local visible = false

local function load_item(id)
    if item_cache[id] then return item_cache[id] end
    local dir = BASE .. id .. "/"
    local data = { id = id, name = id, description = "", price = 0 }
    local cfg = JSON.load(dir .. "config.json")
    if cfg then
        data.name = cfg.name or id
        data.description = cfg.description or ""
        data.price = cfg.price or 0
    end
    if love.filesystem.getInfo(dir .. "image.png") then
        data.image = love.graphics.newImage(dir .. "image.png")
    end
    if love.filesystem.getInfo(dir .. "sprite.png") then
        data.sprite = love.graphics.newImage(dir .. "sprite.png")
    end
    item_cache[id] = data
    return data
end

function Inventory.add(id)
    table.insert(items, id)
    local data = load_item(id)
    Notification.show("Gained item: " .. data.name)
    Log.info("Inventory: added", { id = id, name = data.name })
end

function Inventory.remove(id)
    for i = #items, 1, -1 do
        if items[i] == id then
            table.remove(items, i)
            local data = load_item(id)
            Notification.show("Removed item: " .. data.name)
            Log.info("Inventory: removed", { id = id })
            return true
        end
    end
    return false
end

function Inventory.has(id)
    for _, item_id in ipairs(items) do
        if item_id == id then return true end
    end
    return false
end

function Inventory.get_all()
    return items
end

function Inventory.get_item_data(id)
    return load_item(id)
end

function Inventory.count()
    return #items
end

function Inventory.get_selected()
    return selected
end

function Inventory.set_visible(v)
    visible = v
end

function Inventory.is_visible()
    return visible
end

function Inventory.toggle()
    visible = not visible
end

function Inventory.keypressed(key)
    if not visible then return false end
    if key == "escape" or key == "tab" then
        visible = false
        return true
    end
    local n = #items
    if n == 0 then return true end
    if key == "up" or key == "w" then
        selected = selected - 1
        if selected < 1 then selected = n end
        return true
    elseif key == "down" or key == "s" then
        selected = selected + 1
        if selected > n then selected = 1 end
        return true
    end
    return true
end

function Inventory.draw()
    if not visible then return end
    local sw, sh = love.graphics.getDimensions()
    if not overlay_image and love.filesystem.getInfo(OVERLAY_PATH) then
        overlay_image = love.graphics.newImage(OVERLAY_PATH)
    end
    if overlay_image then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(overlay_image, 0, 0)
    end
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.printf("INVENTORY", 50, 35, sw * 0.45, 'left')
    if #items == 0 then
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.printf("You have nothing.", 50, 65, sw * 0.45, 'left')
        love.graphics.printf("Tab / Esc to close", 0, sh * 0.92, sw, 'center')
        love.graphics.setColor(1, 1, 1, 1)
        return
    end
    local draw_y = 60
    for i, id in ipairs(items) do
        local data = load_item(id)
        if i == selected then
            love.graphics.setColor(1, 0.79, 0.05, 1)
            if data.image then
                love.graphics.draw(data.image, sw * 0.5, 43)
            end
            love.graphics.printf(data.name, sw * 0.52, sh * 0.53, sw, 'left')
            love.graphics.printf(data.description, sw * 0.5, sh * 0.58, sw, 'left')
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        love.graphics.printf(data.name, 50, draw_y, sw, 'left')
        draw_y = draw_y + 20
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(selected .. " / " .. #items, sw * 0.37, sh * 0.9, sw, 'left')
end

function Inventory.clear()
    items = {}
    selected = 1
end

function Inventory.serialize()
    return items
end

function Inventory.deserialize(data)
    items = data or {}
end

return Inventory
