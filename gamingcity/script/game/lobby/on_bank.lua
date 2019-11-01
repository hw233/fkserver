-- 银行消息处理

local pb = require "pb"

require "game.net_func"
local send2client_pb = send2client_pb
local send2db_pb = send2db_pb

require "game.lobby.base_player"


local get_db_status = get_db_status
-- enum BANK_OPT_RESULT
local BANK_OPT_RESULT_SUCCESS = pb.enum("BANK_OPT_RESULT", "BANK_OPT_RESULT_SUCCESS")
local BANK_OPT_RESULT_PASSWORD_HAS_BEEN_SET = pb.enum("BANK_OPT_RESULT", "BANK_OPT_RESULT_PASSWORD_HAS_BEEN_SET")
local BANK_OPT_RESULT_PASSWORD_IS_NOT_SET = pb.enum("BANK_OPT_RESULT", "BANK_OPT_RESULT_PASSWORD_IS_NOT_SET")
local BANK_OPT_RESULT_OLD_PASSWORD_ERR = pb.enum("BANK_OPT_RESULT", "BANK_OPT_RESULT_OLD_PASSWORD_ERR")
local BANK_OPT_RESULT_ALREADY_LOGGED = pb.enum("BANK_OPT_RESULT", "BANK_OPT_RESULT_ALREADY_LOGGED")
local BANK_OPT_RESULT_LOGIN_FAILED = pb.enum("BANK_OPT_RESULT", "BANK_OPT_RESULT_LOGIN_FAILED")
local BANK_OPT_RESULT_NOT_LOGIN = pb.enum("BANK_OPT_RESULT", "BANK_OPT_RESULT_NOT_LOGIN")
local BANK_OPT_RESULT_MONEY_ERR = pb.enum("BANK_OPT_RESULT", "BANK_OPT_RESULT_MONEY_ERR")
local BANK_OPT_RESULT_TRANSFER_ACCOUNT = pb.enum("BANK_OPT_RESULT", "BANK_OPT_RESULT_TRANSFER_ACCOUNT")
local BANK_OPT_RESULT_BANK_MAINTAIN = pb.enum("BANK_OPT_RESULT", "BANK_OPT_RESULT_BANK_MAINTAIN")


-- enum BANK_STATEMENT_OPT_TYPE
local BANK_STATEMENT_OPT_TYPE_DEPOSIT = pb.enum("BANK_STATEMENT_OPT_TYPE", "BANK_STATEMENT_OPT_TYPE_DEPOSIT")
local BANK_STATEMENT_OPT_TYPE_DRAW = pb.enum("BANK_STATEMENT_OPT_TYPE", "BANK_STATEMENT_OPT_TYPE_DRAW")
local BANK_STATEMENT_OPT_TYPE_TRANSFER_OUT = pb.enum("BANK_STATEMENT_OPT_TYPE", "BANK_STATEMENT_OPT_TYPE_TRANSFER_OUT")
local BANK_STATEMENT_OPT_TYPE_TRANSFER_IN = pb.enum("BANK_STATEMENT_OPT_TYPE", "BANK_STATEMENT_OPT_TYPE_TRANSFER_IN")

local LOG_MONEY_OPT_TYPE_AGENTBANKTOPLAYER_MONEY = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_AGENTBANKTOPLAYER_MONEY")
local LOG_MONEY_OPT_TYPE_BANKTRANSFER = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_BANKTRANSFER")


local def_game_id = def_game_id


-- 设置银行密码
function on_cs_bank_set_password(player, msg)
	if player.has_bank_password then
		log.info(string.format("guid[%d] password is already set", player.guid))
		send2client_pb(player, "SC_BankSetPassword", {
			result = BANK_OPT_RESULT_PASSWORD_HAS_BEEN_SET,
		})
		return
	end
	
	player.has_bank_password = true

	send2client_pb(player, "SC_BankSetPassword", {
		result = BANK_OPT_RESULT_SUCCESS,
	})
	player.bank_password = msg.password
	send2db_pb("SD_BankSetPassword", {
		guid = player.guid,
		password = msg.password,
	})
	
	print ("...................... on_cs_bank_set_password", player.bank_password)
end

