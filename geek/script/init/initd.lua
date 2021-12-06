local skynet = require "skynetproto"
local log = require "log"
local json = require "json"
require "functions"
local redisopt = require "redisopt"
local channel = require "channel"
local reddb = redisopt.default
local queue = require "skynet.queue"

LOG_NAME = "init"

local checkqueue = queue()

local function init_games()
    local first_game_types = reddb:smembers("game:all")
    for first in pairs(first_game_types) do
        local seconds = reddb:smembers(string.format("game:level:%d",first))
        for second in pairs(seconds) do
            reddb:del(string.format("player_online:count:%d",first))
            reddb:del(string.format("player_online:count:%d:%d",first,second))
        end
        reddb:del(string.format("game:level:%d",first))
    end
    reddb:del("game:all")
    
end 

local function init_club()
    local clubs = reddb:smembers("club:all")
    for cid,_ in pairs(clubs) do
        reddb:del(string.format("club:table:%s",cid))
        reddb:del(string.format("club:member:online:guid:%s",cid))
        reddb:del(string.format("club:member:online:count:%s",cid))
    end
end

local function init_tables()
    local tables = reddb:smembers("table:all")
    for id,_ in pairs(tables) do
        reddb:del(string.format("table:info:%s",id))
        reddb:del(string.format("table:player:%s",id))
        reddb:srem("table:all",id)
    end
end

local function init_online()
    local onlineguids = reddb:smembers("player:online:all")
    for guid,_ in pairs(onlineguids) do
        reddb:del(string.format("player:online:guid:%s",guid))
        reddb:del(string.format("player:table:%s",guid))
        reddb:srem("player:online:all",guid)
    end

    reddb:del("player:online:all")
    reddb:set("player:online:count",0)
end

local function init()
    init_online()
    init_tables()
    init_club()
    init_games()
end

local CMD = {}

local function checkinitconf(conf)
    assert(conf)
    assert(conf.id)
    assert(conf.name)
    assert(conf.type)
end

function CMD.start(conf)
    checkinitconf(conf)
    LOG_NAME = string.format("init.%d",conf.id)
end

function CMD.initd()
    return checkqueue(function() return 0 end)
end

skynet.start(function()
    skynet.fork(checkqueue,init)
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
