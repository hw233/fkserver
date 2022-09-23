


local skynet = require "skynetproto"
local msgserver = require "gate.msgserver"
local log = require "log"
local protocolnetmsg = require "gate.netmsgopt"
require "skynet.manager"
require "functions"

local traceback = debug.traceback
local xpcall = xpcall

collectgarbage("setpause", 100)
collectgarbage("setstepmul", 1000)

LOG_NAME = "gate"

local sessions = {}
local heartbeat_check_time = 27 --12
local slot

local CMD = {}

local function kickout(guid)
    log.info("kickout %s",guid)
    local ok,ret = xpcall(skynet.call,traceback,slot,"lua","kickout",guid)
    if not ok then
        log.error("%s",ret)
    end
end

local function afk(fd)
    skynet.send(slot,"lua","afk",fd)
    sessions[fd] = nil
end

function CMD.kickout(guid)
    kickout(guid)
end

function CMD.maintain(switch)
    xpcall(skynet.call,traceback,slot,"lua","maintain",switch)
end

function CMD.term()
    log.warning("GATE TERM")
    xpcall(skynet.call,traceback,slot,"lua","term")
    log.warning("GATE TERM END")
end

local function checkgateconf(conf)
    assert(conf)
    assert(conf.id)
    assert(conf.type)
    assert(conf.name)
end

function CMD.start(conf)
    checkgateconf(conf)
    local sconf = conf
    local gateid = conf.id

    LOG_NAME = "gate." .. gateid

    if not sconf or sconf.is_launch == 0 or not sconf.conf then
        log.error("launch a unconfig or unlaunch gate service,service:%d.",gateid)
        return
    end

    local gateconf = sconf.conf
    local agentcount = gateconf.agentcount or 8
    local protocol = gateconf.protocol
    local netmsgopt = protocolnetmsg[protocol]

    local host,port = gateconf.host,gateconf.port
    if not port then
        host,port = host:match("([^:]+):(%d+)")
        port = tonumber(port)
    end

    slot = skynet.uniqueservice("gate.slot",skynet.self(),protocol,agentcount,gateid)

    local server = {
        host = host,
        port = port,
        protocol = protocol
    }

    function server.connect_handler(fd,addr)
        sessions[fd] = { fd = fd,addr = addr}
    end

    function server.disconnect_handler(c)
        afk(c.fd)
    end

    function server.request_handler(msgstr,session)
        local fd = session and session.fd or nil
        if not session or not fd then
            log.error("request_handler but no connection")
            return
        end

        local msgid,str = netmsgopt.unpack(msgstr)
        local msg = netmsgopt.decode(msgid,str)
        local msgname = netmsgopt.msgname(msgid)

        if not msgname then
            log.error("gated.dispatch got nil msgname,msgid:%s,msgname:%s",msgid,msgname)
            return
        end

        -- if msgname ~= "CS_HeartBeat" then
        --     log.info("gated.dispatch %s,guid:%s,fd:%s",msgname,u and u.guid,fd)
        --     log.dump(msg)
        -- end

        skynet.send(slot,"msg",msgname,msg,session)
        local u = sessions[fd]
        u.last_live_time = os.time()
    end

    msgserver.start(server)
end

local FORWARD = {}

function FORWARD.forward(who,...)
    skynet.send(slot,"forward",who,"forward",...)
end

function FORWARD.broadcast(whos,...)
    skynet.send(slot,"forward",whos,"broadcast",...)
end

function FORWARD.lua(who,...)
    skynet.send(slot,"forward",who,"lua",...)
end

local function check_afk(u)
    local now = os.time()
    local last_live_time = u.last_live_time
    if last_live_time and now - last_live_time > heartbeat_check_time then
        log.info("guid_monitor timeout afk %s",u.fd)
        afk(u.fd)
        if u.fd then
            msgserver.closeclient(u.fd)
            return
        end
        log.error("guid_monitor close socket got nil fd,guid:%s",u.fd)
    end
end

local function session_monitor()
    for fd,u in pairs(sessions) do
        check_afk(u)
    end
end

skynet.start(function()
    local handle = skynet.localname ".gate"
    if handle then
        log.error("same cluster launch too many gate service,exit %s.",skynet.self())
        skynet.exit()
        return handle
    end

    skynet.register_protocol {
        name = "client",
        id = skynet.PTYPE_CLIENT,
        unpack = skynet.unpack,
        pack = skynet.pack,
        dispatch = function(_,_,guids,msg,...)
            local f = FORWARD[msg]
            if not f then
                log.error("unknow cmd:%s",msg)
                skynet.retpack(nil)
                return
            end
    
            skynet.retpack(f(guids,...))
        end
    }

    skynet.dispatch("lua", function (_, address, cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.retpack(f(...))
        else
            log.error("unkown cmd,%s",cmd)
            skynet.retpack(nil)
        end
    end)

    local timermgr = require "timermgr"
    timermgr:loop(2,session_monitor)
end)