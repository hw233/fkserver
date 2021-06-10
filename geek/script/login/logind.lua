local skynet = require "skynetproto"
local msgopt = require "msgopt"
local log = require "log"
local channel = require "channel"
require "login.msg.runtime"

collectgarbage("setpause", 100)
collectgarbage("setstepmul", 1000)

LOG_NAME = "login"

local sconf

local CMD = {}

local function checkloginconf(conf)
    assert(conf)
    assert(conf.id)
    assert(conf.type)
    assert(conf.name)
end

function CMD.start(conf)
    checkloginconf(conf)
    sconf = conf
    LOG_NAME = "login."..conf.id

    global_conf = channel.call("config.?","msg","global_conf")
    log.dump(global_conf)
    default_open_id_icon = global_conf.default_open_id_icon
end

skynet.start(function() 
    skynet.dispatch("lua",function(_,_,cmd,...)
        local f = CMD[cmd]
        if not f then
            log.error("unknow cmd:%s",cmd) 
            skynet.retpack(nil)
            return
        end

        skynet.retpack(f(...))
    end)

    require "login.register"
    skynet.dispatch("msg",function(_,_,msgid,...)
        skynet.retpack(msgopt(msgid,...))
    end)
end)