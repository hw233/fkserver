-- 银行消息处理

local pb = require "pb_files"

require "game.net_func"
local send2client_pb = send2client_pb
local send2db_pb = send2db_pb
local send2login_pb = send2login_pb
local base_players = require "game.lobby.base_players"
local log = require "log"
local redisopt = require "redisopt"
local json = require "cjson"
local error = require "gm.errorcode"

local reddb = redisopt.default

local LOG_MONEY_OPT_TYPE_PROXY_CASH_MONEY = pb.enum("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_PROXY_CASH_MONEY")
local LOG_MONEY_OPT_TYPE_CASH_MONEY = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CASH_MONEY")
local LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE")
local LOG_MONEY_OPT_TYPE_RECHARGE_MONEY = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_RECHARGE_MONEY")
local GAME_SERVER_RESULT_MAINTAIN = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_MAINTAIN")
local GMmessageRetCode_ReChargenoPlayer = pb.enum("GMmessageRetCode", "GMmessageRetCode_ReChargenoPlayer")
local GMmessageRetCode_ReChargeError = pb.enum("GMmessageRetCode", "GMmessageRetCode_ReChargeError")
local GMmessageRetCode_Success = pb.enum("GMmessageRetCode", "GMmessageRetCode_Success")

--处理充值 new
function on_gs_recharge(msg)
	-- body
	log.info("on_gs_recharge  begin----------------- guid[%d] type[%d] money[%d] orderid[%d]" , msg.guid,msg.type,msg.money,msg.orderid)
	local notify = {
		guid = msg.guid,
		type = msg.type,
		money = msg.money,
		retid = msg.retid,
		orderid = msg.orderid,
		retcode = GMmessageRetCode_ReChargenoPlayer,
		asyncid = msg.asyncid,
	}
	local player = base_players[msg.guid]
	if player then
		local beforbank = player.bank
		local bRet = player:change_bank(msg.money, msg.type, true)
		if bRet == true then
			log.info("on_gs_recharge success guid[%d] type[%d] money[%d] orderid[%d] beforbank[%d] afterbank[%d]" , msg.guid,msg.type,msg.money,msg.orderid,beforbank,player.bank)
			local notify_T = {
				guid = msg.guid,
				orderid = msg.orderid,
				loginid = msg.loginid,
				retid = msg.retid,
				befor_bank = beforbank,
				after_bank = player.bank
			}
			log.info("on_gs_recharge success guid[%d] type[%d] money[%d] orderid[%d] beforbank[%d] afterbank[%d]" , notify_T.guid,msg.type,msg.money,notify_T.orderid,notify_T.befor_bank,notify_T.after_bank)
			send2db_pb("SD_ReCharge",notify_T)
			return
		else
			retcode = GMmessageRetCode_ReChargeError
		end
	end
	send2loginid_pb(msg.loginid,"GL_ReCharge",notify)
end
--处理充值
function on_changmoney_deal(msg)
	local info = msg.info
	log.info("on_changmoney_deal  begin----------------- player  guid[%d]  money[%g] type[%d] order_id[%d]", info.guid, info.gold, info.type_id, info.order_id)
	local player = base_players[info.guid]
	local nmsg = {
		web_id = msg.web_id,
		login_id = msg.login_id,
		result = 1,
		info = msg.info,
		befor_bank = 0,
		after_bank = 0,
	}
	if player then
		bank_ = player.bank
		local bRet = player:change_bank(info.gold, info.type_id, true)
		if bRet == true then
			nmsg.befor_bank = bank_
			nmsg.after_bank =  player.bank
			send2db_pb("SD_ChangMoneyReply",nmsg)
			log.info "end...................................on_changmoney_deal   A"
			return
		end
		log.info("on_changmoney_deal bRet is" .. bRet);
	else
		log.error("on_changmoney_deal no find player  guid[%d]", info.guid)
		fmsg = {
		web_id =  msg.web_id,
		login_id = msg.login_id,
		info = msg.info,
		}
		send2db_pb("FD_ChangMoneyDeal",nmsg)
		log.info ("end...................................on_changmoney_deal   B")
	end
