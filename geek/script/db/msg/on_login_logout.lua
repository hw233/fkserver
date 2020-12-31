-- 玩家数据消息处理
local log = require "log"
local onlineguid = require "netguidopt"
local dbopt = require "dbopt"
local redisopt = require "redisopt"
local json = require "json"
local channel = require "channel"
local reddb = redisopt.default
local enum = require "pb_enums"
local queue = require "skynet.queue"
local timer = require "timer"
local skynet = require "skynet"

local money_lock = queue()

local server_start_time =  os.time()

local def_save_db_time = 60 -- 1分钟存次档
local def_offline_cache_time = 600 -- 离线玩家数据缓存10分钟

function on_SD_OnlineAccount(game_id, msg)
	dbopt.account:batchquery("REPLACE INTO t_online_account SET guid=%d, first_game_type=%d, second_game_type=%d, game_id=%d, in_game=%d", 
		msg.guid, msg.first_game_type, msg.second_game_type, msg.gamer_id, msg.in_game)
end

-- 玩家退出
function on_s_logout(msg)
	-- 上次在线时间
	local ret = dbopt.account:query([[
			UPDATE t_account SET 
				login_time = FROM_UNIXTIME(%s), 
				logout_time = FROM_UNIXTIME(%s),
				last_login_phone = '%s', 
				last_login_phone_type = '%s', 
				last_login_version = '%s', 
				last_login_channel_id = '%s', 
				last_login_package_name = '%s', 
				last_login_ip = '%s' 
				WHERE guid = %s;
		]],
		msg.login_time, 
		msg.logout_time, 
		msg.phone or '', 
		msg.phone_type or '', 
		msg.version or '', 
		msg.channel_id or '', 
		msg.package_name or '', 
		msg.ip or '', 
		msg.guid
	)
	if ret.errno then
		log.error(ret.err)
	end
end

function on_sd_delonline_player(game_id, msg)
	print ("on_sd_delonline_player........................... begin")
	dbopt.account:batchquery("DELETE FROM t_online_account WHERE guid=%d and game_id=%d", msg.guid, msg.game_id)
	print ("on_sd_delonline_player........................... end")
end

--查询提现记录
function on_sd_cash_money_type(game_id, msg)	
	local guid_ = msg.guid

	local cash_type = "("
	if msg.cash_type then
		local is_first = true
		for _,v in ipairs(msg.cash_type) do
			if is_first == true then
				is_first = false
				cash_type = cash_type..tostring(v)
			else
				cash_type = cash_type..","..tostring(v)
			end
		end
	end
	cash_type = cash_type..")"

	local sql = string.format([[
		select type as cash_type,money,created_at,status,agent_guid,exchange_code from t_cash where  guid = %d and created_at BETWEEN (curdate() - INTERVAL 6 DAY) and (curdate() - INTERVAL -1 DAY) and type in %s  order by created_at desc limit 50
	]], guid_,cash_type)

	local data = dbopt.recharge:batchquery(sql)
	if data.errno then
		log.error(data.err)
	end

	if #data > 0 then
		local msg = {
			guid = msg.guid,
			pb_cash_info = data,
		}
		return msg
	end
end

function on_sd_check_cashTime(game_id, msg)
	local guid_ = msg.guid
	local money_ = msg.money
	local cash_type_ = msg.cash_type

	local sql = string.format([[CALL check_cash_time(%d,%d)]], guid_,cash_type_)

	local data = dbopt.recharge:batchquery(sql)
	if data.errno then
		log.error(data.err)
		return
	end

	if #data == 0 then
		return
	end

	data = data[1]

	local orderid_ = 0
	local time_ = 0
	local money_max_ = 0
	local cash_max_count_ = 1
	if data and data.order_id then
		orderid_ = data.order_id
	end

	if data and data.time_value then
		time_ = data.time_value
	end

	if data and data.money_max then
		money_max_ = data.money_max
	end

	if data and data.cash_max_count then
		cash_max_count_ = data.cash_max_count
	end
	
	print("on_sd_check_cashTime orderid-------------------.",orderid_)
	print("on_sd_check_cashTime time_--------------------.",time_)

	local nmsg = {
		guid = guid_,
		money = money_,
		order_id = orderid_,
		cash_type = cash_type_,
		time = time_,
		money_max = money_max_,
		cash_max_count = cash_max_count_,
	}
	return nmsg
end

function on_sd_proxy_cash_to_bank(game_id,msg)
	local guid = msg.guid
	local money = msg.money
	if not guid or not money then
		return
	end

	local data = dbopt.proxy:batchquery("call cash_commission(%d,%d)",guid,money)
	if data.errno then
		log.error("not commission or not proxy do cash money to bank.guid:[%d],money:[%d],%s",guid,money,data.err)
		return
	end

	data = data[1]

	if data.ret ~= 0 then
		log.error("cash commission failed,guid[%d],money[%d]",guid,money)
	end

	return {
		result = data.ret,
		guid = guid,
		money = money,
		commission = data.commission
	}
end


-- 查询玩家消息及公告
function  on_sd_query_player_msg(game_id, msg)
	log.info("on_sd_query_player_msg----------------------------------")
	local guid_ = msg.guid
	local  sql = string.format('call get_player_notice("%d","%s")',guid_,msg.platform_id)
	log.info(sql)

	local pb_msg_data = {}
	local data = dbopt.game:batchquery(sql)
	if not data.errno and #data > 0 then	
		for _, item in ipairs(data) do
			table.insert(pb_msg_data,item)
		end
	end

	return {
		guid = guid_,
		pb_msg_data = {pb_msg_data_info = pb_msg_data,},
		first = b,
	}
end

