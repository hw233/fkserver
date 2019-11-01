-- 玩家数据消息处理

local pb = require "pb"

require "db.net_func"
local send2game_pb = send2game_pb
local send2center_pb = send2center_pb
local send2login_pb = send2login_pb

local dbopt = require "dbopt"
local log = require "log"

require "timer"
local add_timer = add_timer

require "table_func"
local parse_table = parse_table
server_start_time =  get_second_time()
local server_start_time = server_start_time

local md5 = require "md5"

local redisopt = require "redisopt"
local redis_command = redis_command
local redis_cmd_query = redis_cmd_query

local get_init_money = get_init_money
local get_init_regmoney = get_init_regmoney

local def_save_db_time = 60 -- 1分钟存次档
local def_offline_cache_time = 600 -- 离线玩家数据缓存10分钟

local LOG_MONEY_OPT_TYPE_RECHARGE_MONEY = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_RECHARGE_MONEY")
local LOG_MONEY_OPT_TYPE_CASH_MONEY = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CASH_MONEY")
local LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE")
local GMmessageRetCode_ReChargeDBSetError = pb.enum("GMmessageRetCode", "GMmessageRetCode_ReChargeDBSetError")
local GMmessageRetCode_Success = pb.enum("GMmessageRetCode", "GMmessageRetCode_Success")
local LOG_MONEY_OPT_TYPE_AGENTTOAGENT_MONEY = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_AGENTTOAGENT_MONEY")
local LOG_MONEY_OPT_TYPE_AGENTTOPLAYER_MONEY = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_AGENTTOPLAYER_MONEY")
local LOG_MONEY_OPT_TYPE_PLAYERTOAGENT_MONEY = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_PLAYERTOAGENT_MONEY")
local LOG_MONEY_OPT_TYPE_AGENTBANKTOPLAYER_MONEY = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_AGENTBANKTOPLAYER_MONEY")
local LOG_MONEY_OPT_TYPE_SAVE_BACK = pb.enum("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_SAVE_BACK")


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
	
	-- 基本数据
	--[[redis_cmd_query(string.format("HGET player_base_info %d", guid), function (reply)
		if reply:is_string() then
			local info = pb.decode("PlayerBaseInfo", from_hex(reply:get_string()))
			
			info.money = info.money or 0
			info.bank = info.bank or 0
			db_execute(db, "UPDATE t_player SET $FIELD$ WHERE guid=" .. guid .. ";", info)
		end
	end)--]]

	info.money = info.money or 0
	--info.bank = info.bank or 0

	local str = pb2string(info)
	local sql = "UPDATE t_player SET $FIELD$ WHERE guid=" .. guid .. ";"
	str = string.gsub(sql, '%$FIELD%$', str)
	log.info(str)
	dbopt.game.execute(sql,info)
	-- 背包数据
	--[[redis_cmd_query(string.format("HGET player_bag_info %d", guid), function (reply)
		if reply:is_string() then
			local data = pb.decode("ItemBagInfo", from_hex(reply:get_string()))
			for i, item in ipairs(data.pb_items) do
				data.pb_items[i] = pb.decode(item[1], item[2])
			end

			db_execute(db,  "REPLACE INTO t_bag SET guid=" .. guid .. ", $FIELD$;", data)
		end
	end)]]--
	
	print ("........................... save_player")
end

function on_SD_OnlineAccount(game_id, msg)
	dbopt.account:query("REPLACE INTO t_online_account SET guid=%d, first_game_type=%d, second_game_type=%d, game_id=%d, in_game=%d;", 
		msg.guid, msg.first_game_type, msg.second_game_type, msg.gamer_id, msg.in_game)
end

function on_SD_Get_Instructor_Weixin(game_id, msg)
	local guid_ = msg.guid
	local weixin_sec = math.floor(get_instructor_weixin_sec() / 60) --取分钟数

	--------------------------------------------------------
	local sql = string.format([[select weixin from t_instructor_weixin]])
	log.info(sql)
	local data = dbopt.recharge:query(sql)

	if data and #data > 0 then
		local x = #data
		local nmsg = {}
		nmsg.guid = guid_
		nmsg.instructor_weixin = {}
		if #data < 3 then
			for _,datainfo in ipairs(data) do
				table.insert(nmsg.instructor_weixin, datainfo.weixin)
			end
		else
			local t1 = get_second_time()
			local t2 = math.floor(math.abs(server_start_time - t1) / 60)
			log.info(string.format("t2[%d] weixin_sec[%d]  x[%d]", t2, weixin_sec,  x))
			local sendin = math.floor((math.floor(t2/weixin_sec) * 2) % x + 1)
			table.insert(nmsg.instructor_weixin, data[sendin].weixin)
			log.info(string.format("index A[%d]:%s", sendin,data[sendin].weixin))
			local sendin = math.floor((math.floor(t2/weixin_sec) * 2 + 1) % x + 1)
			table.insert(nmsg.instructor_weixin, data[sendin].weixin)
			log.info(string.format("index B[%d]:%s", sendin,data[sendin].weixin))
		end
		send2game_pb(game_id,"DS_Get_Instructor_Weixin",nmsg)
	else
		send2game_pb(game_id,"DS_Get_Instructor_Weixin",{
			guid = guid_,
			instructor_weixin = {},
		})
	end
	print("---------------------end")
	-----------------------------------------

