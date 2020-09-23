-- 玩家数据消息处理

local pb = require "pb_files"
local log = require "log"
require "db.net_func"
local send2game_pb = send2game_pb
local send2login_pb = send2login_pb
local onlineguid = require "netguidopt"
local dbopt = require "dbopt"
local redisopt = require "redisopt"
local json = require "cjson"
local channel = require "channel"
local reddb = redisopt.default
local enum = require "pb_enums"
local queue = require "skynet.queue"
local timer = require "timer"

local money_lock = queue()

require "table_func"
local server_start_time =  os.time()

local md5 = require "md5"

local get_init_money = get_init_money
local get_init_regmoney = get_init_regmoney

local def_save_db_time = 60 -- 1分钟存次档
local def_offline_cache_time = 600 -- 离线玩家数据缓存10分钟

local GMmessageRetCode_ReChargeDBSetError = pb.enum("GMmessageRetCode", "GMmessageRetCode_ReChargeDBSetError")
local GMmessageRetCode_Success = pb.enum("GMmessageRetCode", "GMmessageRetCode_Success")


-- 存档到数据库
local function save_player(guid, info_)
	--除掉银行金币
	local info = {
		login_award_day = info_.login_award_day,
		login_award_receive_day = info_.login_award_receive_day,
		online_award_time = info_.online_award_time,
		online_award_num = info_.online_award_num,
		relief_payment_count = info_.relief_payment_count,
		level = info_.level,
		money = info_.money,
		header_icon = info_.header_icon,
		slotma_addition = info_.slotma_addition,
	}

	info.money = info.money or 0
	--info.bank = info.bank or 0

	local str = pb2string(info)
	local sql = "UPDATE t_player SET $FIELD$ WHERE guid=" .. guid .. ""
	str = string.gsub(sql, '%$FIELD%$', str)
	log.info(str)
	local ret = dbopt.game.execute(sql,info)
	if ret and ret.errno then
		log.error(ret.err)
	end
	print ("........................... save_player")
end

function on_SD_OnlineAccount(game_id, msg)
	dbopt.account:query("REPLACE INTO t_online_account SET guid=%d, first_game_type=%d, second_game_type=%d, game_id=%d, in_game=%d", 
		msg.guid, msg.first_game_type, msg.second_game_type, msg.gamer_id, msg.in_game)
end

function on_SD_Get_Instructor_Weixin(game_id, msg)
	local guid_ = msg.guid
	local weixin_sec = math.floor(get_instructor_weixin_sec() / 60) --取分钟数

	--------------------------------------------------------
	local sql = string.format([[select weixin from t_instructor_weixin]])
	log.info(sql)
	local data = dbopt.recharge:query(sql)
	if data.errno then
		log.error(data.err)
	end

	if #data > 0 then
		local x = #data
		local nmsg = {}
		nmsg.guid = guid_
		nmsg.instructor_weixin = {}
		if #data < 3 then
			for _,datainfo in ipairs(data) do
				table.insert(nmsg.instructor_weixin, datainfo.weixin)
			end
		else
			local t1 = os.time()
			local t2 = math.floor(math.abs(server_start_time - t1) / 60)
			log.info("t2[%d] weixin_sec[%d]  x[%d]", t2, weixin_sec,  x)
			local sendin = math.floor((math.floor(t2/weixin_sec) * 2) % x + 1)
			table.insert(nmsg.instructor_weixin, data[sendin].weixin)
			log.info("index A[%d]:%s", sendin,data[sendin].weixin)
			local sendin = math.floor((math.floor(t2/weixin_sec) * 2 + 1) % x + 1)
			table.insert(nmsg.instructor_weixin, data[sendin].weixin)
			log.info("index B[%d]:%s", sendin,data[sendin].weixin)
		end
		send2game_pb(game_id,"DS_Get_Instructor_Weixin",nmsg)
	else
		send2game_pb(game_id,"DS_Get_Instructor_Weixin",{
			guid = guid_,
			instructor_weixin = {},
		})
	end
	print("---------------------end")
end

-- 玩家退出
function on_s_logout(msg)
	-- 上次在线时间
	local db = dbopt.account
	local sql
	if msg.phone then
		sql = string.format([[UPDATE t_account SET login_time = FROM_UNIXTIME(%d), logout_time = FROM_UNIXTIME(%d),last_login_phone = '%s', 
			last_login_phone_type = '%s', last_login_version = '%s', last_login_channel_id = '%s', last_login_package_name = '%s', last_login_imei = '%s', last_login_ip = '%s' WHERE guid = %d;]],
			msg.login_time, msg.logout_time, msg.phone, msg.phone_type, msg.version, msg.channel_id, msg.package_name, msg.imei, msg.ip, msg.guid)
	else
		sql = string.format([[UPDATE t_account SET login_time = FROM_UNIXTIME(%d), logout_time = FROM_UNIXTIME(%d) WHERE guid = %d;]],
			msg.login_time, msg.logout_time, msg.guid)
	end
	local ret = db:query(sql)
	if ret.errno then
		log.error(ret.err)
	end

	-- 删除在线
	db:query("DELETE FROM t_online_account WHERE guid=%d", msg.guid)
end

function on_sd_delonline_player(game_id, msg)
	print ("on_sd_delonline_player........................... begin")
	dbopt.account:query("DELETE FROM t_online_account WHERE guid=%d and game_id=%d", msg.guid, msg.game_id)
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

	local data = dbopt.recharge:query(sql)
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

	local data = dbopt.recharge:query(sql)
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

	local data = dbopt.proxy:query("call cash_commission(%d,%d)",guid,money)
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
	local data = dbopt.game:query(sql)
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
	local data = dbopt.game:query(sql)
	if not data.errno and #data > 0 then
		for _,datainfo in ipairs(data) do
			print(datainfo)
			for i,info in pairs(datainfo) do
				print(i,info)
			end
		end
		--local msg = {
		--	pb_msg_data_info = data,
		--}
		--print("-----------------2")
		--redis_command(string.format("HSET player_Msg_info %d %s", guid_, to_hex(pb.encode("Msg_Data", msg))))
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
		local data = db:query(sql)
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
		local data = db:query(sql)
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
	local data = dbopt.account:query("SELECT * FROM t_channel_invite")
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

	local data = dbopt.game:query("CALL get_player_invite_reward(%d)",guid_)
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

function agent_transfer(guid_ ,gameid , data)
	local sqlAgent =  string.format([[select transfer_id,proxy_guid,transfer_money,transfer_type,proxy_before_money,
		proxy_after_money from t_Agent_recharge_order where player_guid = %d and proxy_status = 1 and player_status = 0 and created_at < now() - 1]] , guid_)
	log.info("Agent [%s]",sqlAgent)
	
	local dataAgent = dbopt.recharge:query(sqlAgent)
	if dataAgent and #dataAgent > 0 then
		local Ttotal = #dataAgent
		local Tnum = 0
		for _,Agentdatainfo in pairs(dataAgent) do
			Tnum = Tnum + 1
			local Tbefore_bank = tonumber(data.bank)
			log.info("guid[%d] transfer_id [%s] bef_bank[%d] addmoney[%d]" ,guid_, Agentdatainfo.transfer_id ,Tbefore_bank,Agentdatainfo.transfer_money)
			data.bank = Tbefore_bank + Agentdatainfo.transfer_money
			local Tafter_bank = tonumber(data.bank)
			log.info("guid[%d] transfer_id [%s] after_bank[%d] addmoney[%d]" ,guid_, Agentdatainfo.transfer_id ,Tafter_bank,Agentdatainfo.transfer_money)
			-- 更新 t_recharge_order

			local TsqlR = string.format([[update t_Agent_recharge_order set player_status = 1, player_before_money = %d, player_after_money = %d, updated_at = current_timestamp where  transfer_id = '%s']], Tbefore_bank, Tafter_bank, Agentdatainfo.transfer_id)
			log.info("sqlR:" ..TsqlR)
			local ret = dbopt.recharge:query(TsqlR)
			if ret and ret.errno then
				log.info(ret.err)
			end
			--插入金钱记录
			local log_money_type = enum.LOG_MONEY_OPT_TYPE_AGENTTOAGENT_MONEY
			if tonumber(Agentdatainfo.transfer_type) == 0 then
				log_money_type = enum.LOG_MONEY_OPT_TYPE_AGENTTOAGENT_MONEY
			elseif tonumber(Agentdatainfo.transfer_type) == 1 then
				log_money_type = enum.LOG_MONEY_OPT_TYPE_AGENTTOPLAYER_MONEY
			elseif tonumber(Agentdatainfo.transfer_type) == 2 then
				log_money_type = enum.LOG_MONEY_OPT_TYPE_PLAYERTOAGENT_MONEY
			elseif tonumber(Agentdatainfo.transfer_type) == 3 then
				log_money_type = enum.LOG_MONEY_OPT_TYPE_AGENTBANKTOPLAYER_MONEY
			end
			log.info("guid[%d] transfer_id[%s] transfer_type[%d] log_Type [%d]",guid_,Agentdatainfo.transfer_id,Agentdatainfo.transfer_type,log_money_type)
			-- 入代理商日志表
			local log_data = {
				pb_result = {
					AgentsID = Agentdatainfo.proxy_guid,
					PlayerID = guid_,
					transfer_id = Agentdatainfo.transfer_id,
					transfer_type = Agentdatainfo.transfer_type,
					transfer_money = Agentdatainfo.transfer_money,
				},
				retid = 1,
				a_oldmoney = Agentdatainfo.proxy_before_money,
				a_newmoney = Agentdatainfo.proxy_after_money,
				p_oldmoney = Tbefore_bank,
				p_newmoney = Tafter_bank,
			}
			on_ld_AgentTransfer_finish(1,log_data)
			
			-- 入金币流水日志表
			local log_money_={
				guid = guid_,
				old_money = data.money,
				new_money = data.money,
				old_bank =  Tbefore_bank,
				new_bank =  Tafter_bank,
				opt_type = log_money_type,
			}
			dbopt.log:execute("INSERT INTO t_log_money SET $FIELD$", log_money_)
			if Tnum ==  Ttotal then
				log.info("==========bank B:"..data.bank)
				--保存发送
				save_player(guid_, data)
				channel.publish("game."..tostring(gameid),"msg", "DS_LoadPlayerData", {
					guid = guid_,
					info_type = 1,
					pb_base_info = data,
				})
				channel.publish("game."..tostring(gameid),"msg", "DS_NotifyClientBankerChange", {
					guid = guid_,
					old_bank = Tbefore_bank,
					new_bank = Tafter_bank,
					change_bank = Tafter_bank - Tbefore_bank,
					log_type = log_money_type,
				})
			end
		end
	else
		log.info("==========bank B:"..data.bank)
		--保存发送
		save_player(guid_, data)
		channel.publish("game."..tostring(gameid),"msg", "DS_LoadPlayerData", {
			guid = guid_,
			info_type = 1,
			pb_base_info = data,
		})
	end
end

