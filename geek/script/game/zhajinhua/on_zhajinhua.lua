-- 诈金花消息处理

local log = require "log"
require "game.net_func"

local base_players = require "game.lobby.base_players"

-- 用户加注
function on_cs_zhajinhua_add_score(msg,guid)
	log.info ("test .................. on_cs_zhajinhua_add_score")
	local player = base_players[guid]
	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:lockcall(function() tb:add_score(player, msg) end)
	else
		log.error("guid[%d] add_score", player.guid)
	end
end

function on_cs_zhajinhua_follow_bet(msg,guid)
	log.info("test .................. on_cs_zhajinhua_follow_bet")
	local player = base_players[guid]
	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:lockcall(function() tb:follow(player) end)
	else
		log.error("guid[%d] add_score", player.guid)
	end
end

function on_cs_zhajinhua_all_in(msg,guid)
	log.info ("test .................. on_cs_zhajinhua_all_in")
	local player = base_players[guid]
	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:lockcall(function() tb:all_in(player) end)
	else
		log.error("guid[%d] add_score", player.guid)
	end
end

-- 放弃跟注
function on_cs_zhajinhua_give_up(msg,guid)
	log.info("on_cs_zhajinhua_give_up guid[%d]",guid)
	local player = base_players[guid]
	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:lockcall(function() tb:give_up(player) end)
	else
		log.error("guid[%d] give_up", player.guid)
	end
end

-- 看牌
function on_cs_zhajinhua_look_card(msg,guid)
	log.info ("test .................. on_cs_zhajinhua_look_card")
	local player = base_players[guid]
	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:lockcall(function() tb:look_card(player) end)
	else
		log.error("guid[%d] look_card", player.guid)
	end
end

-- 比牌
function on_cs_zhajinhua_compare_card(msg,guid)
	log.info ("test .................. on_cs_zhajinhua_compare_card")
	local player = base_players[guid]
	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:lockcall(function() tb:compare(player, msg) end)
	else
		log.error("guid[%d] compare_card", player.guid)
	end
end

--亮牌玩家申請亮牌
function on_cs_zhajinhua_show_cards(msg,guid)
	log.info ("test .................. on_cs_zhajinhua_show_cards")
	local player = base_players[guid]
	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:lockcall(function() tb:show_cards_to_all(player,msg) end)
	else
		log.error("guid[%d] on_cs_zhajinhua_show_cards", player.guid)
	end
end

--请求上局结果
function on_CS_ZhaJinHuaLastRecord(msg,guid)
	local player = base_players[guid]
	local tb = g_room:find_table_by_player(player)
	if tb then
		tb:lockcall(function() tb:get_last_record(player,msg) end)
	else
		log.error("guid[%d] on_CS_ZhaJinHuaEnd", player.guid)
	end
end