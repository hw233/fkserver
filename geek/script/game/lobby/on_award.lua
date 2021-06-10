-- 领奖消息处理

local pb = require "pb_files"
local log = require "log"
require "data.login_award_table"
require "data.online_award_table"
local base_players = require "game.lobby.base_players"
local login_award_table = login_award_table
local online_award_table = online_award_table

require "game.net_func"
local send2client_pb = send2client_pb
local send2db_pb = send2db_pb

local base_player = require "game.lobby.base_player"


-- enum RECEIVE_REWARD_RESULT
local RECEIVE_REWARD_RESULT_SUCCESS = pb.enum("RECEIVE_REWARD_RESULT", "RECEIVE_REWARD_RESULT_SUCCESS")
local RECEIVE_REWARD_RESULT_ERR_MONEY = pb.enum("RECEIVE_REWARD_RESULT", "RECEIVE_REWARD_RESULT_ERR_MONEY")
local RECEIVE_REWARD_RESULT_ERR_REPEATED = pb.enum("RECEIVE_REWARD_RESULT", "RECEIVE_REWARD_RESULT_ERR_REPEATED")
local RECEIVE_REWARD_RESULT_ERR_FIND_LOGIN_AWARD = pb.enum("RECEIVE_REWARD_RESULT", "RECEIVE_REWARD_RESULT_ERR_FIND_LOGIN_AWARD")
local RECEIVE_REWARD_RESULT_ERR_FIND_ONLINE_AWARD = pb.enum("RECEIVE_REWARD_RESULT", "RECEIVE_REWARD_RESULT_ERR_FIND_ONLINE_AWARD")
local RECEIVE_REWARD_RESULT_ERR_ONLINE_AWARD_CD = pb.enum("RECEIVE_REWARD_RESULT", "RECEIVE_REWARD_RESULT_ERR_ONLINE_AWARD_CD")
local RECEIVE_REWARD_RESULT_ERR_COUNT_LIMIT = pb.enum("RECEIVE_REWARD_RESULT", "RECEIVE_REWARD_RESULT_ERR_COUNT_LIMIT")
local RECEIVE_REWARD_RESULT_ERR_MONEY_LIMIT = pb.enum("RECEIVE_REWARD_RESULT", "RECEIVE_REWARD_RESULT_ERR_MONEY_LIMIT")

-- enum BANK_STATEMENT_OPT_TYPE
local BANK_STATEMENT_OPT_TYPE_REWARD_LOGIN = pb.enum("BANK_STATEMENT_OPT_TYPE", "BANK_STATEMENT_OPT_TYPE_REWARD_LOGIN")
local BANK_STATEMENT_OPT_TYPE_REWARD_ONLINE = pb.enum("BANK_STATEMENT_OPT_TYPE", "BANK_STATEMENT_OPT_TYPE_REWARD_ONLINE")
local BANK_STATEMENT_OPT_TYPE_RELIEF_PAYMENT = pb.enum("BANK_STATEMENT_OPT_TYPE", "BANK_STATEMENT_OPT_TYPE_RELIEF_PAYMENT")
	
-- enum LOG_MONEY_OPT_TYPE
local LOG_MONEY_OPT_TYPE_REWARD_LOGIN = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_REWARD_LOGIN")
local LOG_MONEY_OPT_TYPE_REWARD_ONLINE = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_REWARD_ONLINE")
local LOG_MONEY_OPT_TYPE_RELIEF_PAYMENT = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_RELIEF_PAYMENT")


local relief_payment_money = 2000			-- 救济一次领取多少钱
local relief_payment_money_limit = 1000		-- 救济金要多少钱以下才能领取
local relief_payment_count_limit = 5		-- 一天领取救济金次数限制


-- 登陆奖励
function on_cs_receive_reward_login(msg,guid)
	local player = base_players[guid]
	local days = cur_to_days()
	if player.login_award_receive_day == days then
		send2client_pb(player, "SC_ReceiveRewardLogin", {
			result = RECEIVE_REWARD_RESULT_ERR_REPEATED,
		})
		return
	end
	
	local award = login_award_table[player.login_award_day]
	if not award then
		send2client_pb(player, "SC_ReceiveRewardLogin", {
			result = RECEIVE_REWARD_RESULT_ERR_FIND_LOGIN_AWARD,
		})
		return
	end
	
	if award <= 0 then
		log.warning("award[%d] err", award)
		send2client_pb(player, "SC_ReceiveRewardLogin", {
			result = RECEIVE_REWARD_RESULT_ERR_MONEY,
		})
		return
	end
	
	local oldbank = player.bank
	player.bank = player.bank + award
	player.login_award_receive_day = days
	
	player.flag_base_info = true
	
	send2client_pb(player, "SC_ReceiveRewardLogin", {
		result = RECEIVE_REWARD_RESULT_SUCCESS,
		money = award,
	})
	
	--[[send2db_pb("SD_SaveBankStatement", {
		pb_statement = {
			guid = player.guid,
			time = get_second_time(),
			opt = BANK_STATEMENT_OPT_TYPE_REWARD_LOGIN,
			money = award,
			bank_balance = player.bank,
		},
	})]]
	
	-- 收益
	send2db_pb("SD_UpdateEarnings", {
		guid = player.guid,
		money = award,
	})

	-- log
	send2db_pb("SD_LogMoney", {
		guid = player.guid,
		old_money = player.money,
		new_money = player.money,
		old_bank = oldbank,
		new_bank = player.bank,
		opt_type = LOG_MONEY_OPT_TYPE_REWARD_LOGIN,
	})
