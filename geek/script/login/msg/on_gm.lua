
local redisdb = require "redisopt"
local json = require "cjson"
require "login.msg.runtime"
local channel = require "channel"
local json = require "cjson"

local reddb = redisdb[0]

local function on_MSG(fd,asyncid,doc)
	if not json_has_member(doc,{
		type = "number",
		content = "string",
		start_time = "string",
		end_time = "string",
	}) then
		return
	end

	local check_msg_type = {
		[1] = function(doc) return not doc.number or not doc.interval_time or not doc.guid end,
		[2] = function(doc) return not doc.name or not doc.author or not doc.guid end,
		[3] = function(doc) return not doc.name or not doc.author end,
	}

	local type = doc.type
	local check_f = check_msg_type[type]
	if not check_f or check_f(doc) then
		log.error("on_wl_request_GMMessage  type not find : %d", type)
		return new_gm_msg(GMmessageRetCode_MsgParamMiss,asyncid)
	end

	local request = {}
	request.asyncid =  asyncid
	if type == 1 then
		request.guid = doc.guid
	end
	request.type = doc.type
	request.content = doc.content
	request.start_time = doc.start_time
	request.end_time = doc.end_time
	if type == 3 then
		request.number = doc.number
		request.interval_time = doc.interval_time
	else
		request.name = doc.name
		request.author = doc.author
	end

	if (type == 2 or type == 3) and doc.plat and type(doc.plat) == "table" then
		request.platforms = doc.plat
	end

	request.retid = fd
	log.info( "retid:%d", fd )
	channel.publish("db.?","msg","LD_NewNotice",request)
end

local function on_MSG_DELETE(fd,asyncid,doc)
	if not json_has_member(doc,{
		type = "number",
		id = "number",
	}) then
		return new_gm_msg(GMmessageRetCode_MsgParamMiss,asyncid)
	end

	
	if doc.type ~= 1 and doc.type ~= 2 and doc.type ~=3 then
		return new_gm_msg(GMmessageRetCode_MsgTypeError,asyncid)
	end
	
	channel.publish("db.?","msg","LD_DelMessage",{
		msg_type = doc.type,
		msg_id = doc.id,
		retid = fd,
		asyncid = asyncid,
	})
end

local function on_feedback(fd,asyncid,doc)
	if not json_has_member(doc,{
		guid = "number",
		type = "number",
		updatetime = "number",
		feedbackid = "number",
	}) then
		return new_gm_msg(GMmessageRetCode_FBParamMiss,asyncid)
	end


	local function update_feedback(fd,asyncid,doc)
		local guid = doc.guid
		local RetID = fd
		local type = doc.type
		local updatetime = doc.updatetime
		local feedbackid = doc.feedbackid
		local gateid,account = player_is_online(guid)
	
		if not gateid then
			sendpb(fd,"LW_GMMessage",{
				result = GMmessageRetCode_FBPlayerOffline,
				asyncid = asyncid,
			})
			return
		end
	
		channel.publish("gate."..tostring(gateid),"msg","LG_FeedBackUpdate",{
			guid = guid,
			type = type,
			updatetime = updatetime,
			retid = fd,
			feedbackid = feedbackid,
			asyncid = asyncid,
		})
	end
	
	update_feedback( fd,asyncid, doc )
end

local function on_newserver(fd,asyncid,doc)
	if not json_has_member(doc,{
		ip = "string",
		port = "number",
	}) then
		return new_gm_msg(GMmessageRetCode_FBParamMiss,asyncid)
	end


	channel.publish("gate.*","msg","LG_AddNewGameServer",{
		ip = doc.ip,
		port = doc.port,
		retid = fd,
	})

	return new_gm_msg(GMmessageRetCode_Success, asyncid )
end

