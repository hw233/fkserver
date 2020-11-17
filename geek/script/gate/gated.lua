local netmsgopt = require "netmsgopt"

local loginservice,gateid,proto = ...
loginservice = tonumber(loginservice)
protocol = tostring(proto)
gateid = tonumber(gateid)

local skynet = require "skynetproto"
local msgserver = require "gate.msgserver"
local log = require "log"

require "functions"

LOG_NAME = "gate"

netmsgopt.protocol(protocol)

local onlineguid = {}
local fdsession = {}
local heartbeat_check_time = 12

local LOGIN_HANDLE = {
    CL_Auth = true,
    CL_Login = true,
}


local server = {}

function server.login(fd,guid,inserverid,conf)
    local s = onlineguid[guid] or fdsession[fd]
    if s then
        if s.fd == fd and s.guid == guid then
            log.warning(" %d login repeated!",guid)
            return
        end
        server.kickout(s.guid)
    end

    local agent = skynet.newservice("gate.agent",skynet.self(),protocol,inserverid)
	local u = {
		agent = agent,
        guid = guid,
        fd = fd,
        ip = msgserver.ip(fd),
        conf = conf,
    }

	skynet.call(agent, "lua", "login", u)
    onlineguid[guid] = u
    fdsession[fd] = u
end

function server.logout(guid)
	local u = onlineguid[guid]
    if u then
        log.warning("%s logout",guid)
        pcall(skynet.call,loginservice, "lua", "logout",u.fd)
        onlineguid[guid] = nil
        fdsession[u.fd] = nil
	end
end

function server.kickout(guid)
    local u = onlineguid[guid]
    if u then
        pcall(skynet.call, u.agent, "lua", "kickout")
        fdsession[u.fd] = nil
        netmsgopt.send(u.fd,"SC_Logout",{
            result = 0,
        })
    end
    onlineguid[guid] = nil
end

function server.maintain(switch)
    skynet.call(loginservice,"lua","maintain",switch)
end

function server.sc_logout(fd,...)
    netmsgopt.send(fd,"SC_Logout",...)
end

function server.disconnect_handler(c)
	local u = fdsession[c.fd]
	if u and u.agent then
        pcall(skynet.call,u.agent, "lua", "afk")
    else
        pcall(skynet.call,loginservice,"lua","logout",c.fd)
	end
end

function server.request_handler(msgstr,session)
    local fd = session and session.fd or nil
    if not session or not fd then
        log.error("request_handler but no connection")
        return
    end

    local u = fdsession[fd]

    local msgid,str = netmsgopt.unpack(msgstr)
    local msg = netmsgopt.decode(msgid,str)
    local msgname = netmsgopt.msgname(msgid)
    if msgname ~= "CS_HeartBeat" then
        log.info("gated.dispatch %s,%s",msgname,u and u.guid or fd)
        log.dump(msg)
    end

    if not u or not u.guid or LOGIN_HANDLE[msgname] then
        skynet.send(loginservice,"client",msgname,msg,session)
        return
    end

    u.last_live_time = os.time()

    skynet.send(u.agent,"client",msgname,msg)
end

local function guid_monitor()
    for _,u in pairs(onlineguid) do
        local last_live_time = u.last_live_time
        if last_live_time and os.time() - last_live_time > heartbeat_check_time then
            pcall(skynet.call,u.agent, "lua", "afk")
        end
    end

    skynet.timeout(2 * 100,guid_monitor)
end

skynet.init(function()
    skynet.call(loginservice,"lua","register_gate",skynet.self())
end)

skynet.start(function()
    guid_monitor()
end)

msgserver.start(server)