-- 查询玩家跑马灯
function  on_sd_query_player_marquee(game_id, msg)
	print("on_sd_query_player_marquee----------------------------------")
	-- body
	local guid_ = msg.guid
	local sql = string.format([[
		select a.id,UNIX_TIMESTAMP(a.start_time) as start_time,UNIX_TIMESTAMP(a.end_time) as end_time,a.content,a.number,a.interval_time from 
		t_notice a where a.end_time > FROM_UNIXTIME(UNIX_TIMESTAMP()) and a.type = 3 and a.platform_ids like '%%,%s,%%']], 
		msg.platform_id)
	
	log.info(sql)

	local items = {}
	local data = dbopt.game:batchquery(sql)
	if not data.errno and #data > 0 then
		for _,datainfo in ipairs(data) do
			print(datainfo)
			for i,info in pairs(datainfo) do
				print(i,info)
			end
		end
		print("-----------------3")
		local b = true
		for _, item in ipairs(data) do
			table.insert(items,item)
		end 
	end

	print("---------------------end")
	return {
		guid = guid_,
		pb_msg_data = {pb_msg_data_info = items},
		first = true,
	}
end

-- 设置公告消息 查看标志
function on_sd_Set_Msg_Read_Flag( game_id, msg )
	-- body
	local guid_ = msg.guid
	local db = dbopt.game
	if msg.msg_type == 1 then
		-- 消息
		local sql = string.format("update t_notice_private set is_read = 2 where guid = %d and id = %d", 
			msg.guid, msg.id)
		local data = db:batchquery(sql)
		if data.errno or data.effected_rows == 0 then
			log.error("set read flag faild :" ..guid_)
			return
		end
		
		log.info("set read flag success :" ..guid_)
	end

	if msg.msg_type == 2 then		
		-- 公告
		local sql = string.format("replace into t_notice_read set guid = %d ,n_id = %d,is_read = 2", 
			msg.guid, msg.id)
		local data = db:batchquery(sql)
		if data.err or data.errno then
			log.error("set read flag faild :" ..guid_)
			return
		end

		log.info("set read flag success :" ..guid_)
	else
		print(" msg type error")
	end
end

function on_sd_query_channel_invite_cfg(game_id, msg)
	local gameid = game_id
	local data = dbopt.account:batchquery("SELECT * FROM t_channel_invite")
	if data.errno then
		log.error("on_sd_query_channel_invite_cfg not find guid:")
		return
	end

	local ret_msg = {}
	for k,v in pairs(data) do
		local tmp = {}
		tmp.channel_id = v.channel_id
		local channel_lock = v.channel_lock
		local big_lock = v.big_lock
		if big_lock == 1 and channel_lock == 1 then
			tmp.is_invite_open = 1
		else
			tmp.is_invite_open = 2
		end
		tmp.tax_rate = v.tax_rate
		table.insert( ret_msg, tmp)
	end

	return {
		cfg = ret_msg,
	}
end

function on_sd_query_player_invite_reward(game_id, msg)
	local guid_ = msg.guid
	local gameid = game_id

	local data = dbopt.game:batchquery("CALL get_player_invite_reward(%d)",guid_)
	if data.errno then
		log.error("on_sd_query_player_invite_reward not find guid:" .. guid_)
		return
	end

	data = data[1]

	return  {
		guid = guid_,
		reward = data.total_reward,
		}
end

function charge_rate(gameid , guid , last_login_channel_id)
	if last_login_channel_id == nil then
		return
	end

	log.info("charge_rate gameid [%d] guid[%d]" , gameid, guid)
	local sqlT =  string.format("call charge_rate(%d,'%s')" , guid,last_login_channel_id)
	log.info("charge_rate : %s" , sqlT)
	local dataTR = dbopt.recharge:batchquery(sqlT)
	if dataTR then
		dataTR = dataTR[1]
		log.info(string.format(
			"guid[%d] charge_num [%s] agent_num [%s] charge_success_num [%s] agent_success_num [%s] agent_rate_def [%s] charge_max [%s] charge_time [%s] charge_times [%s] charge_moneys [%s] agent_rate_other [%s] agent_rate_add [%s] agent_close_times[%s] agent_rate_decr [%s] charge_money [%s] agent_money [%s]"
			, guid
			, dataTR.charge_num
			, dataTR.agent_num
			, dataTR.charge_success_num
			, dataTR.agent_success_num
			, dataTR.agent_rate_def
			, dataTR.charge_max
			, dataTR.charge_time
			, dataTR.charge_times
			, dataTR.charge_moneys
			, dataTR.agent_rate_other
			, dataTR.agent_rate_add
			, dataTR.agent_close_times
			, dataTR.agent_rate_decr
			, dataTR.charge_money
			, dataTR.agent_money
				))

		return  {
			guid = guid,						                            -- 玩家ID
			charge_num = tonumber(dataTR.charge_num),		                -- 成功充值次数
			agent_num = tonumber(dataTR.agent_num),		                    -- 代理商成功充值次数
			charge_success_num = tonumber(dataTR.charge_success_num),   	-- 充值成功限制
			agent_success_num = tonumber(dataTR.agent_success_num),			-- 代理充值成功限制
			agent_rate_def = tonumber(dataTR.agent_rate_def),				-- 默认显示代理充值机率
			charge_max = tonumber(dataTR.charge_max),						-- 显示充值时 单笔最大限制
			charge_time = tonumber(dataTR.charge_time),						-- 充值时间限制
			charge_times = tonumber(dataTR.charge_times),					-- 充值成功超过次数
			charge_moneys = tonumber(dataTR.charge_moneys),					-- 充值成功超过金额
			agent_rate_other = tonumber(dataTR.agent_rate_other),			-- charge_times与charge_moneys 达标后 代理显示机率
			agent_rate_add = tonumber(dataTR.agent_rate_add),				-- 成功一次后增加机率
			agent_close_times = tonumber(dataTR.agent_close_times),			-- 关闭次数
			agent_rate_decr = tonumber(dataTR.agent_rate_decr),				-- 每次减少机率
			charge_money = tonumber(dataTR.charge_money),
			agent_money = tonumber(dataTR.agent_money)
		}
	end
