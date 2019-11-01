-- 消息处理
local pb = require "pb"

require "game.net_func"
local send2client_pb = send2client_pb

require "game.lobby.base_player"


local room = g_room


--获取坐下玩家
function on_cs_banker_enter(player, msg)
	log.info (".................. on_cs_banker_enter")
	if player and player.guid then
		log.info (string.format(".................. on_cs_banker_enter guid[%d]",player.guid))
		local tb = room:find_table_by_player(player)
		if tb then
			tb:sit_on_chair(player, player.chair_id)
			--tb:player_sit_down(player, player.chair_id)
		else
			log.error(string.format("guid[%d] get_sit_down", player.guid))
		end
	end
end

--重开一局
function on_cs_banker_reEnter(player, msg)
	log.info (".................. on_cs_banker_reEnter")
	if player and player.guid then
		log.info (string.format(".................. on_cs_banker_reEnter guid[%d]",player.guid))
		local tb = room:find_table_by_player(player)
		if tb then
			tb:check_reEnter(player, player.chair_id)
		else
			log.error(string.format("guid[%d] get_sit_down", player.guid))
		end
	end
end

-- 玩家离开游戏
function on_cs_banker_leave(player,msg)
	print("..................on_cs_banker_leave :"..player.guid)
	local tb = room:find_table_by_player(player)
	if tb then
		tb:player_leave(player)
	else
		print(string.format("guid[%d] leave banker game error. :", player.guid))
	end
end


function on_cs_banker_contend(player, msg)
	local tb = room:find_table_by_player(player)

	if msg == false then
		print ("  ||||||  error receive [[false]]  ||||||")
		msg = {}
		msg.ratio = -1
	end

	if next(msg) == nil then
		print ("  ||||||   error receive [[emprty]]    ||||||")
		msg = {}
		msg.ratio = -1
	end
	
	print("receive banker_contend")
	dump(msg)

	if tb then
		local retCode = tb:banker_contend(player, msg.ratio)
	end
end



function on_cs_banker_bet(player, msg)
	local tb = room:find_table_by_player(player)

	if msg == false then
		print ("  ||||||  error receive [[false]]  ||||||")
		msg = {}
		msg.bet_money = -1
	end

	if next(msg) == nil then
		print ("  ||||||   error receive [[emprty]]    ||||||")
		msg = {}
		msg.bet_money = 10
	end
	
	if tb then
		local retCode = tb:banker_bet(player, msg)
	end
end



function on_cs_banker_guess(player)
	local tb = room:find_table_by_player(player)
	print("  ------  receive  CS_BankerPlayerGuessCards   ------")
	if tb then
		local retCode = tb:banker_guess_cards(player)
	end
end

function on_cs_quest_last_record(player)
	local tb = room:find_table_by_player(player)
	print("  ------  receive  CS_BankerLastRecord   ------")
	if tb then
		tb:player_quest_last_record(player)
	else
		print(string.format("guid[%d] on_cs_quest_last_record error. :", player.guid))
	end
end