end
-- 玩家退出
function on_s_logout(game_id, msg)
	-- 上次在线时间
	local db = dbopt.account
	local sql
	if msg.phone then
		sql = string.format("UPDATE t_account SET login_time = FROM_UNIXTIME(%d), logout_time = FROM_UNIXTIME(%d), online_time = online_time + %d, last_login_phone = '%s', last_login_phone_type = '%s', last_login_version = '%s', last_login_channel_id = '%s', last_login_package_name = '%s', last_login_imei = '%s', last_login_ip = '%s' WHERE guid = %d;",
			msg.login_time, msg.logout_time, msg.logout_time-msg.login_time, msg.phone, msg.phone_type, msg.version, msg.channel_id, msg.package_name, msg.imei, msg.ip, msg.guid)
	else
		sql = string.format("UPDATE t_account SET login_time = FROM_UNIXTIME(%d), logout_time = FROM_UNIXTIME(%d), online_time = online_time + %d WHERE guid = %d;",
			msg.login_time, msg.logout_time, msg.logout_time-msg.login_time, msg.guid)
	end
	db:query(sql)

	-- 删除在线
	db:query("DELETE FROM t_online_account WHERE guid=%d;", msg.guid)
end

function on_sd_delonline_player(game_id, msg)
	print ("on_sd_delonline_player........................... begin")
	dbopt.account:query("DELETE FROM t_online_account WHERE guid=%d and game_id=%d;", msg.guid, msg.game_id)
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


	local db = get_recharge_db()
	local sql = string.format([[
		select type as cash_type,money,created_at,status,agent_guid,exchange_code from t_cash where  guid = %d and created_at BETWEEN (curdate() - INTERVAL 6 DAY) and (curdate() - INTERVAL -1 DAY) and type in %s  order by created_at desc limit 50
	]], guid_,cash_type)

	local data = dbopt.recharge:query(sql)
	if data and #data > 0 then
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

	local sql = string.format([[CALL check_cash_time(%d,%d);]], guid_,cash_type_)

	local data = dbopt.recharge:query(sql)
	if not data or #data == 0 then
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
	
	print("on_sd_check_cashTime orderid--------------------->",orderid_)
	print("on_sd_check_cashTime time_--------------------->",time_)

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

	local data = dbopt.proxy:query("call cash_commission(%d,%d);",guid,money)
	if not data then
		log.error(string.format("not commission or not proxy do cash money to bank.guid:[%d],money:[%d]",guid,money))
		return
	end

	data = data[1]

	if data.ret ~= 0 then
		log.error(string.foramt("cash commission failed,guid[%d],money[%d]",guid,money))
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
	-- body
	local guid_ = msg.guid
	--local sql = string.format([[
	--	select a.id as id,UNIX_TIMESTAMP(a.start_time) as start_time,UNIX_TIMESTAMP(a.end_time) as end_time,'2' as msg_type,
	--	if(isnull(b.is_read),1,2) as is_read,a.content as content from t_notice a 
	--	LEFT JOIN t_notice_read b on a.id = b.n_id and b.guid = %d where a.end_time > FROM_UNIXTIME(UNIX_TIMESTAMP()) and a.type = 2 and a.platform_ids like '%%,%s,%%'
	--	union all
	--	select c.id as id,UNIX_TIMESTAMP(c.start_time) as start_time,UNIX_TIMESTAMP(c.end_time) as end_time,'1' as msg_type,
	--	if(c.is_read = 0,1,2) as is_read, c.content as content from t_notice_private as c 
	--	where c.guid = %d and c.type = 1 and c.end_time > FROM_UNIXTIME(UNIX_TIMESTAMP())]], 
	--	guid_,msg.platform_id,guid_)

	local  sql = string.format('call get_player_notice("%d","%s")',guid_,msg.platform_id)
	log.info(sql)

	local pb_msg_data = {}
	local data = dbopt.game:query(sql)
	if data and #data > 0 then	
		for _, item in ipairs(data) do
			table.insert(pb_msg_data,item)
		end 
	else
		
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
	if data and #data > 0 then
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
		local ret = db:query(sql)
		ret = ret[1]
		if ret > 0 then
			print("set read flag success :" ..guid_)
		else
			print("set read flag faild :" ..guid_)
		end
	elseif msg.msg_type == 2 then		
		-- 公告
		local sql = string.format("replace into t_notice_read set guid = %d ,n_id = %d,is_read = 2", 
			msg.guid, msg.id)
		local ret = db:query(sql)
		ret = ret[1]
		if ret > 0 then
			print("set read flag success :" ..guid_)
		else
			print("set read flag faild :" ..guid_)
		end
	else
		print(" msg type error")
	end
end

