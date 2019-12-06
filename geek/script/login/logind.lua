local skynet = require "skynetproto"
local msgopt = require "msgopt"
local log = require "log"
local channel = require "channel"
require "login.msg.runtime"

local MSG = {}

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
    global_conf = channel.call("config.?","msg","global_conf")
    dump(global_conf)
    default_open_id_icon = global_conf.default_open_id_icon
end

skynet.start(function() 
    skynet.dispatch("lua",function(_,_,cmd,...) 
        local f = CMD[cmd]
        if not f then
            log.error("unknow cmd:%s",cmd)
            return
        end

        skynet.retpack(f(...))
    end)

    require "login.register"
    msgopt.register_handle(MSG)
    skynet.dispatch("msg",function(_,_,msgid,...)
        skynet.retpack(msgopt.on_msg(msgid,...))
    end)
end)