-- 重置银行密码
function  on_cl_ResetBankPW( player, msg )
	-- body
	if not player.has_bank_password then
		send2client_pb(player, "SC_ResetBankPW", {
			result = BANK_OPT_RESULT_PASSWORD_IS_NOT_SET,
			guid = player.guid,
		})
		return
	end
	if player.bank_password == msg.bank_password_new then
		send2client_pb(player,"SC_ResetBankPW", {
			guid = player.guid,
			result = BANK_OPT_RESULT_SUCCESS,
		})
		return
	end
	send2db_pb("SD_ResetPW", {
		guid = player.guid,
		bank_password_new = msg.bank_password_new,
	})	
	print ("...................... on_cl_ResetBankPW", player.guid)
end
function  on_ds_ResetPw( msg )
	local player = base_players[msg.guid]
	if not player then
		log.warning(string.format("guid[%d] not find in center", msg.guid))
		return
	end
	-- body
	if msg.bank_password_new == "******" then
		log.info(string.format("guid[%d] clear bankpassword success", msg.guid))
		player.bank_password = nil
		player.has_bank_password = false
	else
		player.bank_password = msg.bank_password_new
	end
	send2client_pb(player,"SC_ResetBankPW", {
		guid = player.guid,
		result = msg.result,
	})
	print ("...................... on_ds_ResetPw", player.guid)
end
-- 修改银行密码
function on_cs_bank_change_password(player, msg)
	if not player.has_bank_password then
		send2client_pb(player, "SC_BankChangePassword", {
			result = BANK_OPT_RESULT_PASSWORD_IS_NOT_SET,
		})
		return
	end
	
	send2db_pb("SD_BankChangePassword", {
		guid = player.guid,
		old_password = msg.old_password,
		password = msg.password,
	})
	
	print ("...................... on_cs_bank_change_password", player.guid)
end

-- 修改银行密码结果
function on_ds_bank_change_password(msg)
	local player = base_players[msg.guid]
	if not player then
		log.warning(string.format("guid[%d] not find in center", msg.guid))
		return
	end
	
	player.bank_password = msg.bank_password

	send2client_pb(player, "SC_BankChangePassword", {
		result = msg.result,
	})
end

-- 登录银行
function on_cs_bank_login(player, msg)
	if player.bank_login then
		send2client_pb(player, "SC_BankLogin", {
			result = BANK_OPT_RESULT_ALREADY_LOGGED,
		})
		return
	end
	
	send2db_pb("SD_BankLogin", {
		guid = player.guid,
		password = msg.password,
	})
	
	print "...................... on_cs_bank_login"
end

-- 登录银行返回
function on_ds_bank_login(msg)
	local player = base_players[msg.guid]
	if not player then
		log.warning(string.format("guid[%d] not find in center", msg.guid))
		return
	end

	if msg.result == BANK_OPT_RESULT_SUCCESS then
		player.bank_login = true
	end

	send2client_pb(player, "SC_BankLogin", {
			result = msg.result,
		})
		
	print ("...................... on_ds_bank_login", msg.guid, msg.result)
end