function on_sd_query_channel_invite_cfg(game_id, msg)
	local gameid = game_id
	local data = dbopt.account:query("SELECT * FROM t_channel_invite;")
	if not data then
		log.error("on_sd_query_channel_invite_cfg not find guid:")
		return
	end
	local ret_msg = {}
	for k,v in pairs(data) do
		local tmp = {}
		tmp.channel_id = v.channel_id
		local channel_lock = v.channel_lock;
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
	if not data then
		log.error("on_sd_query_player_invite_reward not find guid:" .. guid_)
		return
	end

	data = data[1]

	return  {
		guid = guid_,
		reward = data.total_reward,
		}
end

function agent_transf(guid_ ,gameid , data)
	local sqlAgent =  string.format([[select transfer_id,proxy_guid,transfer_money,transfer_type,proxy_before_money,
		proxy_after_money from t_Agent_recharge_order where player_guid = %d and proxy_status = 1 and player_status = 0 and created_at < now() - 1]] , guid_)
	log.info(string.format("Agent [%s]",sqlAgent))
	
	local dataAgent = dbopt.recharge:query(sqlAgent)
	if dataAgent and #dataAgent > 0 then
		local Ttotal = #dataAgent
		local Tnum = 0
		for _,Agentdatainfo in pairs(dataAgent) do
			Tnum = Tnum + 1
			local Tbefore_bank = tonumber(data.bank)
			log.info(string.format("guid[%d] transfer_id [%s] bef_bank[%d] addmoney[%d]" ,guid_, Agentdatainfo.transfer_id ,Tbefore_bank,Agentdatainfo.transfer_money))
			data.bank = Tbefore_bank + Agentdatainfo.transfer_money
			local Tafter_bank = tonumber(data.bank)
			log.info(string.format("guid[%d] transfer_id [%s] after_bank[%d] addmoney[%d]" ,guid_, Agentdatainfo.transfer_id ,Tafter_bank,Agentdatainfo.transfer_money))
			-- 更新 t_recharge_order

			local TsqlR = string.format([[update t_Agent_recharge_order set player_status = 1, player_before_money = %d, player_after_money = %d, updated_at = current_timestamp where  transfer_id = '%s']], Tbefore_bank, Tafter_bank, Agentdatainfo.transfer_id)
			log.info("sqlR:" ..TsqlR)
			dbopt.recharge:query(TsqlR)
			-- --消息通知
			-- local notify = {
			-- 	GmCommand = "MSG",
			-- 	data = string.format([[{"name":"%%E5%%85%%85%%E5%%80%%BC%%E6%%88%%90%%E5%%8A%%9F","type":1,"content":"{\"content_type\":1,\"status\":1,\"time\":\"%s\",\"money\":%d,\"actual_money\":%f,\"order\":\"%s\"}","author":"recharge","start_time":"%s","end_time":"%s","guid":%d}]],
			-- 	os.date("%Y-%m-%d %H:%M:%S",os.time()),
			-- 	tonumber(Agentdatainfo.payment_amt),
			-- 	Agentdatainfo.actual_amt,
			-- 	Agentdatainfo.serial_order_no,
			-- 	os.date("%Y-%m-%d %H:%M:%S",os.time()),
			-- 	os.date("%Y-%m-%d %H:%M:%S",
			-- 	os.time() + 24*3600 * 3),
			-- 	guid_
			-- 	)
			-- }
			-- log.info(notify.data)
			-- send2login_pb(1,"WL_GMMessage",notify)

			--插入金钱记录
			local log_money_type = LOG_MONEY_OPT_TYPE_AGENTTOAGENT_MONEY
			if tonumber(Agentdatainfo.transfer_type) == 0 then
				log_money_type = LOG_MONEY_OPT_TYPE_AGENTTOAGENT_MONEY
			elseif tonumber(Agentdatainfo.transfer_type) == 1 then
				log_money_type = LOG_MONEY_OPT_TYPE_AGENTTOPLAYER_MONEY
			elseif tonumber(Agentdatainfo.transfer_type) == 2 then
				log_money_type = LOG_MONEY_OPT_TYPE_PLAYERTOAGENT_MONEY
			elseif tonumber(Agentdatainfo.transfer_type) == 3 then
				log_money_type = LOG_MONEY_OPT_TYPE_AGENTBANKTOPLAYER_MONEY
			end
			log.info(string.format("guid[%d] transfer_id[%s] transfer_type[%d] log_Type [%d]",guid_,Agentdatainfo.transfer_id,Agentdatainfo.transfer_type,log_money_type))
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
			dbopt.log:execute("INSERT INTO t_log_money SET $FIELD$;", log_money_)
			if Tnum ==  Ttotal then
				log.info("==========bank B:"..data.bank)
				--保存发送
				save_player(guid_, data)
				channel.publish("game."..tostring(gameid), "DS_LoadPlayerData", {
					guid = guid_,
					info_type = 1,
					pb_base_info = data,
				})
				channel.publish("game."..tostring(gameid), "DS_NotifyClientBankerChange", {
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
		channel.publish("game."..tostring(gameid), "DS_LoadPlayerData", {
			guid = guid_,
			info_type = 1,
			pb_base_info = data,
		})
	end
end

function  online_proc_recharge_order(guid_ ,gameid , data)		-- 该功能暂时未调用 ，根据线上反应 代理充值失败后 代理商可能会再给玩家补充 需要人工处理
	-- 查询未处理的订单
	local sqlT =  string.format([[ select id,exchange_gold,actual_amt,payment_amt,serial_order_no from t_recharge_order where pay_status = 1 and server_status != 1 and guid = %d]] , guid_);
	log.info(string.format("tttt %s",sqlT))
	local dataTR = dbopt.recharge:query(sqlT)
	if dataTR and #dataTR > 0 then
		local Ttotal = #dataTR
		local Tnum = 0
		for _,Tdatainfo in pairs(dataTR) do
			Tnum = Tnum + 1
			local Tbefore_bank = tonumber(data.bank)
			log.info(string.format("guid[%d] orderid [%d] bef_bank[%d] addmoney[%d]" ,guid_, Tdatainfo.id ,Tbefore_bank,Tdatainfo.exchange_gold))
			data.bank = Tbefore_bank + Tdatainfo.exchange_gold
			local Tafter_bank = tonumber(data.bank)
			log.info(string.format("guid[%d] orderid [%d] after_bank[%d] addmoney[%d]" ,guid_, Tdatainfo.id ,Tafter_bank,Tdatainfo.exchange_gold))
			-- 更新 t_recharge_order

			local TsqlR = string.format([[
					update t_recharge_order set server_status = 1, before_bank = %d, after_bank = %d where  id = '%d']], Tbefore_bank, Tafter_bank, Tdatainfo.id)
			log.info("sqlR:" ..TsqlR)
			dbopt.recharge:query(TsqlR)
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
				opt_type = LOG_MONEY_OPT_TYPE_RECHARGE_MONEY,
			}		
			dbopt.log:execute("INSERT INTO t_log_money SET $FIELD$;", log_money_)
			if Tnum ==  Ttotal then
				agent_transf(guid_ ,gameid , data)
				-- log.info("==========bank B:"..data.bank)
				-- --保存发送
				-- save_player(guid_, data)
				-- send2game_pb(gameid, "DS_LoadPlayerData", {
				-- 	guid = guid_,
				-- 	info_type = 1,
				-- 	pb_base_info = data,
				-- })
			end
		end
	else
		agent_transf(guid_ ,gameid , data)
		--log.info("==========bank B:"..data.bank)
		----保存发送
		--save_player(guid_, data)
		--send2game_pb(gameid, "DS_LoadPlayerData", {
		--	guid = guid_,
		--	info_type = 1,
		--	pb_base_info = data,
		--})
	end
end

function  on_ld_recharge( login_id, msg )
	-- body
	log.info(string.format("on_ld_recharge guid[%d]", msg.guid))
	local guid = msg.guid
	notify = {
		guid = msg.guid,
		retid = msg.retid,
		asyncid = msg.asyncid,
	}
	proc_recharge_order(guid ,login_id , notify , 1)
end

function proc_recharge_order( guid_ ,gameid_or_loginid , data , opttype ,last_login_channel_id )		-- opttype 为 1  在线充值 2离线充值
	query_player_is_or_not_collapse(guid_)

	-- 查询未处理的订单
	local sqlT =  string.format("call proc_recharge_order(%d)" , guid_);
	log.info(string.format("proc_recharge_order : %s" , sqlT));
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
			log.info(string.format("guid [%d] bankmoney[%d]", guid_ , bankmoney))
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
					opt_type = LOG_MONEY_OPT_TYPE_RECHARGE_MONEY,
					}
				
				dbopt.log:execute("INSERT INTO t_log_money SET $FIELD$;", log_money_)
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
				channel.publish("login.?","WL_GMMessage",notify)
				changemoney = changemoney + v.exchange_gold
			end
		end
		if rechargeData and rechargeData.recash then
			for _,v in pairs(rechargeData.recash) do
				log.info(string.format("guid[%d] id[%d] exchange_gold[%d] opttype[%d] order_id[%d] oldbank[%d] newbank[%d]" , guid_ , v.id , v.exchange_gold , v.opttype , v.order_id , v.oldbank , v.newbank ))
				-- 写日志
				local log_money_={
					guid = guid_,
					old_money = 0,
					new_money = 0,
					old_bank =  v.oldbank,
					new_bank =  v.newbank,
					opt_type = v.opttype,
					}
				
				dbopt.log:execute("INSERT INTO t_log_money SET $FIELD$;", log_money_)
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
					opt_type = LOG_MONEY_OPT_TYPE_SAVE_BACK,
					}
				dbopt.log:execute("INSERT INTO t_log_money SET $FIELD$;", log_money_)
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
		channel.publish("login."..tostring(gameid_or_loginid) , "DL_ReCharge" , data)
		log.info(string.format("player guid[%d] proc_recharge_order changemoney[%d]",guid_,changemoney))
	elseif tonumber(opttype) == 2 then
		if bankmoney > 0 then
			data.bank = bankmoney
		end
		log.info(string.format("proc_recharge_order guid[%d] online proc finish bank is [%d]",guid_, data.bank))
		--保存发送
		save_player(guid_, data)
		channel.publish("game."..tostring(gameid_or_loginid), "DS_LoadPlayerData", {
			guid = guid_,
			info_type = 1,
			pb_base_info = data,
		})
		channel.publish("game."..tostring(gameid_or_loginid),"",charge_rate(gameid_or_loginid , guid_ , last_login_channel_id))
		channel.publish("game."..tostring(gameid_or_loginid),"",get_player_append_info(gameid_or_loginid , guid_))
	end