end

function on_GS_UpdatePlayerBank(msg)
	log.info("on_GS_UpdatePlayerBank  begin----------------- player  guid[%d]  opt_type[%g] old_bank[%d] new_bank[%d]", msg.guid, msg.opt_type, msg.old_bank, msg.new_bank)
	local player = base_players[msg.guid]

	if player then
		--更新玩家银行的钱
		player.bank = msg.old_bank
		local bank_change = msg.new_bank - msg.old_bank

		player:change_bank(bank_change,msg.opt_type)
	else
		send2db_pb("SD_LogMoney", {
			guid = msg.guid,
			old_money = 0,
			new_money = 0,
			old_bank =  msg.old_bank,
			new_bank =  msg.new_bank,
			opt_type =  msg.opt_type,
		})
		log.warning("on_GS_UpdatePlayerBank no find player  guid[%d]", msg.guid)
	end
end

--处理提现回退
function on_cash_false_deal(msg)
	local info = msg.info
	log.info("on_changmoney_deal  begin----------------- player  guid[%d]  money[%g]  order_id[%d]", info.guid, info.coins, info.order_id)
	local player = base_players[info.guid]
	local nmsg = {
		web_id = msg.web_id,
		result = 1,
		server_id = msg.server_id,
		order_id = info.order_id,
		info = msg.info,
	}
	if player then
		local bRet = player:change_bank(info.coins, LOG_MONEY_OPT_TYPE_CASH_MONEY, true)
		if bRet == false then
			nmsg.result = 6
			log.warning("on_cash_false_deal..............................%d add money false player", info.guid)
		end
	else
		nmsg.result = 5
		log.warning("on_cash_false_deal..............................%d no find player", info.guid)
	end
	send2loginid_pb(msg.login_id, "SL_CashReply",nmsg)
	log.info "end...................................on_cash_false_deal"
end


function check_cash_switch(var_platform,switch_key,func)
	redis_cmd_query(string.format("get %s",var_platform), function (reply)
		if type(reply) == "string" then
			local result = false
			local cash_switch_json = tostring(reply)
			log.info(cash_switch_json)
			local  switchforcashvalue = json.decode(cash_switch_json)

			if switchforcashvalue and switchforcashvalue[switch_key] then
				log.info("---------------->cash switch key[%s] value[%s]", tostring(switch_key),tostring(switchforcashvalue[switch_key]))
				result = switchforcashvalue[switch_key]
			end

			--if tostring(playertoagent_cash_switch_value) == "true" then
			--	result = true
			--end
			func(result)
		else
			log.error("hget [%s] [%s]error from redis.",tostring(var_platform),switch_key)
			func(false)
		end
	end)
end


function get_player_platform_cashswitch(player,msg, remain_money)
	if not player then
		return
	end
	if msg.cash_type < 0 or msg.cash_type > 6 then
		log.error("unknown cash type.....................return")
		return
	end
	--1:支付宝兑换 2:银行转账（未用）3:代理转账 4:银行卡转账【线下】 5:未用 6:银联卡转账【线上】
	local cash_switch_type = {"cash_switch","banker_transfer_switch","agent_cash_switch","bank_card_cash_switch","nothing","online_card_cash_switch"}
	--查询当前玩家所属平台的提现开关
	--local cash_platform = "platform_cash_"..tostring(player.platform_id)
	--local cash_key = "cash_switch"

	--if msg.cash_type == 3 then
	--	cash_platform = "platform_PlayerToAgent_cash_"..tostring(player.platform_id)
	--	cash_key = "agent_cash_switch"
	--end

	--if msg.cash_type == 4 then
	--	cash_platform = "platform_bankcardswitch_"..tostring(player.platform_id)
	--	cash_key = "bank_card_cash_switch"
	--end

	local platform_info = "platform_all_cash_"..tostring(player.platform_id)
	local cash_key = cash_switch_type[msg.cash_type]
	log.info("player guid[%d] platform_info [%s] cash type [%s]",player.guid, tostring(platform_info), tostring(cash_key))

	check_cash_switch(platform_info,cash_key,function (switch)
		if switch == false then
			local nmsg = {
				result = GAME_SERVER_RESULT_MAINTAIN,
				bank = player.bank ,
				money = player.money,
			}
			send2client_pb(player,"SC_CashMoneyResult", nmsg)
		else
			do_cs_cash_money_do(player, msg, remain_money)
		end
	end)