local room_mgr = g_room
-- 存钱
function on_cs_bank_deposit(player, msg)
	--[[if not player.bank_login then
		send2client_pb(player, "SC_BankDeposit", {
			result = BANK_OPT_RESULT_NOT_LOGIN,
		})
		return
	end]]-- 策划说不需要密码了
	if not player then
		return
	end
	--游戏中，限制该操作
	log.info(string.format("player [%s] table_id[%s] room_id[%s]", tostring(player.guid), tostring(player.table_id) , tostring(player.room_id)))
	if player.table_id ~= nil or player.room_id ~= nil then
	     log.error(string.format("player guid[%d] on_cs_bank_deposit error.",player.guid))
	    send2client_pb(player, "SC_BankDeposit", {
	      result = BANK_OPT_RESULT_FORBID_IN_GAMEING,
	    })
	    return
	  end

	--游戏中，限制该操作
	log.info(string.format("player [%s]  is_play [%s]",tostring(player.guid), tostring(room_mgr:is_play(player))))
	if room_mgr:is_play(player) then
		send2client_pb(player, "SC_BankDeposit", {
			result = BANK_OPT_RESULT_FORBID_IN_GAMEING,
		})
		return
	end
	
	local money_ = msg and msg.money or 0
	local money = player.pb_base_info.money
	
	if money_ <= 0 or money < money_ then
		send2client_pb(player, "SC_BankDeposit", {
			result = BANK_OPT_RESULT_MONEY_ERR,
		})
		return
	end

	if get_db_status() == 0 then
		send2client_pb(player, "SC_BankDeposit", {
			result = BANK_OPT_RESULT_BANK_MAINTAIN,
		})
	end
	
	player.pb_base_info.money = money - money_
	local bank = player.pb_base_info.bank
	player.pb_base_info.bank = bank + money_
	player.flag_base_info = true
	

	-- 银行流程修改 不再存储于玩家身上 修改为只保存在数据库中
	log.info(string.format("guid[%d] optType[%d] oldmoeny[%d] newmoney[%d] changeMoney[%d] player.money[%d]", player.guid, 2 , money, player.pb_base_info.money, money_ ,player.pb_base_info.money))
	send2db_pb("SD_ChangeBank",{
			guid = player.guid,
			changemoney = money_,
			oldmoney = money,
			newmoney = player.pb_base_info.money,
			optType = 2,
			nickname = player.nickname,
			phone = player.phone,
			ip = player.ip,
		})
	--send2client_pb(player, "SC_BankDeposit", {
	--	result = BANK_OPT_RESULT_SUCCESS,
	--	money = money_,
	--})
	--
	---- 日志
	--send2db_pb("SD_BankLog", {
	--	time = get_second_time(),
	--	guid = player.guid,
	--	nickname = player.nickname,
	--	phone = player.phone,
	--	opt_type = 0,
	--	money = money_,
	--	old_money = money,
	--	new_money = player.pb_base_info.money,
	--	old_bank = bank,
	--	new_bank = player.pb_base_info.bank,
	--	ip = player.ip,
	--	gameid = def_game_id,
	--})

	--[[send2db_pb("SD_SaveBankStatement", {
		pb_statement = {
			guid = player.guid,
			time = get_second_time(),
			opt = BANK_STATEMENT_OPT_TYPE_DEPOSIT,
			money = money_,
			bank_balance = player.pb_base_info.bank,
		},
	})]]
end

-- 取钱
function on_cs_bank_draw(player, msg)
	--[[if not player.bank_login then
		send2client_pb(player, "SC_BankDraw", {
			result = BANK_OPT_RESULT_NOT_LOGIN,
		})
		return
	end]]-- 策划说不需要密码了

	if not player then
		return
	end
	log.info(string.format("player [%s] table_id[%s] room_id[%s]", tostring(player.guid), tostring(player.table_id) , tostring(player.room_id)))
	--游戏中，限制该操作
	if player.table_id ~= nil or player.room_id ~= nil then
		log.info(string.format("==================="))
		send2client_pb(player, "SC_BankDeposit", {
			result = BANK_OPT_RESULT_FORBID_IN_GAMEING,
		})
		return
	end
	if player.has_bank_password then
		if not msg.bank_password or msg.bank_password ~= player.bank_password then
			log.info(string.format("on_cs_bank_draw player[%s] bankA[%s]",player.guid,msg.bank_password ))
			log.info(string.format("on_cs_bank_draw player[%s] bankA[%s]",player.guid,player.bank_password ))
			send2client_pb(player, "SC_BankDraw", {
				result = BANK_OPT_RESULT_NOT_LOGIN,
			})
			return
		end
	end

	log.info(string.format("player [%s]  is_play [%s]",tostring(player.guid), tostring(room_mgr:is_play(player))))
	--游戏中，限制该操作
	if room_mgr:is_play(player) then
		send2client_pb(player, "SC_BankDraw", {
			result = BANK_OPT_RESULT_FORBID_IN_GAMEING,
		})
		return
	end
	
	if get_db_status() == 0 then
		send2client_pb(player, "SC_BankDraw", {
			result = BANK_OPT_RESULT_BANK_MAINTAIN,
		})
	end

	local money_ = msg and msg.money or 0
	local bank = player.pb_base_info.bank
	if money_ <= 0 or bank < money_ then
		log.info(string.format("guid[%d] money[%d] bank[%d]", player.guid, money_, bank))
		send2client_pb(player, "SC_BankDraw", {
			result = BANK_OPT_RESULT_MONEY_ERR,
		})
		return
	end


	-- 银行流程修改 不再存储于玩家身上 修改为只保存在数据库中
	log.info(string.format("guid[%d] optType[%d] changeMoney[%d] gameid[%d] player.money[%d]", player.guid, 1 , money_ , def_game_id , player.pb_base_info.money))
	send2db_pb("SD_ChangeBank",{
			guid = player.guid,
			changemoney = money_,
			optType = 1,
			nickname = player.nickname,
			phone = player.phone,
			ip = player.ip,
		})
	return


	-- 
	-- local money = player.pb_base_info.money
	-- player.pb_base_info.money = money + money_
	-- player.pb_base_info.bank = bank - money_
	-- 
	-- player.flag_base_info = true
	-- 
	-- send2client_pb(player, "SC_BankDraw", {
	-- 	result = BANK_OPT_RESULT_SUCCESS,
	-- 	money = money_,
	-- })
	-- 
	-- -- 日志
	-- send2db_pb("SD_BankLog", {
	-- 	time = get_second_time(),
	-- 	guid = player.guid,
	-- 	nickname = player.nickname,
	-- 	phone = player.phone,
	-- 	opt_type = 1,
	-- 	money = money_,
	-- 	old_money = money,
	-- 	new_money = player.pb_base_info.money,
	-- 	old_bank = bank,
	-- 	new_bank = player.pb_base_info.bank,
	-- 	ip = player.ip,
	-- 	gameid = def_game_id,
	-- })
