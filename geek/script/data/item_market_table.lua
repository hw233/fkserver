-- 商城表

local enum = require "pb_enums"

local item_market_table = {
	[10010001] = {item_id = 10010001, price = {money_type = enum.ITEM_PRICE_TYPE_GOLD, money = 100000}},
	[10010002] = {item_id = 10010002, price = {money_type = enum.ITEM_PRICE_TYPE_GOLD, money = 500000}},
	[10010003] = {item_id = 10010003, price = {money_type = enum.ITEM_PRICE_TYPE_GOLD, money = 1000000}},
}


return item_market_table