function  online_proc_recharge_order(guid_ ,gameid , data)		-- 该功能暂时未调用 ，根据线上反应 代理充值失败后 代理商可能会再给玩家补充 需要人工处理
	-- 查询未处理的订单
	local sqlT =  string.format([[ select id,exchange_gold,actual_amt,payment_amt,serial_order_no from t_recharge_order where pay_status = 1 and server_status ~= 1 and guid = %d]] , guid_)
	log.info("tttt %s",sqlT)
	local dataTR = dbopt.recharge:query(sqlT)
	if dataTR and #dataTR > 0 then
		local Ttotal = #dataTR
		local Tnum = 0
		for _,Tdatainfo in pairs(dataTR) do
			Tnum = Tnum + 1
			local Tbefore_bank = tonumber(data.bank)
			log.info("guid[%d] orderid [%d] bef_bank[%d] addmoney[%d]" ,guid_, Tdatainfo.id ,Tbefore_bank,Tdatainfo.exchange_gold)
			data.bank = Tbefore_bank + Tdatainfo.exchange_gold
			local Tafter_bank = tonumber(data.bank)
			log.info("guid[%d] orderid [%d] after_bank[%d] addmoney[%d]" ,guid_, Tdatainfo.id ,Tafter_bank,Tdatainfo.exchange_gold)
			-- 更新 t_recharge_order

			local TsqlR = string.format([[
					update t_recharge_order set server_status = 1, before_bank = %d, after_bank = %d where  id = '%d']], Tbefore_bank, Tafter_bank, Tdatainfo.id)
			log.info("sqlR:" ..TsqlR)
			local ret = dbopt.recharge:query(TsqlR)
			if ret and ret.errno then
				log.error(ret.err)
			end
			--消息通知
			local notify = {
				GmCommand = "MSG",
				data = string.format([[{"name":"%%E5%%85%%85%%E5%%80%%BC%%E6%%88%%90%%E5%%8A%%9F","type":1,"content":"{\"content_type\":1,\"status\":1,\"time\":\"%s\",\"money\":%s,\"actual_money\":%f,\"order\":\"%s\"}","author":"recharge","start_time":"%s","end_time":"%s","guid":%d}]],
				os.date("%Y-%m-%d %H:%M:%S",os.time()),
				tostring(Tdatainfo.payment_amt),
				Tdatainfo.actual_amt,
				Tdatainfo.serial_order_no,
				os.date("%Y-%m-%d %H:%M:%S",os.time()),
				os.date("%Y-%m-%d %H:%M:%S",
				os.time() + 24*3600 * 3),
				guid_
				)
			}
			log.info(notify.data)
			send2login_pb(1,"WL_GMMessage",notify)

			--插入金钱记录	
			local log_money_={
				guid = guid_,
				old_money = data.money,
				new_money = data.money,
				old_bank =  Tbefore_bank,
				new_bank =  Tafter_bank,
				opt_type = enum.LOG_MONEY_OPT_TYPE_RECHARGE_MONEY,
			}		
			dbopt.log:execute("INSERT INTO t_log_money SET $FIELD$", log_money_)
			if Tnum ==  Ttotal then
				agent_transfer(guid_ ,gameid , data)
			end
		end
	else
		agent_transfer(guid_ ,gameid , data)
	end
end

function  on_ld_recharge(msg)
	log.info("on_ld_recharge guid[%d]", msg.guid)
	local guid = msg.guid
	local notify = {
		guid = msg.guid,
		retid = msg.retid,
		asyncid = msg.asyncid,
	}
	proc_recharge_order(guid ,notify , 1)
end

function proc_recharge_order( guid_ , data , opttype ,last_login_channel_id )		-- opttype 为 1  在线充值 2离线充值
	query_player_is_or_not_collapse(guid_)

	-- 查询未处理的订单
	local sqlT =  string.format("call proc_recharge_order(%d)" , guid_)
	log.info("proc_recharge_order : %s" , sqlT)
	local dataTR = dbopt.recharge:query(sqlT)
	local bankmoney = 0
	local changemoney = 0
	if dataTR then
		dataTR = dataTR[1]
		print("==========================================================")
		log.info(dataTR.retdata)
		local rechargeData = json.decode(dataTR.retdata)
		if rechargeData and rechargeData.bank then
			bankmoney = rechargeData.bank
			log.info("guid [%d] bankmoney[%d]", guid_ , bankmoney)
		end
		if rechargeData and rechargeData.recharge then
			for _,v in pairs(rechargeData.recharge) do
				log.info(string.format("guid[%d] id[%d] exchange_gold[%d] actual_amt[%f] payment_amt[%f] serial_order_no[%s] oldbank[%d] newbank[%d]",
										guid_, v.id , v.exchange_gold , v.actual_amt , v.payment_amt , v.serial_order_no , v.oldbank , v.newbank))
				-- 写日志
				local log_money_={
					guid = guid_,
					old_money = 0,
					new_money = 0,
					old_bank =  v.oldbank,
					new_bank =  v.newbank,
					opt_type = enum.LOG_MONEY_OPT_TYPE_RECHARGE_MONEY,
					}
				
				dbopt.log:execute("INSERT INTO t_log_money SET $FIELD$", log_money_)
				-- 发私信
				local notify = {
					GmCommand = "MSG",
					data = string.format([[{"name":"%%E5%%85%%85%%E5%%80%%BC%%E6%%88%%90%%E5%%8A%%9F","type":1,"content":"{\"content_type\":1,\"status\":1,\"time\":\"%s\",\"money\":%s,\"actual_money\":%f,\"order\":\"%s\"}","author":"recharge","start_time":"%s","end_time":"%s","guid":%d}]],
					os.date("%Y-%m-%d %H:%M:%S",os.time()),
					tostring(v.payment_amt),
					v.actual_amt,
					v.serial_order_no,
					os.date("%Y-%m-%d %H:%M:%S",os.time()),
					os.date("%Y-%m-%d %H:%M:%S",
					os.time() + 24*3600 * 3),
					guid_
					)
				}
				log.info(notify.data)
				channel.publish("login.?","msg","WL_GMMessage",notify)
				changemoney = changemoney + v.exchange_gold
			end
		end
		if rechargeData and rechargeData.recash then
			for _,v in pairs(rechargeData.recash) do
				log.info("guid[%d] id[%d] exchange_gold[%d] opttype[%d] order_id[%d] oldbank[%d] newbank[%d]" , guid_ , v.id , v.exchange_gold , v.opttype , v.order_id , v.oldbank , v.newbank )
				-- 写日志
				local log_money_={
					guid = guid_,
					old_money = 0,
					new_money = 0,
					old_bank =  v.oldbank,
					new_bank =  v.newbank,
					opt_type = v.opttype,
					}
				
				dbopt.log:execute("INSERT INTO t_log_money SET $FIELD$", log_money_)
				-- 退钱不需要发送消息
			end
		end
		if rechargeData and rechargeData.save_back then
			for _,v in pairs(rechargeData.save_back) do
				-- 写日志
				local log_money_={
					guid = guid_,
					old_money = 0,
					new_money = 0,
					old_bank =  v.oldbank,
					new_bank =  v.newbank,
					opt_type = enum.LOG_MONEY_OPT_TYPE_SAVE_BACK,
					}
				dbopt.log:execute("INSERT INTO t_log_money SET $FIELD$", log_money_)
			end
		end
	end
	-- 返回结果
	if tonumber(opttype) == 1 then
		data.bank = bankmoney
		data.retcode = 0
		if bankmoney > 0 then
			data.retcode = 1
		end
		data.changemoney = changemoney
		log.info("player guid[%d] proc_recharge_order changemoney[%d]",guid_,changemoney)
		return data
	end
	
	if tonumber(opttype) == 2 then
		if bankmoney > 0 then
			data.bank = bankmoney
		end

		log.info("proc_recharge_order guid[%d] online proc finish bank is [%d]",guid_, data.bank)
		--保存发送
		save_player(guid_, data)
		channel.publish("game."..tostring(gameid_or_loginid),"msg", "DS_LoadPlayerData", {
			guid = guid_,
			info_type = 1,
			pb_base_info = data,
		})
		channel.publish("game."..tostring(gameid_or_loginid),"msg","",charge_rate(gameid_or_loginid , guid_ , last_login_channel_id))
		channel.publish("game."..tostring(gameid_or_loginid),"msg","",get_player_append_info(gameid_or_loginid , guid_))
	end
end

function charge_rate(gameid , guid , last_login_channel_id)
	if last_login_channel_id == nil then
		return
	end

	log.info("charge_rate gameid [%d] guid[%d]" , gameid, guid)
	local sqlT =  string.format("call charge_rate(%d,'%s')" , guid,last_login_channel_id)
	log.info("charge_rate : %s" , sqlT)
	local dataTR = dbopt.recharge:query(sqlT)
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

function get_player_append_info(gameid, guid) 
	log.info("get_player_append_info gameid [%d] guid[%d]" , gameid, guid)
	local sqlT =  string.format("call get_player_append_info(%d)" , guid)
	log.info("get_player_append_info : %s" , sqlT)
	local dataTR = dbopt.account:query(sqlT)
	if dataTR then
		dataTR = dataTR[1]
		log.info(string.format(
			"get_player_append_info guid[%d] seniorpromoter [%s] identity_type [%s] identity_param [%s] risk [%s] risk_show_proxy[%s] create_time[%s]"
			, guid
			, dataTR.seniorpromoter
			, dataTR.identity_type
			, dataTR.identity_param
			, dataTR.risk
			, dataTR.risk_show_proxy
			, dataTR.create_time
				))

		print("send end DS_Player_Append_Info")
		return {
			guid = guid,						                    -- 玩家ID
			seniorpromoter = tonumber(dataTR.seniorpromoter),		            -- 所属推广员
			identity_type = tonumber(dataTR.identity_type),		    -- 所属玩家身份 0 默认身份
			identity_param = tonumber(dataTR.identity_param),   	-- 所属身份附加参数
			risk = tonumber(dataTR.risk),                           -- 玩家危险等级
			risk_show_proxy = dataTR.risk_show_proxy,				-- 危险等级对应显示代理商策略概率
			create_time = dataTR.create_time,						-- 创建时间
		}
	end
end
-- 查询玩家数据
function on_sd_query_player_data(game_id, msg)
	-- 创建player
	local guid_ = msg.guid
	local account = msg.account
	local nick = msg.nickname
	local is_guest = (msg.is_guest == nil or msg.is_guest == false ) and true or false
	local platform_id = msg.platform_id
	local gameid = game_id

	-- 查询基本数据
	local l_add_money = get_init_money()
	local l_reg_money = get_init_regmoney()
	log.info("========guid [%d] is_guest[%s] player.platform_id = [%s]",guid_ , tostring(is_guest),platform_id)
	if is_guest then
		log.info("%d %d",get_init_money() , get_init_regmoney())
		l_add_money = get_init_money() + get_init_regmoney()
		l_reg_money = 0
	end

	
    local data_count = dbopt.account:query("call get_account_count(%d , '%s' )" , guid_ , platform_id)
	if not data_count then
		log.error("on_sd_query_player_data get_account_count not find guid: %d" , guid_)
		return
	end

	data_count = data_count[1]

	if data_count.retcode then
		log.info("%d call get_account_count ret %d",guid_, tonumber(data_count.retcode))
	end

	if data_count.retcode == nil or tonumber(data_count.retcode) == 0 then
		l_add_money = 0
		l_reg_money = 0
	end

	local last_login_channel_id = data_count.last_login_channel_id
	local is_guest_ = tonumber(data_count.is_guest)
	if is_guest_ == 2 then
		l_add_money = get_init_regmoney()
		l_reg_money = 0
	end

	local data = dbopt.game:query("CALL get_player_data(%d,'%s','%s',%d,'%s', %d, %d)",guid_,account,nick,l_add_money,platform_id,is_guest_,l_reg_money)
	if not data then
		log.error("on_sd_query_player_data not find guid: %d" , guid_)
		return
	end

	data = data[1]

	log.info("guid [%d] bank A: %d",guid_, data.bank)
	data.money = data.money or 0
	data.bank = data.bank or 0
	if is_guest_ == 2 then
		local sql = string.format("UPDATE t_account SET is_guest = 0 WHERE guid = %d",guid_ )
		db_execute(accountdb, sql)
	end

	return proc_recharge_order(guid_ ,gameid , data , 2, last_login_channel_id)
end

-- 保存玩家数据
function on_sd_save_player_data(game_id, msg)
	save_player(msg.guid, msg.pb_base_info)
end

-- 立即保存钱
function on_SD_SavePlayerMoney(game_id, msg)
	dbopt.game:query("UPDATE t_player SET money=" .. (msg.money or 0) .. " WHERE guid=" .. msg.guid .."")
end

-- 立即保存银行钱
function on_SD_SavePlayerBank(game_id, msg)	
	dbopt.game:query("UPDATE t_player SET bank=" .. (msg.bank or 0) .. " WHERE guid=" .. msg.guid .."")
end

-- 请求机器人数据
function on_sd_load_android_data(game_id, msg)
	local opttype = msg.opt_type
	local roomid = msg.room_id
	local data = dbopt.game:query("SELECT guid, account, nickname FROM t_player WHERE guid>%d AND is_android=1 ORDER BY guid ASC LIMIT %d", msg.guid, msg.count)

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
	local ret = dbopt.account:query(sql)
	if ret and ret.errno then 
		log.error(ret.err)
	end

	print("on_ld_AlipayEdit=============================================1")
	notify.EditNum = 1
	return notify
end

