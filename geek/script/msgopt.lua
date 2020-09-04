local skynet = require "skynetproto"
local log = require "log"
require "functions"

local MSG = {}

local dispatcher = {}

function MSG.on_msg(msgid,...)
    local f = dispatcher[msgid]
    if not f then
        log.error("unkonw msgid,%s",msgid)
        return
    end

    return f(...)
end

function MSG.register(msgid,func)
    assert(not dispatcher[msgid],msgid)
    assert(func)

    local f = type(func) == "string" and _G[func] or func

    dispatcher[msgid] = f
end

function MSG.register_handle(conf)
    for msgid,func in pairs(conf) do
        MSG.register(msgid,func)
    end
end

function MSG.query(msgid)
    if not msgid then return dispatcher end

    return dispatcher[msgid]
end

MSG.pack = skynet.pack
MSG.unpack = skynet.unpack

return MSG