local function on_edit_alipay(fd,asyncid,doc)
	if not json_has_member(doc,{
		guid = "number",
		alipay_name = "string",
		alipay_name_y = "string",
		alipay_account = "string",
		alipay_account_y = "string",
	}) then
		return new_gm_msg(GMmessageRetCode_FBParamMiss,asyncid)
	end


	local function edit_alipay(fd,asyncid,doc)
		local asyncid_ = asyncid;
		local guid = doc.guid
		local alipay_name = doc.alipay_name
		local alipay_name_y = doc.alipay_name_y
		local alipay_account = doc.alipay_account
		local alipay_account_y = doc.alipay_account_y
		local retid = fd
		local gateid,account = player_is_online(guid)
		if gateid then
			local gameid = reddb.hget("player_online_gameid",guid)
			if gameid then
				channel.publish("game."..tostring(gameid),"msg","LS_AlipayEdit",{
					guid = guid,
					alipay_name = alipay_name,
					alipay_name_y = alipay_name_y,
					alipay_account = alipay_account,
					alipay_account_y = alipay_account_y,
				})
			end
		end

		channel.publish("db.?","msg","LD_AlipayEdit",{
			guid = guid,
			alipay_name = alipay_name,
			alipay_name_y = alipay_name_y,
			alipay_account = alipay_account,
			alipay_account_y = alipay_account_y,
			retid = fd,
			asyncid = asyncid
		})
	end

	edit_alipay( fd,asyncid, doc )
end

local function on_edit_bankcard(fd,asyncid,doc)
	if not json_has_member(doc,{
		guid = "number",
		bank_card_name = "string",
		bank_card_num = "string",
		bank_name = "string",
		bank_province = "string",
		bank_city = "string",
		bank_branch = "string"
	}) then
		return new_gm_msg(GMmessageRetCode_FBParamMiss,asyncid)
	end


	local function edit_bank_card(fd,asyncid,doc)
		local guid = doc["guid"]
		local bank_card_name = doc["bank_card_name"]
		local bank_card_num = doc["bank_card_num"]
		local bank_name = doc["bank_name"]
		local bank_province = doc["bank_province"]
		local bank_city = doc["bank_city"]
		local bank_branch = doc["bank_branch"]
	
		if not bank_card_name or  bank_card_num then
			bank_card_name = "**"
			bank_card_num = "**"
			bank_name = ""
			bank_province = ""
			bank_city = ""
			bank_branch = ""
		end
	
		local retid = fd
		local gateid,account = player_is_online(guid)
		
		if gateid then
			local gameid = reddb.hget("player_online_gameid",guid)
			if gameid then
				channel.publish("game."..tostring(gameid),"msg","LS_BankcardEdit",{
					guid = guid,
					bank_card_name = bank_card_name,
					bank_card_num = bank_card_num,
					bank_name = bank_name,
					bank_province = bank_province,
					bank_city = bank_city,
					bank_branch = bank_branch,
				})
			end
		end

		channel.publish("db.?","msg","LD_BankcardEdit",{
			guid = guid,
			bank_card_name = bank_card_name,
			bank_card_num = bank_card_num,
			bank_name = bank_name,
			bank_province = bank_province,
			bank_city = bank_city,
			bank_branch = bank_branch,
			retid = retid,
			asyncid = asyncid,
		})
	   
	end

	edit_bank_card(fd, asyncid, doc )
end


function on_handle_agent_transfer_ChangeMoney( fd, asyncid,stData ) 
	log.info( "on_handle_agent_transfer_ChangeMoney : id[%s]", stData.transfer_id)
	local keyid = tostring(stData.transfer_id)..tostring(os.time())
	cost_agent_bank_money( keyid, stData.agentsid, stData.playerid, stData.transfer_money, stData.transfer_type, stData.transfer_id, json.encode(stData),
	function( retCode, oldmoeny, newmoney, strData )
		local stData = json.decode(strData)
		if retCode == ChangMoney_Success then
			log.info( "cost_agent_bank_money Agent cost money success, agent id [%d] ,playerid = [%d],orderid = [%s] retCode[%d],transfer_type[%d].", 
				stData.agentsid, stData.playerid, stData.transfer_id, retCode, stData.transfer_type )
			if stData.transfer_type == 0 then
				log.info( "transfer_id[%s] agent_A[%d] transfer to other agent_B[%d] success,transfer_type[%d].", 
					stData.transfer_id, stData.agentsid, stData.playerid, stData.transfer_type )
			else
				add_player_bank_money( stData, oldmoeny, newmoney )
			end
		else
			log.error( "cost agent money failed,agent id [%d] ,playerid = [%d],orderid = [%s] retCode[%d].", 
				stData.agentsid, stData.playerid, stData.transfer_id, retCode )
		end
		return new_gm_msg(retCode,asyncid)
	end)
