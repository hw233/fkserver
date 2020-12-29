
local skynet = require "skynetproto"
local dbopt = require "dbopt"
local channel = require "channel"
local log = require "log"
require "functions"
local timer = require "timer"

local trigger_interval = 10 * 60

collectgarbage("setpause", 100)
collectgarbage("setstepmul", 5000)

require "hotfix"

LOG_NAME = "statistics"

local sconf
local def_db_id
local serviceid

local setup
local task
local dbconf

local function checkdbconf(conf)
    assert(conf)
    assert(conf.id)
    assert(conf.name)
    assert(conf.type)
end

local CMD = {}

local function trigger()
    task()
    
    -- 保证整点计算
    local time = os.time()
    local next = math.ceil(time / trigger_interval + 0.0000001) * trigger_interval
    timer.timeout(next - time,trigger)
end

function CMD.start(conf)
    checkdbconf(conf)
    sconf = conf
    def_db_id = conf.id
    serviceid = conf.id
    LOG_NAME = "statistics_" .. conf.id

    setup()
    trigger()
end

local player = require "statistics.player"

task = function()
    skynet.fork(function()
        player.task(dbconf)
    end)
end

setup = function()
    player.setup()
end

skynet.start(function()
    local conf = channel.call("config.?","msg","query_database_conf")
    _,dbconf = table.choice(conf)

    skynet.dispatch("lua",function(_,_,cmd,...) 
        local f = CMD[cmd]
        if not f then
            log.error("unknow cmd:%s",cmd)
            skynet.retpack(nil)
            return
        end

        skynet.retpack(f(...))
    end)
end)
