local skynet = require "skynetproto"
local dbopt = require "dbopt"
local msgopt = require "msgopt"
local channel = require "channel"
local bootconf = require "conf.boot"
local log = require "log"
local json = require "json"
require "functions"
local redisopt = require "redisopt"
local enum = require "pb_enums"
local util = require "util"

local reddb = redisopt.default

LOG_NAME = "config"

local globalconf = {}

local services = {}
local clusters = {}
local dbs = {}
local redises = {}

local online_service = {}

local function load_service_cfg()
    local confs = dbopt.config:query("SELECT * FROM t_service_cfg WHERE is_launch != 0;")
    for _,conf in pairs(confs) do
        if conf.conf and type(conf.conf) == "string" and conf.conf ~= "" then
            conf.conf = json.decode(conf.conf)
        end
        if not conf.conf then
            conf.conf = {}
        end
    end

    return confs
end

local function load_cluster_cfg()
    local confs = dbopt.config:query("SELECT * FROM t_cluster_cfg WHERE is_launch != 0;")
    for _,conf in pairs(confs) do
        conf.conf = conf.conf and conf.conf ~= "" and json.decode(conf.conf) or nil
    end

    return confs
end

local function load_redis_cfg()
    local r = dbopt.config:query("SELECT * FROM t_redis_cfg;")
    return r
end

local function load_db_cfg()
    local r = dbopt.config:query("SELECT * FROM t_db_cfg;")
    return r
end

local function load_global()
    local globalcfg = dbopt.config:query("SELECT * FROM t_global_cfg;")
    if #globalcfg == 0 then
        return
    end
    
    globalconf = json.decode(globalcfg[1].value)
end

local MSG = {}

function MSG.global_conf()
    return globalconf
end

function MSG.query_php_sign()
    return globalconf.php_sign_key
end

function MSG.query_service_conf(id)
    if not id then return services end

    return services[id]
end

function MSG.query_cluster_conf(id)
    if not id then return clusters end

    return clusters[id]
end

function MSG.cluster_launch(id)
    if not id then return end

    dbopt.config:query("UPDATE t_server_cfg SET launched = 1 WHERE id = %d;",id)
    channel.publish("*.*","lua","cluster_launch",id)
end

function MSG.cluster_exit(id)
    if not id then return end

    dbopt.config:query("UPDATE t_server_cfg SET launched = 0 WHERE id = %d;",id)
    channel.publish("*.*","lua","cluster_exit",id)
end

function MSG.service_launch(id)
    if not id then return end

    dbopt.config:query("UPDATE t_service_cfg SET launched = 1 WHERE id = %d;",id)
    online_service[id] = true
    channel.publish("*.*","lua","service_launch",id)
end

function MSG.service_exit(id)
    if not id then return end

    dbopt.config:query("UPDATE t_service_cfg SET launched = 0 WHERE id = %d;",id)
    online_service[id] = nil
    channel.publish("*.*","lua","service_exit",id)
end

function MSG.query_database_conf(id)
    log.info("MSG.query_database_conf %s",id)
    if not id then return dbs end

    return dbs[id]
end

function MSG.query_redis_conf(id)
    if not id then return redises end

    return redises[id]
end

function MSG.query_online_game_conf(game_type,room_type)
    local games = {}
    for id,conf in pairs(online_service) do
        if (game_type == nil or  game_type == conf.conf.game_type)
            and (room_type == nil or room_type == conf.conf.room_type) then
            table.insert(games,conf)
        end
    end

    return games
end

function MSG.maintain()
    return util.is_in_maintain()
end

local sconf

local CMD = {}

local function checkconfigdconf(conf)
    assert(conf)
    assert(conf.id)
    assert(conf.type)
    assert(conf.name)
end

function CMD.start(conf)
    checkconfigdconf(conf)
    sconf = conf
end

local function clean_when_start()
    local key_patterns = {"table:player:*","player:table:*","table:info:*","club:table:*","player:online:*","sms:verify_code:*"}
    for _,pattern in pairs(key_patterns) do
		local keys = reddb:keys(pattern)
        for _,key in pairs(keys) do
            log.info("redis del %s",key)
            reddb:del(key)
        end
    end
end

local function setup_default_redis_value()
    local global_conf = globalconf
    local first_guid = global_conf.first_guid or 100001
    reddb:setnx("player:global:guid",math.floor(first_guid))
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

    msgopt.register_handle(MSG)
    skynet.dispatch("msg",function(_,_,cmd,...)
        local msg,sz = skynet.pack(msgopt.on_msg(cmd,...))
        skynet.ret(msg,sz)
	end)

    dbopt.open(bootconf.service.conf.db)

    for _,s in pairs(load_service_cfg()) do
        services[s.id] = s
    end

    for _,c in pairs(load_cluster_cfg()) do
        clusters[c.id] = c
    end

    for _,d in pairs(load_db_cfg()) do
        dbs[d.name] = d
    end

    for _,r in pairs(load_redis_cfg()) do
        redises[r.id] = r
    end

    load_global()

    skynet.timeout(0,function()
        clean_when_start()
        -- setup_default_redis_value()
    end)
end)
