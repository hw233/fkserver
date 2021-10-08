local skynet = require "skynetproto"
local log = require "log"
local channel = require "channel"
local base_players  = require "game.lobby.base_players"
require "functions"
local msgopt = require "msgopt"
local redisopt = require "redisopt"
local enum = require "pb_enums"
require "random_mt19937"

local reddb = redisopt.default

collectgarbage("setpause", 100)
collectgarbage("setstepmul", 5000)

LOG_NAME = "game"

def_game_name = nil
def_game_id = nil
global_conf = nil
def_first_game_type = nil
def_second_game_type = nil
g_room = nil

local function checkgameconf(conf)
	assert(conf)
	assert(conf.id)
	assert(conf.name)
	assert(conf.type)
	assert(conf.conf)
	local game_conf = conf.conf
	assert(game_conf.gamename)
	assert(game_conf.first_game_type)
	assert(game_conf.second_game_type)
	assert(game_conf.money_limit)
	assert(game_conf.cell_money)
	assert(game_conf.tax_open)
	assert(game_conf.tax_show)
	assert(game_conf.tax)
end

local function init_server_online_count()
	reddb:zadd(string.format("player:online:count:%d",def_first_game_type),0,def_game_id)
	reddb:zadd(string.format("player:online:count:%d:%d",def_first_game_type,def_second_game_type),0,def_game_id)
end


local CMD = {}

function CMD.start(conf)
	checkgameconf(conf)
	local sconf = conf
	local gameconf = sconf.conf
	def_game_name = gameconf.gamename
	def_game_id = sconf.id
	def_first_game_type = gameconf.first_game_type
	def_second_game_type = gameconf.second_game_type
	global_conf = channel.call("config.?","msg","global_conf")

	LOG_NAME = string.format("%s.%d.%d",def_game_name,def_first_game_type,def_game_id)

	log.info("start game %s.%d.%d",gameconf.gamename,gameconf.first_game_type,gameconf.second_game_type)

	local boot = require("game."..def_game_name..".bootstrap")
	g_room = boot(gameconf)

	require "game.lobby.register"
	require "game.club.register"
	require "game.mail.register"
	require "game.reddot.register"
	require "game.notice.register"
	require "game.lobby.base_android"

	init_server_online_count()
end

function CMD.term()
	log.warning("GAME %s,%d,%d %s TERM",def_game_name,def_first_game_type,def_second_game_type,def_game_id)
	local room = g_room
	local tables = room.tables
	for _,tb in pairs(tables or {}) do
		log.info("GAME TERM DISMISS TABLE %d",tb:id())
		tb:wait_force_dismiss(enum.STANDUP_REASON_ADMIN_DISMISS_FORCE)
	end
	log.warning("GAME %s,%d,%d %s TERM END",def_game_name,def_first_game_type,def_second_game_type,def_game_id)
end

function CMD.afk(guid,offline)
	if not guid then
		return
	end

	local player = base_players[guid]
	if not player then
		return
	end

	log.info("on gate afk,guid:%s,offline:%s",guid,offline)

	return logout(player.guid,offline)
end

function CMD.reloadconf()
	log.info("reloadconf game %s %s ...",def_game_name,def_game_id)

	g_room:reloadconf()
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
        skynet.retpack(msgopt(cmd,...))
	end)
	
    collectgarbage("setpause", 100)
	collectgarbage("setstepmul", 5000)
	
    math.randomseed(tostring(os.time()):reverse():sub(1, 6))
end)