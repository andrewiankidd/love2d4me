-- interact.lua -- Interaction routing.
--
-- Dispatches interactions with NPCs, items, or other objects.
-- Games register handlers; the module routes by object type.
--
-- Usage:
--   local Interact = require("love2d4me.src.interact")
--   Interact.register("npc", function(name, data) chat(name) end)
--   Interact.register("item", function(name, data) additem(name) end)
--   Interact.fire("npc", "Bob", { index = 1 })

local Log = require("love2d4me.src.log")

local Interact = {}

local handlers = {}

function Interact.register(objtype, handler)
    handlers[objtype] = handler
    Log.debug("Interact: registered", { type = objtype })
end

function Interact.fire(objtype, name, data)
    local handler = handlers[objtype]
    if handler then
        handler(name, data or {})
        return true
    end
    Log.warn("Interact: no handler", { type = objtype })
    return false
end

return Interact