end

-- 立即保存钱
function on_SD_SavePlayerMoney(game_id, msg)
	dbopt.game:batchquery("UPDATE t_player SET money=" .. (msg.money or 0) .. " WHERE guid=" .. msg.guid .."")
end

-- 立即保存银行钱
function on_SD_SavePlayerBank(game_id, msg)	
	dbopt.game:batchquery("UPDATE t_player SET bank=" .. (msg.bank or 0) .. " WHERE guid=" .. msg.guid .."")
end

-- 请求机器人数据
function on_sd_load_android_data(game_id, msg)
	local opttype = msg.opt_type
	local roomid = msg.room_id
	local data = dbopt.game:batchquery("SELECT guid, account, nickname FROM t_player WHERE guid>%d AND is_android=1 ORDER BY guid ASC LIMIT %d", msg.guid, msg.count)

	if data and #data > 0 then
		return {
			opt_type = opttype,
			room_id = roomid,
			android_list = data,
		}
	end
end

function on_ld_AlipayEdit(login_id, msg)
	local notify = {
		guid = msg.guid,
		EditNum = 0,
		retid = msg.retid,
		asyncid = msg.asyncid,
	}
	-- body
	print("==============================================on_ld_AlipayEdit=============================================")
	local sql = string.format("update t_account set alipay_name = '%s',alipay_name_y = '%s',alipay_account = '%s',alipay_account_y = '%s' where guid = %d  ",
		msg.alipay_name , msg.alipay_name_y , msg.alipay_account , msg.alipay_account_y,msg.guid  )
	print(sql)
	local ret = dbopt.account:batchquery(sql)
	if ret and ret.errno then 
		log.error(ret.err)
	end

	print("on_ld_AlipayEdit=============================================1")
	notify.EditNum = 1
	return notify
end

function on_ld_DelMessage(login_id, msg)
	-- body
	print("==============================================on_ld_DelMessage=============================================")
	local sql = ""
	local notify = {
		ret = 1,
		msg_type = msg.msg_type,
		msg_id = msg.msg_id,
		retid = msg.retid,
		asyncid = msg.asyncid,
	}
	local data = dbopt.game:batchquery("CALL del_msg(%d, %d)",msg.msg_id, msg.msg_type)
	if not data then
		print("on_ld_DelMessage faild :" ..notify.msg_type)
		return notify
	end

	data = data[1]
	
	if data.ret ~= 0 then
		-- 删除失败
		print(string.format("on_ld_DelMessage faild : [%d] [%d]",data.ret,notify.msg_type))
		return notify
	end

	-- 执行成功
	if notify.msg_type == 1 then
		notify.guid = data.guid
	end
	print("on_ld_NewNotice success :" ..notify.msg_type)
	notify.ret = 100
	return notify
end

function on_ld_NewNotice(login_id, msg)
	-- body
	local sql = ""
	local notify = {
		ret = 1,
		guid = msg.guid,
		type = msg.type,
		retID = msg.retID,
		content = msg.content,
		name = msg.name,
		author = msg.author,
		number = msg.number,
		interval_time = msg.interval_time,
		platforms = msg.platforms,
		asyncid = msg.asyncid,
	}
	

	--公告和跑马灯组装平台id： ,0,1,
	local platform_ids = ","
	if msg.type == 2 or msg.type == 3 then
		for _,plat in ipairs(msg.platforms) do
			platform_ids = platform_ids..plat..","
		end
	end
	
	log.info("msg.type[%s] platform_ids[%s]",msg.type,platform_ids)

	if msg.type == 1 then  --消息
		sql = string.format([[REPLACE INTO t_notice_private set guid=%d,type=1,name='%s',content='%s',author='%s',
			start_time='%s',end_time = '%s']],
		msg.guid, msg.name, msg.content, msg.author,msg.start_time,msg.end_time)
	elseif msg.type == 2 then --公告
		sql = string.format([[REPLACE INTO t_notice set type=2,name='%s',content='%s',author='%s',
			start_time='%s',end_time = '%s',platform_ids = '%s']],
			msg.name, msg.content, msg.author,msg.start_time,msg.end_time,platform_ids)
	elseif msg.type == 3 then --跑马灯
		sql = string.format([[REPLACE INTO t_notice set type=3,number=%d,interval_time=%d,content='%s',
			start_time='%s',end_time = '%s',platform_ids = '%s']],msg.number,msg.interval_time,
			msg.content,msg.start_time,msg.end_time,platform_ids)
	else
		log.error("on_ld_NewNotice not find type:"..msg.type)
	end
	log.info("%s",sql)
	local ret = dbopt.game:batchquery(sql)[1]
	-- print("on_ld_NewNotice=============================================1")
	if ret > 0 then
		print("on_ld_NewNotice success :" ..notify.type)
		sql = string.format("SELECT LAST_INSERT_ID() as ID, UNIX_TIMESTAMP('%s') as start_time,UNIX_TIMESTAMP('%s') as end_time",msg.start_time,msg.end_time)
		local data = db.game.query(sql)
	--	print("on_ld_NewNotice=============================================2")
		if data then
			notify.id = data[1].ID
			notify.start_time = data[1].start_time
			notify.end_time = data[1].end_time
		end
		notify.ret = 100
		return notify
	else
		print("on_ld_NewNotice faild :" ..msg.type)
		return notify
	end
--	print("on_ld_NewNotice=============================================3")
end

