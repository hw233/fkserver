-- 银行消息处理

local pb = require "pb_files"
local log = require "log"
require "game.net_func"
local send2client_pb = send2client_pb

local base_players = require "game.lobby.base_players"


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


-- 设置银行密码
function on_cs_bank_set_password(msg,guid)
	local player = base_players[guid]
	if player.has_bank_password then
		log.info("guid[%d] password is already set", player.guid)
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
	channel.publish("db.?","msg","SD_BankSetPassword", {
		guid = player.guid,
		password = msg.password,
	})
	
	print ("...................... on_cs_bank_set_password", player.bank_password)
end

-- 重置银行密码
function  on_cl_ResetBankPW( msg,guid)
	local player = base_players[guid]
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
	channel.publish("db.?","msg","SD_ResetPW", {
		guid = player.guid,
		bank_password_new = msg.bank_password_new,
	})	
	print ("...................... on_cl_ResetBankPW", player.guid)
end

function  on_ds_ResetPw( msg )
	local player = base_players[msg.guid]
	if not player then
		log.warning("guid[%d] not find in center", msg.guid)
		return
	end
	-- body
	if msg.bank_password_new == "******" then
		log.info("guid[%d] clear bankpassword success", msg.guid)
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
function on_cs_bank_change_password(msg,guid)
	local player = base_players[guid]
	if not player.has_bank_password then
		send2client_pb(player, "SC_BankChangePassword", {
			result = BANK_OPT_RESULT_PASSWORD_IS_NOT_SET,
		})
		return
	end
	
	channel.publish("db.?","msg","SD_BankChangePassword", {
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
		log.warning("guid[%d] not find in center", msg.guid)
		return
	end
	
	player.bank_password = msg.bank_password

	send2client_pb(player, "SC_BankChangePassword", {
		result = msg.result,
	})
end

-- 登录银行
function on_cs_bank_login(msg,guid)
	local player = base_players[guid]
	if player.bank_login then
		send2client_pb(player, "SC_BankLogin", {
			result = BANK_OPT_RESULT_ALREADY_LOGGED,
		})
		return
	end
	
	channel.publish("db.?","msg","SD_BankLogin", {
		guid = player.guid,
		password = msg.password,
	})
	
	print "...................... on_cs_bank_login"
end

-- 登录银行返回
function on_ds_bank_login(msg)
	local player = base_players[msg.guid]
	if not player then
		log.warning("guid[%d] not find in center", msg.guid)
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
function on_cs_bank_deposit(msg,guid)
	--[[if not player.bank_login then
		send2client_pb(player, "SC_BankDeposit", {
			result = BANK_OPT_RESULT_NOT_LOGIN,
		})
		return
	end]]-- 策划说不需要密码了
	local player = base_players[guid]
	if not player then
		return
	end
	--游戏中，限制该操作
	log.info("player [%s] table_id[%s] room_id[%s]", tostring(player.guid), tostring(player.table_id) , tostring(player.room_id))
	if player.table_id ~= nil or player.room_id ~= nil then
	     log.error("player guid[%d] on_cs_bank_deposit error.",player.guid)
	    send2client_pb(player, "SC_BankDeposit", {
	      result = BANK_OPT_RESULT_FORBID_IN_GAMEING,
	    })
	    return
	  end

	--游戏中，限制该操作
	log.info("player [%s]  is_play [%s]",tostring(player.guid), tostring(room_mgr:is_play(player)))
	if room_mgr:is_play(player) then
		send2client_pb(player, "SC_BankDeposit", {
			result = BANK_OPT_RESULT_FORBID_IN_GAMEING,
		})
		return
	end
	
	local money_ = msg and msg.money or 0
	local money = player.money
	
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
	
	player.money = money - money_
	local bank = player.bank
	player.bank = bank + money_
	player.flag_base_info = true
	

	-- 银行流程修改 不再存储于玩家身上 修改为只保存在数据库中
	log.info("guid[%d] optType[%d] oldmoeny[%d] newmoney[%d] changeMoney[%d] player.money[%d]", player.guid, 2 , money, player.money, money_ ,player.money)
	channel.publish("db.?","msg","SD_ChangeBank",{
			guid = player.guid,
			changemoney = money_,
			oldmoney = money,
			newmoney = player.money,
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
	--channel.publish("db.?","msg","SD_BankLog", {
	--	time = os.time(),
	--	guid = player.guid,
	--	nickname = player.nickname,
	--	phone = player.phone,
	--	opt_type = 0,
	--	money = money_,
	--	old_money = money,
	--	new_money = player.money,
	--	old_bank = bank,
	--	new_bank = player.bank,
	--	ip = player.ip,
	--	gameid = def_game_id,
	--})

	--[[channel.publish("db.?","msg","SD_SaveBankStatement", {
		pb_statement = {
			guid = player.guid,
			time = os.time(),
			opt = BANK_STATEMENT_OPT_TYPE_DEPOSIT,
			money = money_,
			bank_balance = player.bank,
		},
	})]]
end

-- 取钱
function on_cs_bank_draw(msg,guid)
	--[[if not player.bank_login then
		send2client_pb(player, "SC_BankDraw", {
			result = BANK_OPT_RESULT_NOT_LOGIN,
		})
		return
	end]]-- 策划说不需要密码了
	local player = base_players[guid]
	if not player then
		return
	end
	log.info("player [%s] table_id[%s] room_id[%s]", tostring(player.guid), tostring(player.table_id) , tostring(player.room_id))
	--游戏中，限制该操作
	if player.table_id ~= nil or player.room_id ~= nil then
		log.info("===================")
		send2client_pb(player, "SC_BankDeposit", {
			result = BANK_OPT_RESULT_FORBID_IN_GAMEING,
		})
		return
	end
	if player.has_bank_password then
		if not msg.bank_password or msg.bank_password ~= player.bank_password then
			log.info("on_cs_bank_draw player[%s] bankA[%s]",player.guid,msg.bank_password )
			log.info("on_cs_bank_draw player[%s] bankA[%s]",player.guid,player.bank_password )
			send2client_pb(player, "SC_BankDraw", {
				result = BANK_OPT_RESULT_NOT_LOGIN,
			})
			return
		end
	end

	log.info("player [%s]  is_play [%s]",tostring(player.guid), tostring(room_mgr:is_play(player)))
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
	local bank = player.bank
	if money_ <= 0 or bank < money_ then
		log.info("guid[%d] money[%d] bank[%d]", player.guid, money_, bank)
		send2client_pb(player, "SC_BankDraw", {
			result = BANK_OPT_RESULT_MONEY_ERR,
		})
		return
	end


	-- 银行流程修改 不再存储于玩家身上 修改为只保存在数据库中
	log.info("guid[%d] optType[%d] changeMoney[%d] gameid[%d] player.money[%d]", player.guid, 1 , money_ , def_game_id , player.money)
	channel.publish("db.?","msg","SD_ChangeBank",{
			guid = player.guid,
			changemoney = money_,
			optType = 1,
			nickname = player.nickname,
			phone = player.phone,
			ip = player.ip,
		})
	return


	-- 
	-- local money = player.money
	-- player.money = money + money_
	-- player.bank = bank - money_
	-- 
	-- player.flag_base_info = true
	-- 
	-- send2client_pb(player, "SC_BankDraw", {
	-- 	result = BANK_OPT_RESULT_SUCCESS,
	-- 	money = money_,
	-- })
	-- 
	-- -- 日志
	-- channel.publish("db.?","msg","SD_BankLog", {
	-- 	time = os.time(),
	-- 	guid = player.guid,
	-- 	nickname = player.nickname,
	-- 	phone = player.phone,
	-- 	opt_type = 1,
	-- 	money = money_,
	-- 	old_money = money,
	-- 	new_money = player.money,
	-- 	old_bank = bank,
	-- 	new_bank = player.bank,
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
		log.warning("guid[%d] not find in game", msg.guid)
		if (tonumber(msg.optType) == 1  and tonumber(msg.retcode) == 1 ) 			-- 取钱成功 但玩家不在线 则回存
			or (tonumber(msg.optType) == 2 and tonumber(msg.retcode) ~= 1) then		-- 存钱失败 但玩家不在线 则回存
			log.info("guid[%d] optType[%d] changemoney[%d] gameid[%d]", msg.guid, 3, msg.changemoney , def_game_id)
			channel.publish("db.?","msg","SD_ChangeBank",{
				guid = msg.guid,
				changemoney = msg.changemoney,
				optType = 3,
			})
		end
		return
	end
	if tonumber(msg.optType) == 1 then
		if tonumber(msg.retcode) == 1 then
			local oldmoeny_ = player.money
			player.money = oldmoeny_ + msg.changemoney
			-- 更新存储开关
			player.flag_base_info = true
			local newmoney = player.money
			-- 更新玩家自身银行记录
			player.bank = msg.newbankmoney
			log.info("BankDraw Success guid[%d] oldmoeny[%d] newmoney[%d] oldbank[%d] newbank[%d]", player.guid, oldmoeny_, newmoney, msg.oldbankmoeny , player.bank)
			-- 记录日志
			channel.publish("db.?","msg","SD_BankLog_New", {
				guid = player.guid,
				nickname = player.nickname,
				phone = player.phone,
				opt_type = 1,
				money = msg.changemoney,
				old_money = oldmoeny_,
				new_money = player.money,
				old_bank = msg.oldbankmoeny,
				new_bank = player.bank,
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
			local playermoney = player.money
			player.money = playermoney + msg.changemoney
			player.flag_base_info = true
			log.info(" guid [%d] playermoney[%d] updater [%d]", player.guid, playermoney, player.money)
			send2client_pb(player, "SC_BankDeposit", {
				result = BANK_OPT_RESULT_MONEY_ERR,
			})
			return
		end
	end
	print("====================================03")
end
