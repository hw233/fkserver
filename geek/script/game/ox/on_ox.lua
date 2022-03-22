-- 牛牛消息处理

local log = require "log"
local player_context = require "game.lobby.player_context"

-- 用户申请上庄
function on_cs_ox_request_banker(msg,guid)
	log.info("test.................... on_cs_ox_request_banker")
	local player = player_context[guid]
	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:requestbanker(player)
	else
		log.error("guid[%d] stand up11", player.guid)
	end
end

-- 在线用户列表用户申请下庄
function on_cs_ox_unrequest_banker(msg,guid)
	log.info("test.................... on_cs_ox_unrequest_banker")
	local player = player_context[guid]
	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:unrequest_banker(player)
	else
		log.error("guid[%d] stand up11", player.guid)
	end
end

-- 在职当庄庄家申请下庄,打完这一局结算完成后下庄
function on_cs_ox_leave_banker(msg,guid)
	log.info("on_cs_ox_leave_banker %s",guid)
	local player = player_context[guid]
	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:leave_banker(player)
	else
		log.error("guid[%d] stand up22", player.guid)
	end
end

-- 用户叫庄
function on_cs_ox_call_banker(msg,guid)
	log.info ("on_cs_ox_call_banker guid:%s",guid)
	local player = player_context[guid]
	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:call_banker(player, msg)
	else
		log.error("guid[%d] stand up", player.guid)
	end
end

-- 用户加注
function on_cs_ox_bet(msg,guid)
	log.info ("on_cs_ox_add_score guid:%s",guid)
	local player = player_context[guid]
	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:bet(player,msg)
	else
		log.error("guid[%d] stand up", player.guid)
	end
end

function on_cs_ox_split_cards(msg,guid)
	log.info ("on_cs_ox_split_cards guid:%s",guid)
	local player = player_context[guid]
	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:split_cards(player,msg)
	else
		log.error("guid[%d] stand up", player.guid)
	end
end

function on_cs_ox_start_game(_,guid)
	local player = player_context[guid]
	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:owner_start_game(player)
	else
		log.error("guid[%d] on_cs_ox_start_game", guid)
	end
end