end

local function on_agent_transfer(fd,asyncid,doc)
	log.info( "AgentsTransfer========start" )
	
	if not json_has_member(doc,{
		proxy_guid = "number",
		player_guid = "number",
		transfer_id = "number",
		transfer_type = "number",
		transfer_money = "number",
		ignore_platform = "number",
	}) then
		return new_gm_msg(GMmessageRetCode_FBParamMiss,asyncid)
	end


	log.info( "AgentsTransfer======== param  check ok proxy_guid[%d] player_guid[%d] transfer_id[%d] transfer_type[%d] transfer_money[%d] ignore_platform[%d]",
			  doc["proxy_guid"],
			  doc["player_guid"],
			  doc["transfer_id"],
			  doc["transfer_type"],
			  doc["transfer_money"],
			  doc["ignore_platform"]
			)
			  
	
	local stData = {}
	stData.agentsid = doc["proxy_guid"]
	stData.playerid = doc["player_guid"]
	local strTransferid = "php_"
	strTransferid = strTransferid + tostring(doc["transfer_id"])
	stData.transfer_id = strTransferid
	stData.transfer_type = doc["transfer_type"]
	stData.transfer_money = doc["transfer_money"]
	stData.retid = fd
	if stData.transfer_money <= 0 then
		log.info( "transfer_id [%d] return GMmessageRetCode::GMmessageRetCode_ATMoneyParamError ", doc["transfer_id"])
		return new_gm_msg( GMmessageRetCode_ATMoneyParamError,  asyncid )
	end

	if stData.transfer_type() == 0 then
	elseif stData.transfer_type() == 1 then
	elseif stData.transfer_type() == 2 then
	else
		log.info( "transfer_id [%d] return GMmessageRetCode::GMmessageRetCode_ATtypeError ", doc["transfer_id"])
		return new_gm_msg(GMmessageRetCode_ATtypeError,  asyncid)
	end

	if stData.agentsid == stData.playerid then
		log.info( "transfer_id [%d] return GMmessageRetCode::GMmessageRetCode_AT_PL_onePlayer ", doc["transfer_id"] )
		return new_gm_msg(GMmessageRetCode_AT_PL_onePlayer, asyncid )
	end

	local keyid = tostring(stData.transfer_id)..tostring(os.time())
	local strsql = string.format( "call check_is_agent(%d,%d,%d)",stData.agentsid,stData.playerid,doc["ignore_platform"] )
	create_do_Sql(keyid, "account", strsql, json.encode(stData), function( retCode, retData,strData )
		if retCode == 9999 then
			log.info( "transfer_id [%s] return GMmessageRetCode::GMmessageRetCode_AT_PL_onePlayer ", strTransferid)
			return new_gm_msg(GMmessageRetCode_DBRquestError, asyncid )
		end

		local stDataR = json.decode(strData)
		local pl = retCode % 10
		local ATe = retCode / 10

		if pl == 9 then
			log.info( "transfer_id [%s] return GMmessageRetCode::GMmessageRetCode_PLnofindUser ", strTransferid )
			return new_gm_msg( GMmessageRetCode_PLnofindUser, asyncid)
		end

		if ATe == 9 then
			log.info( "transfer_id [%s] return GMmessageRetCode_ATnofindUser ", strTransferid.c_str() )
			return new_gm_msg( GMmessageRetCode_ATnofindUser, asyncid)
		end

		if  stData.transfer_type == 0 then
			if  pl + ATe ~= 2 then
				if  ATe ~= 1 then
					log.info( "transfer_id [%s] return GMmessageRetCode_ATCantTransfer ", strTransferid.c_str )
					return new_gm_msg( GMmessageRetCode_ATCantTransfer, asyncid)
				end
				if  pl ~= 1 then
					log.info( "transfer_id [%s] return GMmessageRetCode_PLCantTransfer ", strTransferid.c_str )
					return new_gm_msg( GMmessageRetCode_PLCantTransfer, asyncid)
				end
			end
		elseif  stData.transfer_type == 1 then
			if  ATe ~= 1 then
				log.info( "transfer_id [%s] return GMmessageRetCode_ATCantTransfer ", strTransferid.c_str )
				return new_gm_msg( GMmessageRetCode_ATCantTransfer, asyncid)
			end
			if  pl ~= 0 then
				return new_gm_msg( GMmessageRetCode_PL_ISAgent, asyncid)
			end
		elseif  stData.transfer_type == 2 then
			if  pl ~= 1 then
				log.info( "transfer_id [%s] return GMmessageRetCode_PLCantTransfer ", strTransferid.c_str )
				return new_gm_msg( GMmessageRetCode_PLCantTransfer, asyncid)
			end
		end
		on_handle_agent_transfer_ChangeMoney( fd,asyncid, stData )
	end)
