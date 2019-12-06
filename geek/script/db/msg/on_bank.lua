-- 银行消息处理

local pb = require "pb_files"

require "db.net_func"
local send2game_pb = send2game_pb
local send2login_pb = send2login_pb

local dbopt = require "dbopt"
local redisopt = require "redisopt"
local httpc = require "http.httpc"
local httpurl = require "http.url"
local md5 = require "md5"
local log = require "log"
local enum = require "pb_enums"

local reddb = redisopt.default


local BANK_OPT_RESULT_SUCCESS = pb.enum("BANK_OPT_RESULT", "BANK_OPT_RESULT_SUCCESS")
local BANK_OPT_RESULT_PASSWORD_HAS_BEEN_SET = pb.enum("BANK_OPT_RESULT", "BANK_OPT_RESULT_PASSWORD_HAS_BEEN_SET")
local BANK_OPT_RESULT_PASSWORD_IS_NOT_SET = pb.enum("BANK_OPT_RESULT", "BANK_OPT_RESULT_PASSWORD_IS_NOT_SET")
local BANK_OPT_RESULT_OLD_PASSWORD_ERR = pb.enum("BANK_OPT_RESULT", "BANK_OPT_RESULT_OLD_PASSWORD_ERR")
local BANK_OPT_RESULT_ALREADY_LOGGED = pb.enum("BANK_OPT_RESULT", "BANK_OPT_RESULT_ALREADY_LOGGED")
local BANK_OPT_RESULT_LOGIN_FAILED = pb.enum("BANK_OPT_RESULT", "BANK_OPT_RESULT_LOGIN_FAILED")
local BANK_OPT_RESULT_NOT_LOGIN = pb.enum("BANK_OPT_RESULT", "BANK_OPT_RESULT_NOT_LOGIN")
local BANK_OPT_RESULT_MONEY_ERR = pb.enum("BANK_OPT_RESULT", "BANK_OPT_RESULT_MONEY_ERR")
local BANK_OPT_RESULT_TRANSFER_ACCOUNT = pb.enum("BANK_OPT_RESULT", "BANK_OPT_RESULT_TRANSFER_ACCOUNT")
local BANK_OPT_RESULT_FORBID_IN_GAMEING = pb.enum("BANK_OPT_RESULT", "BANK_OPT_RESULT_FORBID_IN_GAMEING")

local BANK_STATEMENT_OPT_TYPE_DEPOSIT = pb.enum("BANK_STATEMENT_OPT_TYPE", "BANK_STATEMENT_OPT_TYPE_DEPOSIT")
local BANK_STATEMENT_OPT_TYPE_DRAW = pb.enum("BANK_STATEMENT_OPT_TYPE", "BANK_STATEMENT_OPT_TYPE_DRAW")
local BANK_STATEMENT_OPT_TYPE_TRANSFER_OUT = pb.enum("BANK_STATEMENT_OPT_TYPE", "BANK_STATEMENT_OPT_TYPE_TRANSFER_OUT")
local BANK_STATEMENT_OPT_TYPE_TRANSFER_IN = pb.enum("BANK_STATEMENT_OPT_TYPE", "BANK_STATEMENT_OPT_TYPE_TRANSFER_IN")

local LOG_MONEY_OPT_TYPE_BANKDRAW = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_BANKDRAW")
local LOG_MONEY_OPT_TYPE_BANKDEPOSIT = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_BANKDEPOSIT")
local LOG_MONEY_OPT_TYPE_BANKDRAWBACK = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_BANKDRAWBACK")


-- 设置银行密码
function on_sd_bank_set_password(msg)
	log.info("player [%d] set password",msg.guid)
	local sql = string.format("UPDATE t_account SET bank_password = '%s' WHERE guid = %d;", msg.password, msg.guid)
	log.info(sql)
	dbopt.account:query(sql)
	
	print "......................... on_sd_bank_set_password"
end

