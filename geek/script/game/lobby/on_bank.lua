-- 银行消息处理
local log = require "log"
require "game.net_func"
local send2client_pb = send2client_pb

local player_data = require "game.lobby.player_data"
local enum = require "pb_enums"
local channel = require "channel"

-- 设置银行密码
function on_cs_bank_set_password(msg,guid)
	local player = player_data[guid]
	if player.has_bank_password then
		log.info("guid[%d] password is already set", player.guid)
		send2client_pb(player, "SC_BankSetPassword", {
			result = enum.BANK_OPT_RESULT_PASSWORD_HAS_BEEN_SET,
		})
		return
	end
	
	player.has_bank_password = true

	send2client_pb(player, "SC_BankSetPassword", {
		result = enum.BANK_OPT_RESULT_SUCCESS,
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
	local player = player_data[guid]
	if not player.has_bank_password then
		send2client_pb(player, "SC_ResetBankPW", {
			result = enum.BANK_OPT_RESULT_PASSWORD_IS_NOT_SET,
			guid = player.guid,
		})
		return
	end
	if player.bank_password == msg.bank_password_new then
		send2client_pb(player,"SC_ResetBankPW", {
			guid = player.guid,
			result = enum.BANK_OPT_RESULT_SUCCESS,
		})
		return
	end
	channel.publish("db.?","msg","SD_ResetPW", {
		guid = player.guid,
		bank_password_new = msg.bank_password_new,
	})	
	print ("...................... on_cl_ResetBankPW", player.guid)
end

-- 修改银行密码
function on_cs_bank_change_password(msg,guid)
	local player = player_data[guid]
	if not player.has_bank_password then
		send2client_pb(player, "SC_BankChangePassword", {
			result = enum.BANK_OPT_RESULT_PASSWORD_IS_NOT_SET,
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


-- 登录银行
function on_cs_bank_login(msg,guid)
	local player = player_data[guid]
	if player.bank_login then
		send2client_pb(player, "SC_BankLogin", {
			result = enum.BANK_OPT_RESULT_ALREADY_LOGGED,
		})
		return
	end
	
	channel.publish("db.?","msg","SD_BankLogin", {
		guid = player.guid,
		password = msg.password,
	})
	
	print "...................... on_cs_bank_login"
end

local room_mgr = g_room
-- 存钱
function on_cs_bank_deposit(msg,guid)
	--[[if not player.bank_login then
		send2client_pb(player, "SC_BankDeposit", {
			result = enum.BANK_OPT_RESULT_NOT_LOGIN,
		})
		return
	end]]-- 策划说不需要密码了
	local player = player_data[guid]
	if not player then
		return
	end
	--游戏中，限制该操作
	log.info("player [%s] table_id[%s] room_id[%s]", tostring(player.guid), tostring(player.table_id) , tostring(player.room_id))
	if player.table_id ~= nil or player.room_id ~= nil then
	     log.error("player guid[%d] on_cs_bank_deposit error.",player.guid)
	    send2client_pb(player, "SC_BankDeposit", {
	      result = enum.BANK_OPT_RESULT_FORBID_IN_GAMEING,
	    })
	    return
	  end

	--游戏中，限制该操作
	log.info("player [%s]  is_play [%s]",tostring(player.guid), tostring(room_mgr:is_play(player)))
	if room_mgr:is_play(player) then
		send2client_pb(player, "SC_BankDeposit", {
			result = enum.BANK_OPT_RESULT_FORBID_IN_GAMEING,
		})
		return
	end
	
	local money_ = msg and msg.money or 0
	local money = player.money
	
	if money_ <= 0 or money < money_ then
		send2client_pb(player, "SC_BankDeposit", {
			result = enum.BANK_OPT_RESULT_MONEY_ERR,
		})
		return
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
	--	result = enum.BANK_OPT_RESULT_SUCCESS,
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
end

-- 取钱
function on_cs_bank_draw(msg,guid)
	--[[if not player.bank_login then
		send2client_pb(player, "SC_BankDraw", {
			result = enum.BANK_OPT_RESULT_NOT_LOGIN,
		})
		return
	end]]-- 策划说不需要密码了
	local player = player_data[guid]
	if not player then
		return
	end
	log.info("player [%s] table_id[%s] room_id[%s]", tostring(player.guid), tostring(player.table_id) , tostring(player.room_id))
	--游戏中，限制该操作
	if player.table_id ~= nil or player.room_id ~= nil then
		log.info("===================")
		send2client_pb(player, "SC_BankDeposit", {
			result = enum.BANK_OPT_RESULT_FORBID_IN_GAMEING,
		})
		return
	end
	if player.has_bank_password then
		if not msg.bank_password or msg.bank_password ~= player.bank_password then
			log.info("on_cs_bank_draw player[%s] bankA[%s]",player.guid,msg.bank_password )
			log.info("on_cs_bank_draw player[%s] bankA[%s]",player.guid,player.bank_password )
			send2client_pb(player, "SC_BankDraw", {
				result = enum.BANK_OPT_RESULT_NOT_LOGIN,
			})
			return
		end
	end

	log.info("player [%s]  is_play [%s]",tostring(player.guid), tostring(room_mgr:is_play(player)))
	--游戏中，限制该操作
	if room_mgr:is_play(player) then
		send2client_pb(player, "SC_BankDraw", {
			result = enum.BANK_OPT_RESULT_FORBID_IN_GAMEING,
		})
		return
	end

	local money_ = msg and msg.money or 0
	local bank = player.bank
	if money_ <= 0 or bank < money_ then
		log.info("guid[%d] money[%d] bank[%d]", player.guid, money_, bank)
		send2client_pb(player, "SC_BankDraw", {
			result = enum.BANK_OPT_RESULT_MONEY_ERR,
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
	-- 	result = enum.BANK_OPT_RESULT_SUCCESS,
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