end

function charge_rate(gameid , guid , last_login_channel_id)
	if last_login_channel_id == nil then
		return
	end
	log.info(string.format("charge_rate gameid [%d] guid[%d]" , gameid, guid))
	local Rdb = get_recharge_db()
	local sqlT =  string.format("call charge_rate(%d,'%s')" , guid,last_login_channel_id);
	log.info(string.format("charge_rate : %s" , sqlT));
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
	log.info(string.format("get_player_append_info gameid [%d] guid[%d]" , gameid, guid))
	local sqlT =  string.format("call get_player_append_info(%d)" , guid);
	log.info(string.format("get_player_append_info : %s" , sqlT));
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
	log.info(string.format("========guid [%d] is_guest[%s] player.platform_id = [%s]",guid_ , tostring(is_guest),platform_id))
	if is_guest then
		log.info(string.format("%d %d",get_init_money() , get_init_regmoney()))
		l_add_money = get_init_money() + get_init_regmoney()
		l_reg_money = 0
	end

	
    local data_count = dbopt.account:query("call get_account_count(%d , '%s' )" , guid_ , platform_id)
	if not data_count then
		log.error(string.format("on_sd_query_player_data get_account_count not find guid: %d" , guid_))
		return
	end

	data_count = data_count[1]

	if data_count.retcode then
		log.info(string.format("%d call get_account_count ret %d",guid_, tonumber(data_count.retcode)))
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
		log.error(string.format("on_sd_query_player_data not find guid: %d" , guid_))
		return
	end

	data = data[1]

	log.info(string.format("guid [%d] bank A: %d",guid_, data.bank))
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
	dbopt.game:query("UPDATE t_player SET money=" .. (msg.money or 0) .. " WHERE guid=" .. msg.guid ..";")