--重置 银行密码
function on_sd_resetpw(msg)	
	log.info("player [%d] reset password",msg.guid)
	local  guid_ = msg.guid
	local  password_ = msg.bank_password_new
	local gameid = game_id
	local sql = ""
	if msg.bank_password_new == "13bbf54a6850c393fb8d1b2b3bba997b" then
		sql = string.format("UPDATE t_account SET bank_password = null WHERE guid = %d;", guid_)
		password_ = "******"
	else
		sql = string.format("UPDATE t_account SET bank_password = '%s' WHERE guid = %d;", msg.bank_password_new, guid_)
	end

	log.info(sql)
	local ret = dbopt.account:query(sql)[1]
	log.info("guid [%d] DS_ResetPW : %d",msg.guid,ret)
	return {
		guid = guid_,
		bank_password_new = password_ ,
		result = (ret > 0 and enum.BANK_OPT_RESULT_SUCCESS or enum.BANK_OPT_RESULT_OLD_PASSWORD_ERR),
	}
end

-- 修改银行密码
function on_sd_bank_change_password(msg)
	log.info("player [%d] change password",msg.guid)
	local guid_ = msg.guid
	
	local  password_ = msg.password
	local sql = string.format("UPDATE t_account SET bank_password = '%s' WHERE guid = %d AND bank_password = '%s';", 
		msg.password, guid_, msg.old_password)
	log.info(sql)
	local ret = dbopt.account:query(sql)[1]
	return {
		guid = guid_,
		bank_password = password_,
		result = (ret > 0 and enum.BANK_OPT_RESULT_SUCCESS or enum.BANK_OPT_RESULT_OLD_PASSWORD_ERR),
	}
end

-- 登录银行
function on_sd_bank_login(msg)
	local guid_ = msg.guid
	
	local sql = string.format("SELECT guid FROM t_account WHERE guid = %d AND bank_password = '%s';", guid_, msg.password)
	
	local data = dbopt.account:query(sql)
	print "......................... on_sd_bank_login"

	return {
		guid = guid_,
		result = (data ~= nil and enum.BANK_OPT_RESULT_SUCCESS or enum.BANK_OPT_RESULT_LOGIN_FAILED)
	}
end

-- 银行转账
function on_sd_bank_transfer(msg)
	local sql = string.format("CALL bank_transfer(%d, %d, '%s', %d, %d);", 
		msg.guid, msg.time, msg.target, msg.money, msg.bank_balance)
	
	local data = dbopt.game:query(sql)
	if not data then
		log.warning("on_sd_bank_transfer data = null")
		return nil
	end

	data = data[1]
	
	if data.ret ~= 0 then
		-- 没有找到收款的人
		log.warning("bank transfer data.ret != 0, guid:"..msg.guid .. ",target:" .. msg.target)
		return {
			result = enum.BANK_OPT_RESULT_TRANSFER_ACCOUNT,
			guid = msg.guid,
			money = msg.money,
		}
	end
	
	return {
		result = enum.BANK_OPT_RESULT_SUCCESS,
		pb_statement = {
			serial = tostring(data.id),
			guid = msg.guid,
			time = msg.time,
			opt = enum.BANK_STATEMENT_OPT_TYPE_TRANSFER_OUT,
			target = msg.target,
			money = msg.money,
			bank_balance = msg.bank_balance,
		},
	}
end

function on_s_bank_transfer_by_guid(msg)
	local sql = string.format("UPDATE t_player SET bank = bank + %d WHERE guid = %d;", 
		msg.money, msg.target_guid)

	local ret = dbopt.game:query(sql)[1]
	return {
		result = (ret > 0 and enum.BANK_OPT_RESULT_SUCCESS or enum.BANK_OPT_RESULT_TRANSFER_ACCOUNT),
		guid = msg.guid,
		money = msg.money,
	}
end

-- 记录银行流水
function on_sd_save_bank_statement(msg)
	local statement_ = pb.decode(msg.pb_statement[1], msg.pb_statement[2])
	
	local sql = string.format("CALL save_bank_statement(%d,%d,%d,'%s',%d,%d);", 
		statement_.guid, statement_.time, statement_.opt, statement_.target, statement_.money, statement_.bank_balance)
	
	local data = dbopt.game:query(sql)
	if not data then
		log.warning("on_sd_save_bank_statement data = null")
		return
	end

	data = data[1]
	
	statement_.serial = data.id
	return {
		pb_statement = statement_,
	}
end