function  on_ld_do_sql( login_id, msg)
	-- body
	print("==============================================on_ld_do_sql============================================="..msg.database)
	local db = dbopt[msg.database] or dbopt.game

	local sql = msg.sql
	local notify = {
		retCode = 0,
		keyid = msg.keyid,
		retData = "",
		retid = msg.retid,
	}
	print(sql)

	local data = db:query(sql)
	if not data then
		notify.retCode = 9999
		notify.retData = "not Data"
		print("on_ld_do_sql faild :"..notify.retCode)
		return notify
	end

	data = data[1]

	print("******************ret:"..data.retCode)
	notify.retCode = data.retCode
	notify.retData = data.retData
	return notify
end

function send_user_transfer_msg(transfer_id,proxy_guid,player_guid,transfer_money)
	--查询代理商名字
    local data_ = dbopt.recharge:query("SELECT proxy_name FROM t_proxy_ad WHERE proxy_uid = %d",proxy_guid)
	if not data_ then
		log.error("send_user_transfer_msg  get agent name failed proxy_uid[%d]"  , proxy_guid)
		return
	end

	data_ = data_[1]
		--消息通知
	local notify = {
		GmCommand = "MSG",
		data = string.format([[{"name":"%%E5%%85%%85%%E5%%80%%BC%%E6%%88%%90%%E5%%8A%%9F","type":1,"content":"{\"content_type\":5,\"proxy_name\":\"%s\",\"status\":1,\"time\":\"%s\",\"money\":%f,\"order\":\"%s\"}","author":"recharge","start_time":"%s","end_time":"%s","guid":%d}]],
		data_.proxy_name,
		os.date("%Y-%m-%d %H:%M:%S",os.time()),
		transfer_money/100,
		transfer_id,
		os.date("%Y-%m-%d %H:%M:%S",os.time()),
		os.date("%Y-%m-%d %H:%M:%S",os.time() + 24*3600 * 3),
		player_guid
		)
	}
	return notify
end

function on_sd_agent_transfer_success(game_id , msg)
 	-- body
    log.info("on_sd_agent_transfer_success : guid [%d]",msg.player_guid)
    log.info("on_sd_agent_transfer_success : transfer_id [%s]",msg.transfer_id)
    log.info("on_sd_agent_transfer_success : player_oldmoney [%s]",tostring(msg.player_oldmoney))
    log.info("on_sd_agent_transfer_success : player_newmoney [%s]",tostring(msg.player_newmoney))
    
    
 	log.info(string.format("on_sd_agent_transfer_success : guid [%d] transfer_id[%s] oldmoney[%s] newmoney[%s] transfer_type[%d]"
		,msg.player_guid,msg.transfer_id,tostring(msg.player_oldmoney),tostring(msg.player_newmoney),msg.transfer_type))
 	local db_recharge = get_recharge_db()
	
	local player_status = 1 --success
 	local sql_set_order_status = string.format("CALL update_AgentTransfer_Order('%s' , %d , %d , %d , %d )",msg.transfer_id, 2 , player_status , msg.player_oldmoney , msg.player_newmoney)
	log.info(sql_set_order_status)

	local data = dbopt.recharge:query(sql_set_order_status)
	if not data or data.errno then
		log.error("on_sd_agent_transfer_success update status faild : transfer_id:[%s] opt_type[%d]" ,msg.transfer_id, 2)
		return
	end

	data = data[1]

	log.info("on_sd_agent_transfer_success db_execute_query transfer_id [%s]  data.ret [%d]",msg.transfer_id,data.ret)
	if tonumber(data.ret) ~= 1 then
		log.error(string.format("on_sd_agent_transfer_success error : proxy_guid[%d] guid [%d] transfer_id[%s] transfer_money[%d] data.ret [%d] player_oldmoney[%s] player_newmoney[%s] agents_old_bank[%s] agents_new_bank[%s]"
	,msg.proxy_guid,msg.player_guid,msg.transfer_id,msg.transfer_money,data.ret,tostring(msg.player_oldmoney),tostring(msg.player_newmoney),tostring(msg.proxy_oldmoney),tostring(msg.proxy_newmoney)))
		return
	else --success
		local notify = {
				pb_result = {
					AgentsID = msg.proxy_guid,
					PlayerID = msg.player_guid,
					transfer_id = msg.transfer_id,
					transfer_type = msg.transfer_type,
					transfer_money = msg.transfer_money,
				},
				retid = 1,
				a_oldmoney = msg.proxy_oldmoney,
				a_newmoney = msg.proxy_newmoney,
				p_oldmoney = msg.player_oldmoney,
				p_newmoney = msg.player_newmoney,
		}

		on_ld_AgentTransfer_finish( 1, notify)

		--给玩家发送私信
		send_user_transfer_msg(msg.transfer_id,msg.proxy_guid,msg.player_guid,msg.transfer_money)

		log.info(string.format("on_sd_agent_transfer_success success : proxy_guid[%d] guid [%d] transfer_id[%s] transfer_money[%d] data.ret [%d] player_oldmoney[%s] player_newmoney[%s] agents_old_bank[%s] agents_new_bank[%s]"
	,msg.proxy_guid,msg.player_guid,msg.transfer_id,msg.transfer_money,data.ret,tostring(msg.player_oldmoney),tostring(msg.player_newmoney),tostring(msg.proxy_oldmoney),tostring(msg.proxy_newmoney)))
		return
	end		
 end 

function add_player_money(notify ,proxy_before_money,  proxy_after_money)
	log.info("==============add_player_money")
	log.info(string.format("add_player_money : proxy_guid [%d] player_guid [%d] transfer_id [%s] transfer_type [%d] transfer_money[%d]" , 
		notify.proxy_guid, notify.player_guid, notify.transfer_id, notify.transfer_type, notify.transfer_money))
	-- 订单生成成功 开始扣减代理商金币
	local sql_csot_agent_money = string.format("CALL change_player_bank_money(%d, %d,0)",notify.player_guid, notify.transfer_money)
	log.info(sql_csot_agent_money)
	local data = dbopt.game:query(sql_csot_agent_money)
	if not data or data.errno then
		notify.retcode = 28 -- 数据库错误 无法 扣减代理商金币 
		log.error("add_player_money  mysql faild :[%d]  transfer_id[%s],%s"  , notify.retcode, notify.transfer_id,data.err)
	else
		data = data[1]
		log.info("add_player_money transfer_id [%s]  data.ret [%d]",notify.transfer_id,data.ret)
		if tonumber(data.ret) ~= 1 then  -- 2 代理商金币不足 4 代理商金币为空 5 update 代理商金币失败
			log.info("add_player_money faild ,data.ret[%d] [%d]",data.ret,notify.retcode)
		else
			log.info("transfer_id [%s] add_player_money is ok",notify.transfer_id)
			notify.oldmoney = data.oldbank
			notify.newmoney = data.newbank

			-- 入金币流水日志表
			local log_money_type = enum.LOG_MONEY_OPT_TYPE_AGENTTOAGENT_MONEY
			if tonumber(notify.transfer_type) == 0 then
				log_money_type = enum.LOG_MONEY_OPT_TYPE_AGENTTOAGENT_MONEY
			elseif tonumber(notify.transfer_type) == 1 then
				log_money_type = enum.LOG_MONEY_OPT_TYPE_AGENTTOPLAYER_MONEY
			elseif tonumber(notify.transfer_type) == 2 then
				log_money_type = enum.LOG_MONEY_OPT_TYPE_PLAYERTOAGENT_MONEY
			elseif tonumber(notify.transfer_type) == 3 then
				log_money_type = enum.LOG_MONEY_OPT_TYPE_AGENTBANKTOPLAYER_MONEY
			end
			log.info("add_player_money transfer_id [%s] log_money_type is [%d]",notify.transfer_id,log_money_type)
			local log_money_= {
				guid = notify.player_guid,
				old_money = 0,
				new_money = 0,
				old_bank =  notify.oldmoney,
				new_bank =  notify.newmoney,
				opt_type = log_money_type,
			}
			dbopt.log:execute("INSERT INTO t_log_money SET $FIELD$", log_money_)
		end
		notify.retcode = data.ret
	end
	-- 更新状态
	update_agent_order(2 ,notify, notify.retcode , proxy_before_money , proxy_after_money)
end

function update_agent_order(opt_type, notify , code , proxy_before_money ,proxy_after_money )
	log.info(string.format("update_agent_order : proxy_guid [%d] player_guid [%d] transfer_id [%s] transfer_type [%d] transfer_money[%d] agent_oldmoney[%d] agent_newmoney[%d] code[%d]" , 
		notify.proxy_guid, notify.player_guid, notify.transfer_id, notify.transfer_type, notify.transfer_money, notify.oldmoney , notify.newmoney, code))
	-- 更新订单状态
	local sql_update_order = string.format("CALL update_AgentTransfer_Order('%s' , %d , %d , %d , %d )",notify.transfer_id, opt_type , code , notify.oldmoney , notify.newmoney)
	log.info(sql_update_order)
	-- 下面 前缀 1 与 9 的区别 1 表示 db 报错 9 表示 存储过程 检校报错
	local data = dbopt.recharge:query(sql_update_order)
	if not data then
		-- 11 需要注意 表示 代理商金币扣减成功 opt_type 
			-- 1 表示代理商扣钱操作  原来 11 表示代理商扣钱成功 但更新代理商状态失败 现在变为  111 表示上述意思
			-- 2 表示玩家加钱操作    211 表示玩家加钱成功 更新状态失败 （这种情况 仅限代理商与代理商转账）
		notify.retcode = 10 + code + (opt_type * 100)  
		log.error("update_agent_order faild : [%d]  transfer_id:[%s] opt_type[%d]" ,notify.retcode , notify.transfer_id , opt_type)
		return notify
	end

	data = data[1]

	log.info("update_agent_order transfer_id [%s]  data.ret [%d] opt_type[%d]",notify.transfer_id,data.ret , opt_type)
	if tonumber(data.ret) ~= 1 then
		-- 91 需要注意 表示 代理商金币扣减成功 opt_type 1 表示代理商扣钱操作  2 表示玩家加钱操作 原来 11 表示代理商扣钱成功 但更新代理商状态失败 现在变为  111 表示上述意思  211 表示玩家加钱成功 更新状态失败 （这种情况 仅限代理商与代理商转账）
		notify.retcode = 90 + code + (opt_type * 100)-- 91 需要注意 表示 代理商金币扣减成功
		log.error("update_agent_order faild : [%d]  transfer_id:[%s] opt_type[%d] retcode [%d]" ,notify.retcode , notify.transfer_id , opt_type , notify.retcode)
		return notify
	end

	if tonumber(notify.transfer_type) ~= 0 then
		log.info("update_agent_order ok : [%d]  transfer_id:[%s] opt_type[%d]" ,notify.retcode , notify.transfer_id , opt_type)
		notify.retcode = code
		return notify
	end

	if tonumber(opt_type) == 2 then
		local log_data = {
			pb_result = {
				AgentsID = notify.proxy_guid,
				PlayerID = notify.player_guid,
				transfer_id = notify.transfer_id,
				transfer_type = notify.transfer_type,
				transfer_money = notify.transfer_money,
			},
			retid = 1,
			a_oldmoney = proxy_before_money,
			a_newmoney = proxy_after_money,
			p_oldmoney = notify.oldmoney,
			p_newmoney = notify.newmoney,
		}
		on_ld_AgentTransfer_finish(1,log_data)
		
		log.info("update_agent_order ok : [%d]  transfer_id:[%s] opt_type[%d]" ,notify.retcode , notify.transfer_id , opt_type)
		notify.retcode = code
		return notify
	end

	if tonumber(code) == 1 then
		local proxy_before_money = notify.oldmoney
		local proxy_after_money = notify.newmoney
		add_player_money(notify ,proxy_before_money,  proxy_after_money)
	else
		log.info("update_agent_order ok : [%d]  transfer_id:[%s] opt_type[%d]" ,notify.retcode , notify.transfer_id , opt_type)
		notify.retcode = code
		return notify
	end
end