end

-- 立即保存银行钱
function on_SD_SavePlayerBank(game_id, msg)	
	dbopt.game:query("UPDATE t_player SET bank=" .. (msg.bank or 0) .. " WHERE guid=" .. msg.guid ..";")
end

-- 请求机器人数据
function on_sd_load_android_data(game_id, msg)
	local opttype = msg.opt_type
	local roomid = msg.room_id
	local data = dbopt.game:query("SELECT guid, account, nickname FROM t_player WHERE guid>%d AND is_android=1 ORDER BY guid ASC LIMIT %d;", msg.guid, msg.count)

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
    local data_ = dbopt.recharge:query("SELECT proxy_name FROM t_proxy_ad WHERE proxy_uid = %d;",proxy_guid)
	if not data_ then
		log.error(string.format("send_user_transfer_msg  get agent name failed proxy_uid[%d]"  , proxy_guid))
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
    log.info(string.format("on_sd_agent_transfer_success : guid [%d]",msg.player_guid))
    log.info(string.format("on_sd_agent_transfer_success : transfer_id [%s]",msg.transfer_id))
    log.info(string.format("on_sd_agent_transfer_success : player_oldmoney [%s]",tostring(msg.player_oldmoney)))
    log.info(string.format("on_sd_agent_transfer_success : player_newmoney [%s]",tostring(msg.player_newmoney)))
    
    
 	log.info(string.format("on_sd_agent_transfer_success : guid [%d] transfer_id[%s] oldmoney[%s] newmoney[%s] transfer_type[%d]"
		,msg.player_guid,msg.transfer_id,tostring(msg.player_oldmoney),tostring(msg.player_newmoney),msg.transfer_type))
 	local db_recharge = get_recharge_db()
	
	local player_status = 1 --success
 	local sql_set_order_status = string.format("CALL update_AgentTransfer_Order('%s' , %d , %d , %d , %d )",msg.transfer_id, 2 , player_status , msg.player_oldmoney , msg.player_newmoney)
	log.info(sql_set_order_status)

	local data = dbopt.recharge:query(sql_set_order_status)
	if not data then
		log.error(string.format("on_sd_agent_transfer_success update status faild : transfer_id:[%s] opt_type[%d]" ,msg.transfer_id, 2))
		return
	end

	data = data[1]

	log.info(string.format("on_sd_agent_transfer_success db_execute_query transfer_id [%s]  data.ret [%d]",msg.transfer_id,data.ret))
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