end

function on_ds_changebank(msg)
	-- body
	log.info(string.format("guid = [%d], old_bank = [%s], new_bank = [%s] change_bank = [%s] optType = [%s] retcode[%d]",
						   msg.guid, tostring(msg.oldbankmoeny), tostring(msg.newbankmoney), tostring(msg.changemoney), tostring(msg.optType) ,tostring(msg.retcode)))
	local player = base_players[msg.guid]
	if not player then
		log.warning(string.format("guid[%d] not find in game", msg.guid))
		if (tonumber(msg.optType) == 1  and tonumber(msg.retcode) == 1 ) 			-- 取钱成功 但玩家不在线 则回存
			or (tonumber(msg.optType) == 2 and tonumber(msg.retcode) ~= 1) then		-- 存钱失败 但玩家不在线 则回存
			log.info(string.format("guid[%d] optType[%d] changemoney[%d] gameid[%d]", msg.guid, 3, msg.changemoney , def_game_id))
			send2db_pb("SD_ChangeBank",{
				guid = msg.guid,
				changemoney = msg.changemoney,
				optType = 3,
			})
		end
		return
	end
	if tonumber(msg.optType) == 1 then
		if tonumber(msg.retcode) == 1 then
			local oldmoeny_ = player.pb_base_info.money
			player.pb_base_info.money = oldmoeny_ + msg.changemoney
			-- 更新存储开关
			player.flag_base_info = true
			local newmoney = player.pb_base_info.money
			-- 更新玩家自身银行记录
			player.pb_base_info.bank = msg.newbankmoney
			log.info(string.format("BankDraw Success guid[%d] oldmoeny[%d] newmoney[%d] oldbank[%d] newbank[%d]", player.guid, oldmoeny_, newmoney, msg.oldbankmoeny , player.pb_base_info.bank))
			-- 记录日志
			send2db_pb("SD_BankLog_New", {
				guid = player.guid,
				nickname = player.nickname,
				phone = player.phone,
				opt_type = 1,
				money = msg.changemoney,
				old_money = oldmoeny_,
				new_money = player.pb_base_info.money,
				old_bank = msg.oldbankmoeny,
				new_bank = player.pb_base_info.bank,
				ip = player.ip,
				gameid = def_game_id,
			})
			send2client_pb(player, "SC_BankDraw", {
				result = BANK_OPT_RESULT_SUCCESS,
				money = msg.changemoney,
			})
		else
		 	send2client_pb(player, "SC_BankDraw", {
		 		result = BANK_OPT_RESULT_MONEY_ERR,
		 	})
		end
	elseif tonumber(msg.optType) == 2 then
		if tonumber(msg.retcode) == 1 then
			send2client_pb(player, "SC_BankDeposit", {
				result = BANK_OPT_RESULT_SUCCESS,
				money = msg.changemoney,
			})
			return
		else
			local playermoney = player.pb_base_info.money
			player.pb_base_info.money = playermoney + msg.changemoney
			player.flag_base_info = true
			log.info(string.format(" guid [%d] playermoney[%d] updater [%d]", player.guid, playermoney, player.pb_base_info.money))
			send2client_pb(player, "SC_BankDeposit", {
				result = BANK_OPT_RESULT_MONEY_ERR,
			})
			return
		end
	end
	print("====================================03")
