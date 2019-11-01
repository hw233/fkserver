local pb = require "pb"
local skynet = require "skynetproto"
local log = require "log"
require "functions"
local channel = require "channel"

pb.register_file("gamingcity/pb/verify_define.proto")
pb.register_file("gamingcity/pb/redis_define.proto")
pb.register_file("gamingcity/pb/common_player_define.proto")
pb.register_file("gamingcity/pb/config_define.proto")
pb.register_file("gamingcity/pb/common_enum_define.proto")
pb.register_file("gamingcity/pb/common_msg_define.proto")
pb.register_file("gamingcity/pb/msg_server.proto")


SessionGate = pb.enum("ServerSessionFrom","Gate")
SessionLogin = pb.enum("ServerSessionFrom","Login")
SessionDB = pb.enum("ServerSessionFrom","DB")
SessionGame = pb.enum("ServerSessionFrom","Game")
SessionWeb = pb.enum("ServerSessionFrom","Web")
SessionAsynGm = pb.enum("ServerSessionFrom","AsynGm")
SessionConfig = pb.enum("ServerSessionFrom","Config")

local MSG = {}

local dispatcher = {}

function MSG.on_msg(address,msgid,msg)
    local c = dispatcher[msgid]
    if not c then
        return
    end

    return c.f(address,msg)
end

function MSG.register(msgid,func)
    assert(not dispatcher[msgid],msgid)
    assert(func)

    local f = type(func) == "string" and _G[func] or func

    dispatcher[msgid] = {
        msgid = msgid,
        f = f,
    }
end

function MSG.register_handle(conf)
    for msgid,func in pairs(conf) do
        MSG.register(msgid,func)
    end
end

function MSG.get(msgid)
    if not msgid then return dispatcher end

    return dispatcher[msgid]
end

MSG.pack = skynet.pack
MSG.unpack = skynet.unpack

function MSG.call(id,method,msg)
    return channel.call(id,method,msg)
end

function MSG.send(id,method,msg)
    channel.publish(id,method,msg)
end

-- skynet.register_protocol {
--     name = "msg",
--     id = 13,
--     unpack = MSG.unpack,
--     pack = MSG.pack,
--     dispatch = function(_, address, cmd, ...)
--         skynet.ret(MSG.pack(MSG.on_msg(address,cmd,...)))
--     end,
-- }


return MSG