function add_player_money(login_id ,notify ,proxy_before_money,  proxy_after_money)
	log.info("==============add_player_money")
	log.info(string.format("add_player_money : proxy_guid [%d] player_guid [%d] transfer_id [%s] transfer_type [%d] transfer_money[%d]" , 
		notify.proxy_guid, notify.player_guid, notify.transfer_id, notify.transfer_type, notify.transfer_money))
	-- 订单生成成功 开始扣减代理商金币
	local sql_csot_agent_money = string.format("CALL change_player_bank_money(%d, %d,0)",notify.player_guid, notify.transfer_money)
	log.info(sql_csot_agent_money)
	local data = dbopt.game:query(sql_csot_agent_money)
	if not data then
		notify.retcode = 28 -- 数据库错误 无法 扣减代理商金币 
		log.info(string.format("add_player_money  mysql faild :[%d]  transfer_id[%s]"  , notify.retcode, notify.transfer_id))
	else
		data = data[1]
		log.info(string.format("add_player_money transfer_id [%s]  data.ret [%d]",notify.transfer_id,data.ret))
		if tonumber(data.ret) ~= 1 then  -- 2 代理商金币不足 4 代理商金币为空 5 update 代理商金币失败
			log.info(string.format("add_player_money faild ,data.ret[%d] [%d]",data.ret,notify.retcode))
			-- send2login_pb(login_id, "DL_CC_ChangeMoney",notify)
			-- return
		else
			log.info(string.format("transfer_id [%s] add_player_money is ok",notify.transfer_id))
			notify.oldmoney = data.oldbank
			notify.newmoney = data.newbank

			-- 入金币流水日志表
			local log_money_type = LOG_MONEY_OPT_TYPE_AGENTTOAGENT_MONEY
			if tonumber(notify.transfer_type) == 0 then
				log_money_type = LOG_MONEY_OPT_TYPE_AGENTTOAGENT_MONEY
			elseif tonumber(notify.transfer_type) == 1 then
				log_money_type = LOG_MONEY_OPT_TYPE_AGENTTOPLAYER_MONEY
			elseif tonumber(notify.transfer_type) == 2 then
				log_money_type = LOG_MONEY_OPT_TYPE_PLAYERTOAGENT_MONEY
			elseif tonumber(notify.transfer_type) == 3 then
				log_money_type = LOG_MONEY_OPT_TYPE_AGENTBANKTOPLAYER_MONEY
			end
			log.info(string.format("add_player_money transfer_id [%s] log_money_type is [%d]",notify.transfer_id,log_money_type))
			local log_money_= {
				guid = notify.player_guid,
				old_money = 0,
				new_money = 0,
				old_bank =  notify.oldmoney,
				new_bank =  notify.newmoney,
				opt_type = log_money_type,
			}
			dbopt.log:execute("INSERT INTO t_log_money SET $FIELD$;", log_money_)
		end
		notify.retcode = data.ret
	end
	-- 更新状态
	update_agent_order(2 , login_id ,notify, notify.retcode , proxy_before_money , proxy_after_money)
end

function update_agent_order(opt_type, login_id ,notify , code , proxy_before_money ,proxy_after_money )
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
		log.error(string.format("update_agent_order faild : [%d]  transfer_id:[%s] opt_type[%d]" ,notify.retcode , notify.transfer_id , opt_type))
		return notify
	end

	data = data[1]

	log.info(string.format("update_agent_order transfer_id [%s]  data.ret [%d] opt_type[%d]",notify.transfer_id,data.ret , opt_type))
	if tonumber(data.ret) ~= 1 then
		-- 91 需要注意 表示 代理商金币扣减成功 opt_type 1 表示代理商扣钱操作  2 表示玩家加钱操作 原来 11 表示代理商扣钱成功 但更新代理商状态失败 现在变为  111 表示上述意思  211 表示玩家加钱成功 更新状态失败 （这种情况 仅限代理商与代理商转账）
		notify.retcode = 90 + code + (opt_type * 100)-- 91 需要注意 表示 代理商金币扣减成功
		log.error(string.format("update_agent_order faild : [%d]  transfer_id:[%s] opt_type[%d] retcode [%d]" ,notify.retcode , notify.transfer_id , opt_type , notify.retcode))
		return notify
	end

	if tonumber(notify.transfer_type) ~= 0 then
		log.info(string.format("update_agent_order ok : [%d]  transfer_id:[%s] opt_type[%d]" ,notify.retcode , notify.transfer_id , opt_type))
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
		
		log.info(string.format("update_agent_order ok : [%d]  transfer_id:[%s] opt_type[%d]" ,notify.retcode , notify.transfer_id , opt_type))
		notify.retcode = code
		return notify
	end

	if tonumber(code) == 1 then
		local proxy_before_money = notify.oldmoney
		local proxy_after_money = notify.newmoney
		add_player_money(login_id ,notify ,proxy_before_money,  proxy_after_money)
	else
		log.info(string.format("update_agent_order ok : [%d]  transfer_id:[%s] opt_type[%d]" ,notify.retcode , notify.transfer_id , opt_type))
		notify.retcode = code
		return notify
	end
end