-- 保存玩家百人牛牛数据
function on_sd_save_player_Ox_data(game_id, msg)
	--print(string.format("game_id = [%d], guid[%d] is_android[%d] table_id[%d] banker_id[%d] nickname[%s] money[%d] win_money[%d] tax[%d] curtime[%d] save ox data.",
	--game_id,msg.guid,msg.is_android,msg.table_id,msg.banker_id,msg.nickname,msg.money,msg.win_money,msg.tax,msg.curtime))
	local sql = string.format("REPLACE INTO t_ox_player_info set guid = %d, is_android = %d, table_id = %d, banker_id = %d, \
	nickname = '%s', money = %d, win_money = %d, bet_money = %d,tax = %d, curtime = %d",
	msg.guid,msg.is_android,msg.table_id,msg.banker_id,msg.nickname,msg.money,msg.win_money,msg.bet_money,msg.tax,msg.curtime)
	dbopt.game:batchquery(sql)
end

-- 请求百人牛牛基础数据
function on_sd_query_Ox_config_data(game_id, msg)
	print(string.format("on_sd_query_Ox_config_data game_id = [%d],curtime = [%d]",game_id,msg.cur_time))
	local data = dbopt.game:batchquery(
		[[select FreeTime,BetTime,EndTime,MustWinCoeff,BankerMoneyLimit,SystemBankerSwitch,BankerCount,RobotBankerInitUid,RobotBankerInitMoney,BetRobotSwitch,
			BetRobotInitUid,BetRobotInitMoney,BetRobotNumControl,BetRobotTimesControl,RobotBetMoneyControl,BasicChip from t_many_ox_server_config]]
		)
	
	-- 查询数据,返回
	if data and #data > 0 then
		--[[for _,datainfo in ipairs(data) do
			print(datainfo)
			for i,info in pairs(datainfo) do
				print(i,info)
			end
		end--]]
		local msg = {
			FreeTime = data[1].FreeTime,
			BetTime = data[1].BetTime,
			EndTime = data[1].EndTime,
			MustWinCoeff = data[1].MustWinCoeff,
			BankerMoneyLimit = data[1].BankerMoneyLimit,
			SystemBankerSwitch = data[1].SystemBankerSwitch,
			BankerCount = data[1].BankerCount,
			RobotBankerInitUid = data[1].RobotBankerInitUid,
			RobotBankerInitMoney = data[1].RobotBankerInitMoney,
			BetRobotSwitch = data[1].BetRobotSwitch,
			BetRobotInitUid = data[1].BetRobotInitUid,
			BetRobotInitMoney = data[1].BetRobotInitMoney,
			BetRobotNumControl = data[1].BetRobotNumControl,
			BetRobotTimesControl = data[1].BetRobotTimesControl,
			RobotBetMoneyControl = data[1].RobotBetMoneyControl,
			BasicChip = data[1].BasicChip
		}
	
		return msg
	end
end

--查询玩家是否破产
function query_player_is_or_not_collapse(guid_)
	-- body
	if guid_ > 0 then
		local sql =  string.format("call judge_player_is_collapse(%d)" , guid_)

		local data = dbopt.game:batchquery(sql)
		if data then
			data = data[1]
			local playerData = json.decode(data.retdata)
			if playerData and tonumber(playerData.is_collapse) == 1 then
				log.info(data.retdata)
				if playerData.channel_id and playerData.platform_id then
					log.info("guid [%d] is collapse  is_collapse[%d] channel_id[%s] platform_id[%s]", guid_,playerData.is_collapse,playerData.channel_id,playerData.platform_id)
					local log_db = dbopt.log
					local update_sql = string.format([[
						INSERT INTO `t_log_bankrupt`(`day`,`guid`,`times_pay`,`bag_id`,`plat_id`) VALUES('%s',%d,1,'%s','%s') ON DUPLICATE KEY UPDATE `times_pay`=(`times_pay`+1),`bag_id`=VALUES(`bag_id`),`plat_id`=VALUES(`plat_id`)]],
							os.date("%Y-%m-%d",os.time()),guid_,playerData.channel_id,playerData.platform_id)
					log_db:execute(update_sql)
				end
			end
		else
			log.info("guid[%d] data is null..........................",guid_)
		end
	end
end


function on_ld_BankcardEdit(login_id, msg)
	local notify = {
		guid = msg.guid,
		EditNum = 0,
		retid = msg.retid,
		asyncid = msg.asyncid,
	}
	print("==============================================on_ld_BankcardEdit=============================================")
	local sql = string.format("update t_player_bankcard set bank_card_name = '%s' ,bank_card_num = '%s' ,bank_name = '%s' ,bank_province = '%s' ,bank_city = '%s' ,bank_branch = '%s' where guid = %d "
		,msg.bank_card_name , msg.bank_card_num, msg.bank_name, msg.bank_province, msg.bank_city, msg.bank_branch, msg.guid )
	log.info(sql)

	local ret = dbopt.account:batchquery(sql)
	if ret and ret.errno then
		log.info(ret.err)
	end
	print("on_ld_BankcardEdit=============================================1")
	notify.EditNum = 1
	return notify
end

