local skynet = require "skynetproto"
local channel = require "channel"
local gbk = require "gbk"
local util = require "gate.util"
local crypt = require "skynet.crypt"
local httpc = require "http.httpc"
local datacenter = require "skynet.datacenter"
local netmsgopt = require "netmsgopt"
local json = require "json"
local enum = require "pb_enums"
require "functions"
local log = require "log"

collectgarbage("setpause", 100)
collectgarbage("setstepmul", 1000)

LOG_NAME = "gate.agent"

local gate,protocol = ...
gate = tonumber(gate)
log.info("gate.agent protocol %s",protocol)
netmsgopt.protocol(protocol)

local rsa_public_key

local onlineguid = {}

local function send2client(guid,msgname,msg)
    local u = onlineguid[guid]
    if not u or not u.fd then
        log.error("send2client %s got nil session or fd",guid)
        return
    end

    netmsgopt.send(u.fd,msgname,msg)
end

local CMD = {}

function CMD.login(u)
	log.info("%s is login", u.guid)
    onlineguid[u.guid] = u
end

local function kickout(guid)
    send2client(guid,"SC_Logout",{
        result = enum.ERROR_NONE
    })
    onlineguid[guid] = nil
end

function CMD.kickout(guid)
    kickout(guid)
end

local function afk(guid)
    log.warning("afk,guid:%s",guid)
    local u = onlineguid[guid]
    if not u or not u.server then
        log.warning("afk,guid:%s,not in server,%s",guid,u.server)
        return
    end

    channel.call("service."..tostring(u.server),"lua","afk",guid,true)
    onlineguid[guid] = nil
end

function CMD.logout(guid)
    log.warning("%s is logout", guid)
    onlineguid[guid] = nil
end

function CMD.afk(guid)
    afk(guid)
end

function CMD.goserver(guid,server)
    local u = onlineguid[guid]
    if not u then
        log.warning("goserver %s got nil session",guid)
        return
    end
    u.server = server
end

local MSG = {}

function MSG.CS_Logout(msg,guid)
    local u = onlineguid[guid]
    if not u or not u.server then
        log.error("CS_Logout got nil session or server:%s",guid)
        return
    end

    local result = channel.call("service."..tostring(u.server),"msg","CS_Logout",guid)

    netmsgopt.send(u.fd,"SC_Logout",{
        result = result
    })

    if result == enum.ERROR_NONE then
        skynet.call(gate,"lua","logout",guid)
        onlineguid[guid] = nil
    end
end

function MSG.C_RequestPublicKey(msg,guid)
    if not rsa_public_key then
        rsa_public_key = skynet.public_key()
    end

    send2client(guid,"C_PublicKey",{
        public_key = rsa_public_key,
    })
end

function MSG.CS_HeartBeat(_,guid)
    send2client(guid,"SC_HeartBeat",{
        severTime = os.time(),
    })
end

local function dispatch(msgname,msg,guid)
    local f = MSG[msgname]
    if f then
        return f(msg,guid)
    end

    local u = onlineguid[guid]
    if not u or not u.server then
        log.error("dispatch forward to server %s got nil session or fd",guid)
        return
    end

    channel.publish("service."..tostring(u.server),"msg",msgname,msg,guid)
end

skynet.start(function()
	skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = assert(CMD[cmd])
		skynet.retpack(f(...))
    end)

    skynet.register_protocol {
        name = "client",
        id = skynet.PTYPE_CLIENT,
        unpack = skynet.unpack,
        pack = skynet.pack,
    }

	skynet.dispatch("client", function(_,_,...)
	    skynet.retpack(dispatch(...))
    end)

    skynet.dispatch("forward",function (_,_,guid,msgname,msg)
        local u = onlineguid[guid]
        if not u or not u.fd then
            log.error("forward msg got nil session...")
            return
        end
        netmsgopt.send(u.fd,msgname,msg)
    end)
end)