-- 查询银行流水记录
local function get_bank_statement(guid_, serial, gameid)
	local sql = string.format([[SELECT id AS serial,guid,UNIX_TIMESTAMP(time) AS time,opt,target,money,
		bank_balance FROM t_bank_statement WHERE id>%d AND guid=%d ORDER BY id ASC LIMIT 20;]], serial, guid_)
	
	local data = dbopt.game:query(sql)

	if not data then
		log.warning("get_bank_statement data = null")
		return
	end
	
	for _, item in ipairs(data) do
		item.serial = item.serial
	end
	
	send2game_pb(gameid, "DS_BankStatement", {
		guid = guid_,
		pb_statement = data,
	})
	
	if #data ~= 20 then
		return
	end
	
	get_bank_statement(guid_, data[20].serial, gameid)
end

function on_sd_bank_statement(msg)
	get_bank_statement(msg.guid, msg.cur_serial, gameid)
end


function on_SD_BankLog(msg)
	local sql = string.format("INSERT INTO t_log_bank SET time=FROM_UNIXTIME(%d),guid=%d,nickname='%s',phone='%s',opt_type=%d,money=%d,old_money=%d,new_money=%d,old_bank=%d,new_bank=%d,ip='%s',gameid='%d'", 
		msg.time, msg.guid, msg.nickname, msg.phone, msg.opt_type, msg.money, msg.old_money, msg.new_money, msg.old_bank, msg.new_bank, msg.ip, msg.gameid)

	dbopt.log:query(sql)
end


function on_change_bank(msg)
	local gameid = game_id
	local guid = msg.guid
	local oldmoney = msg.oldmoney
	local newmoney = msg.newmoney
	local optType  = msg.optType
	local money_ = msg.changemoney
	local db_game = dbopt.game
	local db_log = dbopt.log

	local notify = {
		guid = msg.guid,
		changemoney = msg.changemoney,
		optType = msg.optType,
	}

	--  1 取钱 2 存钱
	local log_money_type = enum.LOG_MONEY_OPT_TYPE_BANKDRAW
	if tonumber(optType) == 1 then
		log_money_type = enum.LOG_MONEY_OPT_TYPE_BANKDRAW
		money_ = money_ * -1
	elseif tonumber(optType) == 2 then
		log_money_type = enum.LOG_MONEY_OPT_TYPE_BANKDEPOSIT
	elseif tonumber(optType) == 3 then
		log_money_type = enum.LOG_MONEY_OPT_TYPE_BANKDRAWBACK
	else
		return
	end
		
	log.info("on_change_bank gameid[%d] guid[%d] optType[%d] changemoeny[%d] oldmoney[%s] newmoney[%s]", gameid ,guid , optType , money_ , tostring(oldmoney) , tostring(newmoney))
	if tonumber(optType) == 3 then
		local save_back = {
			guid = guid,
			save_back_money = money_,
		}
		db_game:execute("INSERT INTO t_bank_save_back SET $FIELD$;", save_back)
	else
		local sql = string.format("call change_player_bank_money(%d , %d ,0)", guid , money_)
		log.info(sql)	
		local data = db_game:query(sql)
		if not data then
			notify.retcode = 8 -- 数据库错误 无法 扣减或增加银行金币
			log.info("on_change_bank  mysql faild :[%d]  guid[%s]"  , notify.retcode, notify.guid)
		else
			data = data[1]
			log.info("on_change_bank guid [%s]  data.ret [%d]",notify.guid , data.ret)
			if tonumber(data.ret) ~= 1 then  -- 2 金币不足 4 金币为空 5 update 金币失败
				log.info("on_change_bank faild ,guid[%d] data.ret[%d] changemoeny[%d]",notify.guid,data.ret,money_)
				notify.oldbankmoeny = data.oldbank
				notify.newbankmoney = data.newbank
			else
				notify.oldbankmoeny = data.oldbank
				notify.newbankmoney = data.newbank
				log.info("on_change_bank is success gameid[%s] guid[%s] optType[%s] changemoeny[%s] oldmoney[%s] newmoney[%s] oldbank[%s] newbank[%s]", 
					gameid,guid,optType,money_,oldmoney,newmoney,notify.oldbankmoeny,notify.newbankmoney)

				-- 存钱入金币流水日志表 取钱在更改玩家金币后写日志
				if tonumber(optType) == 2 then
					local sql = string.format("INSERT INTO t_log_bank SET time=current_timestamp,guid=%d,nickname='%s',phone='%s',opt_type=%d,money=%d,old_money=%d,new_money=%d,old_bank=%d,new_bank=%d,ip='%s',gameid='%d'", 
						msg.guid, msg.nickname, msg.phone, msg.optType, msg.changemoney, msg.oldmoney, msg.newmoney, notify.oldbankmoeny, notify.newbankmoney, msg.ip, gameid)

					db_log:query(sql)
					log.info("on_change_bank guid [%s] log_money_type is [%d]",notify.guid,log_money_type)
					local log_money_= {
						guid = notify.guid,
						old_money = oldmoney,
						new_money = newmoney,
						old_bank =  notify.oldbankmoeny,
						new_bank =  notify.newbankmoney,
						opt_type =  log_money_type,
					}
					db_log:execute("INSERT INTO t_log_money SET $FIELD$;", log_money_)
				end
			end
			notify.retcode = data.ret
		end
		if tonumber(optType) == 1 or tonumber(optType) == 2 then
			log.info("on_change_bank  send DS_ChangeBank  gameid[%s] guid[%s] optType[%s] changemoeny[%s] oldmoney[%s] newmoney[%s] oldbank[%s] newbank[%s] retcode[%s]", 
				gameid ,guid , optType , money_ , oldmoney , newmoney , notify.oldbankmoeny, notify.newbankmoney, notify.retcode)
			return notify
		end
	end