function cost_agent_money(notify)
	log.info("==============cost_agent_money")
	log.info(string.format("cost_agent_money : proxy_guid [%d] player_guid [%d] transfer_id [%s] transfer_type [%d] transfer_money[%d]" , 
		notify.proxy_guid, notify.player_guid, notify.transfer_id, notify.transfer_type, notify.transfer_money))
	-- 订单生成成功 开始扣减代理商金币
	local sql_csot_agent_money = string.format("CALL change_player_bank_money(%d, %d,0)",notify.proxy_guid, -1 * notify.transfer_money)
	log.info(sql_csot_agent_money)
	local data = dbopt.game:query(sql_csot_agent_money)
	if not data then
		notify.retcode = 8 -- 数据库错误 无法 扣减代理商金币 
		log.info("cost_agent_money  mysql faild :[%d]  transfer_id[%s]"  , notify.retcode, notify.transfer_id)
	else
		data = data[1]
		log.info("cost_agent_money transfer_id [%s]  data.ret [%d]",notify.transfer_id,data.ret)
		if tonumber(data.ret) ~= 1 then  -- 2 代理商金币不足 4 代理商金币为空 5 update 代理商金币失败
			log.info("cost_agent_money faild ,data.ret[%d] [%d]",data.ret,notify.retcode)
			-- send2login_pb(login_id, "DL_CC_ChangeMoney",notify)
			-- return
		else
			log.info("transfer_id [%s] cost_agent_money is ok",notify.transfer_id)
			notify.oldmoney = data.oldbank
			notify.newmoney = data.newbank

			-- 入金币流水日志表
			local log_money_type = enum.LOG_MONEY_OPT_TYPE_AGENTTOAGENT_MONEY
			if tonumber(notify.transfer_type) == 0 then
				log_money_type = enum.LOG_MONEY_OPT_TYPE_AGENTTOAGENT_MONEY
			elseif tonumber(notify.transfer_type) == 1 then
				log_money_type = enum.LOG_MONEY_OPT_TYPE_AGENTTOPLAYER_MONEY
			elseif tonumber(notify.transfer_type) == 2 then
				log_money_type = enum.LOG_MONEY_OPT_TYPE_PLAYERTOAGENT_MONEY
			elseif tonumber(notify.transfer_type) == 3 then
				log_money_type = enum.LOG_MONEY_OPT_TYPE_AGENTBANKTOPLAYER_MONEY
			end
			log.info("cost_agent_money transfer_id [%s] log_money_type is [%d]",notify.transfer_id,log_money_type)
			local log_money_= {
				guid = notify.proxy_guid,
				old_money = 0,
				new_money = 0,
				old_bank =  notify.oldmoney,
				new_bank =  notify.newmoney,
				opt_type =  log_money_type,
			}
			dbopt.log:execute("INSERT INTO t_log_money SET $FIELD$", log_money_)
		end
		notify.retcode = data.ret
	end
	-- 更新状态
	update_agent_order(1 ,notify, notify.retcode)
end


function do_ld_cc_changemoney(msg, platform_id,channel_id,seniorpromoter)
	log.info("==============================================on_ld_cc_changemoney=============================================")

	local notify = {
		proxy_guid  	=	msg.proxy_guid  	,							-- 代理商guid
		player_guid 	=	msg.player_guid 	,							-- 玩家guid
		transfer_money 	=	msg.transfer_money	,							-- 金钱
		transfer_type  	=	msg.transfer_type 	,							-- 参数
		transfer_id   	=	msg.transfer_id   	,							-- id
		keyid 		  	=	msg.keyid 		  	,							-- 结果处理函数存储id
		retid         	=	msg.retid         	,							-- 会话sessionid
		login_id      	=	msg.login_id   		,							-- loginid
		retcode 	  	=	0		 	  		,							-- 处理结果
		oldmoney 	  	=	0		 	  		,							-- 修改前moeny
		newmoney 	  	=	0		 	  		,							-- 修改后money
	}

	log.info(string.format("on_ld_cc_changemoney : proxy_guid [%d] player_guid [%d] transfer_id [%s] transfer_type [%d] transfer_money[%d] platform_id[%s] channel_id[%s] seniorpromoter[%d]", 
		notify.proxy_guid, notify.player_guid, notify.transfer_id, notify.transfer_type, notify.transfer_money,platform_id,channel_id,seniorpromoter))
	-- 生成订单
	local sql_create_order  = string.format("CALL insert_AgentTransfer_Order( '%s' , %d , %d , %d , %d , '%s', '%s' , %d)",
		msg.transfer_id, msg.proxy_guid, msg.player_guid, msg.transfer_type, msg.transfer_money, platform_id, channel_id, seniorpromoter)
	log.info(sql_create_order)
	local data = dbopt.recharge:query(sql_create_order)
	log.info("===============================1")
	if not data then
		log.info("===============================2")
		notify.retcode = 5 -- 数据库错误无法创建订单
		log.info("on_ld_cc_changemoney faild : %d" ,notify.retcode)
		return notify
	end

	data = data[1]

	log.info("on_ld_cc_changemoney transfer_id [%s]  data.ret [%d]",msg.transfer_id,data.ret)
	if tonumber(data.ret) == 0 then
		notify.retcode = 6 -- 存储过程错误 insert失败
		log.info("on_ld_cc_changemoney faild : %d" ,notify.retcode)
		return notify
	end

	if tonumber(data.ret) == 2 then
		notify.retcode = 7 -- 订单重复
		log.info("on_ld_cc_changemoney faild : %d" ,notify.retcode)
		return notify
	end
	
	if tonumber(data.ret) == 1 then
		cost_agent_money(notify)
	end
end

function on_ld_cc_changemoney(msg)
	local db_account = dbopt.account

	local notify = {
		proxy_guid  	=	msg.proxy_guid  	,							-- 代理商guid
		player_guid 	=	msg.player_guid 	,							-- 玩家guid
		transfer_money 	=	msg.transfer_money	,							-- 金钱
		transfer_type  	=	msg.transfer_type 	,							-- 参数
		transfer_id   	=	msg.transfer_id   	,							-- id
		keyid 		  	=	msg.keyid 		  	,							-- 结果处理函数存储id
		retid         	=	msg.retid         	,							-- 会话sessionid
		login_id      	=	msg.login_id   		,							-- loginid
		retcode 	  	=	0		 	  		,							-- 处理结果
		oldmoney 	  	=	0		 	  		,							-- 修改前moeny
		newmoney 	  	=	0		 	  		,							-- 修改后money
	}

	--判断平台是否相同，平台不同返回为找不到玩家
	local data  = dbopt.account:query("SELECT platform_id,channel_id,ifnull(seniorpromoter,0) as seniorpromoter FROM t_account WHERE guid = %d", msg.player_guid)
	data = data[1]
	if not data then
		notify.retcode = 7 --db error
		log.info("get_platform_id faild transfer_id[%s] proxy_guid[%d] player_guid[%d]" ,notify.transfer_id,msg.proxy_guid, msg.player_guid)
		return notify
	end

	log.info("on_ld_cc_changemoney get_platform_id [%s] channel_id [%s] seniorpromoter [%d]",data.platform_id,data.channel_id,data.seniorpromoter)
	do_ld_cc_changemoney(msg,data.platform_id,data.channel_id,data.seniorpromoter)
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
	local data = dbopt.game:query("CALL del_msg(%d, %d)",msg.msg_id, msg.msg_type)
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

function on_ld_AgentTransfer_finish( login_id, msg)
	-- body
	log.info("=======================on_ld_AgentTransfer_finish===================================")
	sql = string.format([[insert into t_AgentsTransfer_tj (  `agents_guid`,  `player_guid`,  `transfer_id`,  `transfer_type`,  `transfer_money`,  `transfer_status`,`agents_old_bank`,  `agents_new_bank`,  `player_old_bank`,  `player_new_bank`) values(%d, %d,'%s', %d, %d, %d, %d, %d, %d, %d)]],
		msg.pb_result.AgentsID,
		msg.pb_result.PlayerID,
		msg.pb_result.transfer_id,
		msg.pb_result.transfer_type,
		msg.pb_result.transfer_money,
		msg.retid,
		msg.a_oldmoney,
		msg.a_newmoney,
		msg.p_oldmoney,
		msg.p_newmoney)
	log.info(sql)
	dbopt.log:query(sql)
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
	local ret = dbopt.game:query(sql)[1]
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
	dbopt.game:query(sql)
end

