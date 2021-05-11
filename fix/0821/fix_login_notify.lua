local string = string
if not string.match(package.path,"%./%?%.lua") then
	package.path = package.path .. ";./?.lua"
end

local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"

local log = require "log"
local onlineguid = require "netguidopt"
local base_players = require "game.lobby.base_players"
local redisopt = require "redisopt"

local reddb = redisopt.default


-- 玩家登录通知 验证账号成功后会收到
local function on_ls_login_notify(guid,reconnect,gate)
	log.info("on_ls_login_notify game_id = %d,guid:%s,reconnect:%s", def_game_id,guid, reconnect)
	onlineguid[guid] = nil

	local p = base_players[guid]
	if not p then
		log.error("on_ls_login_notify game_id = %s,no player,guid:%d",def_game_id,guid)
		return
	end

	local function do_login_notify(player)
		local s = onlineguid[guid]
		log.info("set player.online = true,guid:%d",guid)
		player.online = true

		if gate then
			reddb:hset(string.format("player:online:guid:%d",guid),"gate",gate)
		end

		local repeat_login = s and s.server == def_game_id
		if reconnect or repeat_login then
			-- 重连/重复登陆
			log.info("login step game->LC_Login,guid=%s,game_id:%s,reconnect:%s,repeat:%s", 
				guid,def_game_id,reconnect,repeat_login)
			-- g_room:enter_room(player,true)
			return
		end

		if s and s.server then
			log.error("on_ls_login_notify guid:%s,game_id:%s,server:%s,login but session not nil",
				guid,def_game_id,s.server)
		end
		
		log.info("login step game->LC_Login,account=%s", player.account)
		
		local now = os.time()
		reddb:hset(string.format("player:info:%d",guid),"login_time",now)

		player.login_time = now
		g_room:enter_server(player)
	end

	return p:lockcall(function()
		-- double check
		local pd = base_players[guid]
		if p == pd then
			return do_login_notify(p)
		end

		return pd:lockcall(do_login_notify,pd)
	end)
end

local msgopt = require "msgopt"

msgopt.LS_LoginNotify = on_ls_login_notify