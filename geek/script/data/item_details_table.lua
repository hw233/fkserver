-- 物品表

local enum = require "pb_enums"

local item_details_table = {
	[10010000] = {item_id = 10010000, item_type = enum.ITEM_TYPE_MONEY, name = "金币"},
	[10010001] = {item_id = 10010001, item_type = enum.ITEM_TYPE_BOX, name = "小宝箱", price = {money_type = enum.ITEM_PRICE_TYPE_GOLD, money = 100000}, sub_item = {{item_id = 10010000, item_num = 100000}}},
	[10010002] = {item_id = 10010002, item_type = enum.ITEM_TYPE_BOX, name = "中宝箱", price = {money_type = enum.ITEM_PRICE_TYPE_GOLD, money = 500000}, sub_item = {{item_id = 10010000, item_num = 500000}}},
	[10010003] = {item_id = 10010003, item_type = enum.ITEM_TYPE_BOX, name = "大宝箱", price = {money_type = enum.ITEM_PRICE_TYPE_GOLD, money = 1000000}, sub_item = {{item_id = 10010000, item_num = 1000000}}},
}

return item_details_table