-- 请求百人牛牛基础数据
function on_sd_query_Ox_config_data(game_id, msg)
	print(string.format("on_sd_query_Ox_config_data game_id = [%d],curtime = [%d]",game_id,msg.cur_time))
	local data = dbopt.game:query(
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

function on_sd_recharge(gameid,msg)
	log.info("on_sd_recharge begin ------- guid[%d] orderid[%d] bef_bank[%d] aft_bank[%d] login[%d]",msg.guid,msg.orderid,msg.befor_bank,msg.after_bank,msg.loginid)
	local db = get_recharge_db()
	local loginid = msg.loginid
	local sql = string.format([[call update_recharge_order(%d,%d,%d)]], msg.orderid, msg.befor_bank, msg.after_bank)
	log.info("sql:" ..sql)
	local notify = {
		guid = msg.guid,
		retid = msg.retid,
		orderid = msg.orderid,
		retcode = GMmessageRetCode_ReChargeDBSetError,
	}
	local aft_bank = msg.after_bank
	local bef_bank = msg.befor_bank

	local data = dbopt.recharge:query(sql)
	if not data then
		notify.retcode = GMmessageRetCode_ReChargeDBSetError
		log.info(string.format("on_sd_recharge dberror guid[%d] orderid[%d] bef_bank[%d] aft_bank[%d]",notify.guid,notify.orderid,bef_bank,aft_bank))			
		channel.publish("login."..tostring(loginid),"msg", "DL_ReCharge",notify)
		return
	end

	data = data[1]
	
	if tonumber(data.retCode) == 0 then
		log.info("on_sd_recharge success guid[%d] orderid[%d] bef_bank[%d] aft_bank[%d]",notify.guid,notify.orderid,bef_bank,aft_bank)
		notify.retcode = GMmessageRetCode_Success
	else			
		log.info("on_sd_recharge db faild guid[%d] orderid[%d] bef_bank[%d] aft_bank[%d] ret [%d]",notify.guid,notify.orderid,bef_bank,aft_bank,data.retCode)
	end
	log.info("DL_ReCharge loginid[%d]",loginid)
	channel.publish("login."..tostring(loginid),"msg", "DL_ReCharge",notify)
end

--提现失败，归还金币到银行
function cash_failed_back_bankMoney(guid_,back_bank_money,error_code)
	log.info("cash_failed_back_bankMoney guid_[%d],back_bank_money[%d]",guid_,back_bank_money)

	local data = dbopt.game:query([[call change_player_bank_money(%d,%d,0)]], guid_,back_bank_money)
	if not data then
		log.error("cash_failed_back_bankMoney failed")
		return
	end

	data = data[1]

	local msg = {
		guid = guid_,
		result = error_code,
		real_bank_cost = 0,
		old_bank = data.oldbank,
		new_bank = data.newbank
	}
	log.info("cash_failed_back_bankMoney guid_[%d],old_bank[%d] new_bank[%d]",guid_,data.oldbank,data.newbank)
	return msg
end


--扣除银行金币成功，插入提现记录
function do_WithDrawCash_Success(game_id,msg,oldbank,newbank)

	local guid_ = msg.guid
	--提现扣除的金币
	local coins_ = msg.money
	--给玩家的钱
	local money_ = msg.money / 100

	--扣除手续费给玩家的钱
	local pay_money_ =  0
	if money_  < 150 then
		pay_money_ = money_ - 2
	else
		pay_money_ = money_ - money_ * 0.02
	end
	local ip_ = msg.ip
	local phone_ = msg.phone
	local phone_type_ = msg.phone_type
	local bag_id_ = msg.bag_id
	local bef_money_ = msg.bef_money
	local aft_money_ = msg.aft_money
	local bef_bank_ = oldbank
	local aft_bank_ = newbank
	local cash_type_ = msg.cash_type
	local platform_id_ = msg.platform_id

	local data = dbopt.account:query([[
		select channel_id as bag_id_ from t_account where guid = %d]], 
		guid_)

	bag_id_ = data[1].bag_id_

	local sql = string.format([[
	CALL insert_cash_money(%d,%d,%d,%d,'%s','%s','%s','%s', %d, %d, %d, %d ,%d,0,'%s', %d)
	]], guid_, money_, coins_, pay_money_, ip_, phone_, phone_type_, bag_id_, bef_money_, bef_bank_, aft_money_, aft_bank_,cash_type_,platform_id_,msg.seniorpromoter)

	log.info("sql [%s]",sql)
	data = dbopt.recharge:query(sql)
	if not data then
		log.error("on_sd_cash_money:" .. sql)
		--退还扣除所有的金币
		return cash_failed_back_bankMoney(game_id,guid_,coins_,6)
	end

	data = data[1]

	if data.order_id and data.order_id ~= 0 then
		--创建订单成功
		local smd5 =  md5.sumhexa(string.format("order_id=%s%s",data.order_id, db_cfg.php_interface_addr))
		local host,url = db_cfg.cash_money_addr:match "(https?://[^/]+)(.*)"
		httpc.post(host,url,string.format("{\"order_id\":\"%s\", \"cash_type\":\"%d\", \"sign\":\"%s\"}",data.order_id, msg.cash_type, smd5))

		local nmsg = {
			guid = guid_,
			result = 1,
			real_bank_cost = msg.cost_bank,
			old_bank = bef_bank_,
			new_bank = aft_bank_
		}
		return nmsg
	end

	log.error("do_WithDrawCash_Success error guid [%d]",guid_)
	--退还扣除所有的金币
	return cash_failed_back_bankMoney(game_id,guid_,coins_,6)
end

function on_SD_WithDrawCash(game_id , msg)
	log.info("on_SD_WithDrawCash begin ------- guid[%d] cost_money[%d] cost_bank[%d] seniorpromoter[%d]",msg.guid,msg.cost_money,msg.cost_bank,msg.seniorpromoter)

	--扣除银行0的时候也调用可以查询出最新的银行金币
	local sql = string.format([[call change_player_bank_money(%d,%d,0)]], msg.guid, -msg.cost_bank)
	log.info(sql)

	local data = dbopt.game:query(sql)
	if not data then
		--退还之前扣除的金币
		return cash_failed_back_bankMoney(game_id,msg.guid,msg.cost_money,6)
	end

	data = data[1]
	
	if tonumber(data.ret) == 1 then
		--成功
		return do_WithDrawCash_Success(game_id,msg,data.oldbank,data.newbank)
	else
		--退还之前扣除的金币	
		return cash_failed_back_bankMoney(game_id,msg.guid,msg.cost_money,data.ret)
	end
end

function do_agent_addplayer_money_sucess(msg,oldbank,newbank)
 	log.info("do_agent_addplayer_money_sucess : guid [%d] transfer_id[%s] transfer_type[%d]",msg.player_guid,msg.transfer_id,msg.transfer_type)

	local player_status = 1 --success
 	local sql_set_order_status = string.format("CALL update_AgentTransfer_Order('%s' , %d , %d , %d , %d )",msg.transfer_id, 2 , player_status ,oldbank, newbank)
	log.info(sql_set_order_status)

	local data = dbopt.recharge:query(sql_set_order_status)
	if not data or data.errno then
		log.error("on_sd_agent_transfer_success update status faild : transfer_id:[%s] opt_type[%d]" ,msg.transfer_id, 2)
		return
	end

	data = data[1]

	log.info("on_sd_agent_transfer_success db_execute_query transfer_id [%s]  data.ret [%d]",msg.transfer_id,data.ret)
	if tonumber(data.ret) ~= 1 then
		log.error(string.format("on_sd_agent_transfer_success error : proxy_guid[%d] guid [%d] transfer_id[%s] transfer_money[%d] data.ret [%d] player_oldmoney[%d] player_newmoney[%d] agents_old_bank[%s] agents_new_bank[%s]"
		,msg.proxy_guid,msg.player_guid,msg.transfer_id,msg.transfer_money,data.ret,oldbank,newbank,tostring(msg.proxy_oldmoney),tostring(msg.proxy_newmoney)))
		return
	else --success
		local notify = {
				pb_result = {
					AgentsID = msg.proxy_guid,
					PlayerID = msg.player_guid,
					transfer_id = msg.transfer_id,
					transfer_type = msg.transfer_type,
					transfer_money = msg.transfer_money,
				},
				retid = 1,
				a_oldmoney = msg.proxy_oldmoney,
				a_newmoney = msg.proxy_newmoney,
				p_oldmoney = oldbank,
				p_newmoney = newbank,
		}

		on_ld_AgentTransfer_finish(1, notify)

		--给玩家发送私信
		send_user_transfer_msg(msg.transfer_id,msg.proxy_guid,msg.player_guid,msg.transfer_money)

		log.info(string.format("on_sd_agent_transfer_success success : proxy_guid[%d] guid [%d] transfer_id[%s] transfer_money[%d] data.ret [%d] player_oldmoney[%d] player_newmoney[%d] agents_old_bank[%s] agents_new_bank[%s]"
		,msg.proxy_guid,msg.player_guid,msg.transfer_id,msg.transfer_money,data.ret,oldbank,newbank,tostring(msg.proxy_oldmoney),tostring(msg.proxy_newmoney)))
		return
	end		
end

function notify_agent_addmoney(login_id,msg,oldbank,newbank,ret)
	return {
		result 	     = ret,	
		proxy_guid   = msg.proxy_guid,
		player_guid  = msg.player_guid,
		transfer_id  = msg.transfer_id,
		transfer_type= msg.transfer_type,
		old_bank 	 = oldbank,
		new_bank 	 = newbank,
	}
end

function on_LD_AgentAddPlayerMoney(login_id,msg)
	query_player_is_or_not_collapse(msg.player_guid)
	
	log.info(string.format("on_LD_AgentAddPlayerMoney begin ------- player_guid[%d] proxy_guid[%d] transfer_id[%s] transfer_type[%d]  transfer_money[%d] transfer_status[%d]",
		msg.player_guid,msg.proxy_guid,msg.transfer_id,msg.transfer_type,msg.transfer_money,msg.transfer_status))

	--添加银行0的时候也调用可以查询出最新的银行金币
	local sql = string.format([[call change_player_bank_money(%d,%d,0)]], msg.player_guid,msg.transfer_money)
	log.info(sql)

	local data = dbopt.game:query(sql)
	if not data then
		log.error("on_LD_AgentAddPlayerMoney failed player_guid[%d] proxy_guid[%d] transfer_id[%s]",msg.player_guid,msg.proxy_guid,msg.transfer_id)
		return notify_agent_addmoney(login_id,msg,0,0,3)
	end

	data = data[1]
	
	if tonumber(data.ret) == 1 then
		--成功
		do_agent_addplayer_money_sucess(msg,data.oldbank,data.newbank)
		return notify_agent_addmoney(login_id,msg,data.oldbank,data.newbank,data.ret)
	else
		log.error("on_LD_AgentAddPlayerMoney failed player_guid[%d] proxy_guid[%d] transfer_id[%s]",msg.player_guid,msg.proxy_guid,msg.transfer_id)
		return notify_agent_addmoney(login_id,msg,data.oldbank,data.newbank,data.ret)
	end
end

--查询玩家是否破产
function query_player_is_or_not_collapse(guid_)
	-- body
	if guid_ > 0 then
		local sql =  string.format("call judge_player_is_collapse(%d)" , guid_)

		local data = dbopt.game:query(sql)
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

	local ret = dbopt.account:query(sql)
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

	local reply = dbopt.account:query(string.format( "CALL verify_account(\"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\")",
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
		local sql = string.format([[INSERT INTO `log`.`t_log_login` (`guid`, `login_phone`, `login_phone_type`, `login_version`, `login_channel_id`, `login_package_name`, `login_imei`, `login_ip`, `channel_id` , `is_guest` , `create_time` , `register_time`, `deprecated_imei` , `platform_id` , `seniorpromoter`),
			VALUES('%d', '%s', '%d', '%s', '%s', '%s', '%s', '%s', '%s' ,'%d' ,FROM_UNIXTIME('%d'), if ('%d'>'0', FROM_UNIXTIME('%d'), null) ,'%s' , '%s' , '%d')]],
			reply.guid , phone ,phone_type ,version ,channelid ,package_name ,imei ,ip ,reply.channel_id , reply.is_guest , reply.create_time, reply.register_time, deprecated_imei , platform_id , reply.seniorpromoter)

		log.info(sql)
		dbopt.account:query(sql)
	else
		-- 维护中
	end

	reply.account = account
	reply.platform_id = platform_id

	return reply
end

function on_ld_reg_account(msg)
	log.dump(msg)

	local transqls = {
		string.format([[INSERT INTO account.t_account(guid,account,nickname,level,last_login_ip,openid,head_url,create_time,login_time,
						register_time,ip,version,phone_type,package_name,phone) 
						VALUES(%d,'%s','%s','%s','%s','%s','%s',NOW(),NOW(),NOW(),'%s','%s','%s','%s','%s');]],
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
			msg.package_name or "",
			msg.phone or ""),
		string.format([[INSERT INTO game.t_player(guid,account,nickname,level,head_url,phone,promoter,channel_id,created_time) VALUES(%d,'%s','%s','%s','%s','%s',%s,'%s',NOW());]],
			msg.guid,
			msg.account,
			msg.nickname,
			msg.level,
			msg.icon,
			msg.phone or "",
			msg.promoter or "NULL",
			msg.channel_id or ""),
		string.format([[INSERT INTO game.t_player_money(guid,money_id) VALUES(%d,%d),(%d,%d);]],msg.guid,enum.ROOM_CARD_ID,msg.guid,-1),
		string.format([[INSERT INTO log.t_log_login(guid,login_version,login_phone_type,login_ip,login_time,create_time,register_time,platform_id,login_phone)
				VALUES(%d,'%s','%s','%s',NOW(),NOW(),NOW(),'%s','%s');]],
			msg.guid,
			msg.version,
			msg.phone_type or "unkown",
			msg.ip,
			msg.platform_id or "",
			msg.phone or ""),
	}

	local res = dbopt.game:query(table.concat(transqls,"\n"))
	if res.errno then
		log.error("on_ld_reg_account insert into t_account throw exception.[%d],[%s]",res.errno,res.err)
		return
	end
end


function on_ld_sms_login( msg )
	local sql = string.format( 
		"CALL sms_login('%1%','%2%','%3%','%4%','%5%','%6%')",
									 msg.account, 
									 msg.ip, 
									 msg.phone, 
									 msg.imei, 
									 msg.platform_id, 
									 msg.shared_id )
	log.info( "sql = [%s]", strsql )

	local data = dbopt.account:query(sql)
	local reply = {}
	if data then
		reply.verify_account_result = data
		if data.ret == LOGIN_RESULT_SUCCESS then
			reply.password = data.password
			if data.ret == 0 or data.vip == 100 then
				local sql = string.format(
					[[INSERT INTO `log`.`t_log_login` (`guid`, `login_phone`, `login_phone_type`, `login_version`,
					`login_channel_id`, `login_package_name`, `login_imei`, `login_ip`, `channel_id` , `is_guest` , `create_time` , `register_time`, `deprecated_imei` ,
					`platform_id` , `seniorpromoter`) 
					"VALUES('1', '2', '3', '4', '5', '6', '7', '8', '9' ,'10' ,FROM_UNIXTIME('11'),
							if ('12'>'0', FROM_UNIXTIME('12'), null), '13' , '14' , '15')]]
					,data.guid 
					,msg.account
					,msg.phone_type 
					,msg.version 
					,msg.channel_id 
					,msg.package_name 
					,msg.imei 
					,msg.ip 
					,data.channel_id 
					,data.is_guest 
					,data.create_time 
					,data.register_time 
					,msg.deprecated_imei 
					,msg.platform_id 
					,data.seniorpromoter )
				log.info( "%s", sql )
				dbopt.log:query(sql)
			else
				-- 维护中
				log.info( "game is MaintainStatus" )
			end
		elseif data.ret == LOGIN_RESULT_ACCOUNT_PASSWORD_ERR then
			reply = {}
			reply.ret = REG_ACCOUNT_RESULT_SUCCESS
			reply.is_guest =  false
			reply.phone =  msg.phone
			reply.phone_type =  msg.phone_type
			reply.version =  msg.version
			reply.channel_id =  msg.channel_id
			reply.package_name =  msg.package_name
			reply.imei =  msg.imei
			reply.ip =  msg.ip
			reply.ip_area =  msg.ip_area
			reply.deprecated_imei =  msg.deprecated_imei
			reply.platform_id =  msg.platform_id
			
			if not msg.invite_code then
				reply.ret =  enum.LOGIN_RESULT_NEED_INVITE_CODE
				return reply
			end

			local validatebox_ip = reddb:get("validatebox_feng_ip")
			local is_validatebox_block = validatebox_ip and tonumber(validatebox_ip) or 0

			-- 没有账号就注册
			sql = string.format("CALL create_account('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s' , '%s', %d, '%s','%s',%d)", 
						msg.account, 
						msg.phone, 
						msg.phone_type, 
						msg.version,
						msg.channel_id, 
						msg.package_name,
						msg.imei, 
						msg.ip, 
						msg.platform_id, 
						enabled_, 
						msg.shared_id,
						msg.invite_code,
						msg.invite_type)
			
			local data = dbopt.account:query(sql)
			reply.account = data.account
			reply.guid = data.guid
			reply.nickname = data.nickname
			reply.password = data.password
			reply.using_login_validatebox = data.using_login_validatebox
			
			if data then
				if data.ret == -100 then
					log.error( "sms login ip[%s] failed", msg.ip() )
					reply.ret = enum.LOGIN_RESULT_IP_CREATE_ACCOUNT_LIMIT 
				elseif (data.ret == -99) then
					log.error( "sms login ip[%s] failed", msg.ip() )
					reply.ret = enum.LOGIN_RESULT_CREATE_MAX 
				elseif data.ret ~= enum.LOGIN_RESULT_NEED_INVITE_CODE then
					reply.ret = enum.LOGIN_RESULT_NEED_INVITE_CODE 
				else 
					sql = string.format([[INSERT INTO `log`.`t_log_login` (`guid`, `login_phone`, `login_phone_type`, `login_version`,
									`login_channel_id`, `login_package_name`, `login_imei`, `login_ip`, `channel_id` , `is_guest` , `create_time` , `register_time`, `deprecated_imei` ,
									`platform_id` , `seniorpromoter`) "
									"VALUES('%d', '%s', '%d', '%s', '%s', '%s', '%s', '%s', '%s' ,'%d' ,if ('11'>'%d', FROM_UNIXTIME('%d'), now()),
									if ('%d'>'0', FROM_UNIXTIME('%d'), null), '%s' , '%s' , '%s')]]
									, data.guid 
									, msg.phone 
									, msg.phone_type
									, msg.version 
									, msg.channel_id 
									, msg.package_name 
									, msg.imei 
									, msg.ip 
									, msg.channel_id 
									, data.is_guest
									, data.create_time 
									, data.register_time 
									, msg.deprecated_imei 
									, msg.platform_id
									, data.seniorpromoter )
					log.info( "%s", sql )
					dbopt.account:query(sql)
					-- 插入代理关系
					dbopt.proxy:query(
						"INSERT INTO proxy.player_proxy_relationship(guid,proxy_guid,proxy_account) VALUES(%d,%d,'%s')"
						, data.guid, data.inviter_guid, data.inviter_account
						)
				end
			else
				reply.ret = LOGIN_RESULT_IMEI_HAS_ACCOUNT
			end

			return reply
		end
	else
		log.error( "sms login[%s] failed", msg.account )

		reply.verify_account_result = LOGIN_RESULT_DB_ERR
	end

	reply.account = msg.account
	reply.platform_id = msg.platform_id

	return reply
end



function on_sd_reset_account( msg )
	local guid = msg.guid
	local account = msg.account
	local nickname = msg.nickname
	local game_id = server_id_

	local reply = {}
	local data = dbopt.account:query("UPDATE t_account SET account = '%s', `password` = '%s', nickname = '%s', is_guest = 0, register_time = NOW() WHERE guid = %d AND is_guest != 0",
				account, msg.password, nickname, guid)

	local has = dbopt.account:query("SELECT account FROM t_account WHERE nickname = '%s' AND guid <> %d", nickname, guid)
	reply.guid = guid
	reply.account = account
	reply.nickname = nickname
	reply.ret = has and LOGIN_RESULT_RESET_ACCOUNT_DUP_NICKNAME or LOGIN_RESULT_RESET_ACCOUNT_DUP_ACC
	reply.addflag = 0
	reply.ret = LOGIN_RESULT_SUCCESS
	dbopt.game:query("UPDATE t_player SET account='%s', nickname = '%s' WHERE guid=%d", account, nickname, guid)
	local data = dbopt.account:query("select change_alipay_num from t_account where guid = '%d'", guid)
	if nmsg then
		nmsg.guid = guid
		nmsg.sing_num = tonumber(data[1][1])
		return nmsg
	end


	log.info( "select reg_gold from t_player where guid = '%d'", guid )
	data = dbopt.game:query("select reg_gold from t_player where guid = '%d'", guid)
	if data then
		reply.addflag = tonumber(data[1][1]) > 0 and 1 or 0
	end
	return reply
end

function on_sd_set_password( msg )
	local guid = msg.guid
	local old_password_from_client = msg.old_password
	local new_password = msg.password
	local reply = {
		guid = msg.guid,
	}

	local data = dbopt.account:query("select password from t_account where guid = '%d'", guid)
	if data  then
		local old_password_from_db = data[1]
		if old_password_from_client == old_password_from_db then
			local data = dbopt.account:query("UPDATE t_account SET `password` = '%s' WHERE guid = %d AND `password` = '%s'",
				new_password, guid, old_password_from_client)
			if ret > 0 then
				reply.ret = LOGIN_RESULT_SUCCESS
				return reply
			end

			reply.ret = LOGIN_RESULT_SET_PASSWORD_FAILED
			return
		end

		log.warning( "guid[%d]: old_password_from_client !!!!==== old_password_from_db.", guid )
		reply.ret = LOGIN_RESULT_INPUT_OLD_PASSWORD_ERROR
		return
	end

	log.error( "guid[%d] get old password from db error.", guid )
	reply.ret = LOGIN_RESULT_SET_PASSWORD_FAILED
	return reply
end

function on_sd_set_password_by_sms(msg)
	local guid = msg.guid
	local data = dbopt.account:query("UPDATE t_account SET `password` = '%s' WHERE guid = %d", msg.password, guid)
	if data.errno then
		log.error(data.err)
		return
	end

	local reply = {}
	reply.guid = guid
	if data.effected_rows > 0 then
		reply.ret = LOGIN_RESULT_SUCCESS
		return reply
	end
	
	local data = dbopt.account:query("select guid from t_account where guid = '%d'", guid)
	if data.errno then
		log.error(data.err)
		return
	end

	reply.ret = #data > 0 and LOGIN_RESULT_SUCCESS or LOGIN_RESULT_SET_PASSWORD_FAILED
	return reply
end

function on_sd_set_nickname(msg)
	local guid = msg.guid
	local nickname = msg.nickname

	local ret = dbopt.game:query("UPDATE t_player SET `nickname` = '%s' WHERE guid = %d;", nickname, guid)
	if ret.errno then
		log.error(ret.err)
	end

	return 
end

function on_sd_update_earnings( msg )
	dbopt.account:query([[UPDATE t_earnings SET daily_earnings = daily_earnings + %d, weekly_earnings = weekly_earnings + %d, 
						monthly_earnings = monthly_earnings + %d WHERE guid = %d]],msg.money, msg.money, msg.money, msg.guid )
end


function on_ld_cash_false( msg )
	local order_id = msg.order_id
	local web_id = msg.web_id
	local del = msg.del
	local reply = {}
	local data = dbopt.account:query("SELECT guid, order_id, coins, status, status_c FROM t_cash WHERE order_id='%d'", order_id)
	data = data and data[1] or nil
	if (data and (data.status ~= 1) and (data.status ~= 0) and (data.status ~= 4) and (data.status_c == 0)) then
		local guid = data.guid
		reply.web_id = web_id
		reply.info = data
		if del then
			dbopt.account:query([[UPDATE t_account SET `alipay_account_y` = NULL, alipay_name_y = NULL, alipay_account = NULL, 
				alipay_name = NULL  WHERE guid = %d]], guid )
		end
		return reply
	else
		reply.web_id = web_id
		reply.result = 2
		return reply
	end
end


function on_ld_cash_reply(msg )
	dbopt.account:query("UPDATE t_cash SET `status_c` = '%d' WHERE order_id = %d", msg.result, msg.order_id)
end


function on_ld_cash_deal(msg )
	local guid = msg.info.guid
	local order_id = msg.info.order_id
	local money = msg.info.coins
	local web_id = msg.web_id

	local res = dbopt.game:query("UPDATE t_player SET `bank` = `bank` +  '%d' WHERE guid = %d", money, guid)
	reply.web_id = web_id
	if res > 0 then
		reply.result = 1
		dbopt.account:query("UPDATE t_cash SET `status_c` = '1' WHERE order_id = %d", order_id)
		local data = dbopt.game:query("SELECT money, bank FROM t_player WHERE guid='%d'", guid)
		if data then
			data = data[1]
			dbopt.log:query("INSERT INTO t_log_money (`guid`,`old_money`,`new_money`,`old_bank`,`new_bank`,`opt_type`)VALUES ('%d','%I64d','%I64d','%I64d','%I64d','%d')",
			guid, data.money(), data.money(), data.bank() - money, data.bank(), enum.LOG_MONEY_OPT_TYPE_CASH_MONEY)
		end
		return reply
	end

	reply.result = 4
	dbopt.account:query( "UPDATE t_cash SET `status_c` = '4' WHERE order_id = %d", order_id)
	return reply
end


function on_ld_re_add_player_money( msg )
	local guid = msg.guid
	local money = msg.money
	local Add_Type = msg.add_type

	local res = dbopt.game:query("UPDATE t_player SET `bank` = `bank` +  '%d' WHERE guid = %d", money, guid)
	if res then
		local data = dbopt.game:query("SELECT money, bank FROM t_player WHERE guid='%d'", guid)
		if data then
			data = data[1]
			dbopt.log:query("INSERT INTO t_log_money (`guid`,`old_money`,`new_money`,`old_bank`,`new_bank`,`opt_type`)VALUES ('%d','%I64d','%I64d','%I64d','%I64d','%d')",
				guid, data.money, data.money, data.bank - money, data.bank, Add_Type)
		end
		return
	end

	log.error("on_ld_re_add_player_money----false guid = %d  money = %d add_type = %d", guid, money, Add_Type)
end

local function is_chinese_words(s)
	return false
end

local function check_alipay_account(account,name)
	if account:match("^%d+$") then
		if is_chinese_words(account) then return false end
		if #account ~= 11 then return false end

		return 2
	end

	local id,domain = account:match("([^@]+)@([^.]+).%.+")
	if not id or #id == 0 then return false end
	if not domain or #domain == 0 then return false end

	return is_chinese_words(name)
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

function on_sd_binding_alipay(msg)
	local guid = msg.guid
	local account = msg.alipay_account
	local name = msg.alipay_name
	local platform_id = msg.platform_id

	if check_alipay_account( account, name ) then
		account,name = alipay_mixed_name(account,name)
	else
		local reply = {}
		reply.guid = guid
		reply.result = GAME_BAND_ALIPAY_CHECK_ERROR
		return reply
	end

	local data = dbopt.account:query("select account, password from t_account where alipay_account_y = '%s' and platform_id = '%s';", account, platform_id)
	if not data.errno or #data > 0 then
		local reply = {
			guid = guid,
			result = GAME_BAND_ALIPAY_REPEAT_BAND,
		}
		return reply
	end

	local ret = dbopt.account:query(
		"UPDATE t_account SET `alipay_account_y` = '%s', alipay_name_y = '%s', alipay_account = '%s', alipay_name = '%s', change_alipay_num = change_alipay_num - 1  WHERE guid = %d", 
		account, name, start_account, start_name, guid )
	
	if ret.errno or ret.effected_rows == 0 then
		return {
			guid = guid,
			result = GAME_BAND_ALIPAY_DB_ERROR,
		}
	end

	local data = dbopt.account:query("select account, password from t_account where  guid = %d and not(bang_alipay_time is NULL)", guid)
	if data.errno or #data == 0 then
		dbopt.account:query("UPDATE t_account SET `bang_alipay_time` = current_timestamp WHERE guid = %d", guid)
	end

	return {
		guid = guid,
		result = GAME_BAND_ALIPAY_SUCCESS,
		alipay_account = start_account,
		alipay_name = start_name,
	}
end


local function check_bankcard_account( player_guid, account, name )
	if not account:match("^%d+$") then
		log.error( "player guid[%d] band account [%s] type error,not all number.", player_guid, account)
		return false
	end

	if #account < 11 then
		log.error( "player guid[%d] band account [%s] length error.", player_guid, account )
		return false
	end

	if is_chinese_words(name) then
		log.error( "player guid[%d] band name [%s]  error.", player_guid, name )
		return false
	end
	
	return true
end

function on_sd_binding_bankcard(msg)
	local guid = msg.guid
	local card_name = msg.bank_card_name
	local card_num = msg.bank_card_num
	local bank_name = msg.bank_name
	local bank_province = msg.bank_province
	local bank_city = msg.bank_city
	local bank_branch = msg.bank_branch
	local platform_id = msg.platform_id

	if not check_bankcard_account( guid, card_num, card_name ) then
		return {
			guid = guid,
			result = GAME_BAND_ALIPAY_CHECK_ERROR,
		}
	end

	local sql = string.format( "call create_or_update_bankcard(%d, '%s', '%s', '%s', '%s', '%s', '%s', '%s');"
								  , guid
								  , platform_id
								  , card_num
								  , card_name
								  , bank_name
								  , bank_province
								  , bank_city
								  , bank_branch
								  )
	log.info( "on_sd_band_bankcard sql [%s]", sql)
	
	local reply = {
		guid = guid,
		bank_card_num = bank_card_num,
		bank_card_name = bank_card_name,
		bank_name = bank_name,
		bank_province = bank_province,
		bank_city = bank_city,
		bank_branch = bank_branch,
	}

	local data = dbopt.account:query(sql)
	if data.errno or #data == 0 then
		reply.result = GAME_BAND_ALIPAY_DB_ERROR
		return reply
	end

	local ret = tonumber(data[1])
	if ret == 1 then
		reply.result = GAME_BAND_ALIPAY_SUCCESS
	elseif ret == 2 then
		reply.result = GAME_BAND_ALIPAY_REPEAT_BAND
	end

	return reply
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

	local data = dbopt.account:query(sql)
	if data.errno or #data == 0 then
		reply.ret = 1
	else
		reply.ret = 2
	end

	return reply
end

function on_ld_offlinechangemoney_query(msg)
	eval(msg.gmcommand)
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
	local data = dbopt.account:query("select guid,account,alipay_name_y,alipay_account_y from t_account where invite_code = '%s';", invite_code)
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
	dbopt.account:query("UPDATE t_account SET `inviter_guid` = %d WHERE guid = %d;", inviter_guid, new_player_guid)
	return reply
end

-- 修改金钱成功 
function on_sd_changemoney( msg )
	log.info( "on_sd_changemoney  web[%d] gudi[%d] order_id[%d] type[%d]", msg.web_id, msg.info.guid, msg.info.order_id, msg.info.type_id )
	if msg.info.type_id == enum.LOG_MONEY_OPT_TYPE_RECHARGE_MONEY then
		dbopt.recharge:query("UPDATE t_recharge_order SET `server_status` = '1', before_bank = '%I64d', after_bank = '%I64d' WHERE id = %d",
				msg.befor_bank, msg.after_bank, msg.info.order_id)
	elseif msg.info.type_id == enum.LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE then
		dbopt.recharge:query("UPDATE t_cash SET `status_c` = '1' WHERE order_id = %d", msg.info.order_id)
	end

	return {
		web_id = msg.web_id,
		result = 1,
	}
end

-- 修改金钱失败插入数据库
local function insert_into_changemoney( msg )
	log.info( "on_DF_ChangMoney  web[%d] gudi[%d] order_id[%d] type[%d]", msg.web_id, msg.info.guid, msg.info.order_id, msg.info.type_id )
	local login_id = msg.login_id
	local web_id = msg.web_id
	local info = msg.info
	local data = dbopt.recharge:query("select id, guid from t_re_recharge where type = '%d' and order_id = '%d'", info.type_id, info.order_id)

	if data then
		log.info( "on_DF_ChangMoney  order[%d] is  deal", info.order_id )
		return {
			web_id = web_id,
			result = 6,
		}
	end

	log.info( "on_DF_ChangMoney  order[%d] is not deal", info.order_id )
	local data = dbopt.recharge:query(
		"INSERT INTO t_re_recharge(`guid`,`money`,`type`,`order_id`,`created_at`)VALUES('%d', '%I64d', '%d', '%d', current_timestamp)", 
		info.guid, info.gold, info.type_id, info.order_id)

	local reply = {
		web_id = web_id,
	}
	if data > 0 then
		log.info( "on_DF_ChangMoney  order[%d] insert t_re_recharge  true", info.order_id )
		reply.result = 6
		if info.type_id == enum.LOG_MONEY_OPT_TYPE_RECHARGE_MONEY then
			dbopt.recharge:query("UPDATE t_recharge_order SET `server_status` = '6' WHERE id = %d", info.order_id)
		elseif info.type_id == enum.LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE then
			if info.order_id ~= -1 then
				dbopt.recharge:query("UPDATE t_cash SET `status_c` = '6' WHERE order_id = %d", info.order_id)
			end
		end
	else
		log.info( "on_DF_ChangMoney  order[%d] insert t_re_recharge  false", info.order_id )
		reply.result = 4
	end

	return reply
end


function on_fd_changemoney( msg )
	log.info( "on_fd_changemoney  web[%d] gudi[%d] order_id[%d] type[%d]", msg.web_id, msg.info.guid, msg.info.order_id, msg.info.type_id )
	return insert_into_changemoney( msg )
end

function on_cash_false_changemoney( msg )
	local order_id = msg.order_id
	local web_id = msg.web_id
	local type_id = msg.type_id

	if msg.type_id ~= enum.LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE then
		return
	end

	local del = msg.other_oper
	local data = dbopt.recharge:query("SELECT guid, order_id, coins, status, status_c FROM t_cash WHERE order_id='%d'", order_id)
	data = data and data[1] or nil
	if (data and (data.status ~= 1) and (data.status ~= 0) and (data.status ~= 4) and (data.status_c == 0)) then
		local guid = data.guid
		local add_bank_money = data.coins
		local data = dbopt.recharge:query("CALL change_player_bank_money(%d,%d,0)", guid, add_bank_money)
		data = data and data[1] or nil
		if data and #data == 3 then
			local ret = data[1]
			local oldbank = data[2]
			local newbank = data[3]

			local  reply = {
				guid = guid,
				web_id = web_id,
				result = ret,
				old_bank = oldbank,
				new_bank = new_bank,
			}

			log.info("change_player_bank_money guid[%d] order_id[%d] ret[%d]", guid, order_id, ret )
			dbopt.recharge:query("UPDATE t_cash SET `status_c` = %d WHERE order_id = %d", ret, order_id)
			return reply
		end

		log.error("change_player_bank_money error guid[%d] order_id[%d]", guid, order_id )

		if del == 1 then
			local res = dbopt.account:query("UPDATE t_account SET `alipay_account_y` = NULL, alipay_name_y = NULL, alipay_account = NULL, alipay_name = NULL  WHERE guid = %d", guid)
			channel.publish("login.?","msg","DL_ResetAlipay",{
				guid = guid,
				alipay_name = "",
				alipay_name_y = "",
				alipay_account = "",
				alipay_account_y = "",
				status = ret,
			})
		end

		if del == 2 then
			dbopt.game:query([[UPDATE t_player_bankcard SET bank_card_name = '**', bank_card_num = '**',
				bank_name = '', bank_province = '', bank_city = '' , bank_branch = '' where guid = %d]], guid)
		end
	else
		return {
			web_id = web_id,
			result = 10,
		}
	end
end

function on_ld_query_maintain(msg)
	if msg.maintaintype == 3 then
		local switchopen = msg.switchopen
	end
end

function on_ld_create_proxy_account(msg)
	local web_id = msg.web_id
	local guid = msg.guid
	local proxy_id = msg.proxy_id
	local platform_id = msg.platform_id
	local str_platform_id = tostring(platform_id)
	local asyncid = msg.asyncid
	local reply = {
		web_id = web_id,
		guid = guid,
		proxy_id = proxy_id,
		platform_id = platform_id,
		result = 0,
		proxy_guid = 0,
		asyncid = asyncid,
	}

	local data = dbopt.account:query("CALL create_proxy_account(%d,%d,'%s');", guid, proxy_id, str_platform_id)
	if data.errno or #data == 0 or #data[1] ~= 4 then
		log.error( "create_proxy_account error guid[%d] proxy_id[%d]", guid, proxy_id )
		return reply
	end

	local ret,proxy_guid,account,nickname = table.unpack(data[1])
	ret = tonumber(ret)
	proxy_guid = tonumber(proxy_guid)

	-- 0成功 3重复创建t_account
	if ret == 0 or ret == 3 then
		local data = dbopt.account:query("CALL get_player_data(%d,'%s','%s',0,'%s',1);", proxy_guid, account, nickname, str_platform_id)
		if not data.errno and #data > 0 then
			proxy.ret = 1
			proxy.proxy_guid = proxy_guid
			-- 修改状态为创建完毕
			dbopt.account:query("UPDATE t_player_proxy SET `status` = 2 WHERE guid = %d AND proxy_id = %d;", guid, proxy_id)
		else
			log.error( "CALL get_player_data error guid[%d] proxy_id[%d] proxy_guid[%d] account[%s]", guid, proxy_id, proxy_guid, account)
		end
		return proxy
	else
		log.error( "create_proxy_account error guid[%d] proxy_id[%d] ret[%d]", guid, proxy_id, ret )
		return reply
	end
end

function on_s_request_proxy_platform_ids(msg)
	local data = dbopt.account:query("SELECT DISTINCT platform_id FROM t_proxy_ad ;")
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
	local data = dbopt.proxy:query("CALL get_proxy_info(%d);", platform_id)
	if data.errno or #data == 0 then
		log.error( "load cfg from db error" )
		return
	end

	if data[1][1] == "0" then
		log.error( "get_proxy_info[%d] failed", platform_id )
		return
	end

	local reply = {
		pb_platform_proxys = pb.decode("PlatformProxyInfos",data[1][1])
	}

	return reply
end

function on_ld_gm_changemoney(msg)
	local web_id = msg.web_id
	local login_id = msg.login_id
	local guid = msg.guid
	local change_bank_money = msg.bank_money
	local type_id = msg.type_id
	
	local data = dbopt.recharge:query("CALL change_player_bank_money(%d,%d,0);", guid, change_bank_money)
	if data.errno or #data == 0 or #data[1] ~= 3 then
		log.error( "change_player_bank_money error guid[%d] type_id[%d]", guid, type_id )
		return 
	end

	data = data[1]
	local ret = tonumber(data[1])
	local oldbank = tonumber(data[2])
	local newbank = tonumber(data[3])

	log.info( "change_player_bank_money guid[%d] type_id[%d] ret[%d]", guid, type_id, ret )

	return {
		web_id = web_id,
		guid = guid,
		result = ret,
		old_bank = old_bank,
		new_bank = new_bank,
		type_id = type_id,
	}
end

function on_ld_return_agent_money(msg)
	local web_id = msg.web_id
	local login_id = msg.login_id
	local guid = msg.guid
	local change_bank_money = msg.bank_money
	local type_id = msg.type_id
	local order_id = msg.order_id

	local data = dbopt.game:query("CALL change_player_bank_money(%d,%d,1);", guid, change_bank_money)
	if data.errno or #data == 0 and #data[1] ~= 3 then
		log.error( "change_player_bank_money error guid[%d] type_id[%d]", guid, type_id )
		return
	end

	data = data[1]
	
	local ret = tonumber(data[1])
	local oldbank = tonumber(data[2])
	local newbank = tonumber(data[3])
	log.info( "change_player_bank_money guid[%d] type_id[%d] ret[%d]", guid, type_id, ret )

	return {
		web_id = web_id,
		guid = guid,
		result = ret,
		cost_money = cost_money,
		acturl_cost_money = acturl_cost_money,
		old_bank = old_bank,
		new_bank = new_bank,
		type_id = type_id,
		order_id = order_id,
	}
end

function get_binding_bankcard_num(msg)
	local guid = msg.guid
	log.info( "get_band_bankcard_num: player guid[%d] game_id[%d].", guid, game_id )
	local data = dbopt.account:query("select change_bankcard_num from t_account where guid = '%d';", guid)
	if data.errno or #data == 0 then
		return
	end

	data = data[1]
	return {
		guid = guid,
		bank_card_num = tonumber(data[1])
	}
end

function on_reg_account(msg)
	log.dump(msg)
	local res = dbopt.account:query(
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

	res = dbopt.log:query(
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

local function incr_player_money(guid,money_id,money,where,why)
	log.info("%s,%s,%s,%s,%s",guid,money_id,money,where,why)
	local res = dbopt.game:query([[SELECT money FROM t_player_money WHERE guid =  %s AND money_id = %s and `where` = %s;]],guid,money_id,where)
	if res.errno then
		log.error("incr_player_money query old money error,%s,%s,%s",guid,money_id,where)
		return
	end

	log.dump(res)

	local oldmoney = res[1].money

	local res = dbopt.game:query([[UPDATE t_player_money SET money = money + (%d) WHERE guid = %d AND money_id = %d AND `where` = %d;]],money,guid,money_id,where)
	if res.errno then
		log.error("incr_player_money error,errno:%d,error:%s",res.errno,res.err)
		return
	end

	log.dump(res)

	local res = dbopt.game:query([[SELECT money FROM t_player_money WHERE guid =  %s AND money_id = %s and `where` = %s;]],guid,money_id,where)
	if res.errno then
		log.error("incr_player_money query old money error,%s,%s,%s",guid,money_id,where)
		return
	end

	log.dump(res)

	local newmoney = res[1].money
	if not oldmoney or not newmoney then
		log.error("incr_player_money bad oldmoney [%s] or newmoney [%s]",oldmoney,newmoney)
		return
	end

	dbopt.log:query([[
			INSERT INTO t_log_money(guid,money_id,old_money,new_money,`where`,reason,created_time) 
			VALUES(%d,%d,%d,%d,%d,%d,%d);
		]],
		guid,money_id,oldmoney,newmoney,where,why,timer.ms_time())
	return oldmoney,newmoney
end

function on_sd_change_player_money(items,why)
	local changes = {}
	for _,item in pairs(items) do
		local oldmoney,newmoney = incr_player_money(item.guid,item.money_id,item.money,item.where or 0,why)
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
	dbopt.game:query("INSERT INTO t_money(id,type,club_id) VALUES(%d,%d,%s)",id,money_type,club_id)
end

local function transfer_money_club2player(club_id,guid,money_id,amount,why,why_ext)
	log.info("transfer_money_club2player club:%s,guid:%s,money_id:%s,amount:%s,why:%s,why_ext:%s",
		club_id,guid,money_id,amount,why,why_ext)
	local sqls = {
		string.format([[SELECT money FROM t_club_money WHERE club = %d AND money_id = %d;]],club_id,money_id),
		string.format([[UPDATE t_club_money SET money = money + (%d) WHERE club = %d AND money_id = %d;]],- amount,club_id,money_id),
		string.format([[SELECT money FROM t_club_money WHERE club = %d AND money_id = %d;]],club_id,money_id),
		string.format([[SELECT money FROM t_player_money WHERE guid = %d AND money_id = %d AND `where` = 0;]],guid,money_id),
		string.format([[UPDATE t_player_money SET money = money + (%d) WHERE guid = %d AND money_id = %d AND `where` = 0;]],amount,guid,money_id),
		string.format([[SELECT money FROM t_player_money WHERE guid = %d AND money_id = %d AND `where` = 0;]],guid,money_id),
	}

	local gamedb = dbopt.game

	local transid,res = gamedb:begin_trans()

	transid,res = gamedb:do_trans(transid,table.concat(sqls,"\n"))
	if res.errno then
		gamedb:rollback_trans(transid)
		log.error("transfer_money_club2player do money error,errno:%d,err:%s",res.errno,res.err)
		return enum.ERROR_INTERNAL_UNKOWN
	end

	log.dump(res)

	gamedb:commit_trans(transid)

	local old_club_money = res[1] and res[1][1] and res[1][1].money or nil
	local new_club_money = res[3] and res[3][1] and res[3][1].money or nil
	local old_player_money = res[4] and res[4][1] and res[4][1].money or nil
	local new_player_money = res[6] and res[6][1] and res[6][1].money or nil

	local logsqls = {
		string.format([[INSERT INTO t_log_money_club(club,money_id,old_money,new_money,opt_type,opt_ext) VALUES(%d,%d,%d,%d,%d,'%s');]],
					club_id,money_id,old_club_money,new_club_money,why,why_ext),
		string.format([[
				INSERT INTO t_log_money(guid,money_id,old_money,new_money,`where`,reason,reason_ext,created_time) 
				VALUES(%d,%d,%d,%d,0,%d,'%s',%s);
				]],guid,money_id,old_player_money,new_player_money,why,why_ext,timer.ms_time()),
	}
	res = dbopt.log:query(table.concat(logsqls,"\n"))
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
		string.format([[SELECT money FROM t_player_money WHERE guid = %d AND money_id = %d AND `where` = 0;]],guid,money_id),
		string.format([[UPDATE t_player_money SET money = money + (%d) WHERE guid = %d AND money_id = %d AND `where`= 0;]],- amount,guid,money_id),
		string.format([[SELECT money FROM t_player_money WHERE guid = %d AND money_id = %d AND `where` = 0;]],guid,money_id),
		string.format([[SELECT money FROM t_club_money WHERE club = %d AND money_id = %d;]],club_id,money_id),
		string.format([[UPDATE t_club_money SET money = money + (%d) WHERE club = %d AND money_id = %d;]],amount,club_id,money_id),
		string.format([[SELECT money FROM t_club_money WHERE club = %d AND money_id = %d;]],club_id,money_id),
	}

	local gamedb = dbopt.game

	local transid,res = gamedb:begin_trans()
	transid,res = gamedb:do_trans(nil,table.concat(sqls,"\n"))
	if res.errno then
		gamedb:rollback_trans(transid)
		log.error("transfer_money_player2club do money error,errno:%d,err:%s",res.errno,res.err)
		return enum.ERROR_INTERNAL_UNKOWN
	end

	gamedb:commit_trans(transid)

	local old_player_money = res[1] and res[1][1] and res[1][1].money or nil
	local new_player_money = res[3] and res[3][1] and res[3][1].money or nil
	local old_club_money = res[4] and res[4][1] and res[4][1].money or nil
	local new_club_money = res[6] and res[6][1] and res[6][1].money or nil

	local logsqls = {
		string.format([[INSERT INTO t_log_money_club(club,money_id,old_money,new_money,opt_type,opt_ext) VALUES(%d,%d,%d,%d,%d,'%s');]],
					club_id,money_id,old_club_money,new_club_money,why,why_ext),
		string.format([[
				INSERT INTO t_log_money(guid,money_id,old_money,new_money,`where`,reason,reason_ext,created_time) 
				VALUES(%d,%d,%d,%d,0,%d,'%s',%s);
				]],guid,money_id,old_player_money,new_player_money,why,why_ext,timer.ms_time()),
	}
	res = dbopt.log:query(table.concat(logsqls,"\n"))
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
		string.format([[SELECT money FROM t_club_money WHERE club = %d AND money_id = %d;]],club_id_from,money_id),
		string.format([[UPDATE t_club_money SET money = money + (%d) WHERE club = %d AND money_id = %d;]], -amount,club_id_from,money_id),
		string.format([[SELECT money FROM t_club_money WHERE club = %d AND money_id = %d;]],club_id_from,money_id),
		string.format([[SELECT money FROM t_club_money WHERE club = %d AND money_id = %d;]],club_id_to,money_id),
		string.format([[UPDATE t_club_money SET money = money + (%d) WHERE club = %d AND money_id = %d;]],amount,club_id_to,money_id),
		string.format([[SELECT money FROM t_club_money WHERE club = %d AND money_id = %d;]],club_id_to,money_id),
	}

	log.dump(sqls)

	local gamedb = dbopt.game

	local transid,res = gamedb:begin_trans()
	transid,res = gamedb:do_trans(transid,table.concat(sqls,"\n"))
	if res.errno then
		gamedb:rollback_trans(transid)
		log.error("transfer_money_club2club do money error,errno:%d,err:%s",res.errno,res.err)
		return enum.ERROR_INTERNAL_UNKOWN
	end

	log.dump(res)

	gamedb:commit_trans(transid)

	local old_from_money = res[1] and res[1][1] and res[1][1].money or nil
	local new_from_money = res[3] and res[3][1] and res[3][1].money or nil
	local old_to_money = res[4] and res[4][1] and res[4][1].money or nil
	local new_to_money = res[6] and res[6][1] and res[6][1].money or nil

	local logsqls = {
		string.format([[INSERT INTO t_log_money_club(club,money_id,old_money,new_money,opt_type,opt_ext) VALUES(%d,%d,%d,%d,%d,'%s');]],
					club_id_from,money_id,old_from_money,new_from_money,why,why_ext),
		string.format([[INSERT INTO t_log_money_club(club,money_id,old_money,new_money,opt_type,opt_ext) VALUES(%d,%d,%d,%d,%d,'%s');]],
					club_id_to,money_id,old_to_money,new_to_money,why,why_ext),
	}

	log.dump(logsqls)
	res = dbopt.log:query(table.concat(logsqls,"\n"))
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
		string.format([[SELECT money FROM t_player_money WHERE guid = %d AND money_id = %d;]],from_guid,money_id),
		string.format([[UPDATE t_player_money SET money = money + (%d) WHERE guid = %d AND money_id = %d;]], -amount,from_guid,money_id),
		string.format([[SELECT money FROM t_player_money WHERE guid = %d AND money_id = %d;]],from_guid,money_id),
		string.format([[SELECT money FROM t_player_money WHERE guid = %d AND money_id = %d;]],to_guid,money_id),
		string.format([[UPDATE t_player_money SET money = money + (%d) WHERE guid = %d AND money_id = %d;]],amount,to_guid,money_id),
		string.format([[SELECT money FROM t_player_money WHERE guid = %d AND money_id = %d;]],to_guid,money_id),
	}

	log.dump(sqls)

	local gamedb = dbopt.game

	local transid,res = gamedb:begin_trans()
	transid,res = gamedb:do_trans(transid,table.concat(sqls,"\n"))
	if res.errno then
		gamedb:rollback_trans(transid)
		log.error("transfer_money_club2club do money error,errno:%d,err:%s",res.errno,res.err)
		return enum.ERROR_INTERNAL_UNKOWN
	end

	log.dump(res)

	gamedb:commit_trans(transid)

	local old_from_money = res[1] and res[1][1] and res[1][1].money or nil
	local new_from_money = res[3] and res[3][1] and res[3][1].money or nil
	local old_to_money = res[4] and res[4][1] and res[4][1].money or nil
	local new_to_money = res[6] and res[6][1] and res[6][1].money or nil

	local logsqls = {
		string.format(
			[[
				INSERT INTO t_log_money(guid,money_id,old_money,new_money,`where`,reason,reason_ext,created_time) 
				VALUES(%d,%d,%d,%d,0,%d,'%s',%s);
			]],from_guid,money_id,old_from_money,new_from_money,why,why_ext,timer.ms_time()),
		string.format(
			[[
				INSERT INTO t_log_money(guid,money_id,old_money,new_money,`where`,reason,reason_ext,created_time) 
				VALUES(%d,%d,%d,%d,0,%d,'%s',%s);
			]],to_guid,money_id,old_to_money,new_to_money,why,why_ext,timer.ms_time()),
	}

	log.dump(logsqls)
	res = dbopt.log:query(table.concat(logsqls,"\n"))
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
	dbopt.game:query("UPDATE t_player SET phone = \"%s\" WHERE guid = %s;",phone,guid)
end

function on_sd_update_player_info(msg)
	local guid = msg.guid

	if 	(not guid or guid == 0) or
		(
			not msg.nickname and 
			not msg.icon and 
			not msg.phone
		) 
	then
		return
	end

	local sql = "UPDATE t_player SET "
	if msg.nickname then
		sql = sql .. string.format(" nickname = '%s'",msg.nickname)
	end

	if msg.icon then
		sql = sql .. string.format(", head_url = '%s'",msg.icon)
	end

	if msg.phone then
		sql = sql .. string.format(", phone = '%s'",msg.icon)
	end

	sql = sql .. string.format(" WHERE guid = %s;",guid)

	local r = dbopt.game:query(sql)
	if r.errno then
		log.error("on_sd_update_player_info UPDATE t_player error,%s,%s",r.errno,r.err)
	end
end