function cost_agent_money(login_id ,notify)
	log.info("==============cost_agent_money")
	log.info(string.format("cost_agent_money : proxy_guid [%d] player_guid [%d] transfer_id [%s] transfer_type [%d] transfer_money[%d]" , 
		notify.proxy_guid, notify.player_guid, notify.transfer_id, notify.transfer_type, notify.transfer_money))
	-- 订单生成成功 开始扣减代理商金币
	local sql_csot_agent_money = string.format("CALL change_player_bank_money(%d, %d,0)",notify.proxy_guid, -1 * notify.transfer_money)
	log.info(sql_csot_agent_money)
	local data = dbopt.game:query(sql_csot_agent_money)
	if not data then
		notify.retcode = 8 -- 数据库错误 无法 扣减代理商金币 
		log.info(string.format("cost_agent_money  mysql faild :[%d]  transfer_id[%s]"  , notify.retcode, notify.transfer_id))
	else
		data = data[1]
		log.info(string.format("cost_agent_money transfer_id [%s]  data.ret [%d]",notify.transfer_id,data.ret))
		if tonumber(data.ret) ~= 1 then  -- 2 代理商金币不足 4 代理商金币为空 5 update 代理商金币失败
			log.info(string.format("cost_agent_money faild ,data.ret[%d] [%d]",data.ret,notify.retcode))
			-- send2login_pb(login_id, "DL_CC_ChangeMoney",notify)
			-- return
		else
			log.info(string.format("transfer_id [%s] cost_agent_money is ok",notify.transfer_id))
			notify.oldmoney = data.oldbank
			notify.newmoney = data.newbank

			-- 入金币流水日志表
			local log_money_type = LOG_MONEY_OPT_TYPE_AGENTTOAGENT_MONEY
			if tonumber(notify.transfer_type) == 0 then
				log_money_type = LOG_MONEY_OPT_TYPE_AGENTTOAGENT_MONEY
			elseif tonumber(notify.transfer_type) == 1 then
				log_money_type = LOG_MONEY_OPT_TYPE_AGENTTOPLAYER_MONEY
			elseif tonumber(notify.transfer_type) == 2 then
				log_money_type = LOG_MONEY_OPT_TYPE_PLAYERTOAGENT_MONEY
			elseif tonumber(notify.transfer_type) == 3 then
				log_money_type = LOG_MONEY_OPT_TYPE_AGENTBANKTOPLAYER_MONEY
			end
			log.info(string.format("cost_agent_money transfer_id [%s] log_money_type is [%d]",notify.transfer_id,log_money_type))
			local log_money_= {
				guid = notify.proxy_guid,
				old_money = 0,
				new_money = 0,
				old_bank =  notify.oldmoney,
				new_bank =  notify.newmoney,
				opt_type =  log_money_type,
			}
			dbopt.log:execute("INSERT INTO t_log_money SET $FIELD$;", log_money_)
		end
		notify.retcode = data.ret
	end
	-- 更新状态
	update_agent_order(1 , login_id ,notify, notify.retcode)
end


function do_ld_cc_changemoney(login_id, msg, platform_id,channel_id,seniorpromoter)
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
		log.info(string.format("on_ld_cc_changemoney faild : %d" ,notify.retcode))
		return notify
	end

	data = data[1]

	log.info(string.format("on_ld_cc_changemoney transfer_id [%s]  data.ret [%d]",msg.transfer_id,data.ret))
	if tonumber(data.ret) == 0 then
		notify.retcode = 6 -- 存储过程错误 insert失败
		log.info(string.format("on_ld_cc_changemoney faild : %d" ,notify.retcode))
		return notify
	end

	if tonumber(data.ret) == 2 then
		notify.retcode = 7 -- 订单重复
		log.info(string.format("on_ld_cc_changemoney faild : %d" ,notify.retcode))
		return notify
	end
	
	if tonumber(data.ret) == 1 then
		cost_agent_money(login_id, notify)
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
	local data  = dbopt.account:query("SELECT platform_id,channel_id,ifnull(seniorpromoter,0) as seniorpromoter FROM t_account WHERE guid = %d;", msg.player_guid)
	data = data[1]
	if not data then
		notify.retcode = 7 --db error
		log.info(string.format("get_platform_id faild transfer_id[%s] proxy_guid[%d] player_guid[%d]" ,notify.transfer_id,msg.proxy_guid, msg.player_guid))
		return notify
	end

	log.info(string.format("on_ld_cc_changemoney get_platform_id [%s] channel_id [%s] seniorpromoter [%d]",data.platform_id,data.channel_id,data.seniorpromoter))
	do_ld_cc_changemoney(login_id, msg,data.platform_id,data.channel_id,data.seniorpromoter)
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
	
	log.info(string.format("msg.type[%s] platform_ids[%s]",msg.type,platform_ids))

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
	log.info(string.format("%s",sql))
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
	nickname = '%s', money = %d, win_money = %d, bet_money = %d,tax = %d, curtime = %d;",
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
	log.info(string.format("on_sd_recharge begin ------- guid[%d] orderid[%d] bef_bank[%d] aft_bank[%d] login[%d]",msg.guid,msg.orderid,msg.befor_bank,msg.after_bank,msg.loginid))
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
		channel.publish("login."..tostring(loginid), "DL_ReCharge",notify)
		return
	end

	data = data[1]
	
	if tonumber(data.retCode) == 0 then
		log.info(string.format("on_sd_recharge success guid[%d] orderid[%d] bef_bank[%d] aft_bank[%d]",notify.guid,notify.orderid,bef_bank,aft_bank))
		notify.retcode = GMmessageRetCode_Success
	else			
		log.info(string.format("on_sd_recharge db faild guid[%d] orderid[%d] bef_bank[%d] aft_bank[%d] ret [%d]",notify.guid,notify.orderid,bef_bank,aft_bank,data.retCode))
	end
	log.info(string.format("DL_ReCharge loginid[%d]",loginid))
	channel.publish("login."..tostring(loginid), "DL_ReCharge",notify)
