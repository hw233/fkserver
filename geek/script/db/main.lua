
local skynet = require "skynetproto"
local msgopt = require "msgopt"
local dbopt = require "dbopt"
local channel = require "channel"
local log = require "log"
require "functions"

collectgarbage("setpause", 100)
collectgarbage("setstepmul", 1000)

LOG_NAME = "db"

local sconf
local def_db_id
local serviceid

local CMD = {}

local function checkdbconf(conf)
    assert(conf)
    assert(conf.id)
    assert(conf.name)
    assert(conf.type)
end

function CMD.start(conf)
    checkdbconf(conf)
    sconf = conf
    def_db_id = conf.id
    serviceid = conf.id
    LOG_NAME = string.format("db.%d",conf.id)
end

skynet.start(function()
    -- local dbconf = channel.call("config.?","msg","query_database_conf")
    -- for _,c in pairs(dbconf) do
    --     dbopt.open(c)
    -- end

    skynet.dispatch("lua",function(_,_,cmd,...) 
        local f = CMD[cmd]
        if not f then
            log.error("unknow cmd:%s",cmd)
            skynet.retpack(nil)
            return
        end

        skynet.retpack(f(...))
    end)

    require "db.register"

    skynet.dispatch("msg",function(_,_,cmd,...)
        skynet.retpack(msgopt(cmd,...))
    end)
end)
