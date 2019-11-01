-- 斗地主消息处理

local pb = require "pb_files"

require "game.net_func"
local send2client_pb = send2client_pb

require "game.lobby.base_player"


local room = g_room
local def_second_game_type = def_second_game_type


-- 出牌
function on_cs_bigtwo_out_card(player, msg)
	if player and player.chair_id then
		print ("test .................. on_cs_bt_out_card:"..player.chair_id)
	end
	local tb = room:find_table_by_player(player)
	if tb then
		--[[newCards = {}
		print(string.format("on_cs_bigtwo_out_card card_count[%d],cards[%s]",#msg.cards , table.concat(msg.cards, ", ")))
		if msg ~= nil then
			local i = 0
			for _,card in ipairs(msg.cards) do
				table.insert(newCards, card - 1)
			end
		end		
		print(string.format("on_cs_bigtwo_out_card newCards_count[%d],newCards[%s]",#newCards , table.concat(newCards, ", ")))
		tb:out_card(player, newCards)--]]
		tb:out_card(player, msg.cards)
		tb:operation(player)
	else
		log.error("guid[%d] stand up", player.guid)
	end
end

-- 放弃出牌
function on_cs_bigtwo_pass_card(player, msg)
	print ("test .................. on_cs_bt_pass_card")

	local tb = room:find_table_by_player(player)
	if tb then
		tb:pass_card(player)
		tb:operation(player)
	else
		log.error("guid[%d] stand up", player.guid)
	end
end

function  on_cs_bigtwo_Trusteeship(  player, msg )
	-- body
	print("=============on_cs_btTrusteeship================")
	local tb = room:find_table_by_player(player)
	if (tb and def_second_game_type ~= 99 ) or (tb and  player.isTrusteeship == true) then
		tb:set_trusteeship(player,false)
		tb:operation(player)
	else
		log.error("guid[%d] btTrusteeship", player.guid)
	end
end