end


function do_cs_cash_money_do(player, msg, remain_money)
	-- body
	log.info("on_cs_cash_money  begin----------------- player  guid[%d]  money[%d] seniorpromoter[%d]", player.guid, msg.money ,player.seniorpromoter)
	local nmsg = {
		result = 1,
		bank = player.bank ,
		money = player.money,
	}

	--封号禁提现
	if player.disable == 1 then
		log.error("cash is disable [%d]",player.guid)
		send2client_pb(player,"SC_CashMoneyResult", nmsg)
		return
	end

	--阿里账号错误
	if (player.alipay_account == nil or player.alipay_account == "") and (player.alipay_name == nil or player.alipay_name == "") then
		log.error ("alipay is empty [%d]",player.guid)
		nmsg.result = 9
		send2client_pb(player,"SC_CashMoneyResult", nmsg)
		return
	end
	--银行账号
	if msg.cash_type == 4 then
		log.info("do_cs_cash_money_do bank_card ------- guid[%d] bank_card_num[%s] bank_card_name[%s] bank_name[%s]",player.guid, player.bank_card_num, player.bank_card_name, player.bank_name)
		if (player.bank_card_num == nil or player.bank_card_num == "**") or (player.bank_card_name == nil or player.bank_card_name == "**") or (player.bank_name == nil or player.bank_name == "")then
			log.error ("bank_card is empty [%d]",player.guid)
			nmsg.result = 10
			send2client_pb(player,"SC_CashMoneyResult", nmsg)
			return
		end
	end

	local nmoney = msg.money / 100
	if nmoney < 50 or  nmoney % 50 ~= 0 then
		log.error("msg.money < 50 or  msg.money % 50 ~= 0  money = [%d]",msg.money)
		send2client_pb(player,"SC_CashMoneyResult", nmsg)
		return
	end
	--	remain_money（送的金币）不能提
	if player.bank + player.money < msg.money + remain_money then
		local all_money_t_ = player.bank + player.money
		log.error("msg.money[%d] all_money_t_ [%d]",msg.money,all_money_t_)
		send2client_pb(player,"SC_CashMoneyResult", nmsg)
		return
	end

	local bef_money_ = player.money
	--扣除的金币
	local money_cost = 0
	--扣除的银行金币
	local bank_cost  = msg.money

	if player.bank < msg.money then
		money_cost = msg.money - player.bank
		local bRet = player:change_money(-money_cost, LOG_MONEY_OPT_TYPE_CASH_MONEY, true)
		if bRet == false then
			log.error("on_cs_cash_money player:change_money false")
			send2client_pb(player,"SC_CashMoneyResult", nmsg)
			return
		end

		bank_cost = msg.money - money_cost
	end

	local aft_money_ = player.money

	local fmsg = {
		guid = player.guid,
		money = msg.money,
		cost_money = money_cost,
		cost_bank = bank_cost,
		phone = player.phone,
		phone_type = player.phone_type,
		ip = player.ip,
		bag_id = player.channel_id,
		bef_money = bef_money_,
		aft_money = aft_money_,
		cash_type = msg.cash_type,
		platform_id = player.platform_id,
		seniorpromoter = player.seniorpromoter,
	}

	send2db_pb("SD_WithDrawCash", fmsg)
