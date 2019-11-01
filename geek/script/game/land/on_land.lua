-- 斗地主消息处理

local pb = require "pb_files"
local log = require "log"

require "game.net_func"
local send2client_pb = send2client_pb

require "game.lobby.base_player"


local room = g_room


-- 用户叫分
function on_cs_land_call_score(player, msg)

	local tb = room:find_table_by_player(player)
	if tb then
		tb:call_score(player, msg.call_score - 1)
	else
		log.error("guid[%d] stand up", player.guid)
	end
end

-- 用户加倍
function on_cs_land_call_double(player, msg)
	local tb = room:find_table_by_player(player)
	if tb then
		tb:call_double(player, msg.is_double == 2)
	else
		log.error("guid[%d] call double", player.guid)
	end
end

-- 出牌
function on_cs_land_out_card(player, msg)
	local tb = room:find_table_by_player(player)
	if tb then
		newCards = {}
		if msg ~= nil then
			local i = 0
			for _,card in ipairs(msg.cards) do
				table.insert(newCards, card - 1)
			end
		end
		tb:out_card(player, newCards)
	else
		log.error("guid[%d] stand up", player.guid)
	end
end

-- 放弃出牌
function on_cs_land_pass_card(player, msg)
	local tb = room:find_table_by_player(player)
	if tb then
		tb:pass_card(player)
	else
		log.error("guid[%d] stand up", player.guid)
	end
end

function  on_cs_LandTrusteeship(  player, msg )
	local tb = room:find_table_by_player(player)
	if tb then
		tb:set_trusteeship(player,false)
	else
		log.error("guid[%d] LandTrusteeship", player.guid)
	end
end

function  on_cs_LandLastTrusteeship(  player, msg )
	local tb = room:find_table_by_player(player)
	if tb then
		tb:set_LandLastTrusteeship(player,msg)
	else
		log.error("guid[%d] on_cs_LandLastTrusteeship", player.guid)
	end
end

--

function  on_cs_LandGetCards(  player, msg )
	local tb = room:find_table_by_player(player)
	if tb then
		tb:GetCards(player,msg)
	else
		log.error("guid[%d] on_cs_LandGetCards", player.guid)
	end
end