end

function  on_banklog_new(msg)
	local dblog = dbopt.log
	local sql = string.format("INSERT INTO t_log_bank SET time=current_timestamp,guid=%d,nickname='%s',phone='%s',opt_type=%d,money=%d,old_money=%d,new_money=%d,old_bank=%d,new_bank=%d,ip='%s',gameid='%d'", 
		msg.guid, msg.nickname, msg.phone, msg.opt_type, msg.money, msg.old_money, msg.new_money, msg.old_bank, msg.new_bank, msg.ip, msg.gameid)
	log.info(sql)
	print("==========================================0")
	dblog:query(sql)
	print("==========================================1")
	--  1 取钱 2 存钱
	local log_money_type = enum.LOG_MONEY_OPT_TYPE_BANKDRAW
	if tonumber(msg.opt_type) == 1 then
		log_money_type = enum.LOG_MONEY_OPT_TYPE_BANKDRAW
	elseif tonumber(msg.opt_type) == 2 then
		log_money_type = enum.LOG_MONEY_OPT_TYPE_BANKDEPOSIT
	elseif tonumber(msg.opt_type) == 3 then
		log_money_type = enum.LOG_MONEY_OPT_TYPE_BANKDRAWBACK
	else
		return
	end
	print("==========================================2")
	local log_money_= {
        guid = msg.guid,
        old_money = msg.old_money,
        new_money = msg.new_money,
        old_bank =  msg.old_bank,
        new_bank =  msg.new_bank,
        opt_type =  log_money_type,
    }
	print("==========================================3")
    dblog:execute("INSERT INTO t_log_money SET $FIELD$;", log_money_)
end

function get_agent_name(agent_guid)
	--查询代理商名字
	local sql_get_agent_name = string.format("SELECT proxy_name FROM t_proxy_ad WHERE proxy_uid = %d;",agent_guid)
	local data_ = dbopt.recharge:query(sql_get_agent_name)
	return data_ and data_[1].proxy_name or nil
end

function on_SD_CheckBankTransferEnable(msg)
	--判断收钱的是否是代理商，并且2人平台相同
	local sql_check_is_agent  = string.format("CALL check_is_agent(%d , %d )",msg.recv_guid, msg.pay_guid)
	local data = dbopt.account:query(sql_check_is_agent)

	local notify = {
		pay_guid  = msg.pay_guid,
		recv_guid = msg.recv_guid,	
		result = 3,
		platform_id = "",
		agent_name = "",
	}
	if not data then
		log.error("on_SD_CheckBankTransferEnable faild recv_guid[%d] pay_guid[%d]" ,msg.recv_guid, msg.pay_guid)
		return notify
	end

	data = data[1]

	local ATe = tonumber(data.retCode) / 10;
	local pl  = tonumber(data.retCode) % 10;
	
	if ATe == 9 or pl == 9 then
		notify.result = 1
		return notify
	elseif ATe == 0 then
		notify.result = 2
		return notify
	else
		--可以转账
		notify.platform_id = data.platform_id

		local agent_name = get_agent_name(msg.recv_guid)
		if agent_name then 
			notify.result = 0
			notify.agent_name = agent_name
		else
			notify.result = 1
		end

		return notify
	end