end

function do_cs_cash_money (player, msg)
	local remain_money = 600

	redis_cmd_query(string.format("GET cash_remain_money"), function (reply)
		if type(reply) == "string" or type(reply) == "number" then
			log.info("do_cs_cash_money is_string..............................")
			remain_money = tonumber(reply)
			log.info("remain_money = [%d]", remain_money)
			get_player_platform_cashswitch(player, msg, remain_money)
		else
			log.error("do_cs_cash_money player[%d] get cash_remain_money error..............................",player.guid)
			if player then
					local nmsg = {
					result = 2,
					bank = player.bank ,
					money = player.money,
				}
				send2client_pb(player,"SC_CashMoneyResult", nmsg)
				return
			end
		end
	end)
end




function on_SD_CheckCashTime(msg)

	local player = base_players[msg.guid]
	if not player then
		log.warning("on_SD_CheckCashTime guid[%d] not find in game", msg.guid)
		return
	end
	if msg.order_id and msg.order_id > 0 then
		local nmsg = {
			result = 10,
			bank = player.bank ,
			money = player.money,
			time = msg.time,
			money_max = msg.money_max,
		}
		send2client_pb(player,"SC_CashMoneyResult", nmsg)
	elseif msg.cash_max_count and msg.cash_max_count == 2 then		
		log.info("on_SD_CheckCashTime guid[%d] msg.cash_max_count[%d]",player.guid,msg.cash_max_count)
		local nmsg = {
			result = 30,
			bank = player.bank ,
			money = player.money,
			time = msg.time,
			money_max = msg.money_max,
		}
		send2client_pb(player,"SC_CashMoneyResult", nmsg)
	else
		if msg.money > msg.money_max then
			local nmsg = {
				result = 20,
				bank = player.bank ,
				money = player.money,
				time = msg.time,
				money_max = msg.money_max,
			}
			send2client_pb(player,"SC_CashMoneyResult", nmsg)
		else
			do_cs_cash_money(player,{money = msg.money,cash_type = msg.cash_type})
		end
	end
end

--用户申请提现
function on_cs_cash_money(player, msg)
	--数据库出问题了
	if get_db_status() == 0 then
		send2client_pb(player,"SC_CashMoneyResult", {
			result = 1,
			bank = player.bank ,
			money = player.money,
		})
    	return
 	 end

	--游戏中，限制该操作
	if player.table_id ~= nil or player.room_id ~= nil then
		log.error("player guid[%d] on_cs_cash_money error.",player.guid)
	    return
	end
	local cash_type_ = 1
	if msg.cash_type then
		cash_type_ = msg.cash_type
	end
	--查询数据库上次提现订单是否在一分钟以内
	send2db_pb("SD_CheckCashTime", {guid=player.guid, money = msg.money, cash_type = cash_type_})
end


--代理把佣金存到银行
function on_cs_proxy_cash_money_to_bank(player, msg)
	dump(msg)
	--数据库出问题了
	if get_db_status() == 0 then
		send2client_pb(player,"SC_ProxyCashMoneyToBankResult", {
			result = 1,
			money = player.money,
		})
    	return
 	 end

	--查询数据库上次提现订单是否在一分钟以内
	send2db_pb("SD_ProxyCashToBank", {guid=player.guid, money = msg.money})
end




--用户查询提现记录
function on_cs_cash_money_type( player, msg )
	local cash_type_ = {1}
	if msg and msg.cash_type then
		cash_type_ = msg.cash_type
	end
	send2db_pb("SD_CashMoneyType", {guid = player.guid,cash_type = cash_type_})
end

--处理服务器返回提现记录
function on_ds_cash_money_type( msg )
	print "...................................on_ds_cash_money_type"
	local player = base_players[msg.guid]
	if player then
		local nmsg = {
		pb_cash_info = msg.pb_cash_info
		}
		send2client_pb(player,"SC_CashMoneyType",nmsg)
	else
		log.warning("on_ds_cash_money_type..............................%d no find player", msg.guid)
	end
	print "...................................on_ds_cash_money_type end"
