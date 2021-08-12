-- 玩家数据消息处理
local log = require "log"
local dbopt = require "dbopt"
local json = require "json"
local enum = require "pb_enums"
local queue = require "skynet.queue"
local timer = require "timer"
local skynet = require "skynet"

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

	-- 单独执行，避免统计时锁表卡住
	dbopt.log:query([[
			INSERT INTO t_log_money(guid,money_id,old_money,new_money,`where`,reason,reason_ext,created_time) 
			VALUES(%d,%d,%d,%d,%d,%d,'%s',%d);
		]],
		guid,money_id,old_money,new_money,where,why,
		why_ext or '',timer.milliseconds_time()
	)
end

function on_sd_change_player_money(items,why,why_ext)
	for _,item in pairs(items) do
		incr_player_money(item.guid,item.money_id,item.old_money,item.new_money,item.where or 0,why,why_ext)
	end
end


function on_sd_new_money_type(msg)
	local id = msg.id
	local club_id = msg.club_id
	local money_type = msg.type
	dbopt.game:batchquery("INSERT INTO t_money(id,type,club_id) VALUES(%d,%d,%s)",id,money_type,club_id)
end

local function transfer_money_club2player(club_id,guid,money_id,amount,why,why_ext,operator)
	log.info("transfer_money_club2player club:%s,guid:%s,money_id:%s,amount:%s,why:%s,why_ext:%s,operator:%s",
		club_id,guid,money_id,amount,why,why_ext,operator)
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

local function transfer_money_player2club(guid,club_id,money_id,amount,why,why_ext,operator)
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

local function transfer_money_club2club(club_id_from,club_id_to,money_id,amount,why,why_ext,operator)
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


local function transfer_money_player2player(from,to,money_id,why,why_ext,operator)
	local from_guid = from.guid
	local to_guid = to.guid
	local amount = from.new_money - (from.old_money or 0)
	log.info("transfer_money_player2player from:%s,to:%s,money_id:%s,amount:%s,why:%s,why_ext:%s,opertor:%s",
		from_guid,to_guid,money_id,amount,why,why_ext,operator)
	local sqls = {
		{
			[[
				INSERT INTO t_player_money(guid,money_id,money) VALUES(%s,%s,%s),(%s,%s,%s) 
				ON DUPLICATE KEY UPDATE money = VALUES(money);
			]],from_guid,money_id,from.new_money,to_guid,money_id,to.new_money
		},
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

	local res = dbopt.log:query([[
			INSERT INTO t_log_recharge(source_id,target_id,type,operator,money,comment,created_time) VALUES(%d,%d,%d,%d,%s,'%s',%d);
		]],
		from_guid,to_guid,4,operator,"","",os.time()
	)
	if res.errno then
		log.error("on_sd_log_recharge insert into t_log_recharge info throw exception.[%d],[%s]",res.errno,res.err)
		return
	end

	why_ext = res.insert_id

	local logsqls = {
		{
			[[
				INSERT INTO t_log_money(guid,money_id,old_money,new_money,`where`,reason,reason_ext,created_time) 
				VALUES(%d,%d,%d,%d,0,%d,'%s',%s),(%d,%d,%d,%d,0,%d,'%s',%s)
			]],
			from_guid,money_id,from.old_money or 0,from.new_money,why,why_ext,timer.milliseconds_time(),
			to_guid,money_id,to.old_money or 0,to.new_money,why,why_ext,timer.milliseconds_time()
		}
	}

	res = dbopt.log:batchquery(logsqls)
	if res.errno then
		log.error("transfer_money_player2club insert log error,errno:%d,err:%s",res.errno,res.err)
	end

	return enum.ERROR_NONE
end

function on_sd_transfer_money(msg)
	local from = msg.from
	local to = msg.to
	local trans_type = msg.type
	local money_id = msg.money_id
	local amount = msg.amount
	local why = msg.why
	local why_ext = msg.why_ext
	local operator = msg.operator

	if trans_type == 1 then
		return transfer_money_club2player(from,to,money_id,amount,why,why_ext,operator)
	end

	if trans_type == 2 then
		return transfer_money_player2club(from,to,money_id,amount,why,why_ext,operator)
	end

	if trans_type == 3 then
		return transfer_money_club2club(from,to,money_id,amount,why,why_ext,operator)
	end

	if trans_type == 4 then
		return transfer_money_player2player(from,to,money_id,why,why_ext,operator)
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

	local sets = table.series(msg,function(v,f) 
		local v = type(v) == "string" and "'" .. v .. "'" or v
		return string.format("%s = %s",f,v)
	end)

	local sql = string.format("UPDATE t_player SET %s WHERE guid = %s;",table.concat(sets,","),guid)
	log.dump(sql)
	local r = dbopt.game:query(sql)
	if r.errno then
		log.error("on_sd_update_player_info UPDATE t_player error,%s,%s",r.errno,r.err)
	end
end