end

-- 转账
function on_cs_bank_transfer(player, msg)
	if msg.account == player.account then
		log.error(string.format("on_cs_bank_transfer guid[%d] target = self", player.guid))
		return
	end

	if not player.enable_transfer then
		log.error(string.format("on_cs_bank_transfer enable_transfer=false guid[%d] target = self", player.guid))
		return
	end
	
	--[[if not player.bank_login then
		send2client_pb(player, "SC_BankTransfer", {
			result = BANK_OPT_RESULT_NOT_LOGIN,
		})
		return
	end]]-- 策划说不需要密码了
	
	local bank = player.pb_base_info.bank
	if msg.money <= 0 or bank < msg.money then
		send2client_pb(player, "SC_BankTransfer", {
			result = BANK_OPT_RESULT_MONEY_ERR,
		})
		return
	end
	
	player.pb_base_info.bank = bank - msg.money
	player.flag_base_info = true
		
	local target = base_player:find_by_account(msg.account)
	if target then -- 在该服务器情况
		target.pb_base_info.bank = target.pb_base_info.bank + msg.money
		target.flag_base_info = true
		
		-- self
		send2client_pb(player, "SC_BankTransfer", {
			result = BANK_OPT_RESULT_SUCCESS,
		})
		--[[local statement_ = {
			guid = player.guid,
			time = get_second_time(),
			opt = BANK_STATEMENT_OPT_TYPE_TRANSFER_OUT,
			target = msg.account,
			money = msg.money,
			bank_balance = player.pb_base_info.bank,
		}
		send2db_pb("SD_SaveBankStatement", {
			pb_statement = statement_,
		})]]
		
		-- target
		send2client_pb(target, "SC_BankTransfer", {
			result = BANK_OPT_RESULT_SUCCESS,
		})
		--[[statement_.guid = target.guid
		statement_.opt = BANK_STATEMENT_OPT_TYPE_TRANSFER_IN
		statement_.target = player.account
		statement_.bank_balance = target.pb_base_info.bank
		send2db_pb("SD_SaveBankStatement", {
			pb_statement = statement_,
		})]]
	else -- 不在该服务器情况
		send2login_pb("SD_BankTransfer", {
			guid = player.guid,
			time = get_second_time(),
			target = msg.account,
			money = msg.money,
			bank_balance = player.pb_base_info.bank,
			selfname = player.account,
			game_id = def_game_id,
		})
	end

	print "...................................on_cs_bank_transfer"
end

function on_ls_bank_transfer_self(msg)
	send2client_pb(msg.guid, "SC_BankTransfer", {
		result = BANK_OPT_RESULT_SUCCESS,
	})
	--[[local statement_ = {
		guid = msg.guid,
		time = msg.time,
		opt = BANK_STATEMENT_OPT_TYPE_TRANSFER_OUT,
		target = msg.target,
		money = msg.money,
		bank_balance = msg.bank_balance.bank,
	}
	send2db_pb("SD_SaveBankStatement", {
		pb_statement = statement_,
	})]]

	print "...................................on_es_bank_transfer_self"
end

function on_ls_bank_transfer_target(msg)
	local target = base_player:find_by_account(msg.target)
	if not target then 
		log.warning(string.format("on_es_bank_transfer_target account[%s] not find in game", msg.target))
		return
	end

	target.pb_base_info.bank = target.pb_base_info.bank + msg.money
	target.flag_base_info = true

	send2client_pb(target, "SC_BankTransfer", {
		result = BANK_OPT_RESULT_SUCCESS,
	})
	--[[local statement_ = {
		guid = target.guid,
		time = msg.time,
		opt = BANK_STATEMENT_OPT_TYPE_TRANSFER_IN,
		target = msg.selfname,
		money = msg.money,
		bank_balance = target.pb_base_info.bank,
	}
	send2db_pb("SD_SaveBankStatement", {
		pb_statement = statement_,
	})]]

	print "...................................on_es_bank_transfer_target"
end