function on_ld_verify_account(msg)
	local account = msg.verify_account.account
	local platform_id = msg.platform_id
	log.info("login step db.DL_VerifyAccountResult,account=%s, platform_id =%s", account, platform_id )
	log.info( "find_verify_account=============false,account=%s", account)
	local ip = msg.ip
	local phone = msg.phone
	local phone_type = msg.phone_type
	local version = msg.version
	local channelid = msg.channel_id
	local package_name = msg.package_name
	local imei = msg.imei
	local deprecated_imei = msg.deprecated_imei

	local reply = dbopt.account:batchquery(string.format( "CALL verify_account(\"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\")",
		account,msg.verify_account.password,msg.ip,msg.phone,msg.phone_type,msg.version,msg.channel_id,msg.package_name,
		msg.imei,msg.deprecated_imei,msg.platform_id,msg.shared_id))

	if not reply then
		reply = {}
		log.error( "verify account[%s] failed", account )
		reply.ret = enum.LOGIN_RESULT_DB_ERR
		reply.account = account
		reply.platform_id = platform_id
		return reply
	end

	if reply.ret == 0 and reply.vip == 100 then
		log.info( "login step db.DL_VerifyAccountResult ok,account=%s", account )
		local sql = string.format([[
			INSERT INTO `log`.`t_log_login` (`guid`, `login_phone`, `login_phone_type`, `login_version`, `login_channel_id`, `login_package_name`, 
			`login_imei`, `login_ip`, `channel_id` , `is_guest` , `create_time` , `register_time`, `deprecated_imei` , `platform_id` , `seniorpromoter`),
			VALUES('%d', '%s', '%d', '%s', '%s', '%s', '%s', '%s', '%s' ,'%d' ,FROM_UNIXTIME('%d'), if ('%d'>'0', FROM_UNIXTIME('%d'), null) ,'%s' , '%s' , '%d')
			]],
			reply.guid , phone ,phone_type ,version ,channelid ,package_name ,imei ,ip ,reply.channel_id , reply.is_guest , 
			reply.create_time, reply.register_time, deprecated_imei , platform_id , reply.seniorpromoter)

		log.info(sql)
		dbopt.account:batchquery(sql)
	else
		-- 维护中
	end

	reply.account = account
	reply.platform_id = platform_id

	return reply
end

function on_ld_reg_account(msg)
	log.dump(msg)

	local guid = msg.guid

	local rs = dbopt.account:batchquery(
			[[
				INSERT INTO account.t_account(
					guid,account,nickname,level,last_login_ip,openid,head_url,create_time,login_time,
					register_time,ip,version,phone_type,package_name,phone,union_id
				)
				VALUES(
					%d,'%s','%s','%s','%s','%s','%s',NOW(),NOW(),NOW(),'%s','%s','%s','%s','%s','%s'
				);
			]],
			guid,
			msg.account,
			msg.nickname,
			msg.level,
			msg.login_ip,
			msg.open_id,
			msg.icon,
			msg.login_ip,
			msg.version,
			msg.phone_type or "unkown",
			msg.package_name or "",
			msg.phone or "",
			msg.union_id or ""
		)

	if rs.errno then
		log.error("on_ld_reg_account insert into t_account throw exception.[%s],[%s]",rs.errno,rs.err)
		return
	end

	local transqls = {
		{	[[
				INSERT INTO t_player(guid,account,nickname,level,head_url,phone,phone_type,union_id,promoter,channel_id,created_time) 
				VALUES(%d,'%s','%s','%s','%s','%s','%s','%s',%s,'%s',NOW())
			]],
			guid,
			msg.account,
			msg.nickname,
			msg.level,
			msg.icon,
			msg.phone or "",
			msg.phone_type or "unknown",
			msg.union_id or "",
			msg.promoter or "NULL",
			msg.channel_id or ""
		},
		{	[[INSERT INTO t_player_money(guid,money_id) VALUES(%d,0),(%d,-1)]],
			guid,guid
		},
	}

	rs = dbopt.game:batchquery(transqls)
	if rs.errno then
		log.error("on_ld_reg_account insert into game player info throw exception.[%d],[%s]",rs.errno,rs.err)
		return
	end

	rs = dbopt.log:batchquery([[
				INSERT INTO t_log_login(guid,login_version,login_phone_type,login_ip,login_time,create_time,register_time,platform_id,login_phone)
				VALUES(%d,'%s','%s','%s',NOW(),NOW(),NOW(),'%s','%s');
			]],
			guid,
			msg.version,
			msg.phone_type or "unkown",
			msg.ip,
			msg.platform_id or "",
			msg.phone or "")
	if rs.errno then
		log.error("on_ld_reg_account insert into log login info throw exception.[%d],[%s]",rs.errno,rs.errstr)
	end

	return true
end

function on_sd_set_nickname(msg)
	local guid = msg.guid
	local nickname = msg.nickname

	local ret = dbopt.game:batchquery("UPDATE t_player SET `nickname` = '%s' WHERE guid = %d;", nickname, guid)
	if ret.errno then
		log.error(ret.err)
	end

	return 
end

function on_sd_update_earnings( msg )
	dbopt.account:batchquery([[UPDATE t_earnings SET daily_earnings = daily_earnings + %d, weekly_earnings = weekly_earnings + %d, 
						monthly_earnings = monthly_earnings + %d WHERE guid = %d]],msg.money, msg.money, msg.money, msg.guid )
end

