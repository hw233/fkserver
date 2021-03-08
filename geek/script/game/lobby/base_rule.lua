
local enum = require "pb_enums"


local base_rule = {}


local pay_option_all = {
	[enum.PAY_OPTION_BOSS] = true,
	[enum.PAY_OPTION_AA] = true,
	[enum.PAY_OPTION_ROOM_OWNER] = true,
}

local money_type_all = {
	[enum.ITEM_PRICE_TYPE_GOLD] = true,
	[enum.ITEM_PRICE_TYPE_ROOM_CARD] = true,
}


function base_rule.check_pay_option(option)
	return option ~= nil and pay_option_all[option]
end

function base_rule.check_money_type(money_type)
	return money_type ~= nil and money_type_all[money_type]
end

function base_rule.chair_count(option)
	local gameconf = g_room.conf
	return gameconf.private_conf.chair_count_option[option]
end

function base_rule.play_round(option)
	local gameconf = g_room.conf
	return gameconf.private_conf.round_count_option[option]
end

function base_rule.check(rule)
	local chair_count = base_rule.chair_count(rule.room.player_count_option + 1)
	if not chair_count then
		return enum.ERROR_PARAMETER_ERROR
	end

	local play_round = base_rule.play_round(rule.round.option + 1)
	if not play_round then
		return enum.ERROR_PARAMETER_ERROR
	end

	local pay_option = rule.pay.option
	if not base_rule.check_pay_option(pay_option) then
		return enum.ERROR_PARAMETER_ERROR
	end

	local money_type = rule.pay.money_type
	if not base_rule.check_money_type(money_type) then
		return enum.ERROR_PARAMETER_ERROR
	end

	return enum.ERROR_NONE,play_round,chair_count,pay_option,money_type
end

return base_rule