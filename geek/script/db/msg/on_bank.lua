-- 银行消息处理
local dbopt = require "dbopt"
local log = require "log"
local enum = require "pb_enums"

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