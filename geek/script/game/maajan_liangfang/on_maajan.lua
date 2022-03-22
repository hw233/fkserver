-- 诈金花消息处理
local log = require "log"
require "game.net_func"
local send2client_pb = send2client_pb

local player_context = require "game.lobby.player_context"

function on_cs_act_win(msg,guid)
	log.info ("test .................. on_cs_act_win")
	local player = player_context[guid]
	if not player then
		log.error("on_cs_act_win no player,guid:%s",guid)
		return
	end
	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:lockcall(function() tb:on_cs_act_win(player, msg) end)
	end
end

function on_cs_act_double(msg,guid)
	log.info ("test .................. on_cs_act_double")
	local player = player_context[guid]
	if not player then
		log.error("on_cs_act_win no player,guid:%s",guid)
		return
	end
	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:lockcall(function() tb:on_cs_act_double(player, msg) end)
	end
end

function on_cs_act_discard(msg,guid)
	log.info ("test .................. on_cs_act_discard")
	local player = player_context[guid]
	if not player then
		log.error("on_cs_act_win no player,guid:%s",guid)
		return
	end

	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:lockcall(function() tb:on_cs_act_discard(player, msg) end)
	end
end

function on_cs_act_peng(msg,guid)
	log.info ("test .................. on_cs_act_peng")
	local player = player_context[guid]
	if not player then
		log.error("on_cs_act_win no player,guid:%s",guid)
		return
	end

	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:lockcall(function() tb:on_cs_act_peng(player, msg) end)
	end
end

function on_cs_act_gang(msg,guid)
	log.info ("test .................. on_cs_act_gang")
	local player = player_context[guid]
	if not player then
		log.error("on_cs_act_win no player,guid:%s",guid)
		return
	end

	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:lockcall(function() tb:on_cs_act_gang(player, msg) end)
	end
end

function on_cs_act_pass(msg,guid)
	log.info ("test .................. on_cs_act_pass")
	local player = player_context[guid]
	if not player then
		log.error("on_cs_act_win no player,guid:%s",guid)
		return
	end

	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:lockcall(function() tb:on_cs_act_pass(player, msg) end)
	end
end

function on_cs_act_chi(msg,guid)
	log.info ("test .................. on_cs_act_chi")
	local player = player_context[guid]
	if not player then
		log.error("on_cs_act_win no player,guid:%s",guid)
		return
	end

	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:lockcall(function() tb:on_cs_act_chi(player, msg) end)
	end
end

function on_cs_act_trustee(msg,guid)
	log.info ("test .................. on_cs_act_trustee")
	local player = player_context[guid]
	if not player then
		log.error("on_cs_act_win no player,guid:%s",guid)
		return
	end

	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:lockcall(function() tb:on_cs_act_trustee(player, msg) end)
	end
end

function on_cs_act_baoting(msg,guid)
	log.info ("test .................. on_cs_act_baoting")
	local player = player_context[guid]
	if not player then
		log.error("on_cs_act_win no player,guid:%s",guid)
		return
	end

	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:lockcall(function() tb:on_cs_act_baoting(player, msg) end)
	end
end

function on_cs_do_action(msg,guid)
	log.info ("test .................. on_cs_do_action,guid:%s",guid)
	local player = player_context[guid]
	if not player then
		log.error("on_cs_act_win no player,guid:%s",guid)
		return
	end

	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:lockcall(function() tb:on_cs_do_action(player, msg) end)
	end
end

function on_cs_get_ting_tiles_info(msg,guid)
	log.info ("test .................. on_cs_get_ting_tiles_info,guid:%s",guid)
	local player = player_context[guid]
	if not player then
		log.error("on_cs_get_ting_tiles_info no player,guid:%s",guid)
		return
	end

	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:lockcall(function() tb:on_cs_get_ting_tiles_info(player, msg) end)
	end
end