end

local function on_freeze_account(fd,asyncid,doc)
	if not json_has_member(doc,{
		guid = "number",
		status = "number",
	}) then
		return new_gm_msg(GMmessageRetCode_FBParamMiss,asyncid)
	end


	local stData = {}
	stData.guid = doc["guid"]
	stData.status = doc["status"]
	stData.retid = fd
	stData.login_id = netopt.byfd(fd).server_id
	stData.asyncid = asyncid

	local keyid = tostring(stData.guid) .. tostring(os.time())
	local strsql = string.format( "call FreezeAccount(%d,%d)",stData.guid,stData.status)
	create_do_Sql( keyid, "account", strsql, json.encode(stData), function( retCode, retData, strData )
		if retCode ~= 0 then
			return new_gm_msg( GMmessageRetCode_DBRquestError, asyncid )
		end

		local stDataR = json.decode(strData)
		local guid = stDataR.guid
		local status = stDataR.status
		local retid = stDataR.retid
		local server_idT = stData.login_id
		local gateid,account = player_is_online(stDataR.guid)

		if gateid then
			local gameid = reddb.hget("player_online_gameid",guid)
			if gameid then
				channel.publish("game."..tostring(gameid),"msg", stDataR )
			else
				return new_gm_msg( GMmessageRetCode_FreezeAccountOnLineFaild, asyncid )
			end
		else
			return new_gm_msg( GMmessageRetCode_Success, asyncid )
		end
	end)
end

local function on_update_proxy(fd,asyncid,doc)
	if not json_has_member(doc,{
		platform_id = "number",
	}) then
		return new_gm_msg(GMmessageRetCode_FBParamMiss,asyncid)
	end


	channel.publish("db.?","msg","S_RequestProxyInfo",{
		platform_id = doc.platform_id,
		loginid = netopt.byfd(fd).server_id,
	})

	return new_gm_msg( GMmessageRetCode_Success, asyncid )
end

local function on_update_pay_switch(fd,asyncid,doc)
	if not json_has_member(doc,{
		platform_id = "number",
	}) then
		return new_gm_msg(GMmessageRetCode_FBParamMiss,asyncid)
	end


	channel.publish("config.?","msg","S_RequestPlatformRechargeSwitchIndex",{
		platform_id = doc.platform_id,
		update_flag = 1,
	})

	return new_gm_msg( GMmessageRetCode_Success, asyncid );
end

local function on_update_all_cash_switch(fd,asyncid,doc)
	if not json_has_member(doc,{
		platform_id = "number",
	}) then
		return new_gm_msg(GMmessageRetCode_FBParamMiss,asyncid)
	end

	channel.publish("config.?","msg","S_RequestPlatformRechargeSwitchIndex",{
		platform_id = doc.platform_id,
		update_flag = 1,
	})

	return new_gm_msg( GMmessageRetCode_Success, asyncid )
end

local function on_create_proxy_account(fd,asyncid,doc)
	if not json_has_member(doc,{
		guid = "number",
		proxy_id = "number",
		platform_id = "number",
	}) then
		return new_gm_msg(GMmessageRetCode_FBParamMiss,asyncid)
	end


	local creater_guid = doc.guid
	if creater_guid == 0 then creater_guid = 1215163 end

	channel.publish("db.?","msg","LD_CreateProxyAccount",{
		web_id = fd,
		guid = creater_guid,
		proxy_id = doc.proxy_id,
		platform_id = doc.platform_id,
		asyncid = asyncid,
	})
