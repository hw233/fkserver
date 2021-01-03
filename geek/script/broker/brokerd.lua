local skynet = require "skynetproto"
local channel = require "channel"
require "functions"
local log = require "log"
local json = require "json"
local util = require "util"

collectgarbage("setpause", 100)
collectgarbage("setstepmul", 1000)

LOG_NAME = "broker"

local sconf
local brokerconf
local brokerid

local global_conf

local function qirui_request_sms(phone,sms)
    local params = {
        dc = 8,
        un = "2294280010",
        pw = "b13f4de0d2ff3687e2fd",
        sm = sms,
        da = phone,
        tf = 3,
        rf = 2,
        rd = 0,
    }

    local status,body = util.http_get("http://api.qirui.com:7891/mt",params)
    log.dump(status)
    log.dump(body)
    if status ~= 200 then 
        return 
    end
    local ok,rep = pcall(json.decode,body)
    if ok and rep.success then 
        return rep.id
    end
    return
end

local function wx_auth(code)
    log.dump(code)
    local conf = global_conf.auth.wx
    local _,authjson = util.http_get(conf.auth_url,{
        appid = conf.appid,
        secret = conf.secret,
        code = code,
        grant_type="authorization_code",
    })
    local ok,auth = pcall(json.decode,authjson)
    if not ok or auth.errcode then
        log.warning("wx_auth get access token failed,errcode:%s,errmsg:%s",auth.errcode,auth.errmsg)
        return tonumber(auth.errcode),auth.errmsg
    end

    local _,userinfojson = util.http_get(conf.userinfo_url,{
        access_token = auth.access_token,
        openid = auth.openid
    })
    local ok,userinfo = pcall(json.decode,userinfojson)
    if not ok or userinfo.errcode then
        log.warning("wx_auth get user info failed,errcode:%s,errmsg:%s",userinfo.errcode,userinfo.errmsg)
        return tonumber(userinfo.errcode),userinfo.errmsg
    end

    log.dump(userinfo)

    return nil,userinfo
end

local MSG = {}

function MSG.SB_PostSms(phone,sms)
    return qirui_request_sms(phone,sms)
end

function MSG.SB_WxAuth(code)
    return wx_auth(code)
end

local CMD = {}

local function checkconf(conf)
    assert(conf)
    assert(conf.id)
    assert(conf.type)
    assert(conf.name)
end

function CMD.start(conf)
    checkconf(conf)
    sconf = conf
    brokerid = conf.id

    LOG_NAME = "broker_" .. brokerid

    if not sconf or sconf.is_launch == 0 or not sconf.conf then
        log.error("launch a unconfig or unlaunch gate service,service:%d.",brokerid)
        return
    end
end

skynet.start(function()
    local handle = skynet.localname ".broker"
    if handle then
        log.error("same cluster launch too many broker service,exit service:%d",brokerid)
        skynet.exit()
        return handle
    end

    global_conf = channel.call("config.?","msg","global_conf")

    skynet.dispatch("lua",function(_,_,cmd,...) 
        local f = CMD[cmd]
        if not f then
			log.error("unknow cmd:%s",cmd)
			skynet.retpack(nil)
            return
        end

        skynet.retpack(f(...))
    end)

    skynet.dispatch("msg",function(_,_,cmd,...)
        local f = MSG[cmd]
        if not f then
			log.error("unknow cmd:%s",cmd)
			skynet.retpack(nil)
            return
        end

        skynet.retpack(f(...))
    end)
end)