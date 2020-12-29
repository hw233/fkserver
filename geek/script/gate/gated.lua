


local skynet = require "skynetproto"
local msgserver = require "gate.msgserver"
local log = require "log"
local netmsgopt = require "netmsgopt"
local channel = require "channel"
require "skynet.manager"
require "functions"

collectgarbage("setpause", 100)

LOG_NAME = "gate"

local loginservice = nil
local protocol = nil

local onlineguid = {}
local fduser = {}
local heartbeat_check_time = 12

local LOGIN_HANDLE = {
    CL_Auth = true,
    CL_Login = true,
}

local CMD = {}

local function logout(guid)
    local u = onlineguid[guid]
    if u and u.guid then
        log.warning("%s logout",guid)
        skynet.kill(u.agent)
        onlineguid[guid] = nil
        fduser[u.fd] = nil
	end
end

local function kickout(guid)
    log.info("kickout %s",guid)
    local u = onlineguid[guid]
    if u then
        skynet.kill(u.agent)
        fduser[u.fd] = nil
        netmsgopt.send(u.fd,"SC_Logout",{
            result = 0,
        })
    end
    onlineguid[guid] = nil
end

local function afk(fd)
    local u  = fduser[fd]
    if not u then
        pcall(skynet.call,loginservice, "lua", "afk",fd)
        return
    end

    pcall(skynet.call,u.agent, "lua", "afk")
    logout(u.guid)
end

local function login(fd,guid,server,conf)
    local s = onlineguid[guid] or fduser[fd]
    if s then
        if s.fd == fd and s.guid == guid then
            log.warning(" %d login repeated!",guid)
            return
        end
        kickout(s.guid)
    end

    local agent = skynet.newservice("gate.agent",skynet.self(),protocol,server)
	local u = {
		agent = agent,
        guid = guid,
        fd = fd,
        ip = msgserver.ip(fd),
        conf = conf,
        server = server,
    }

	skynet.call(agent, "lua", "login", u)
    onlineguid[guid] = u
    fduser[fd] = u
end

function CMD.login(fd,guid,server,conf)
    login(fd,guid,server,conf)
end

function CMD.logout(guid)
	logout(guid)
end

function CMD.kickout(guid)
    kickout(guid)
end

function CMD.maintain(switch)
    skynet.call(loginservice,"lua","maintain",switch)
end

function CMD.sc_logout(guid)
    log.info("sc_logout %s",guid)
    kickout(guid)
end

function CMD.forward(who,proto,...)
    channel.publish(who,proto,...)
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
    protocol = gateconf.protocol
    netmsgopt.protocol(protocol)

    local host,port = gateconf.host,gateconf.port
    if not port then
        host,port = host:match("([^:]+):(%d+)")
        port = tonumber(port)
    end

    loginservice = skynet.newservice("gate.logind",skynet.self(),gateid,protocol)

    local is_maintain = channel.call("config.?","msg","maintain")
    log.dump(is_maintain)
    skynet.call(loginservice,"lua","maintain",is_maintain)

    local server = {
        host = host,
        port = port,
        protocol = protocol
    }

    function server.disconnect_handler(c)
        afk(c.fd)
    end

    function server.request_handler(msgstr,session)
        local fd = session and session.fd or nil
        if not session or not fd then
            log.error("request_handler but no connection")
            return
        end

        local u = fduser[fd]

        local msgid,str = netmsgopt.unpack(msgstr)
        local msg = netmsgopt.decode(msgid,str)
        local msgname = netmsgopt.msgname(msgid)
        if msgname ~= "CS_HeartBeat" then
            log.info("gated.dispatch %s,guid:%s,fd:%s",msgname,u and u.guid,fd)
            log.dump(msg)
        end

        if not u or not u.guid or LOGIN_HANDLE[msgname] then
            skynet.send(loginservice,"client",msgname,msg,session)
            return
        end

        u.last_live_time = os.time()

        skynet.send(u.agent,"client",msgname,msg)
    end

    msgserver.start(server)
end

local FORWARD = {}

local function forward(guid,msgname,msg)
    local u = onlineguid[guid]
    if not u then
        log.error("forward %s got nil session.",guid)
        return
    end

    if not u.fd then
        log.error("forward %s got nil fd.",guid)
        return
    end

    log.info("gated toclient %s:%s,%s",guid,u.fd,msgname)
    log.dump(msg)

    netmsgopt.send(u.fd,msgname,msg)
end

local function forwardcommand(guid,...)
    local u = onlineguid[guid]
    if not u then
        log.error("forwardcommand %s got nil session.",guid)
        return
    end

    if not u.agent then
        log.error("forwardcommand %s got nil agent.",guid)
        return
    end

    skynet.send(u.agent,"lua",...)
end

function FORWARD.forward(who,...)
    forward(who,...)
end

function FORWARD.broadcast(whos,...)
    for _,guid in pairs(whos) do
        forward(guid,...)
    end
end

function FORWARD.lua(who,...)
    forwardcommand(who,...)
end

local function guid_monitor()
    local now = os.time()
    for _,u in pairs(onlineguid) do
        local last_live_time = u.last_live_time
        if last_live_time and now - last_live_time > heartbeat_check_time then
            log.info("guid_monitor timeout afk %s",u.guid)
            afk(u.fd)
            if u.fd then
                msgserver.closeclient(u.fd)
            else
                log.error("guid_monitor close socket got nil fd,guid:%s",u.guid)
            end
        end
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
    }

    skynet.dispatch("client",function(_,_,guids,msg,...)
        local f = FORWARD[msg]
        if not f then
            log.error("unknow cmd:%s",msg)
            return
        end

        skynet.retpack(f(guids,...))
    end)

    skynet.dispatch("lua", function (_, address, cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.retpack(f(...))
        else
            log.error("unkown cmd,%s",cmd)
        end
    end)

    local timermgr = require "timermgr"
    timermgr:loop(2,guid_monitor)
end)