end

-- 在线奖励
function on_cs_receive_reward_online(msg,guid)
	local player = base_players[guid]
	local award = online_award_table[player.online_award_num + 1]
	if not award then
		send2client_pb(player, "SC_ReceiveRewardOnline", {
			result = RECEIVE_REWARD_RESULT_ERR_FIND_ONLINE_AWARD,
		})
		return
	end
	
	if award.money <= 0 then
		log.warning("award[%d] err", award.money)
		send2client_pb(player, "SC_ReceiveRewardOnline", {
			result = RECEIVE_REWARD_RESULT_ERR_MONEY,
		})
		return
	end
	
	if player.online_award_time + get_second_time() - player.online_award_start_time < award.cd then
		send2client_pb(player, "SC_ReceiveRewardOnline", {
			result = RECEIVE_REWARD_RESULT_ERR_ONLINE_AWARD_CD,
		})
		return
	end

	local oldbank = player.bank
	player.bank = player.bank + award.money
	player.online_award_time = 0
	player.online_award_num = player.online_award_num + 1
	
	player.flag_base_info = true
	
	player.online_award_start_time = get_second_time()
	
	send2client_pb(player, "SC_ReceiveRewardOnline", {
		result = RECEIVE_REWARD_RESULT_SUCCESS,
		money = award.money,
	})
	
	--[[send2db_pb("SD_SaveBankStatement", {
		pb_statement = {
			guid = player.guid,
			time = get_second_time(),
			opt = BANK_STATEMENT_OPT_TYPE_REWARD_ONLINE,
			money = award.money,
			bank_balance = player.bank,
		},
	})]]
	
	-- 收益
	send2db_pb("SD_UpdateEarnings", {
		guid = player.guid,
		money = award.money,
	})

	-- log
	send2db_pb("SD_LogMoney", {
		guid = player.guid,
		old_money = player.money,
		new_money = player.money,
		old_bank = oldbank,
		new_bank = player.bank,
		opt_type = LOG_MONEY_OPT_TYPE_REWARD_ONLINE,
	})
end

-- 救济金
function on_cs_receive_relief_payment(msg,guid)
	local player = base_players[guid]
	if player.relief_payment_count >= relief_payment_count_limit then
		send2client_pb(player, "SC_ReceiveReliefPayment", {
			result = RECEIVE_REWARD_RESULT_ERR_COUNT_LIMIT,
		})
		return
	end
	
	if player.money +  player.bank >= relief_payment_money_limit then
		send2client_pb(player, "SC_ReceiveReliefPayment", {
			result = RECEIVE_REWARD_RESULT_ERR_MONEY_LIMIT,
		})
		return
	end
	
	local oldbank = player.bank
	player.bank = player.bank + relief_payment_money
	player.relief_payment_count = player.relief_payment_count + 1
	
	player.flag_base_info = true
	
	send2client_pb(player, "SC_ReceiveReliefPayment", {
		result = RECEIVE_REWARD_RESULT_SUCCESS,
		money = relief_payment_money,
	})
	
	--[[send2db_pb("SD_SaveBankStatement", {
		pb_statement = {
			guid = player.guid,
			time = get_second_time(),
			opt = BANK_STATEMENT_OPT_TYPE_RELIEF_PAYMENT,
			money = relief_payment_money,
			bank_balance = player.bank,
		},
	})]]
	
	-- 收益
	send2db_pb("SD_UpdateEarnings", {
		guid = player.guid,
		money = relief_payment_money,
	})

	-- log
	send2db_pb("SD_LogMoney", {
		guid = player.guid,
		old_money = player.money,
		new_money = player.money,
		old_bank = oldbank,
		new_bank = player.bank,
		opt_type = LOG_MONEY_OPT_TYPE_RELIEF_PAYMENT,
	})
end
