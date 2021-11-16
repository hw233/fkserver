


local skynet = require "skynetproto"
local msgserver = require "gate.msgserver"
local log = require "log"
local protocolnetmsg = require "gate.netmsgopt"
local channel = require "channel"
require "skynet.manager"
require "functions"
local queue = require "skynet.queue"

collectgarbage("setpause", 100)
collectgarbage("setstepmul", 1000)

LOG_NAME = "slot"

local gateservice,protocol,agentcount,gateid = ...

local loginservice = nil
local agentservice = {}
local balance = 0

local onlineguid = {}
local fduser = {}
local netmsgopt

local ctx = {}

function ctx:lockcall(fn,...)
    self.__lock = self.__lock or queue()
    return self.__lock(fn,...)
end

local LOGIN_HANDLE = {
    CL_Auth = true,
    CL_Login = true,
}

local CMD = {}

local function balanceagent()
    balance = (balance % #agentservice) + 1
    return agentservice[balance]
end

local function logout(guid)
    log.warning("%s logout",guid)
    local u = onlineguid[guid]
    if u and u.fd then
        fduser[u.fd] = nil
    end
    onlineguid[guid] = nil
end

local function kickout(guid)
    log.info("kickout %s",guid)
    local u = onlineguid[guid]
    if u then
        skynet.call(u.agent,"lua","kickout",u.guid)
        fduser[u.fd] = nil
    end
    onlineguid[guid] = nil
end

local function afk(fd)
    local u  = fduser[fd]
    if not u then
        log.error("afk got nil session,%d",fd)
        return
    end

    u:lockcall(function()
        -- double check
        if not fduser[fd] then
            log.error("afk %s double check nil",fd)
            return
        end
        
        pcall(skynet.call,u.agent, "lua", "afk",u.guid)
        logout(u.guid)
    end)
end

local function login(fd,guid,conf)
    local s = onlineguid[guid] or fduser[fd]
    if s then
        if s.fd == fd and s.guid == guid then
            log.warning(" %d login repeated!",guid)
            return
        end
        kickout(s.guid)
    end

    log.info("login %s:%s",fd,guid)

    local agent = balanceagent()
    skynet.call(agent, "lua", "login", {
        guid = guid,
        fd = fd,
        ip = msgserver.ip(fd),
        conf = conf,
    })
    
    local u = {
        agent = agent,
        guid = guid,
        fd = fd,
    }

    setmetatable(u,{__index = ctx})

    onlineguid[guid] = u
    fduser[fd] = u
end

function CMD.login(fd,guid,conf)
    login(fd,guid,conf)
end

function CMD.logout(guid)
	logout(guid)
end

function CMD.kickout(guid)
    kickout(guid)
end

function CMD.afk(guid)
    afk(guid)
end

function CMD.maintain(switch)
    skynet.call(loginservice,"lua","maintain",switch)
end

function CMD.forward(who,proto,...)
    log.dump(who)
    log.dump(proto)
    channel.publish(who,proto,...)
end

function CMD.term()
    log.warning("GATE TERM")
    for fd,_ in pairs(fduser) do
        afk(fd)
    end
    log.warning("GATE TERM END")
end

local function dispatch(msgname,msg,session)
    local fd = session and session.fd or nil
    if not session or not fd then
        log.error("request_handler but no connection")
        return
    end

    local u = fduser[fd]
    -- if msgname ~= "CS_HeartBeat" then
    --     log.info("gated.dispatch %s,guid:%s,fd:%s",msgname,u and u.guid,fd)
    --     log.dump(msg)
    -- end

    if not u or not u.guid or LOGIN_HANDLE[msgname] then
        skynet.call(loginservice,"client",msgname,msg,session)
        return
    end

    u:lockcall(function()
        -- double check
        if not fduser[fd] then
            log.error("dispatch double check %s,%s msg:%s nil session",u.guid,fd,msgname)
            return
        end
        
        skynet.call(u.agent,"client",msgname,msg,u.guid)
    end)
    u.last_live_time = os.time()
end

local FORWARD = {}

local function forward(guid,msgname,msg)
    local u = onlineguid[guid]
    if not u then
        log.error("forward %s,%s got nil session.",guid,msgname)
        log.dump(msg)
        return
    end

    if not u.fd then
        log.error("forward %s,%s got nil fd.",guid,msgname)
        log.dump(msg)
        return
    end

    -- log.info("gated toclient %s:%s,%s",guid,u.fd,msgname)
    -- log.dump(msg)

    netmsgopt.send(u.fd,msgname,msg)
end

local function forwardcommand(guid,cmd,...)
    local u = onlineguid[guid]
    if not u then
        log.error("forwardcommand %s got nil session.",guid)
        return
    end

    if not u.agent then
        log.error("forwardcommand %s got nil agent.",guid)
        return
    end

    skynet.send(u.agent,"lua",cmd,guid,...)
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

skynet.start(function()
    local handle = skynet.localname ".slot"
    if handle then
        log.error("same cluster launch too many gate service,exit %s.",skynet.self())
        skynet.exit()
        return handle
    end

    skynet.register(".slot")

    netmsgopt = protocolnetmsg[protocol]

    loginservice = skynet.newservice("gate.logind",skynet.self(),gateid,protocol)
    for i = 1,agentcount do
        agentservice[i] = skynet.newservice("gate.agent",skynet.self(),protocol)
    end

    local is_maintain = channel.call("config.?","msg","maintain")
    log.dump(is_maintain)
    skynet.call(loginservice,"lua","maintain",is_maintain)

    skynet.dispatch("forward",function(_,_,guids,action,...)
        local f = FORWARD[action]
        if not f then
            log.error("unknow cmd:%s",action)
            skynet.retpack(nil)
            return
        end

        skynet.retpack(f(guids,...))
    end)

    skynet.dispatch("msg",function(_,_,msgname,msg,...)
        skynet.retpack(dispatch(msgname,msg,...))
    end)

    skynet.dispatch("lua", function (_, _, cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.retpack(f(...))
        else
            log.error("unkown cmd,%s",cmd)
            skynet.retpack(nil)
        end
    end)

    skynet.register_protocol {
        name = "client",
        id = skynet.PTYPE_CLIENT,
        unpack = skynet.unpack,
        pack = skynet.pack,
    }
end)