end

local function on_update_globle_int_cfg(fd,asyncid,doc)
	local globlekey = {}
	if doc.globlekeys then
		for _,v in pairs(doc.globlekeys) do
			table.insert(v)
		end
	end


	if #globlekey > 0 then
		channel.publish("config.?","msg","S_RequestGlobleIntCfg",{
			globlekey = globlekey,
		})
		return new_gm_msg(GMmessageRetCode_Success,asyncid)
	else
		return new_gm_msg(GMmessageRetCode_GmParamMiss,asyncid)
	end
end

local function on_update_promoter_msg(fd,asyncid,doc)
	if json_has_member(doc,{
		guid = "number",
		type = "number",
		level = "number",
	}) then
		return new_gm_msg(GMmessageRetCode_GmParamMiss,asyncid)
	end


	local guid = doc.guid
	local type = doc.type
	local level = doc.level

	local gateid,account = player_is_online(guid)
	if not gateid then
		return new_gm_msg( GMmessageRetCode_Success, asyncid )
	end

	local gameid = reddb.hget("player_online_gameid",guid)
	if gameid then
		channel.publish("game."..tostring(gameid),"msg","LS_Player_Identiy",{
			guid = guid,
			identity_type = type,
			identity_param = level,
		})
	end

	return new_gm_msg(GMmessageRetCode_Success,asyncid)
end

local function on_update_risk(fd,asyncid,doc)
	if json_has_member(doc,{
		guid = "number",
		risk = "number",
	}) then
		return new_gm_msg(GMmessageRetCode_GmParamMiss,asyncid)
	end


	local guid = doc.guid
	local risk = doc.risk

	local gateid,account = player_is_online(guid)
	if not gateid then
		return new_gm_msg(GMmessageRetCode_Success,asyncid)
	end

	local gameid = reddb.hget("player_online_gameid",guid)
	if gameid then
		channel.publish("game."..tostring(gameid),"msg","LS_Update_Risk",{
			guid = guid,
			risk = risk,
		})
	end

	return new_gm_msg(GMmessageRetCode_Success,asyncid)
end

local function on_update_sensior_promoter(fd,asyncid,doc)
	if json_has_member(doc,{
		guid = "number",
		seniorpromoter = "number",
	}) then
		return new_gm_msg(GMmessageRetCode_GmParamMiss,asyncid)
	end

	local guid = doc.guid
	local seniorpromoter = doc.seniorpromoter

	local gateid,account = player_is_online(guid)
	if not gateid then
		return new_gm_msg(GMmessageRetCode_Success,asyncid)
	end

	local gameid = reddb.hget("player_online_gameid",guid)
	if gameid then
		channel.publish("game."..tostring(gameid),"msg","LS_Player_SeniorPromoter",{
			guid = guid,
			seniorpromoter = seniorpromoter,
		})
	end

	return new_gm_msg(GMmessageRetCode_Success,asyncid)
end

local gm_cmd_func = {
    MSG = on_MSG,
    MSG_DELET = on_MSG_DELETE,
    FeedBack = on_feedback,
    newServer = on_newserver,
    EditAlipay = on_edit_alipay,
    EditBankcard = on_edit_bankcard,
	AgentsTransfer = on_agent_transfer,
	FreezeAccount = on_freeze_account,
	UpdateProxy = on_update_proxy,
	UpdatePaySwitch = on_update_pay_switch,
	UpdateAllCashSwitch = on_update_all_cash_switch,
	CreateProxyAccount = on_create_proxy_account,
	UpdatetGlobleIntCfg = on_update_globle_int_cfg,
	UpdatePromoterMsg = on_update_promoter_msg,
	UpDataRisk = on_update_risk,
	UpdateSeniorPromoter = on_update_sensior_promoter,
}

function on_wl_request_GMMessage(fd,asyncid,doc)  
    local asyncid = msg.asyncid
    local doc = json.decode(msg.data)

	local f = gm_cmd_func[msg.gmcommand]
	if not f then
		return new_gm_msg( GMmessageRetCode_GmCommandError,asyncid)
	end

	f(fd,asyncid,doc)
end