-- 转账回复
function on_ds_bank_transfer(msg)
	if msg.result == BANK_OPT_RESULT_SUCCESS then
		local statement_ = pb.decode(msg.pb_statement[1], msg.pb_statement[2])
		
		send2client_pb(statement_.guid, "SC_BankTransfer", {
			result = BANK_OPT_RESULT_SUCCESS,
		})
		
		--[[send2client_pb(statement_.guid, "SC_NotifyBankStatement", {
			pb_statement = statement_,
		})]]
	else
		local player = base_players[msg.guid]
		if not player then
			log.warning(string.format("on_ds_bank_transfer guid[%d] not find in game", msg.guid))
			return
		end
		
		player.pb_base_info.bank = player.pb_base_info.bank + msg.money
	
		player.flag_base_info = true
		
		send2client_pb(player, "SC_BankTransfer", {
			result = msg.result,
		})
	end

	print "...................................on_ds_bank_transfer"
end

function on_CS_CheckBankTransferEnable(player, msg)
	if msg.guid == player.guid then
		log.error(string.format("on_CS_CheckBankTransferEnable guid[%d] target = self", player.guid))

		send2client_pb(player, "SC_CheckBankTransferEnable", {
			result = 3,
			agent_name = "",
		})
		return
	end

	send2db_pb("SD_CheckBankTransferEnable", {
		pay_guid  = player.guid,
		recv_guid = msg.guid,
	})
end

function on_DS_CheckBankTransferEnable(msg)
	local player = base_players[msg.pay_guid]
	if not player then
		log.error(string.format("on_DS_CheckBankTransferEnable guid[%d] not find in game", msg.pay_guid))
		return
	end

	send2client_pb(player,"SC_CheckBankTransferEnable", {
		result = msg.result,
		agent_name = msg.agent_name
	})	
end

function do_player_transfer(player, msg, remain_money)
	-- body
	log.info(string.format("do_player_transfer  begin----------------- player  guid[%d]  money[%d] ", msg.guid, msg.money ))

	local nmoney = msg.money / 100
	if nmoney < 50 or  nmoney % 50 ~= 0 then
		log.error(string.format("msg.money < 50 or  msg.money % 50 ~= 0  money = [%d]",msg.money))
		send2client_pb(player,"SC_BankTransfer", {result = 7})
		return
	end

	--	remain_money（送的金币）不能提
	if player.pb_base_info.bank + player.pb_base_info.money < msg.money + remain_money then
		send2client_pb(player,"SC_BankTransfer", {result = 2})
		return
	end

	local fmsg = {
		guid = player.guid,
		agent_guid = msg.guid,
		money = msg.money,
		phone = player.phone,
		phone_type = player.phone_type,
		ip = player.ip,
		bag_id = player.channel_id,
		bef_money = player.pb_base_info.money,
		aft_money = player.pb_base_info.money,
		platform_id = player.platform_id,
		seniorpromoter = player.seniorpromoter,
	}

	send2db_pb("SD_PlayerBankTransfer", fmsg)
end

function check_bank_transfer_switch(var_platform,switch_key,func)
	redis_cmd_query(string.format("HGET %s %s",var_platform,switch_key), function (reply)
		if reply:is_string()then	
			local result = false
			local playertoagent_cash_switch_value = tostring(reply:get_string())
			
			if tostring(playertoagent_cash_switch_value) == "true" then
				result = true
			end
			func(result)
		else
			log.error(string.format("hget [%s] [%s]error from redis.",tostring(var_platform),switch_key))
			func(false)
		end
	end)	
end

-- 玩家通过guid转账给代理商
function on_cs_bank_transfer_by_guid(player, msg)
	if not player or msg.guid == player.guid then
		log.error(string.format("on_cs_bank_transfer_by_guid guid[%d] target = self", msg.guid))
		send2client_pb(player,"SC_BankTransfer", {result = 7})
		return
	end

	--数据库出问题了
	if get_db_status() == 0 then
		send2client_pb(player,"SC_BankTransfer", {result = 3})
    	return
 	end

 	local var_platform = "platform_bankerTransfer_"..tostring(player.platform_id)
	local switch_key = "banker_transfer_switch"

 	check_bank_transfer_switch(var_platform,switch_key,function(switch)
 		if switch == false then
			send2client_pb(player,"SC_BankTransfer", {result = 8})
		else
			redis_cmd_query(string.format("GET cash_remain_money"), function (reply)
				if reply:is_string() then
					local remain_money = tonumber(reply:get_string())
					do_player_transfer(player, msg, remain_money)
				else
					log.error(string.format("on_cs_bank_transfer_by_guid player[%d] get cash_remain_money error..............................",player.guid))
					send2client_pb(player,"SC_BankTransfer", {result = 7})
				end
			end)
		end
 	end)

	
