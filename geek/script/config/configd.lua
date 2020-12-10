local skynet = require "skynetproto"
local dbopt = require "dbopt"
local bootconf = require "conf.boot"
local log = require "log"
local json = require "json"
require "functions"
local redisopt = require "redisopt"
local g_common = require "common"
local timer = require "timer"

local cache_elapsed_time = 10

LOG_NAME = "config"

local globalconf = {}

local online_service = {}

local function cache(tb,conf,id)
    id = id or conf.id
    tb[id] = conf
end

local function load_service_cfg(id)
    local sql = "SELECT * FROM t_service_cfg WHERE is_launch != 0"
    if id and id ~= "*" then
        sql = sql .. string.format(" AND id = %s",id)
    end
    local confs = dbopt.config:query(sql)
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

local services = setmetatable({},{
    __index = function(t,id)
        local confs = load_service_cfg(id)
        if not confs or #confs == 0 then
            return
        end

        if not id or id == "*" then
            for _,conf in pairs(confs) do
                cache(t,conf)
            end
            return confs
        end

        cache(t,confs[1],id)
        return confs[1]
    end
})

local function load_cluster_cfg(id)
    local sql = "SELECT * FROM t_cluster_cfg WHERE is_launch != 0"
    if id and id ~= "*" then
        sql = sql .. string.format(" AND id = %s",id)
    end
    local confs = dbopt.config:query(sql)
    for _,conf in pairs(confs) do
        conf.conf = conf.conf and conf.conf ~= "" and json.decode(conf.conf) or nil
    end

    return confs
end

local clusters = setmetatable({},{
    __index = function(t,id)
        local confs = load_cluster_cfg(id)
        if not confs or #confs == 0 then
            return
        end

        if not id or id == "*" then
            for _,conf in pairs(confs) do
                cache(t,conf)
            end
            return confs
        end

        cache(t,confs[1],id)

        return confs[1]
    end
})

local function load_redis_cfg(id)
    local sql = "SELECT * FROM t_redis_cfg"
    if id and id ~= "*" then
        sql = sql .. string.format(" WHERE id = %s",id)
    end
    local r = dbopt.config:query(sql)
    return r
end

local redises = setmetatable({},{
    __index = function(t,id)
        local confs = load_redis_cfg(id)
        if not confs or #confs == 0 then
            return
        end

        if not id or id == "*" then
            for _,conf in pairs(confs) do
                cache(t,conf)
            end
            return confs
        end

        cache(t,confs[1],id)
        return confs[1]
    end
})

local function load_db_cfg(id)
    local sql = "SELECT * FROM t_db_cfg"
    if id and id ~= "*" then
        sql = sql .. string.format(" WHERE id = %s OR name = %s",id,id)
    end

    local r = dbopt.config:query(sql)
    return r
end

local dbs = setmetatable({},{
    __index = function(t,id)
        local confs = load_db_cfg(id)
        if not confs or #confs == 0 then
            return
        end

        if not id or id == "*" then
            for _,conf in pairs(confs) do
                cache(t,conf)
            end
            return confs
        end

        cache(t,confs[1],id)

        return confs[1]
    end
})

local function load_global()
    local globalcfg = dbopt.config:query("SELECT * FROM t_global_cfg WHERE `key` = 'default';")
    if #globalcfg == 0 then
        return
    end
    
    globalconf = json.decode(globalcfg[1].value)
end

local MSG = {}

function MSG.reload_service(id)
    services[id] = nil
end

function MSG.reload_global()
    load_global()
end

function MSG.reload_cluster(id)
    clusters[id] = nil
end

function MSG.reload_redis(id)
    redises[id] = nil
end

function MSG.reload_db(id)
    dbs[id] = nil
end

function MSG.global_conf()
    return globalconf
end

function MSG.query_php_sign()
    return globalconf.php_sign_key
end

function MSG.query_service_conf(id)
    return services[id]
end

function MSG.query_cluster_conf(id)
    return clusters[id]
end

function MSG.query_database_conf(id)
    return dbs[id]
end

function MSG.query_redis_conf(id)
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
    return g_common.is_in_maintain()
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
    local reddb = redisopt.default
    local tables = reddb:smembers("table:all")
    log.dump(tables)
    for id,_ in pairs(tables) do
        log.info("redis clean table session %s",id)
        reddb:del(string.format("table:info:%s",id))
        reddb:del(string.format("table:player:%s",id))
        reddb:srem("table:all",id)
    end

    local onlineguids = reddb:smembers("player:online:all")
    log.dump(onlineguids)
    for guid,_ in pairs(onlineguids) do
        log.info("redis clean guid session %s",guid)
        reddb:del(string.format("player:online:guid:%s",guid))
        reddb:del(string.format("player:table:%s",guid))
        reddb:srem("player:online:all",guid)
    end

    local clubs = reddb:smembers("club:all")
    log.dump(clubs)
    for cid,_ in pairs(clubs) do
        log.info("redis clean club session %s",cid)
        reddb:del(string.format("club:table:%s",cid))
    end

    reddb:del("player:online:all")
    reddb:set("player:online:count",0)
    for sid,sconf in pairs(services) do
        log.info("redis reset online count session %s",sid)
        if sconf.conf.first_game_type then
            reddb:set(string.format("player:online:count:%s",sconf.conf.first_game_type),0)
            reddb:set(string.format("player:online:count:%s:%s",sconf.conf.first_game_type,sconf.conf.second_game_type),0)
        end
    end
end

local function setup_default_redis_value()
    local reddb = redisopt.default
    local global_conf = globalconf
    local first_guid = global_conf.first_guid or 100001
    reddb:setnx("player:global:guid",math.floor(first_guid))
end

local function clean_cache()
    for id,conf in pairs(services) do
        log.info("clean service cache id:%s,name:%s",id,conf.name)
        services[id] = nil
    end

    for id,conf in pairs(clusters) do
        log.info("clean cluster cache id:%s,name:%s",id,conf.name)
        clusters[id] = nil
    end

    for id,conf in pairs(redises) do
        log.info("clean redis cache id:%s,name:%s",id,conf.name)
        redises[id] = nil
    end

    for id,conf in pairs(dbs) do
        log.info("clean db cache id:%s,name:%s",id,conf.name)
        dbs[id] = nil
    end

    timer.timeout(cache_elapsed_time,clean_cache)
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

    skynet.dispatch("msg",function(_,_,cmd,...)
        local f = MSG[cmd]
        if not f then
            log.error("unknow msg:%s",cmd)
            skynet.retpack(nil)
            return
        end

        skynet.retpack(f(...))
	end)

    dbopt.open(bootconf.service.conf.db)

    load_global()

    timer.timeout(0,function()
        clean_when_start()
        -- setup_default_redis_value()
    end)

    timer.timeout(cache_elapsed_time,clean_cache)
end)
