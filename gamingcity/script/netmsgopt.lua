local skynet = require "skynet"
local pb = require "pb"

local socketdriver = require "skynet.socketdriver"

pb.register_file("gamingcity/pb/verify_define.proto")
pb.register_file("gamingcity/pb/redis_define.proto")
pb.register_file("gamingcity/pb/common_player_define.proto")
pb.register_file("gamingcity/pb/config_define.proto")
pb.register_file("gamingcity/pb/common_enum_define.proto")
pb.register_file("gamingcity/pb/common_msg_define.proto")
pb.register_file("gamingcity/pb/msg_server.proto")

local conn_protocol = skynet.getenv("conn.protocol")

local netpack = {}
if conn_protocol == "ws" then
    local ws = require "websocket"
    netpack.pack = ws.build_binary
else
    local package = require "skynet.netpack"
    netpack.pack = package.pack
end

local msg_extra_data = 0x14

local dispatcher = {}

local NETMSG = {}

function NETMSG.pack(guid,id,msgstr)
    return netpack.pack(string.pack("<HBs"..tostring(string.len(msgstr)).."BI",id,msg_extra_data,msgstr,msg_extra_data,guid))
end

function NETMSG.unpack(msgstr)
    local id,_,guid = string.unpack("<HBH",msgstr)
    return guid,id,string.sub(msgstr,3,string.len(msgstr) - 1)
end

function NETMSG.decode(msgid,msgstr)
    local d = assert(dispatcher[msgid])
    return pb.decode(d.msgname,msgstr)
end

function NETMSG.encode(msgid,msg)
    local d = assert(dispatcher[msgid])
    return pb.encode(d.msgname,msg)
end

function NETMSG.dispatch(fd,guid,msgid,msg)
    local d = assert(dispatcher[msgid])
    local f = d.f
	assert(f, string.format("on_net_msg func:%s", d.msgname))

    f(guid,msg)
end

function NETMSG.on_msg(fd,msg,sz)
    local msgstr = netpack.tostring(msg,sz)
    local _,guid,msgid,buf = NETMSG.unpack(msgstr)
    local d = dispatcher[msgid]
    if not d then
        log.error("")
        return false
    end

	local f = d.f
	assert(f, string.format("on_net_msg func:%s", d.msgname))

    if buf ~= "" then
        f(guid,pb.decode(d.msgname, buf))
    else
        f(guid,{})
    end
    
    return true
end

function NETMSG.register_handle(conf)
    for msgname,func in pairs(conf) do
        NETMSG.register(msgname,func)
    end
end

function NETMSG.register(msgname,func)
    local msgid = pb.enum(msgname .. ".MsgID", "ID")
    -- print("net msg register",msgid)
    assert(msgid, string.format("msg:%s, func:%s", msgname,func))
    local c = {
        msgid = msgid,
        msgname = msgname,
        f = type(func) == "string" and _G[func] or func,
    }

    dispatcher[msgname] = c
    dispatcher[msgid] = c
end

function NETMSG.query(msgid)
    return dispatcher[msgid]
end

function NETMSG.send(fd,guid,msgname,msg)
    local msgid = pb.enum(msgname..".MsgID","ID")
    local msgstr = NETMSG.encode(msgname,msg)
    local packstr = NETMSG.pack(guid,msgid,msgstr)
    socketdriver.send(fd,packstr)
end

return NETMSG
