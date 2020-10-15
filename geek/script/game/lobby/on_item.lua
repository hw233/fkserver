-- 物品消息处理
require "data.item_details_table"
require "data.item_market_table"
local item_details_table = item_details_table
local item_market_table = item_market_table

require "game.net_func"
local send2client_pb = send2client_pb

local base_player = require "game.lobby.base_player"
local log = require "log"
local enum = require "pb_enums"


-- 购买物品
function on_cs_buy_item(player, msg)
	if msg.item_num <= 0 then
		log.warning("guid[%d] item num[%d] <= 0", player.guid, msg.item_num)
		send2client_pb(player, "SC_BuyItem", {
			item_id = msg.item_id,
			item_num = msg.item_num,
			result = enum.ITEM_OPERATE_RESULT_NUM_ERR,
		})
		return
	end

	local goods = item_market_table[msg.item_id]
	if not goods then
		log.error("guid[%d] item id[%d] not find in item market table", player.guid, msg.item_id)
		send2client_pb(player, "SC_BuyItem", {
			item_id = msg.item_id,
			item_num = msg.item_num,
			result = enum.ITEM_OPERATE_RESULT_ITEMID_ERR,
		})
		return
	end
	
	if not item_details_table[msg.item_id] then
		log.error("guid[%d] item id[%d] not find in item details table", player.guid, msg.item_id)
		send2client_pb(player, "SC_BuyItem", {
			item_id = msg.item_id,
			item_num = msg.item_num,
			result = enum.ITEM_OPERATE_RESULT_ITEMID_ERR,
		})
		return
	end
	
	if not player:cost_money({{money_type = goods.price.money_type, money = msg.item_num * goods.price.money}}, enum.LOG_MONEY_OPT_TYPE_BUY_ITEM) then
		log.error("guid[%d] item id[%d] money not enough", player.guid, msg.item_id)
		send2client_pb(player, "SC_BuyItem", {
			item_id = msg.item_id,
			item_num = msg.item_num,
			result = enum.ITEM_OPERATE_RESULT_MONEY_NOT_ENOUGH,
		})
		return
	end
	
	player:add_item(msg.item_id, msg.item_num)
	
	send2client_pb(player, "SC_BuyItem", {
		item_id = msg.item_id,
		item_num = msg.item_num,
		result = enum.ITEM_OPERATE_RESULT_SUCCESS,
	})
		
	print ("...................... on_cs_buy_item")
end

-- 删除物品
function on_cs_del_item(player, msg)
	if msg.item_num <= 0 then
		log.warning("guid[%d] item num[%d] <= 0", player.guid, msg.item_num)
		send2client_pb(player, "SC_DelItem", {
			item_id = msg.item_id,
			item_num = msg.item_num,
			result = enum.ITEM_OPERATE_RESULT_NUM_ERR,
		})
		return
	end
	
	if not item_details_table[msg.item_id] then
		log.error("guid[%d] item id[%d] not find in item details table", player.guid, msg.item_id)
		send2client_pb(player, "SC_DelItem", {
			item_id = msg.item_id,
			item_num = msg.item_num,
			result = enum.ITEM_OPERATE_RESULT_ITEMID_ERR,
		})
		return
	end
	
	if not player:del_item(msg.item_id, msg.item_num) then
		send2client_pb(player, "SC_DelItem", {
			item_id = msg.item_id,
			item_num = msg.item_num,
			result = enum.ITEM_OPERATE_RESULT_DEL_FAILED,
		})
	end
	
	send2client_pb(player, "SC_DelItem", {
		item_id = msg.item_id,
		item_num = msg.item_num,
		result = enum.ITEM_OPERATE_RESULT_SUCCESS,
	})
	
	print ("...................... on_cs_del_item")
end

-- 使用物品
function on_cs_use_item(player, msg)
	if msg.item_num <= 0 then
		log.warning("guid[%d] item num[%d] <= 0", player.guid, msg.item_num)
		send2client_pb(player, "SC_UseItem", {
			item_id = msg.item_id,
			item_num = msg.item_num,
			result = enum.ITEM_OPERATE_RESULT_NUM_ERR,
		})
		return
	end
	
	if not item_details_table[msg.item_id] then
		log.error("guid[%d] item id[%d] not find in item details table", player.guid, msg.item_id)
		send2client_pb(player, "SC_UseItem", {
			item_id = msg.item_id,
			item_num = msg.item_num,
			result = enum.ITEM_OPERATE_RESULT_ITEMID_ERR,
		})
		return
	end
	
	if not player:use_item(msg.item_id, msg.item_num) then
		send2client_pb(player, "SC_UseItem", {
			item_id = msg.item_id,
			item_num = msg.item_num,
			result = enum.ITEM_OPERATE_RESULT_USE_FAILED,
		})
	end
	
	send2client_pb(player, "SC_UseItem", {
		item_id = msg.item_id,
		item_num = msg.item_num,
		result = enum.ITEM_OPERATE_RESULT_SUCCESS,
	})
	
	print ("...................... on_cs_use_item")
end