end

--提现失败，归还金币到银行
function cash_failed_back_bankMoney(game_id,guid_,back_bank_money,error_code)
	log.info(string.format("cash_failed_back_bankMoney guid_[%d],back_bank_money[%d]",guid_,back_bank_money))

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
	log.info(string.format("cash_failed_back_bankMoney guid_[%d],old_bank[%d] new_bank[%d]",guid_,data.oldbank,data.newbank))
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
		select channel_id as bag_id_ from t_account where guid = %d;]], 
		guid_)

	bag_id_ = data[1].bag_id_

	local sql = string.format([[
	CALL insert_cash_money(%d,%d,%d,%d,'%s','%s','%s','%s', %d, %d, %d, %d ,%d,0,'%s', %d)
	]], guid_, money_, coins_, pay_money_, ip_, phone_, phone_type_, bag_id_, bef_money_, bef_bank_, aft_money_, aft_bank_,cash_type_,platform_id_,msg.seniorpromoter)

	log.info(string.format("sql [%s]",sql))
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

	log.error(string.format("do_WithDrawCash_Success error guid [%d]",guid_))
	--退还扣除所有的金币
	return cash_failed_back_bankMoney(game_id,guid_,coins_,6)
end

function on_SD_WithDrawCash(game_id , msg)
	log.info(string.format("on_SD_WithDrawCash begin ------- guid[%d] cost_money[%d] cost_bank[%d] seniorpromoter[%d]",msg.guid,msg.cost_money,msg.cost_bank,msg.seniorpromoter))

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
 	log.info(string.format("do_agent_addplayer_money_sucess : guid [%d] transfer_id[%s] transfer_type[%d]",msg.player_guid,msg.transfer_id,msg.transfer_type))

 	local db_recharge = get_recharge_db()
	
	local player_status = 1 --success
 	local sql_set_order_status = string.format("CALL update_AgentTransfer_Order('%s' , %d , %d , %d , %d )",msg.transfer_id, 2 , player_status ,oldbank, newbank)
	log.info(sql_set_order_status)

	local data = dbopt.recharge:query(sql_set_order_status)
	if not data then
		log.error(string.format("on_sd_agent_transfer_success update status faild : transfer_id:[%s] opt_type[%d]" ,msg.transfer_id, 2))
		return
	end

	data = data[1]

	log.info(string.format("on_sd_agent_transfer_success db_execute_query transfer_id [%s]  data.ret [%d]",msg.transfer_id,data.ret))
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
		log.error(string.format("on_LD_AgentAddPlayerMoney failed player_guid[%d] proxy_guid[%d] transfer_id[%s]",msg.player_guid,msg.proxy_guid,msg.transfer_id))
		return notify_agent_addmoney(login_id,msg,0,0,3)
	end

	data = data[1]
	
	if tonumber(data.ret) == 1 then
		--成功
		do_agent_addplayer_money_sucess(msg,data.oldbank,data.newbank)
		return notify_agent_addmoney(login_id,msg,data.oldbank,data.newbank,data.ret)
	else
		log.error(string.format("on_LD_AgentAddPlayerMoney failed player_guid[%d] proxy_guid[%d] transfer_id[%s]",msg.player_guid,msg.proxy_guid,msg.transfer_id))
		return notify_agent_addmoney(login_id,msg,data.oldbank,data.newbank,data.ret)
	end
end

--查询玩家是否破产
function query_player_is_or_not_collapse(guid_)
	-- body
	if guid_ > 0 then
		local sql =  string.format("call judge_player_is_collapse(%d)" , guid_);

		local data = dbopt.game:query(sql)
		if data then
			data = data[1]
			--log.info(string.format("player guid[%d] is collapse............",guid_))
			local playerData = json.decode(data.retdata)
			if playerData and tonumber(playerData.is_collapse) == 1 then
				log.info(data.retdata)
				if playerData.channel_id and playerData.platform_id then
					log.info(string.format("guid [%d] is collapse  is_collapse[%d] channel_id[%s] platform_id[%s]", guid_,playerData.is_collapse,playerData.channel_id,playerData.platform_id))
					local log_db = get_log_db()
					local update_sql = string.format([[
						INSERT INTO `t_log_bankrupt`(`day`,`guid`,`times_pay`,`bag_id`,`plat_id`) VALUES('%s',%d,1,'%s','%s') ON DUPLICATE KEY UPDATE `times_pay`=(`times_pay`+1),`bag_id`=VALUES(`bag_id`),`plat_id`=VALUES(`plat_id`)]],
							os.date("%Y-%m-%d",os.time()),guid_,playerData.channel_id,playerData.platform_id);
					log_db:execute(update_sql)
				end
			end
		else
			log.info(string.format("guid[%d] data is null..........................",guid_))
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

	dbopt.account:query(sql)
	print("on_ld_BankcardEdit=============================================1")
	notify.EditNum = 1
	return notify
end