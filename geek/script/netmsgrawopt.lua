local pb = require "pb_files"
local log = require "log"
local skynet = require "skynetproto"
local netpack = require "skynet.netpack"
require "functions"

local socketdriver = require "skynet.socketdriver"

local msgidmap = {}

for k in pb.types() do
    local msgname = string.match(k,"%.([^%.]+)%.MsgID")
    if msgname then
        local msgid = pb.enum(msgname..".MsgID", "ID")
        if msgid then
            local c = {
                name = msgname,
                id = msgid,
            }
            msgidmap[msgid] = c
            msgidmap[msgname] = c
        end
    end
end


local dispatcher = {}
local NETMSG = {}


function NETMSG.msgname(msgid)
    local c = msgidmap[msgid]
    if not c then
        return nil
    end

    return c.name
end

function NETMSG.msgid(msgname)
    local c = msgidmap[msgname]
    if not c then
        return nil
    end

    return c.id
end

function NETMSG.pack(msgid,msgstr,guid)
    msgid = msgidmap[msgid].id
    if guid and type(guid) == "number" then
        return string.pack("<HHI4",#msgstr + 6,msgid,guid)..msgstr
    else
        return string.pack("<HH",#msgstr + 6,msgid)..msgstr
    end
end

function NETMSG.unpack(msgstr,has_guid)
    local msgid,guid
    if has_guid then
        msgid,guid = string.unpack("<HI4",msgstr)
    else
        msgid = string.unpack("<H",msgstr)
    end
    return msgid,string.sub(msgstr,3),guid
end

function NETMSG.decode(msgid,msgstr)
    local m = msgidmap[msgid]
    if not m then
        log.error("unkown msgid to decode.")
        return nil
    end

    return pb.decode(m.name,msgstr)
end

function NETMSG.encode(msgid,msg)
    local m = msgidmap[msgid]
    if not m then
        log.error("unkown msgid to encode.")
        return nil
    end

    return pb.encode(m.name,msg)
end

function NETMSG.dispatch(msgid,msg,...)
    local f = dispatcher[msgid]
    if not f then
        log.error("netmsg.dispatch func:%s", msgidmap[msgid].name)
        return
    end

    return f(msg,...)
end

function NETMSG.on_msg(msgstr,...)
    local msgid,buf = NETMSG.unpack(msgstr)
    local msgname = msgidmap[msgid].name
    local f = dispatcher[msgid]
    if not f then
        log.error("NETMSG.on_msg not found dispatcher for %s,%s",msgid,msgname)
        return nil
    end

    local msg = #buf > 0 and NETMSG.decode(msgid,buf) or {}

    log.info("netmsg.on_msg %s,%d,%d",msgname,msgid,#buf)

    return f(msg,...)
end

function NETMSG.register_handle(conf)
    for msgname,func in pairs(conf) do
        if type(func) == "function" then
            NETMSG.register(msgname,func)
        end
    end
end

function NETMSG.register(msgname,func)
    local c = msgidmap[msgname]
    assert(c,string.format("register unkown msg,%s",msgname))

    local msgid = c.id
    assert(msgid, string.format("msg:%s, func:%s", tostring(msgname),func))

    -- print(string.format("%s %-30s %d",msgname,"=>",msgid))
    local f = type(func) == "string" and _G[func] or func
    dispatcher[msgname] = f
    dispatcher[msgid] = f
end

function NETMSG.dispatcher(msgid)
    return dispatcher[msgid]
end

function NETMSG.send(fd,msgname,msg,guid)
    local msgstr = NETMSG.encode(msgname,msg)
    local msgid = pb.enum(msgname..".MsgID","ID")
    if not msgid then
        log.error("invalid msgname:%s,%s",msgname,msgid)
    end

    local packstr = NETMSG.pack(msgid,msgstr,guid)
    log.info("NETMSG.send msgname:%s,%s,%d",msgname,msgid,#packstr)
    socketdriver.send(fd,packstr,#packstr)
end


skynet.start(function() 
    skynet.dispatch("msg",function(_,_,msgid,...) 
        skynet.retpack(NETMSG.on_msg(msgid,...))
    end)
end)

return NETMSG
