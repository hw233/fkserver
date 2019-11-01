local skynet = require "skynet"

local event = {}

local events = {}
local dispatcher = {}

local function on_event(e)
    local fs = dispatcher[e.id]
    if not fs then
        return
    end

    local param = e.param
    if not e.param or type(e.param) ~= "table" then
        param = {}
    end

    for _,f in pairs(fs) do
        f(evt.source,evt.target,table.unpack(param))
    end
end

function event.create(id,source,target,param)
    local e = {
        id = id,
        source = source,
        target = target,
        param = param,
    }

    return e
end

function event.raise(id)
    on_event(event.create(id))
end

function event.post(e)
    events[e.id] = e
    if coroutine.status(event.co) == "suspend" then
        skynet.wakeup(event.co)
    end
end

function event.register(id,func)
    if not dispatcher[id] then
        dispatcher[id] = {}
    end
    table.insert(dispatcher[id],func)
end

function event.tick()
    for _,e in ipairs(event) do
        on_event(e)
    end
    events = {}
end

event.co = skynet.fork(function() 
    while true do
        event.tick()
        skynet.suspend(event.co)
    end
end)

return event