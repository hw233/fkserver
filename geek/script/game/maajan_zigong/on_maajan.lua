-- 诈金花消息处理
local log = require "log"
local enum = require "pb_enums"

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
		tb:on_cs_act_win(player, msg)
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
		tb:on_cs_act_double(player, msg)
	end
end

function on_cs_act_discard(msg,guid)
	log.info ("test .................. on_cs_act_discard %s",guid)
	log.dump(msg,string.format("on_cs_act_discard_%s",guid))
	local player = player_context[guid]
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
	local player = player_context[guid]
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
	local player = player_context[guid]
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
	log.info ("test .................. on_cs_act_pass %s",guid)
	local player = player_context[guid]
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
	local player = player_context[guid]
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
	log.info ("test .................. on_cs_act_trustee,guid:%s",guid)
	log.dump(msg,string.format("on_cs_act_trustee_%s",guid))
	local player = player_context[guid]
	if not player then
		log.error("on_cs_act_win no player,guid:%s",guid)
		return
	end

	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:on_cs_act_trustee(player, msg)
	end
end

function on_cs_do_action(msg,guid)
	log.info ("test .................. on_cs_do_action,guid:%s",guid)
	log.dump(msg,string.format("on_cs_do_action_%s",guid))
	local player = player_context[guid]
	if not player then
		log.error("on_cs_act_win no player,guid:%s",guid)
		return
	end

	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:on_cs_do_action(player, msg)
	end
end

-- function on_cs_huan_pai(msg,guid)
-- 	log.info ("test .................. on_cs_huan_pai,guid:%s",guid)
-- 	log.dump(msg,string.format("on_cs_huan_pai_%s",guid))
-- 	local player = player_context[guid]
-- 	if not player then
-- 		log.error("on_cs_huan_pai no player,guid:%s",guid)
-- 		return
-- 	end

-- 	local tb = g_room:find_table_by_player(player)
-- 	if tb then
-- 		tb:on_cs_huan_pai(player, msg)
-- 	end
-- end

function on_cs_piao_fen(msg,guid)
	log.info ("test .................. on_cs_piao_fen,guid:%s",guid)
	log.dump(msg,string.format("on_cs_piao_fen_%s",guid))
	local player = player_context[guid]
	if not player then
		log.error("on_cs_piao_fen no player,guid:%s",guid)
		return
	end

	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:on_cs_piao_fen(player, msg)
	end
end

function on_cs_piao_fen(msg,guid)
	log.info ("test .................. on_cs_piao_fen,guid:%s",guid)
	log.dump(msg,string.format("on_cs_piao_fen_%s",guid))
	local player = player_context[guid]
	if not player then
		log.error("on_cs_piao_fen no player,guid:%s",guid)
		return
	end

	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:on_cs_piao_fen(player, msg)
	end
end

function on_cs_bao_ting(msg,guid)
	log.info ("test .................. on_cs_bao_ting,guid:%s",guid)
	log.dump(msg,string.format("on_cs_bao_ting%s",guid))
	local player = player_context[guid]
	if not player then
		log.error("on_cs_bao_ting no player,guid:%s",guid)
		return
	end

	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:on_cs_bao_ting(player, msg)
	end
end

function on_cs_vote_table_req(msg,guid)
	log.info ("test .................. on_cs_vote_table_req,guid:%s",guid)
	local player = player_context[guid]
	if not player then
		log.error("on_cs_vote_table_req no player,guid:%s",guid)
		return
	end

	local tb = g_room:find_table_by_player(player)
	if tb then
		if msg.vote_type == "FAST_START" then
			tb:fast_start_vote_req(player, msg)
		else
			send2client_pb("SC_VoteTableReq",{
				result = enum.ERROR_PARAMETER_ERROR
			})
		end
	end
end

function on_cs_vote_table_commit(msg,guid)
	log.info ("test .................. on_cs_vote_table_commit,guid:%s",guid)
	local player = player_context[guid]
	if not player then
		log.error("on_cs_vote_table_commit no player,guid:%s",guid)
		return
	end

	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:fast_start_vote_commit(player, msg)
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
		tb:get_ting_tiles_info(player, msg)
	end

end