end


--代理提现数据库返回
function on_ds_proxy_cash_money_to_bank(msg)
	local guid = msg.guid
	local money = msg.money
	local commission = msg.commission
	local result = msg.result
	local commission_max = msg.commission_max

	local player = base_players[guid]
	if not player then
		log.error("proxy player not online but cash money,error,guid:[%d],commssion_remain:[%d]",guid,commission)
		return
	end

	if result == 0 then
		if money > 0 then
			player:changeBankMoney(money, LOG_MONEY_OPT_TYPE_PROXY_CASH_MONEY,true)
		end

		send2client_pb(player,"SC_ProxyCashMoneyToBankResult", {
			result = result,
			guid = guid,
			money = money,
			commission = commission,
			commission_max = commission_max
		})

		return
	end

	send2client_pb(player,"SC_ProxyCashMoneyToBankResult", {
		result = result,
		guid = guid,
		money = money,
		commission = commission,
		commission_max = commission_max
	})
end


function on_DS_WithDrawCash(msg)
	log.info ("on_DS_WithDrawCash begin  guid[%d]  ret[%d]", msg.guid, msg.result)
	local player = base_players[msg.guid]
	if player then

		--提现成功
		if msg.result == 1 then
			--只是修改内存的值
			if msg.real_bank_cost > 0 then
				player:change_bank(-msg.real_bank_cost, LOG_MONEY_OPT_TYPE_CASH_MONEY)
			end

			local nmsg = {
				result = 0,
				bank = player.bank ,
				money = player.money,
			}
			send2client_pb(player,"SC_CashMoneyResult", nmsg)
			return
		end

		--纠正玩家身上的钱
		player.bank = msg.old_bank
		local bank_change = msg.new_bank - msg.old_bank

		player:change_bank(bank_change, LOG_MONEY_OPT_TYPE_CASH_MONEY)

		local nmsg = {
			result = 1,
			bank = player.bank ,
			money = player.money,
		}
		send2client_pb(player,"SC_CashMoneyResult", nmsg)
	else
		send2db_pb("SD_LogMoney", {
			guid = msg.guid,
			old_money = 0,
			new_money = 0,
			old_bank =  msg.old_bank,
			new_bank =  msg.new_bank,
			opt_type = LOG_MONEY_OPT_TYPE_CASH_MONEY,
		})
		log.warning("on_ds_cash_money..............................[%d] no find player", msg.guid)
	end

end


function on_ls_addmoney( msg )
	print "start...................................on_ls_addmoney"
	local player = base_players[msg.guid]
	local bRet = false
	if player then
		bRet = player:change_bank(msg.money, LOG_MONEY_OPT_TYPE_CASH_MONEY)
	end
	if bRet == false then
		print "on_ls_addmoney----------------------false"

		local fmsg =
		{
			guid = msg.guid,
			money = msg.money,
			add_type = msg.add_type,
		}
		send2login_pb("SL_AddMoney",fmsg)
	end
	print "end...................................on_ls_addmoney"

end

function on_s_notify_recharge(msg)
	local guid = tonumber(msg.guid)
	if not guid then
		return {
			errcode = error.DATA_ERROR,
			errstr = string.format("player guid can not be nil.",guid) 
		}
	end

	local player = base_players[guid]
	if not player then
		return {
			errcode = error.DATA_ERROR,
			errstr = string.format("player guid[%d] not exists.",guid)
		}
	end

	local now_count = reddb.hincrby("player:info:"..msg.guid,msg.type == 1 and "diamond" or "room_card",tonumber(msg.number))
	now_count = tonumber(now_count)
	if player.online then
		if msg.type == 1 then player.diamond = now_count
		elseif msg.type == 2 then player.room_card = now_count
		end
	end

	return {
		errcode = error.SUCCESS,
	}
end