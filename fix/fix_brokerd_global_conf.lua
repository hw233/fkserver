local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"
--require "functions"
local log = require "log"
local json = require "json"
local util = require "util"
local channel = require "channel"
G_global_conf = channel.call("config.?","msg","global_conf")

dump(print,G_global_conf)
local function wx_auth(code)
    log.dump(code)
    local conf = G_global_conf.auth.wx
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

local function package_wx_auth(code,package)
    log.dump(code)
    local conf = G_global_conf.package_auth.wx
    local auth_url = assert(conf.auth_url)
    local userinfo_url = assert(conf.userinfo_url)
    local appconf = conf.package and conf.package[package] or nil
    assert(appconf)

    local _,authjson = util.http_get(auth_url,{
        appid = appconf.appid,
        secret = appconf.secret,
        code = code,
        grant_type="authorization_code",
    })
    
    local ok,auth = pcall(json.decode,authjson)
    if not ok or auth.errcode then
        log.warning("wx_auth get access token failed,errcode:%s,errmsg:%s",auth.errcode,auth.errmsg)
        return tonumber(auth.errcode),auth.errmsg
    end

    local _,userinfojson = util.http_get(userinfo_url,{
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

local MSG = _P.msg.MSG

dump(print,MSG)
function MSG.SB_WxAuth(code)
    return wx_auth(code)
end

function MSG.SB_PackageWxAuth(code,package)
    return package_wx_auth(code,package)
end

dump(print,MSG)





