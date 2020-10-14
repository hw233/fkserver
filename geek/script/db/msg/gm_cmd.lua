local pb = require "pb_files"

local dbopt = require "dbopt"
local redisopt = require "redisopt"
local channel = require "channel"
local log = require "log"

local reddb = redisopt.default

local enum = require "pb_enums"

function gm_change_money(guid,money,log_type)
	print("gm_change_money comming......")
	local db = dbpot.game

	local data = db:query("SELECT money,bank from t_player WHERE guid = %d;",guid)
	if not data.errno and #data > 0 then	
		local old_money = data[1].money
		local old_bank = data[1].bank
		if(money < 0) then
			local tempMoney = old_money + money
			if tempMoney < 0 then
				return false
			end
		end
		local new_money = old_money + money
		db:query("UPDATE t_player SET money=%d WHERE guid=%d;",new_money,guid)
		-- 加钱日志存档
		dbopt.log:query("INSERT INTO t_log_money SET guid = %d,old_money=%d,new_money=%d,old_bank=%d,new_bank=%d,opt_type=%d;",
			guid,old_money,new_money,old_bank,old_bank,log_type or enum.LOG_MONEY_OPT_TYPE_GM)
	end
	return true
end

function gm_change_bank_money(guid,bank_money,log_type)
	print("gm_change_bank_money comming......")
    local db = dbopt.game
	local data = db:query("SELECT money,bank FROM t_player WHERE guid = %d;",guid)
	if not data.errno and #data > 0 then
		local old_money = data[1].money
		local old_bank = data[1].bank
		if(bank_money < 0) then
			local tempMoney = old_bank + bank_money
			if tempMoney < 0 then
				return false
			end
		end
		local new_bank_money = old_bank + bank_money
		db:query("UPDATE t_player SET bank=%d WHERE guid=%d;",new_bank_money,guid)
		-- 加钱日志存档
		dbopt.log:query("INSERT INTO t_log_money SET guid = %d,old_money=%d,new_money=%d,old_bank=%d,new_bank=%d,opt_type=%d;",
			guid,old_money,old_money,old_bank,new_bank_money,log_type or enum.LOG_MONEY_OPT_TYPE_GM)
	end

	return true
end

function gm_change_bank(web_id_, login_id, guid, bank_money, log_type)
    local db = dbopt.game
	local ret = db:query("UPDATE t_player SET bank = bank + %d WHERE guid = %d;", bank_money, guid)

	ret = ret and ret[1] or 0

	if ret == 0 then
		log.warning("gm_change_bank not find guid:" .. guid)
		return {
			web_id = web_id_,
			result = 0,
			}
	end

	local data = db:query("SELECT money, bank FROM t_player WHERE guid = %d;", guid)
	if data.errno or #data == 0 then
		log.warning("gm_change_bank data = null")
		return {
			web_id = web_id_,
			result = 0,
		}
	end

	-- 加钱日志存档
	local log = {
		guid = guid,
		old_money = data.money,
		new_money = data.money,
		old_bank = data.bank-bank_money,
		new_bank = data.bank,
		opt_type = log_type or enum.LOG_MONEY_OPT_TYPE_GM,
	}
	dbopt.log:execute("INSERT INTO t_log_money SET $FIELD$;", log)

	return {
		web_id = web_id_,
		result = 1,
		}
end

--[[maintain_switch = 1
--gm命令维护开关通知
--switch_type:开关类型(1提现开关,2游戏服开关)
--switch_flag:开关(0关,1开)
function gm_query_maintain_switch(switch_type,switch_flag)
	print("gm_query_maintain_switch comming......")
	--test_code
	if maintain_switch == 0 then
		maintain_switch = 1 
	else
		maintain_switch = 0
	end
	print("gm_query_maintain_switch comming......"..maintain_switch)
end--]]