end

function on_DS_PlayerBankTransfer(msg)
	log.info (string.format("on_DS_PlayerBankTransfer begin  guid[%d]  ret[%d]", msg.guid, msg.result))
	local player = base_players[msg.guid]	
	if player and  player.pb_base_info  then
		
		--成功
		if msg.result == 1 then
			--只是修改内存的值
			if msg.real_bank_cost > 0 then
				player:change_bank(-msg.real_bank_cost, LOG_MONEY_OPT_TYPE_BANKTRANSFER)
			end

			send2client_pb(player,"SC_BankTransfer", {result = 0, money = msg.money, bank = msg.new_bank})
			return
		end

		--纠正玩家身上的钱
		player.pb_base_info.bank = msg.old_bank
		local bank_change = msg.new_bank - msg.old_bank
		player:change_bank(bank_change, LOG_MONEY_OPT_TYPE_BANKTRANSFER)

		send2client_pb(player,"SC_BankTransfer", {result = msg.result, money = msg.money, bank = msg.new_bank})
	else
		send2db_pb("SD_LogMoney", {
			guid = msg.guid,
			old_money = 0,
			new_money = 0,
			old_bank =  msg.old_bank,
			new_bank =  msg.new_bank,
			opt_type = LOG_MONEY_OPT_TYPE_BANKTRANSFER,
		})
		log.warning(string.format("on_DS_PlayerBankTransfer..............................[%d] no find player", msg.guid))
	end
	
end

function on_ls_bank_transfer_by_guid(msg)
	local player = base_players[msg.guid]
	if not player then 
		log.warning(string.format("on_ls_bank_transfer_by_guid guid[%d] not find in game", msg.guid))
		return
	end

	if msg.money > 0 then
		player.pb_base_info.bank = player.pb_base_info.bank + msg.money
		player.flag_base_info = true
	end

	send2client_pb(player, "SC_BankTransfer", {
		result = BANK_OPT_RESULT_SUCCESS,
		money = msg.money,
		bank = player.pb_base_info.bank,
	})

	print "...................................on_ls_bank_transfer_by_guid"
end

-- 转账回复
function on_ds_bank_transfer_by_guid(msg)
	local player = base_players[msg.guid]
	if not player then
		log.warning(string.format("on_ds_bank_transfer_by_guid guid[%d] not find in game", msg.guid))
		return
	end

	if msg.result == BANK_OPT_RESULT_SUCCESS then
		send2client_pb(player, "SC_BankTransfer", {
			result = BANK_OPT_RESULT_SUCCESS,
			money = -msg.money,
			bank = player.pb_base_info.bank,
		})
	else
		-- 失败恢复钱
		player.pb_base_info.bank = player.pb_base_info.bank + msg.money
		player.flag_base_info = true
		
		send2client_pb(player, "SC_BankTransfer", {
			result = msg.result,
		})
	end

	print "...................................on_ds_bank_transfer"
end

-- 保存流水
function on_ds_save_bank_statement(msg)
	local statement_ = pb.decode(msg.pb_statement[1], msg.pb_statement[2])
	
	--[[send2client_pb(statement_.guid, "SC_NotifyBankStatement", {
		pb_statement = statement_,
	})]]
end


-- 银行流水记录
function on_cs_bank_statement(player, msg)
	if player.b_bank_statement then
		log.warning(string.format("on_cs_bank_statement guid[%d] repeated", player.guid))
		return
	end
	player.b_bank_statement = true
	
	send2db_pb("SD_BankStatement", {
		guid = player.guid,
		cur_serial = (msg and msg.cur_serial or 0),
	})
end

function on_ds_bank_statement(msg)
	local player = base_players[msg.guid]
	if not player then
		log.warning(string.format("on_ds_bank_statement guid[%d] not find in game", msg.guid))
		return
	end
	
	for i, v in ipairs(msg.pb_statement) do
		msg.pb_statement[i] = pb.decode(v[1], v[2])
	end
	
	send2client_pb(player, "SC_BankStatement", {
		pb_statement = msg.pb_statement,
	})
end
