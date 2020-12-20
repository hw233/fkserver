-- 银行消息处理
local dbopt = require "dbopt"
local redisopt = require "redisopt"
local httpc = require "http.httpc"
local httpurl = require "http.url"
local md5 = require "md5"
local log = require "log"
local enum = require "pb_enums"
local channel = require "channel"

local reddb = redisopt.default

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
	local statement_ = msg.pb_statement
	
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
	
	channel.publish("game."..tostring(gameid),"msg","DS_BankStatement", {
		guid = guid_,
		pb_statement = data,
	})
	
	if #data ~= 20 then
		return
	end
	
	get_bank_statement(guid_, data[20].serial, gameid)
end

function on_sd_bank_statement(msg)
	get_bank_statement(msg.guid, msg.cur_serial)
end


function on_SD_BankLog(msg)
	local sql = string.format("INSERT INTO t_log_bank SET time=FROM_UNIXTIME(%d),guid=%d,nickname='%s',phone='%s',opt_type=%d,money=%d,old_money=%d,new_money=%d,old_bank=%d,new_bank=%d,ip='%s',gameid='%d'", 
		msg.time, msg.guid, msg.nickname, msg.phone, msg.opt_type, msg.money, msg.old_money, msg.new_money, msg.old_bank, msg.new_bank, msg.ip, msg.gameid)

	dbopt.log:query(sql)
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

function on_SD_UpdateBonusPool(msg)
	dbopt.game:query([[REPLACE INTO t_bonus_pool(bonus_pool_name,money) values('%s',%d)]], msg.bonus_pool_name, msg.money)
end