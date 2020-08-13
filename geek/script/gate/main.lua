local skynet = require "skynetproto"
local channel = require "channel"
local msgopt = require "msgopt"
require "functions"
local log = require "log"
local httpc = require "http.httpc"
local json = require "cjson"

LOG_NAME = "gate"

local sconf 
local gateid
local gateconf
protocol = nil

local function escape(s)
    return (string.gsub(s, "([^A-Za-z0-9_])", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

local function http_get(url)
    local host,url = string.match(url,"([h|H][t|T][t|T][p|P][s|S]?://[^/]+)(.+)")
    log.info("http.get %s  %s",host,url)
    return httpc.get(host,url)
end

local function qirui_request_sms(phone,sms)
    local params = {
        dc = 8,
        un = "2294280010",
        pw = "b13f4de0d2ff3687e2fd",
        sm = escape(sms),
        da = phone,
        tf = 3,
        rf = 2,
        rd = 0,
    }

    local parampath = table.concat(table.series(params,function(v,k) return tostring(k).."="..tostring(v) end),"&")
    local status,body = http_get("http://api.qirui.com:7891/mt?"..parampath)
    log.dump(status)
    log.dump(body)
    if status ~= 200 then return end
    local rep = json.decode(body)
    if rep.success then return rep.id end
    return
end

local CMD = {}

function CMD.LG_PostSms(phone,sms)
    return qirui_request_sms(phone,sms)
end

local function checkgateconf(conf)
    assert(conf)
    assert(conf.id)
    assert(conf.type)
    assert(conf.name)
end

function CMD.start(conf)
    checkgateconf(conf)
    sconf = conf
    gateid = conf.id

    LOG_NAME = "gate." .. gateid

    if not sconf or sconf.is_launch == 0 or not sconf.conf then
        log.error("launch a unconfig or unlaunch gate service,service:%d.",gateid)
        return
    end

    gateconf = sconf.conf
    protocol = gateconf.protocol

    local host,port = gateconf.host,gateconf.port
    if not port then
        host,port = host:match("([^:]+):(%d+)")
        port = tonumber(port)
    end

    local loginservice = skynet.newservice("gate.logind",gateid,protocol)
    local gate = skynet.newservice("gate.gated",loginservice,gateid,protocol)
    skynet.call(gate,"lua","open",{
        host = host,
        port = port,
    })
end

function CMD.forward(who,proto,...)
    channel.publish(who,proto,...)
end

local CONTROL = {}

function CONTROL.forward(who,...)
    channel.publish(who,...)
end

local FORWARD = {}

function FORWARD.forward(who,...)
    channel.publish("guid."..tostring(who),"forward",...)
end

function FORWARD.broadcast(whos,...)
    for _,guid in pairs(whos) do
        channel.publish("guid."..tostring(guid),"forward",...)
    end
end

function FORWARD.lua(who,...)
    channel.publish("guid."..tostring(who),"lua",...)
end

skynet.start(function()
    local handle = skynet.localname ".gate"
    if handle then
        log.error("same cluster launch too many gate service,exit service:%d",gateid)
        skynet.exit()
        return handle
    end

    skynet.dispatch("lua",function(_,_,cmd,...) 
        local f = CMD[cmd]
        if not f then
			log.error("unknow cmd:%s",cmd)
			skynet.retpack(nil)
            return
        end

        skynet.retpack(f(...))
    end)

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
end)