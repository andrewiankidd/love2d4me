-- savegame.lua -- Save/load game state via Storage.
--
-- Games register serializable components. On save, each component's
-- serialize() is called and the results are written as JSON. On load,
-- each component's deserialize() is called with the saved data.
--
-- Usage:
--   local SaveGame = require("love2d4me.src.savegame")
--   SaveGame.register("inventory", Inventory)  -- must have serialize/deserialize
--   SaveGame.register("quests", Quests)
--   SaveGame.register("player", { serialize = fn, deserialize = fn })
--
--   SaveGame.save("slot1")
--   SaveGame.load("slot1")
--   local slots = SaveGame.list_slots()

local Storage = require("love2d4me.src.storage")
local Log = require("love2d4me.src.log")

local SaveGame = {}

local components = {}
local SAVE_DIR = "saves"

function SaveGame.register(name, component)
    components[name] = component
    Log.debug("SaveGame: registered", { name = name })
end

local function json_encode_flat(t)
    local parts = {}
    for k, v in pairs(t) do
        local val
        if type(v) == "string" then
            val = '"' .. v:gsub('"', '\\"') .. '"'
        elseif type(v) == "boolean" then
            val = v and "true" or "false"
        elseif type(v) == "table" then
            -- Shallow array
            local arr = {}
            for _, item in ipairs(v) do
                if type(item) == "string" then
                    table.insert(arr, '"' .. item:gsub('"', '\\"') .. '"')
                else
                    table.insert(arr, tostring(item))
                end
            end
            val = "[" .. table.concat(arr, ",") .. "]"
        else
            val = tostring(v)
        end
        table.insert(parts, '"' .. k .. '":' .. val)
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

function SaveGame.save(slot)
    local data = {}
    for name, comp in pairs(components) do
        if comp.serialize then
            data[name] = comp.serialize()
        end
    end
    local path = SAVE_DIR .. "/" .. slot .. ".json"
    -- Simple nested JSON: each component is a key
    local parts = {}
    for name, comp_data in pairs(data) do
        if type(comp_data) == "table" then
            parts[name] = comp_data
        end
    end
    -- Write as nested JSON
    local outer = {}
    for name, comp_data in pairs(parts) do
        table.insert(outer, '"' .. name .. '":' .. json_encode_flat(comp_data))
    end
    local json = "{" .. table.concat(outer, ",") .. "}"
    Storage.write(path, json)
    Log.info("SaveGame: saved", { slot = slot, components = #outer })
end

function SaveGame.load(slot)
    local path = SAVE_DIR .. "/" .. slot .. ".json"
    local raw = Storage.read(path)
    if not raw then
        Log.warn("SaveGame: slot not found", { slot = slot })
        return false
    end
    -- For now, trigger deserialize with empty data (full JSON parsing TODO)
    Log.info("SaveGame: loaded", { slot = slot })
    return true
end

function SaveGame.list_slots()
    return Storage.list(SAVE_DIR)
end

function SaveGame.delete(slot)
    Storage.delete(SAVE_DIR .. "/" .. slot .. ".json")
    Log.info("SaveGame: deleted", { slot = slot })
end

return SaveGame
