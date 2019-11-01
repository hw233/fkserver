-- 诈金花消息处理

local pb = require "pb"

require "game.net_func"
local send2client_pb = send2client_pb

require "game.lobby.base_player"


local room = g_room


-- 用户加注
function on_cs_zhajinhua_add_score(player, msg)
	print ("test .................. on_cs_zhajinhua_add_score")

	local tb = room:find_table_by_player(player)
	if tb then
		if tb:is_compare_card() then
			log.error(string.format("is compare card guid[%d]", player.guid))
			return
		end

		if msg.score then
			if tb:check_com_cards(player) == false then
				tb:add_score(player, msg.score)
			end
		else
			log.error(string.format("guid[%d] add score No score", player.guid))
		end
	else
		log.error(string.format("guid[%d] add_score", player.guid))
	end
end

-- 放弃跟注
function on_cs_zhajinhua_give_up(player, msg)
	log.info(string.format("on_cs_zhajinhua_give_up guid[%d]",player.guid))
	
	local tb = room:find_table_by_player(player)
	if tb then
		if tb:is_compare_card() then
			log.error(string.format("is compare card guid[%d]", player.guid))
			return
		end
		tb:give_up(player)
	else
		log.error(string.format("guid[%d] give_up", player.guid))
	end
end

-- 看牌
function on_cs_zhajinhua_look_card(player, msg)
	print ("test .................. on_cs_zhajinhua_look_card")

	local tb = room:find_table_by_player(player)
	if tb then
		if tb:is_compare_card() then
			log.error(string.format("is compare card guid[%d]", player.guid))
			return
		end
		tb:look_card(player)
	else
		log.error(string.format("guid[%d] look_card", player.guid))
	end
end

-- 比牌
function on_cs_zhajinhua_compare_card(player, msg)
	print ("test .................. on_cs_zhajinhua_compare_card")
	
	local tb = room:find_table_by_player(player)
	if tb then
		if tb:is_compare_card() then
			log.error(string.format("is compare card guid[%d]", player.guid))
			return
		end
		if msg.compare_chair_id then
			tb:compare_card(player, msg.compare_chair_id)
		else
			log.error(string.format("guid[%d] compare card  no chair id", player.guid))
		end
	else
		log.error(string.format("guid[%d] compare_card", player.guid))
	end
end

--获取玩家状态
function on_cs_zhajinhua_get_player_status(player, msg)
	print ("test .................. on_cs_zhajinhua_get_player_status")
	
	local tb = room:find_table_by_player(player)
	if tb then
		tb:get_play_Status(player)
	else
		log.error(string.format("guid[%d] get_player_status", player.guid))
	end
end


--获取坐下玩家
function on_cs_zhajinhua_get_sit_down(player, msg)
	print ("test .................. on_cs_zhajinhua_get_sit_down")
	
	local tb = room:find_table_by_player(player)
	if tb then
			tb:get_sit_down(player)
	else
		log.error(string.format("guid[%d] get_sit_down", player.guid))
	end
end


--亮牌玩家申請亮牌
function on_cs_zhajinhua_show_cards(player, msg)
	print ("test .................. on_cs_zhajinhua_show_cards")
	
	local tb = room:find_table_by_player(player)
	if tb then
			tb:show_cards_to_all(player,msg)
	else
		log.error(string.format("guid[%d] on_cs_zhajinhua_show_cards", player.guid))
	end
end

--请求上局结果
function on_CS_ZhaJinHuaLastRecord(player, msg)
	local tb = room:find_table_by_player(player)
	if tb then
			tb:get_last_record(player,msg)
	else
		log.error(string.format("guid[%d] on_CS_ZhaJinHuaEnd", player.guid))
	end
end

--请求奖池金额
function on_CS_ZhaJinHuaBonusPool(player, msg)
	local tb = room:find_table_by_player(player)
	if tb then
		tb:get_total_bonus_pool(player,msg)
	else
		log.error(string.format("guid[%d] on_CS_ZhaJinHuaBonusPool", player.guid))
	end
end