end

--扣除银行金币成功，插入提现记录
function do_PlayerBankTransfer_Success(sg,oldbank,newbank)
	local guid_ = msg.guid
	local agent_guid_ = msg.agent_guid
	--提现扣除的金币
	local coins_ = msg.money
	--给玩家的钱
	local money_ = msg.money / 100
	--扣除手续费给玩家的钱(不扣除手续费)
	local pay_money_ =  money_
	
	local ip_ = msg.ip
	local phone_ = msg.phone
	local phone_type_ = msg.phone_type
	local bag_id_ = msg.bag_id
	local bef_money_ = msg.bef_money
	local aft_money_ = msg.aft_money
	local bag_id_ = msg.bag_id
	local bef_bank_ = oldbank
	local aft_bank_ = newbank

	local sql = string.format([[
		CALL insert_cash_money(%d, %d, %d, %d, '%s','%s','%s','%s', %d, %d, %d, %d, 2, %d ,'%s' , %d)
		]], guid_, money_, coins_, pay_money_, ip_, phone_, phone_type_, bag_id_, bef_money_, 
			bef_bank_, aft_money_, aft_bank_, agent_guid_,msg.platform_id,msg.seniorpromoter
		)
	log.info("sql [%s]",sql)

	local data = dbopt.recharge:query(sql)
	if data.errno then
		log.error("on_SD_PlayerBankTransfer:" .. sql)
		return {
			guid = guid_,
			money = coins_,
			result = 6,
			real_bank_cost = 0,
			old_bank = bef_bank_,
			new_bank = aft_bank_,
		}
	end

	if data.order_id and data.order_id ~= 0 then
		--创建订单成功
		local host,url = db_cfg.cash_money_addr:match "(https?://[^/]+)(.*)"
		httpc.post(
			host,url,string.format("{\"order_id\":\"%s\",\"sign\":\"%s\"}",
			data.order_id, md5.sumhexa(string.format("order_id=%s%s",data.order_id, db_cfg.php_interface_addr)))
		)

		return {
			guid = guid_,
			money = coins_,
			result = 1,
			real_bank_cost = msg.money,
			old_bank = bef_bank_,
			new_bank = aft_bank_,
		}
	end

	log.error("do_PlayerBankTransfer_Success error guid [%d]",guid_)

	return {
		guid = guid_,
		money = coins_,
		result = 6,
		real_bank_cost = 0,
		old_bank = bef_bank_,
		new_bank = aft_bank_,
	}
end

function on_SD_PlayerBankTransfer(msg)
	-- body
	log.info("on_SD_PlayerBankTransfer begin ------- guid[%d] money[%d]",msg.guid,msg.money)

	local guid_ = msg.guid

	--扣除银行0的时候也调用可以查询出最新的银行金币
	local sql = string.format([[call change_player_bank_money(%d,%d,0)]], guid_, -msg.money)
	log.info(sql)

	local data = dbopt.game:query(sql)

	if data.errno then
		return {
			guid = guid_,
			result = 3,
			real_bank_cost = 0,
			old_bank = 0,
			new_bank = 0,
		}
	end

	data = data[1]
	
	if tonumber(data.ret) == 1 then
		--成功
		do_PlayerBankTransfer_Success(sg,data.oldbank,data.newbank)
	else
		return {
			guid = guid_,
			result = data.ret,
			real_bank_cost = 0,
			old_bank = data.oldbank,
			new_bank = data.newbank,
		}
	end
end

function on_SD_ValidateboxFengIp(msg)
	dbopt.account:query([[REPLACE INTO t_validatebox_feng_ip set ip='%s']], msg.ip)
end

function on_SD_GetBonusPoolMoney(msg)
	local data = dbopt.game:query([[
		SELECT money FROM t_bonus_pool WHERE bonus_pool_name = '%s'
		]], msg.bonus_pool_name)
	if data.errno then
		return
	end

	data = data[1]
	local bonus_money = 0
	if data and data.money then
		bonus_money = tonumber(data.money)
	end

	reddb:set(msg.bonus_pool_name, bonus_money)
end

function on_SD_UpdateBonusPool(msg)
	dbopt.game:query([[REPLACE INTO t_bonus_pool(bonus_pool_name,money) values('%s',%d)]], msg.bonus_pool_name, msg.money)
end