local function alipay_mixed_name( account, name)
	local id,domain,www = account:match("([^@]+)@([^.]+).(%.+)")
	if id and domain then
		id = #id > 4 and account.sub(1,-4).."****" or #id > 2 and account.sub(1,-2).."**" or account.sub(1,-1).."*"
		account = id.."@"..domain.."."..www
	else
		account = account.sub(1,3).."****"..account.sub(7,11)
	end

	name = name.sub(1,3).."*" * math.floor(#name / 3)
	return account,name
end

function on_ld_phone_query(msg)
	local phone = msg.phone
	local gate_session_id = msg.gate_session_id
	local gate_id = msg.gate_id
	local guid = msg.guid
	local platform_id = msg.platform_id
	local sql = string.format( "select account from t_account where account = '%s' and platform_id = '%d';",msg.phone, platform_id )
	log.info( sql )

	local reply = {
		phone = phone,
		gate_session_id = gate_session_id,
		gate_id = gate_id,
		guid = guid,
		platform_id = platform_id,
	}

	local data = dbopt.account:batchquery(sql)
	if data.errno or #data == 0 then
		reply.ret = 1
	else
		reply.ret = 2
	end

	return reply
end

function on_ld_get_inviter_info(msg)
	local invite_code = msg.invite_code
	local gate_session_id = msg.gate_session_id
	local gate_id = msg.gate_id
	local new_player_guid = msg.guid

	local reply = {
		gate_session_id = gate_session_id,
		gate_id = gate_id,
	}
	local data = dbopt.account:batchquery("select guid,account,alipay_name_y,alipay_account_y from t_account where invite_code = '%s';", invite_code)
	if data.errno or #data == 0 then
		return reply
	end

	data = data[1]
	reply.guid = data.guid
	reply.account = data.account
	reply.alipay_name = data.alipay_name
	reply.alipay_account = data.alipay_account
	reply.guid_self = new_player_guid
	local inviter_guid = data.guid
	dbopt.account:batchquery("UPDATE t_account SET `inviter_guid` = %d WHERE guid = %d;", inviter_guid, new_player_guid)
	return reply
end

function on_s_request_proxy_platform_ids(msg)
	local data = dbopt.account:batchquery("SELECT DISTINCT platform_id FROM t_proxy_ad ;")
	if data.errno or #data == 0 then
		log.error("RequestProxyIds error")
		return nil
	end

	data = data[1][1]
	return string.split(data,"[^,]+")
end

function on_s_request_proxy_info(msg)
	local login_id = msg.loginid
	local platform_id = msg.platform_id
	local data = dbopt.proxy:batchquery("CALL get_proxy_info(%d);", platform_id)
	if data.errno or #data == 0 then
		log.error( "load cfg from db error" )
		return
	end

	if data[1][1] == "0" then
		log.error( "get_proxy_info[%d] failed", platform_id )
		return
	end

	local reply = {
		pb_platform_proxys = data[1][1]
	}

	return reply
end


function on_reg_account(msg)
	log.dump(msg)
	local res = dbopt.account:batchquery(
					[[insert into t_account(guid,account,nickname,level,last_login_ip,openid,head_url,create_time,login_time,
						register_time,ip,version,phone_type,package_name) 
					values(%d,'%s','%s','%s','%s','%s','%s',NOW(),NOW(),NOW(),'%s','%s','%s','%s');]],
					msg.guid,
					msg.account,
					msg.nickname,
					msg.level,
					msg.login_ip,
					msg.open_id,
					msg.icon,
					msg.login_ip,
					msg.version,
					msg.phone_type or "unkown",
					msg.package_name or ""
				)
	if res.errno then
		log.error("on_reg_account insert into t_account throw exception.[%d],[%s]",res.errno,res.err)
		return
	end

	res = dbopt.log:batchquery(
		[[insert into t_log_login(guid,login_version,login_phone_type,login_ip,login_time,create_time,register_time,platform_id)
			values(%d,'%s','%s','%s',NOW(),NOW(),NOW(),'%s');]],
		msg.guid,
		msg.version,
		msg.phone_type or "unkown",
		msg.ip,
		msg.platform_id or ""
	)

	if res.errno then
		log.error("on_reg_account update t_log_login throw exception.[%d],[%s]",res.errno,res.err)
		return
	end
end

local function incr_player_money(guid,money_id,old_money,new_money,where,why,why_ext)
	local money = math.floor(new_money - old_money)
	log.info("incr_player_money %s,%s,old:%s,new:%s,%s,%s,%s",guid,money_id,old_money,new_money,money,where,why)
	local res = dbopt.game:query(
			[[INSERT INTO t_player_money(guid,money_id,money,`where`) VALUES(%s,%s,%s,%s) ON DUPLICATE KEY UPDATE money = %s;]],
			guid,money_id,new_money,where,new_money
		)
	if res.errno then
		log.error("incr_player_money error,errno:%d,error:%s",res.errno,res.err)
		return
	end

	log.dump(res)

	-- 单独执行，避免统计时锁表卡住
	skynet.fork(function()
		dbopt.log:batchquery([[
				INSERT INTO t_log_money(guid,money_id,old_money,new_money,`where`,reason,reason_ext,created_time) 
				VALUES(%d,%d,%d,%d,%d,%d,'%s',%d);
			]],
			guid,money_id,old_money,new_money,where,why,
			why_ext or '',timer.milliseconds_time()
		)
	end)
	return old_money,new_money
end

function on_sd_change_player_money(items,why,why_ext)
	local changes = {}
	for _,item in pairs(items) do
		local oldmoney,newmoney = incr_player_money(item.guid,item.money_id,item.old_money,item.new_money,item.where or 0,why,why_ext)
		table.insert(changes,{
			oldmoney = oldmoney,
			newmoney = newmoney,
		})
	end

	return changes
end


function on_sd_new_money_type(msg)
	local id = msg.id
	local club_id = msg.club_id
	local money_type = msg.type
	dbopt.game:batchquery("INSERT INTO t_money(id,type,club_id) VALUES(%d,%d,%s)",id,money_type,club_id)
end

local function transfer_money_club2player(club_id,guid,money_id,amount,why,why_ext)
	log.info("transfer_money_club2player club:%s,guid:%s,money_id:%s,amount:%s,why:%s,why_ext:%s",
		club_id,guid,money_id,amount,why,why_ext)
	local sqls = {
		{[[SELECT money FROM t_club_money WHERE club = %d AND money_id = %d;]],club_id,money_id},
		{[[UPDATE t_club_money SET money = money + (%d) WHERE club = %d AND money_id = %d;]],- amount,club_id,money_id},
		{[[SELECT money FROM t_club_money WHERE club = %d AND money_id = %d;]],club_id,money_id},
		{[[SELECT money FROM t_player_money WHERE guid = %d AND money_id = %d AND `where` = 0;]],guid,money_id},
		{[[UPDATE t_player_money SET money = money + (%d) WHERE guid = %d AND money_id = %d AND `where` = 0;]],amount,guid,money_id},
		{[[SELECT money FROM t_player_money WHERE guid = %d AND money_id = %d AND `where` = 0;]],guid,money_id},
	}

	local gamedb = dbopt.game

	local succ,res = gamedb:transaction(function(trans)
		local res = trans:batchexec(sqls)
		return not res.errno,res
	end)
	if not succ then
		log.error("transfer_money_club2player do money error,errno:%d,err:%s",res.errno,res.err)
		return enum.ERROR_INTERNAL_UNKOWN
	end

	log.dump(res)

	local old_club_money = res[1] and res[1][1] and res[1][1].money or nil
	local new_club_money = res[3] and res[3][1] and res[3][1].money or nil
	local old_player_money = res[4] and res[4][1] and res[4][1].money or nil
	local new_player_money = res[6] and res[6][1] and res[6][1].money or nil

	local logsqls = {
		{
			[[INSERT INTO t_log_money_club(club,money_id,old_money,new_money,opt_type,opt_ext) VALUES(%d,%d,%d,%d,%d,'%s');]],
			club_id,money_id,old_club_money,new_club_money,why,why_ext
		},
		{	
			[[
			INSERT INTO t_log_money(guid,money_id,old_money,new_money,`where`,reason,reason_ext,created_time) 
			VALUES(%d,%d,%d,%d,0,%d,'%s',%s);
			]],guid,money_id,old_player_money,new_player_money,why,why_ext,timer.milliseconds_time()
		},
	}
	res = dbopt.log:batchquery(logsqls)
	if res.errno then
		log.error("transfer_money_player2club insert log error,errno:%d,err:%s",res.errno,res.err)
		return enum.ERROR_INTERNAL_UNKOWN
	end

	return enum.ERROR_NONE,old_club_money,new_club_money,old_player_money,new_player_money
end

local function transfer_money_player2club(guid,club_id,money_id,amount,why,why_ext)
	log.info("transfer_money_player2club club:%s,guid:%s,money_id:%s,amount:%s,why:%s,why_ext:%s",
		club_id,guid,money_id,amount,why,why_ext)
	local sqls = {
		{[[SELECT money FROM t_player_money WHERE guid = %d AND money_id = %d AND `where` = 0;]],guid,money_id},
		{[[UPDATE t_player_money SET money = money + (%d) WHERE guid = %d AND money_id = %d AND `where`= 0;]],- amount,guid,money_id},
		{[[SELECT money FROM t_player_money WHERE guid = %d AND money_id = %d AND `where` = 0;]],guid,money_id},
		{[[SELECT money FROM t_club_money WHERE club = %d AND money_id = %d;]],club_id,money_id},
		{[[UPDATE t_club_money SET money = money + (%d) WHERE club = %d AND money_id = %d;]],amount,club_id,money_id},
		{[[SELECT money FROM t_club_money WHERE club = %d AND money_id = %d;]],club_id,money_id},
	}

	local succ,res = dbopt.game:transaction(function(trans)
		local res = trans:batchexec(sqls)
		return not res.errno,res
	end)
	if not succ then
		log.error("transfer_money_player2club do money error,errno:%d,err:%s",res.errno,res.err)
		return enum.ERROR_INTERNAL_UNKOWN
	end

	log.dump(res)

	local old_player_money = res[1] and res[1][1] and res[1][1].money or nil
	local new_player_money = res[3] and res[3][1] and res[3][1].money or nil
	local old_club_money = res[4] and res[4][1] and res[4][1].money or nil
	local new_club_money = res[6] and res[6][1] and res[6][1].money or nil

	local logsqls = {
		{
			[[INSERT INTO t_log_money_club(club,money_id,old_money,new_money,opt_type,opt_ext) VALUES(%d,%d,%d,%d,%d,'%s');]],
			club_id,money_id,old_club_money,new_club_money,why,why_ext
		},
		{
			[[
			INSERT INTO t_log_money(guid,money_id,old_money,new_money,`where`,reason,reason_ext,created_time) 
			VALUES(%d,%d,%d,%d,0,%d,'%s',%s);
			]],
			guid,money_id,old_player_money,new_player_money,why,why_ext,timer.milliseconds_time()
		},
	}
	res = dbopt.log:batchquery(logsqls)
	if res.errno then
		log.error("transfer_money_player2club insert log error,errno:%d,err:%s",res.errno,res.err)
		return enum.ERROR_INTERNAL_UNKOWN
	end

	return enum.ERROR_NONE,old_club_money,new_club_money,old_player_money,new_player_money
end

local function transfer_money_club2club(club_id_from,club_id_to,money_id,amount,why,why_ext)
	log.info("transfer_money_club2club from:%s,to:%s,money_id:%s,amount:%s,why:%s,why_ext:%s",
		club_id_from,club_id_to,money_id,amount,why,why_ext)
	local sqls = {
		{[[SELECT money FROM t_club_money WHERE club = %d AND money_id = %d;]],club_id_from,money_id},
		{[[UPDATE t_club_money SET money = money + (%d) WHERE club = %d AND money_id = %d;]],-amount,club_id_from,money_id},
		{[[SELECT money FROM t_club_money WHERE club = %d AND money_id = %d;]],club_id_from,money_id},
		{[[SELECT money FROM t_club_money WHERE club = %d AND money_id = %d;]],club_id_to,money_id},
		{[[UPDATE t_club_money SET money = money + (%d) WHERE club = %d AND money_id = %d;]],amount,club_id_to,money_id},
		{[[SELECT money FROM t_club_money WHERE club = %d AND money_id = %d;]],club_id_to,money_id},
	}

	log.dump(sqls)

	local gamedb = dbopt.game

	local succ,res = gamedb:transaction(function(trans)
		local res = trans:batchexec(sqls)
		return not res.errno,res
	end)

	if not succ then
		log.error("transfer_money_club2club do money error,errno:%d,err:%s",res.errno,res.err)
		return enum.ERROR_INTERNAL_UNKOWN
	end

	log.dump(res)

	local old_from_money = res[1] and res[1][1] and res[1][1].money or nil
	local new_from_money = res[3] and res[3][1] and res[3][1].money or nil
	local old_to_money = res[4] and res[4][1] and res[4][1].money or nil
	local new_to_money = res[6] and res[6][1] and res[6][1].money or nil

	local logsqls = {
		{
			[[INSERT INTO t_log_money_club(club,money_id,old_money,new_money,opt_type,opt_ext) VALUES(%d,%d,%d,%d,%d,'%s');]],
			club_id_from,money_id,old_from_money,new_from_money,why,why_ext
		},
		{
			[[INSERT INTO t_log_money_club(club,money_id,old_money,new_money,opt_type,opt_ext) VALUES(%d,%d,%d,%d,%d,'%s');]],
			club_id_to,money_id,old_to_money,new_to_money,why,why_ext,
		}
	}

	log.dump(logsqls)
	res = dbopt.log:batchquery(logsqls)
	if res.errno then
		log.error("transfer_money_player2club insert log error,errno:%d,err:%s",res.errno,res.err)
		return enum.ERROR_INTERNAL_UNKOWN
	end

	return enum.ERROR_NONE,old_from_money,new_from_money,old_to_money,new_to_money
end


local function transfer_money_player2player(from_guid,to_guid,money_id,amount,why,why_ext)
	log.info("transfer_money_player2player from:%s,to:%s,money_id:%s,amount:%s,why:%s,why_ext:%s",
		from_guid,to_guid,money_id,amount,why,why_ext)
	local sqls = {
		{[[SELECT money FROM t_player_money WHERE guid = %d AND money_id = %d;]],from_guid,money_id},
		{[[UPDATE t_player_money SET money = money + (%d) WHERE guid = %d AND money_id = %d;]],-amount,from_guid,money_id},
		{[[SELECT money FROM t_player_money WHERE guid = %d AND money_id = %d;]],from_guid,money_id},
		{[[SELECT money FROM t_player_money WHERE guid = %d AND money_id = %d;]],to_guid,money_id},
		{[[UPDATE t_player_money SET money = money + (%d) WHERE guid = %d AND money_id = %d;]],amount,to_guid,money_id},
		{[[SELECT money FROM t_player_money WHERE guid = %d AND money_id = %d;]],to_guid,money_id},
	}

	log.dump(sqls)

	local succ,res = dbopt.game:transaction(function(trans)
		local res = trans:batchexec(sqls)
		return not res.errno,res
	end)
	
	if not succ then
		log.error("transfer_money_player2player do money error,err:%s",res and res.err or nil)
		return enum.ERROR_INTERNAL_UNKOWN
	end

	log.dump(res)

	local old_from_money = res[1] and res[1][1] and res[1][1].money or nil
	local new_from_money = res[3] and res[3][1] and res[3][1].money or nil
	local old_to_money = res[4] and res[4][1] and res[4][1].money or nil
	local new_to_money = res[6] and res[6][1] and res[6][1].money or nil

	local logsqls = {
		{
			[[
				INSERT INTO t_log_money(guid,money_id,old_money,new_money,`where`,reason,reason_ext,created_time) 
				VALUES(%d,%d,%d,%d,0,%d,'%s',%s);
			]],
			from_guid,money_id,old_from_money,new_from_money,why,why_ext,timer.milliseconds_time()
		},
		{
			[[
				INSERT INTO t_log_money(guid,money_id,old_money,new_money,`where`,reason,reason_ext,created_time) 
				VALUES(%d,%d,%d,%d,0,%d,'%s',%s);
			]],
			to_guid,money_id,old_to_money,new_to_money,why,why_ext,timer.milliseconds_time()
		},
	}

	log.dump(logsqls)
	res = dbopt.log:batchquery(logsqls)
	if res.errno then
		log.error("transfer_money_player2club insert log error,errno:%d,err:%s",res.errno,res.err)
		return enum.ERROR_INTERNAL_UNKOWN
	end

	return enum.ERROR_NONE,old_from_money,new_from_money,old_to_money,new_to_money
end

function on_sd_transfer_money(msg)
	local from_id = msg.from
	local to_id = msg.to
	local trans_type = msg.type
	local money_id = msg.money_id
	local amount = msg.amount
	local why = msg.why
	local why_ext = msg.why_ext

	if trans_type == 1 then
		return money_lock(transfer_money_club2player,from_id,to_id,money_id,amount,why,why_ext)
	end

	if trans_type == 2 then
		return money_lock(transfer_money_player2club,from_id,to_id,money_id,amount,why,why_ext)
	end

	if trans_type == 3 then
		return money_lock(transfer_money_club2club,from_id,to_id,money_id,amount,why,why_ext)
	end

	if trans_type == 4 then
		return money_lock(transfer_money_player2player,from_id,to_id,money_id,amount,why,why_ext)
	end

	return enum.ERROR_PARAMETER_ERROR
end

function on_sd_bind_phone(msg)
	local guid = msg.guid
	local phone = msg.phone
	dbopt.game:batchquery("UPDATE t_player SET phone = \"%s\" WHERE guid = %s;",phone,guid)
end

function on_sd_update_player_info(msg,guid)
	if 	(not guid or guid == 0) or
		(
			not msg.nickname and 
			not msg.icon and 
			not msg.phone and 
			not msg.promoter and
			not msg.channel_id and 
			not msg.platform_id and
			not msg.vip and 
			not msg.head_url and 
			not msg.status
		)
	then
		return
	end

	if msg.icon then
		msg.head_url = msg.icon
		msg.icon = nil
	end

	local sets = table.map(msg,function(v,f) 
		local fmtv = type(v) == "string" and "'%s'" or '%s'
		return string.format("%s = %s",f,fmtv),v
	end)

	local sql = string.format("UPDATE t_player SET %s  WHERE guid = %s;",table.concat(table.keys(sets),","),guid)
	log.dump(sql)
	local r = dbopt.game:query(sql,table.unpack(table.values(sets)))
	if r.errno then
		log.error("on_sd_update_player_info UPDATE t_player error,%s,%s",r.errno,r.err)
	end
end