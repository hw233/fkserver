-- 诈金花消息处理
local log = require "log"
require "game.net_func"
local send2client_pb = send2client_pb

local base_players = require "game.lobby.base_players"

function on_cs_act_win(msg,guid)
	log.info ("test .................. on_cs_act_win")
	local player = base_players[guid]
	if not player then
		log.error("on_cs_act_win no player,guid:%s",guid)
		return
	end
	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:on_cs_act_win(player, msg)
	end
end

function on_cs_act_double(msg,guid)
	log.info ("test .................. on_cs_act_double")
	local player = base_players[guid]
	if not player then
		log.error("on_cs_act_win no player,guid:%s",guid)
		return
	end
	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:on_cs_act_double(player, msg)
	end
end

function on_cs_act_discard(msg,guid)
	log.info ("test .................. on_cs_act_discard")
	local player = base_players[guid]
	if not player then
		log.error("on_cs_act_win no player,guid:%s",guid)
		return
	end

	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:on_cs_act_discard(player, msg)
	end
end

function on_cs_act_peng(msg,guid)
	log.info ("test .................. on_cs_act_peng")
	local player = base_players[guid]
	if not player then
		log.error("on_cs_act_win no player,guid:%s",guid)
		return
	end

	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:on_cs_act_peng(player, msg)
	end
end

function on_cs_act_gang(msg,guid)
	log.info ("test .................. on_cs_act_gang")
	local player = base_players[guid]
	if not player then
		log.error("on_cs_act_win no player,guid:%s",guid)
		return
	end

	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:on_cs_act_gang(player, msg)
	end
end

function on_cs_act_pass(msg,guid)
	log.info ("test .................. on_cs_act_pass")
	local player = base_players[guid]
	if not player then
		log.error("on_cs_act_win no player,guid:%s",guid)
		return
	end

	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:on_cs_act_pass(player, msg)
	end
end

function on_cs_act_chi(msg,guid)
	log.info ("test .................. on_cs_act_chi")
	local player = base_players[guid]
	if not player then
		log.error("on_cs_act_win no player,guid:%s",guid)
		return
	end

	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:on_cs_act_chi(player, msg)
	end
end

function on_cs_act_trustee(msg,guid)
	log.info ("test .................. on_cs_act_trustee")
	local player = base_players[guid]
	if not player then
		log.error("on_cs_act_win no player,guid:%s",guid)
		return
	end

	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:on_cs_act_trustee(player, msg)
	end
end

function on_cs_act_baoting(msg,guid)
	log.info ("test .................. on_cs_act_baoting")
	local player = base_players[guid]
	if not player then
		log.error("on_cs_act_win no player,guid:%s",guid)
		return
	end

	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:on_cs_act_baoting(player, msg)
	end
end