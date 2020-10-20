-- 桌子基类

require "game.net_func"
local log = require "log"
local enum = require "pb_enums"
require "msgopt"
local base_players = require "game.lobby.base_players"
local base_private_table = require "game.lobby.base_private_table"
local redisopt = require "redisopt"
local club_table = require "game.club.club_table"
local base_clubs = require "game.club.base_clubs"
local timer_manager = require "game.timer_manager"
local onlineguid = require "netguidopt"
local skynet = require "skynetproto"
local channel = require "channel"
local club_money_type = require "game.club.club_money_type"
local player_money = require "game.lobby.player_money"
local player_club = require "game.lobby.player_club"
local club_template_conf = require "game.club.club_template_conf"
local club_team_template_conf = require "game.club.club_team_template_conf"
local club_utils = require "game.club.club_utils"
local club_role = require "game.club.club_role"
local json = require "cjson"
local util = require "util"
local club_partner_commission = require "game.club.club_partner_commission"
local club_member_partner = require "game.club.club_member_partner"
local club_partner_template_commission = require "game.club.club_partner_template_commission"
local club_partner_template_default_commission = require "game.club.club_partner_template_default_commission"
local club_partners = require "game.club.club_partners"
local reddb = redisopt.default
local queue = require "skynet.queue"
local game_util = require "game.util"

local dismiss_timeout = 60
local auto_dismiss_timeout = 10 * 60
local auto_kickout_timer = 5 * 60

local EXT_ROUND_STATUS = {
	NONE = 0,
	FREE = 1,
	GAMING = 2,
	END = 3,
}

-- local base_prize_pool = require "game.lobby.base_prize_pool"
-- 奖池
-- global_prize_pool = global_prize_pool or base_prize_pool:new()

local base_table = {}
-- 创建
function base_table:new()
    local o = {}
    setmetatable(o, {__index = self})

    return o
end

-- 获取当前游戏ID
function base_table:get_next_game_id()
	local sround_id = string.format(
		[[%03d-%03d-%04d-%s-%03d]], def_game_id, self.room_.id, self.table_id_,os.date("%Y%m%d%H%M%S"),math.floor((skynet.time() % 1) * 1000)
	)
	log.info(sround_id)
	return sround_id
end

function base_table:get_ext_game_id()
	local sext_round_id = string.format("%03d-%03d-%04d-%s-%06d",def_game_id,self.room_.id, self.table_id_,os.date("%Y%m%d%H%M%S"),math.random(1,100000))
	log.info(sext_round_id)
	return sext_round_id
end

function base_table:hold_game_id()
	self.round_id = self.round_id or self:get_ext_game_id()
	return self.round_id
end

function base_table:hold_ext_game_id()
	self.ext_round_id = self.ext_round_id or self:get_ext_game_id()
	return self.ext_round_id
end

function base_table:start_save_info()
	log.info("===============start_save_info")
	for _,v in ipairs(self.players) do
		-- 添加游戏场次
		v:inc_play_times()
		-- 记录对手
		v:set_player_ip_control(self.players)
	end
	log.info("===============start_save_info end")
end

function base_table:can_enter(player)
	log.info("base_table:can_enter")
	return true
end

function base_table:clear()
	self:clear_dismiss_request()
	self:private_clear()
	self:clear_ready()
	self.round_id = nil
	self.ext_round_id = nil
	self.cur_round = nil
end

-- 初始化
function base_table:init(room, table_id, chair_count)
	self.room_ = room
	self.table_id_ = table_id
	self.chair_count = chair_count
	self.start_count = chair_count
	self.player_count = 0
	self.def_game_name = def_game_name
	self.def_game_id = def_game_id
	self.game_end_event = {}
	self.players = {}
	self.config_id = room.config_id
	self.tax_show_ = room.tax_show -- 是否显示税收信息
	self.tax_open_ = room.tax_open -- 是否开启税收
	self.tax_ = room.tax

	self.room_limit = room.room_limit -- 房间分限制
	self.cell_score = room.cell_score -- 底注
	self.game_switch_is_open = room.game_switch_is_open
	self.ready_list = {}

	self.notify_msg = {}
	if self.tax_show_ == 1 then
		self.notify_msg.flag = 3
	else
		self.notify_msg.flag = 4
	end

	self.ext_round_status = nil
	self.lock = queue()
end

function base_table:lockcall(fn,...)
	return self.lock(fn,...)
end

function base_table:is_play( ... )
	log.info("base_table:is_play")
	return false
end

function base_table:load_lua_cfg( ... )
	log.info("base_table:load_lua_cfg")
	return false
end

function base_table:get_chair_count()
	return self.chair_count
end

function base_table:get_free_chair_id()
	if table.nums(self.players) >= self.start_count then
		return nil
	end

	for i = 1, self.start_count do 
		if not self.players[i] then return i end
	end

	return nil
end

function base_table:begin_clock(timeout,player,total_time)
	if player then 
		send2client_pb(player,"SC_TimeOutNotify",{
			left_time = math.ceil(timeout),
			total_time = total_time and math.floor(total_time) or nil,
		})
		return
	end
	
	self:broadcast2client("SC_TimeOutNotify",{
		left_time = timeout,
		total_time = total_time,
	})
end

function base_table:on_reconnect(player)
	if not self.dismiss_request then return end

	local status = {}
	for chair,is in pairs(self.dismiss_request.commissions) do
		local p = self.players[chair]
		table.insert(status,{
			guid = p.guid,
			chair_id = chair,
			agree = is,
		})
	end

	local requester = self.dismiss_request.requester
	local timer = self.dismiss_request.timer

	send2client_pb(player,"SC_DismissTableRequestInfo",{
		result = enum.ERROR_NONE,
		request_guid = requester.guid,
		request_chair_id = requester.chair_id,
		datetime = os.time(),
		timeout = timer and math.ceil(timer.remainder) or 0,
		status = status,
	})
end

function base_table:request_dismiss(player)
	local timer = self:new_timer(dismiss_timeout,function()
		self:foreach(function(p)
			if not self.dismiss_request then
				return
			end

			if self.dismiss_request.commissions[p.chair_id] == nil then
				self:commit_dismiss(p,true)
			end
		end)
	end)

	if self.dismiss_request then
		send2client_pb(player.guid,"SC_DismissTableReq",{
			result = enum.ERROR_OPERATION_REPEATED
		})
		return
	end

	self.dismiss_request = {
		commissions = {},
		requester = player,
		datetime = os.time(),
		timer = timer,
	}

	self.dismiss_request.commissions[player.chair_id] = true

	self:broadcast2client("SC_DismissTableReq",{
		result = enum.ERROR_NONE,
		request_guid = player.guid,
		request_chair_id = player.chair_id,
		datetime = os.time(),
		timeout = dismiss_timeout,
	})

	self:broadcast2client("SC_DismissTableCommit",{
		result = enum.ERROR_NONE,
		chair_id = player.chair_id,
		guid = player.guid,
		agree = true,
	})

	return enum.ERROR_NONE
end

function base_table:clear_dismiss_request()
	if not self.dismiss_request then return end

	if self.dismiss_request.timer then
		self.dismiss_request.timer:kill()
		self.dismiss_request.timer = nil
	end

	self.dismiss_request = nil
end

function base_table:commit_dismiss(player,agree)
	if not self.dismiss_request then
		log.error("commit dismiss but not dismiss request,guid:%d,agree:%s",player.guid,agree)
		return enum.ERROR_OPERATION_EXPIRE
	end

	local commissions = self.dismiss_request.commissions
	agree = agree and agree == true or false

	commissions[player.chair_id] = agree and agree == true or false

	self:broadcast2client("SC_DismissTableCommit",{
		chair_id = player.chair_id,
		guid = player.guid,
		agree = agree,
	})

	local done,succ = self:check_dismiss_commit(commissions)
	if not done then
		return
	end

	self:clear_dismiss_request()
	
	if not succ then
		self:broadcast2client("SC_DismissTable",{
			success = false,
		})
		return
	end

	self:dismiss()
end

local function get_real_club_template_conf(club,template_id)
    local conf = club_template_conf[club.id][template_id]
    if not conf then
        club = base_clubs[club.parent]
        if not club then return end
        conf = club_team_template_conf[club.id][template_id]
        if not conf then return end
    end

    return conf
end

local function calc_club_template_commission_rate(club,template_id)
    if not club or not club.parent or club.parent == 0 then
        return 1
    end

    local conf = get_real_club_template_conf(club,template_id)
    if not conf then
        return 0
    end

    local rate = (conf and conf.commission_rate or 0) / 10000
    if rate == 0 then
        return rate
    end

    return rate * calc_club_template_commission_rate(base_clubs[club.parent],template_id)
end

function base_table:calc_score_money(score)
	local base_multi = 1
    if self.private_id then
        local private_table = base_private_table[self.private_id]
        local rule = private_table.rule
        base_multi = rule.union and rule.union.score_rate or 1
	end
	
	return score * 100 * base_multi
end

function base_table:do_commission_standalone(guid,commission,contributer)
	if not self.private_id then 
		return
	end

	local club = self.conf.club
	if not club or club.type ~= enum.CT_UNION then
		log.error("base_table:do_commission_standalone [%d] got private club.",self.private_id)
		return
	end

	local private_table = base_private_table[self.private_id]
	if not private_table then 
		log.error("base_table:do_commission_standalone [%d] got nil private table.",self.private_id)
		return
	end

	local template_id = private_table.template
	if not template_id then
		log.error("base_table:do_commission_standalone [%d] got nil template.",self.private_id)
		return
	end

	commission = math.floor(commission + 0.000001)
	if commission <= 0 then
		return
	end

	channel.publish("db.?","msg","SD_LogPlayerCommissionContribute",{
		parent = guid,
		guid = contributer,
		commission = commission,
		template = template_id,
		club = club.id,
	})

	club:incr_team_commission(guid,commission,self.ext_round_id)
end

function base_table:do_commission(taxes)
	if not self.private_id then 
		return
	end

	local money_id = self:get_money_id()
	if not money_id then
		log.error("base_table:do_commission [%d] got nil private money id.",self.private_id)
		return
	end

	local club = self.conf.club
	if not club then
		log.error("base_table:do_commission [%d] got private club.",self.private_id)
		return
	end

	local private_table = base_private_table[self.private_id]
	if not private_table then 
		log.error("base_table:do_commission [%d] got nil private table.",self.private_id)
		return
	end

	local template_id = private_table.template
	if not template_id then
		log.error("base_table:do_commission [%d] got nil template.",self.private_id)
		return
	end

	local function get_club_partner_template_commission_rate(c_id,t_id,partner_id)
		local commission_rate = club_partner_template_commission[c_id][t_id][partner_id]
		if not commission_rate then
			partner_id = club_member_partner[c_id][partner_id]
			if not partner_id then
				return 1
			end
			commission_rate = club_partner_template_default_commission[c_id][t_id][partner_id]
		end
	
		return commission_rate and commission_rate / 10000 or 0
	end

	local club_id = club.id
	local commissions = {}
	for guid,tax in pairs(taxes) do
		local last_rate = 0
		local p_guid = guid
		local s_guid = guid
		while p_guid and p_guid ~= 0 do
			local role = club_role[club_id][p_guid]
			if role == enum.CRT_BOSS or role == enum.CRT_PARTNER then
				local commission_rate = get_club_partner_template_commission_rate(club_id,template_id,p_guid)
				local commission = tax * (commission_rate - last_rate)
				last_rate = commission_rate

				commissions[p_guid] = (commissions[p_guid] or 0) + commission

				channel.publish("db.?","msg","SD_LogPlayerCommissionContribute",{
					parent = p_guid,
					guid = s_guid,
					commission = math.floor(commission + 0.00000001),
					template = template_id,
					club = club_id,
				})

				log.info("base_table:do_commission club:%s,partner:%s,commission:%s",club_id,p_guid,commission)
			end

			s_guid = p_guid
			p_guid = club_member_partner[club_id][p_guid]
		end
	end

	for guid,commission in pairs(commissions) do
		commission = math.floor(commission + 0.0001)
		if commission > 0 then
			club:incr_team_commission(guid,commission,self.ext_round_id)
		end
	end
end

function base_table:cost_tax(winlose)
	local money_id = self:get_money_id()
	if not money_id then
		log.error("base_table:cost_tax [%d] got nil private money id.",self.private_id)
		return
	end
	
	if not self.private_id then
		return
	end

	local club = self.conf.club
	if not club then
		log.warning("base_table:cost_tax [%d] got nil club id,don't cost tax = 0.",self.private_id)
		return
	end

	if club.type ~= enum.CT_UNION then
		return
	end

	local rule = self.rule
	if not rule then
		log.error("base_table:cost_tax [%d] got nil private rule conf.",self.private_id)
		return
	end

	local taxconf = rule.union and rule.union.tax or nil
	if not taxconf or (not taxconf.AA and not taxconf.big_win) then
		log.error("base_table:cost_tax [%d] got nil private tax conf.",self.private_id)
		return
	end

	local function do_cost_tax_money(taxes)
		for _,p in pairs(self.players) do
			local change = taxes[p.guid] or 0
			log.dump(change)
			if change ~= 0 then
				club:incr_member_money(p.guid,-change,enum.LOG_MONEY_OPT_TYPE_GAME_TAX,self.round_id)
			end
		end

		self:notify_game_money()
	end

	if taxconf.AA and not winlose then
		if self.cur_round ~= 1 then
			return
		end

		local tax = {}
		for _,p in pairs(self.players) do
			tax[p.guid] = taxconf.AA
		end

		log.dump(self.round_id)
		do_cost_tax_money(tax)
		self:do_commission(tax)
		return
	end

	if taxconf.big_win and winlose and table.nums(winlose) > 0 then
		log.dump(winlose)
		log.dump(taxconf)

		local bigwin_conf = taxconf.big_win
		local winloselist = table.series(winlose,function(change,guid) 
			return {guid = guid,change = change} 
		end)

		table.sort(winloselist,function(l,r) return l.change > r.change end)

		table.sort(bigwin_conf,function(l,r)
			if l[1] < 0 then return false end
			if r[1] < 0 then return true end
			return l[1] < r[1] 
		end)

		local bigwin_data = winloselist[1]
		local maxwin = bigwin_data.change
		if maxwin <= 0 then
			log.warning("base_table:cost_tax [%d] invalid maxwin:%s.",self.private_id,maxwin)
			return
		end

		local bigwin_guid
		local bigwin_tax
		for _,s in ipairs(bigwin_conf) do
			if not s or #s < 2 then break end
			if maxwin <= s[1] or s[1] < 0 then
				bigwin_tax = s[2] or 0
				bigwin_guid = bigwin_data.guid
				break
			end
		end

		if not bigwin_tax or not bigwin_guid then
			log.warning("base_table:cost_tax [%d] invalid bigwin tax,maxwin:%s.",self.private_id,maxwin)
			return
		end

		log.dump(bigwin_guid)
		log.dump(bigwin_tax)

		do_cost_tax_money({
			[bigwin_guid] = bigwin_tax,
		})

		if bigwin_tax <= (taxconf.min_ensurance or 0) then
			self:do_commission_standalone(club.owner,bigwin_tax,bigwin_guid)
			return
		end

		local eachwin = bigwin_tax / table.nums(self.players)
		local commission_tax = table.map(self.players,function(p) return p.guid,math.floor(eachwin) end)

		self:do_commission(commission_tax)
		return
	end
end

function base_table:notify_game_money()
	local player_moneys = {}
	local money_id = self:get_money_id()
	for chair_id,p in pairs(self.players) do
		table.insert(player_moneys,{
			chair_id = chair_id,
			money_id = money_id,
			money = player_money[p.guid][money_id] or 0,
		})
	end

	self:broadcast2client("SYNC_OBJECT",util.format_sync_info(
		"GAME",{},{
			players = player_moneys,
		}))
end

function base_table:game_over()
	self:check_game_maintain()

	self:on_game_overed()
end

function base_table:on_final_game_overed(bankruptcy)
	self:on_process_over()

	self.round_id = nil
	self.ext_round_id = nil
	self.cur_round = nil
end

function base_table:on_game_overed()
	self.old_moneies = nil
	self:clear_ready()
	if self.private_id then
		if table.logic_or(self.players,function(p) return self:is_bankruptcy(p) end) then
			self:notify_bankruptcy(enum.ERROR_BANKRUPTCY_WARNING)
			self:on_final_game_overed()
			self:foreach(function(p)
				p:forced_exit()
			end)
			return
		end

		if self.cur_round and self.cur_round >= self.conf.round then
			self:on_final_game_overed()
			self:delay_dismiss()
		end
	end
end

-- 得到玩家
function base_table:get_player(chair_id)
	if not chair_id then
		return nil
	end
	return self.players[chair_id]
end

-- 设置玩家
function base_table:set_player(chair_id, player)
	self.players[chair_id] = player
end

-- 得到玩家列表
function base_table:get_player_list()
	return self.players
end

--用户数量
function base_table:get_player_count()
	return table.nums(self.players)
end

-- 遍历桌子
function base_table:foreach(func,except)
	for i,p in pairs(self.players) do
		repeat
			if type(except) == "function" and except(p,i) then
				break
			end

			if i == except or p == except then
				break
			end

			func(p,i)
 		until true
	end
end

function base_table:foreach_except(except, func)
	for i, p in pairs(self.players) do
		if i ~= except and p ~= except then
			func(p,i)
		end
	end
end

function  base_table:save_game_log(gamelog)
	log.info("==============================base_table:save_game_log")
	log.info(json.encode(gamelog))
	local nMsg = {
		game_id = def_first_game_type,
		game_name = def_game_name,
		log = gamelog,
		starttime = self.start_time,
		endtime = os.time(),
		round_id = self.round_id,
		ext_round_id = self.ext_round_id,
	}
	channel.publish("db.?","msg","SL_Log_Game",nMsg)
end

function base_table:player_bet_flow_log(player,money)
	if player:is_android() then return end

	if money <= 0 then return end

	local msg = {
		guid = player.guid,
		account = player.account,
		money = money
	}

	channel.publish("db.?","msg","SD_LogBetFlow",msg)
end

function base_table:player_money_log_when_gaming(player,money_id,old_money,change_money)
	local nMsg = {
		guid = player.guid,
		type = change_money > 0 and 2 or 1,
		gameid = self.def_game_id,
		game_name = self.def_game_name,
		money_id = money_id,
		old_money = old_money,
		new_money = player.money,
		change_money = change_money,
		id = self.round_id,
		platform_id = player.platform_id,
	}
	channel.publish("db.?","msg","SD_LogGameMoney",nMsg)
end

function base_table:robot_money_log(robot,banker_flag,winorlose,old_money,tax,money_change,round_id)
	log.info("==============================base_table:robot_money_log")
	local nMsg = {
		guid = robot.guid,
		isbanker = banker_flag,
		winorlose = winorlose,
		gameid = self.def_game_id,
		game_name = self.def_game_name,
		old_money = old_money,
		new_money = robot.money,
		tax = tax,
		money_change = money_change,
		id = round_id,
	}
	channel.publish("db.?","msg","SL_Log_Robot_Money",nMsg)
end

--渠道税收分成
function base_table:channel_invite_taxes(channel_id_p,guid_p,guid_invite_p,tax_p)
	log.info("ChannelInviteTaxes channel_id:" .. channel_id_p .. " guid:" .. guid_p .. " guid_invite:" .. tostring(guid_invite_p) .. " tax:" .. tax_p)
	if tax_p == 0 or guid_invite_p == nil or guid_invite_p == 0 then
		return
	end
	local cfg = channel_invite_cfg(channel_id_p)
	if cfg and cfg.is_invite_open == 1 then
		log.info("ChannelInviteTaxes step 2--------------------------------")
		local nMsg = {
			channel_id = channel_id_p,
			guid = guid_p,--贡献者
			guid_invite = guid_invite_p,--受益者
			val = math.floor(tax_p*cfg.tax_rate/100)
		}
		channel.publish("db.?","msg","SL_Channel_Invite_Tax",nMsg)
	end
end


-- 广播桌子中所有人消息
function base_table:broadcast2client(msgname, msg)
	local guids = {}
	self:foreach(function(p) table.insert(guids,p.guid) end)
	onlineguid.broadcast(guids,msgname,msg)
end

function base_table:broadcast2client_except(except,msgname, msg)
	local guids = {}
	self:foreach_except(except,function(p) table.insert(guids,p.guid) end)
	onlineguid.broadcast(guids,msgname,msg)
end




function base_table:calculate_gps_distance(pos1,pos2)
	local R = 6371393
	local C = math.sin(pos1.latitude) * math.sin(pos2.latitude) * math.cos(pos1.longitude-pos2.longitude)
		+ math.cos(pos1.latitude) * math.cos(pos2.latitude)

	return R * math.acos(C) * math.pi/180
end

function base_table:check_cheat_control(player,reconnect)
	local option = self.rule and self.rule.option
	if not option then
		return enum.ERROR_NONE
	end

	if option.ip_stop_cheat and self:check_same_ip_net(player) then
		return enum.ERROR_IP_TREAT
	end

	if option.gps_distance and option.gps_distance >= 0 then
		if not player.gps_latitude or not player.gps_longitude then
			return enum.ERROR_GPS_TREAT
		end

		local player_gps = {
			longitude = player.gps_longitude,
			latitude = player.gps_latitude,
		}

		local limit = option.gps_distance
		local is_gps_treat = table.logic_or(self.players,function(p)
			local p_gps = {
				longitude = p.gps_longitude,
				latitude = p.gps_latitude,
			}
			local dist = self:calculate_gps_distance(p_gps,player_gps)
			log.info("player %s,%s distance %s",p.guid,player.guid,dist)
			return dist < limit
		end)

		if is_gps_treat then
			return enum.ERROR_GPS_TREAT
		end
	end

	return enum.ERROR_NONE
end

function base_table:check_same_ip_net(player)
	local function ipsec(ip)
		local ips = {}
		for s in ip:gmatch("%d+") do
			table.insert(ips,tonumber(s))
		end

		return ips
	end

	local function same_ip_net(ip1,ip2)
		local s1 = ipsec(ip1)
		local s2 = ipsec(ip2)
		if #s1 < 3 or #s2 < 3 then
			return false
		end
	
		return s1[1] == s2[1] and s1[2] == s2[2] and s1[3] == s2[3]
	end

	local login_ip = player.login_ip
	return table.logic_or(self.players,function(p)
		if p == player then return end
		return same_ip_net(login_ip,p.login_ip)
	end)
end

function base_table:can_sit_down(player,chair_id,reconnect)
	if reconnect then 
		return enum.ERROR_NONE 
	end

	if self.players[chair_id] then
		return enum.ERROR_INTERNAL_UNKOWN
	end

	local cheat_check = self:check_cheat_control(player,reconnect)
	if cheat_check ~= enum.ERROR_NONE then
		return cheat_check
	end

	if self.private_id then
		if self.cur_round or self:is_play() then
			return enum.ERROR_TABLE_STATUS_GAMING
		end
	else
		if self:is_play() then
			return enum.ERROR_TABLE_STATUS_GAMING
		end
	end

	return enum.ERROR_NONE
end

function base_table:on_player_sit_down(player,chair_id,reconnect)

end

-- 玩家坐下
function base_table:player_sit_down(player, chair_id,reconnect)
	local can =  self:can_sit_down(player,chair_id,reconnect)
	if can ~= enum.ERROR_NONE then
		return can
	end

	player.table_id = self.table_id_
	player.chair_id = chair_id
	self.players[chair_id] = player
	log.info("base_table:player_sit_down, guid %s, table_id %s, chair_id %s",
			player.guid,player.table_id,player.chair_id)

	self.player_count = self.player_count + 1
	self:on_player_sit_down(player,chair_id,reconnect)
	
	if not player:is_android() then
		for i, p in ipairs(self.players) do
			if p == false then
				-- 主动机器人坐下
				player:on_notify_android_sit_down(def_game_id, self.table_id_, i)
			end
		end
	end

	reddb:hmset("player:online:guid:"..tostring(player.guid),{
		table = self.table_id_,
		chair = chair_id,
	})

	local privatetb = base_private_table[self.private_id]
	self:foreach_except(player.chair_id,function (p)
		p:notify_sit_down(player,reconnect,privatetb)
	end)

	self:broadcast_sync_table_info_2_club(enum.SYNC_UPDATE,self:global_status_info())

	onlineguid[player.guid] = nil

	return enum.LOGIN_RESULT_SUCCESS
end

function base_table:player_sit_down_finished(player)
	return
end

function base_table:on_private_pre_dismiss()
	if self.cur_round and self.cur_round > 0 and self.cur_round <= self.conf.round then
        self:on_final_game_overed()
    end
end

function base_table:on_private_dismissed()
	self:foreach(function(p)
		p:forced_exit(enum.STANDUP_REASON_DISMISS)
	end)
end

function base_table:can_dismiss()
	return true
end

function base_table:check_dismiss_commit(agrees)
	local all_count = table.nums(self.players)
    local done_count = table.nums(agrees)
    local agree_count_at_least = self.rule.room.dismiss_all_agree and all_count or math.floor(all_count / 2) + 1
    local refuse_done_count = all_count - agree_count_at_least
    local agree_count = table.sum(agrees,function(agree) return agree and 1 or 0 end)
    local refuse_count = done_count - agree_count
    local agreed = agree_count >= agree_count_at_least
    local refused = refuse_count > refuse_done_count
    local done = agreed or refused or done_count >= all_count
	return done,agreed
end

function base_table:dismiss()
	log.info("base_table:dismiss %s",self.private_id)
	if not self.conf or not self.private_id then
		log.warning("dismiss non-private table,real_table_id:%s",self.table_id)
		return enum.GAME_SERVER_RESULT_PRIVATE_ROOM_NOT_FOUND
	end

	if not self:can_dismiss() then
		return enum.ERROR_OPERATION_INVALID
	end

	self:cancel_delay_dismiss()
	self:cancel_all_dealy_kickout()
	self:on_private_pre_dismiss()

	self:broadcast_sync_table_info_2_club(enum.SYNC_DEL)

	log.info("base_table:dismiss %s,%s",self.private_id,self.table_id_)
	local private_table_conf = base_private_table[self.private_id]
	local club_id = private_table_conf.club_id
	local private_table_id = private_table_conf.table_id
	local private_table_owner = private_table_conf.owner
	reddb:del("table:info:"..private_table_id)
	reddb:del("player:table:"..private_table_owner)
	
	if club_id then
		reddb:srem("club:table:"..club_id,private_table_id)
		club_table[club_id][private_table_id] = nil
	end

	base_private_table[self.private_id] = nil
	self:broadcast2client("SC_DismissTable",{success = true,})
	self:clear()

	self:on_private_dismissed()

	self.private_id = nil
	self.conf = nil
	self.cur_round = nil
	self.start_count = self.chair_count
	self.ext_round_status = nil

	return enum.GAME_SERVER_RESULT_SUCCESS
end

function base_table:transfer_owner()
	log.info("transfer owner:%s,%s",self.conf.private_id,self.conf.owner.guid)
	if not self.conf or not self.private_id then
		log.warning("dismiss non-private table,real_table_id:%s",self.table_id)
		return enum.GAME_SERVER_RESULT_PRIVATE_ROOM_NOT_FOUND
	end

	local function next_player(owner)
		local chair_id = owner.chair_id
		for i = chair_id,chair_id + self.chair_count - 2 do
			local p = self.players[i % self.chair_count + 1]
			if p then
				return p
			end
		end

		return nil
	end

	local private_conf = self.conf
	local private_table_id = self.private_id
	local old_owner = private_conf.owner
	local new_owner = next_player(old_owner)
	if not new_owner then
		log.warning("base_table:transfer_owner %s,%s,old:%s, new owner not found",self.private_id,self.table_id_,old_owner.guid)
		return enum.GAME_SERVER_RESULT_CREATE_PRIVATE_ROOM_CHAIR
	end

	log.info("base_table:transfer_owner %s,%s,old:%s,new:%s",self.private_id,self.table_id_,old_owner.guid,new_owner.guid)
	reddb:srem("player:table:"..old_owner.guid,private_table_id)
	reddb:hset("table:info:"..private_table_id,"owner",new_owner.guid)
	reddb:sadd("player:table:"..new_owner.guid,private_table_id)
	reddb:expire("player:table:"..new_owner.guid,dismiss_timeout)
	private_conf.owner = new_owner

	self:broadcast2client("S2C_TRANSFER_ROOM_OWNER_RES",{
		table_id = self.private_id,
		old_owner = old_owner.guid,
		new_owner = new_owner.guid,
	})

	return enum.GAME_SERVER_RESULT_SUCCESS
end

function base_table:cancel_ready(chair_id)
	self.ready_list[chair_id] = nil
	self:broadcast2client("SC_Ready", {
		ready_chair_id = chair_id,
		is_ready = false,
	})
end

function base_table:is_ready(chair_id)
	return self.ready_list[chair_id] ~= nil	
end

function base_table:is_private()
	return self.private_id and self.conf
end

function base_table:delay_dismiss(player)
	self.dismiss_timer = self:new_timer(auto_dismiss_timeout,function()
		log.info("base_table:delay_dismiss timeout %s",self.table_id_)
		self:dismiss()
	end)
	log.info("base_table:delay_dismiss %s",self.dismiss_timer.id)
end

function base_table:cancel_delay_dismiss()
	log.info("base_table:cancel_delay_dismiss %s",self.dismiss_timer and self.dismiss_timer.id or nil)
	if not self.dismiss_timer then
		return
	end

	self.dismiss_timer:kill()
	self.dismiss_timer = nil
end

function base_table:delay_kickout(player)
	log.info("delay_kickout %s",player.guid)
	player.kickout_timer = self:new_timer(auto_kickout_timer,function()
		if not self.ext_round_status or self.ext_round_status == EXT_ROUND_STATUS.FREE then
			player:forced_exit()
		end
		self:cancel_delay_kickout(player)
	end)
end

function base_table:cancel_delay_kickout(player)
	log.info("cancel_delay_kickout %s",player.guid)
	if not player.kickout_timer then
		return
	end
	
	player.kickout_timer:kill()
	player.kickout_timer = nil
end

function base_table:cancel_all_dealy_kickout()
	self:foreach(function(p)
		self:cancel_delay_kickout(p)
	end)
end

function base_table:broadcast_sync_table_info_2_club(type,roominfo)
	if not self.private_id then
		return
	end

	local priv_tb = base_private_table[self.private_id]
	if not priv_tb then
		return 
	end

	if not priv_tb.club_id then
		return
	end


	local club = base_clubs[priv_tb.club_id]
	if not club then
		return
	end

	local root = club_utils.root(club)
	root:recusive_broadcast("S2C_SYNC_TABLES_RES",{
		root_club = root.id,
		club_id = club.id,
		room_info = roominfo,
		sync_table_id = self.private_id,
		sync_type = type or enum.SYNC_UPDATE,
	})
end

-- 玩家站起
function base_table:player_stand_up(player, reason)
	log.info("base_table:player_stand_up, guid %s, table_id %s, chair_id %s, reason %s,offline:%s",
			player.guid,player.table_id,player.chair_id,reason,reason == enum.STANDUP_REASON_OFFLINE)

	log.info("guid %s,reason %s,offline:%s",player.guid,reason,reason == enum.STANDUP_REASON_OFFLINE)
	if reason == enum.STANDUP_REASON_OFFLINE then
		self:on_offline(player)
		self:foreach_except(player.chair_id,function(p)
			p:notify_stand_up(player,true)
		end)
	end

	if self:can_stand_up(player, reason) then
		local player_count = table.nums(self.players)
		-- 玩家掉线不直接解散,针对邀请玩家进入房间情况
		if 	self.private_id and 
			self.ext_round_status == EXT_ROUND_STATUS.FREE and 
			reason == enum.STANDUP_REASON_OFFLINE 
		then
			self:delay_kickout(player)
			return
		end
		log.info("base_table:player_stand_up success")
		local chairid = player.chair_id
		local p = self.players[chairid]
		local list_guid = p and p.guid or -1
		log.info("set guid[%s] table_id[%s] players[%d] is false [ player_list is %s , player_list.guid [%s]]",
			player.guid,player.table_id,chairid , self.players[chairid], list_guid)
		self.player_count = self.player_count - 1
		self:on_player_stand_up(player,reason)

		if self:is_ready(chairid) then
			self:cancel_ready(chairid)
		end

		if self.private_id and player == self.conf.owner and player_count > 1 then
			self:transfer_owner()
		end

		self:foreach_except(player.chair_id,function(p)
			p:notify_stand_up(player)
		end)

		player.table_id = nil
		player.chair_id = nil

		self.players[chairid] = nil

		if 	player_count == 1 and
			(self.ext_round_status == EXT_ROUND_STATUS.END or reason ~= enum.STANDUP_REASON_OFFLINE) 
		then
			self:dismiss()
		else
			self:broadcast_sync_table_info_2_club(enum.SYNC_UPDATE,self:global_status_info())
		end

		reddb:hdel("player:online:guid:"..tostring(player.guid),"global_table")
		reddb:hdel("player:online:guid:"..tostring(player.guid),"table")
		reddb:hdel("player:online:guid:"..tostring(player.guid),"chair")
		onlineguid[player.guid] = nil

		self:check_start()

		return true
	end

	return false
end

function base_table:on_player_stand_up(player,reason)

end

function base_table:on_offline(player)
	player.inactive = true
end

function base_table:set_trusteeship(player,trustee)
	log.info("====================base_table:set_trusteeship")
	self:broadcast2client("SC_Trustee",{
		result = enum.ERROR_NONE,
		chair_id = player.chair_id,
		is_trustee = trustee and true or false,
	})
end

-- 准备开始
function base_table:ready(player)
	if player.disable == 1 then
		--当玩家处理冻结状态时
		player:forced_exit()
		return
	end

	if not self:check_ready(player) then
		return
	end

	if not player.table_id then
		log.warning("guid[%d] not find in table", player.guid)
		return
	end

	if not player.chair_id then
		log.warning("guid[%d] not find in chair_id", player.guid)
		return
	end

	local ready_mode = self.room_:get_ready_mode()
	if ready_mode == enum.GAME_READY_MODE_NONE then
		log.warning("guid[%d] mode=GAME_READY_MODE_NONE", player.guid)
		return
	end

	self.lock(function()
		if self.ready_list[player.chair_id] then
			log.warning("chair_id[%d] ready error,guid[%d]", player.chair_id,player.guid)
			return true
		end

		log.info("set tableid [%d] chair_id[%d]  ready_list is %s ",self.table_id_,player.chair_id,player.guid)
		self.ready_list[player.chair_id] = player

		-- 机器人准备
		self:foreach(function(p)
			if p:is_android() and (not self.ready_list[p.chair_id]) then
				self.ready_list[p.chair_id] = p
				self:broadcast2client("SC_Ready", {
					ready_chair_id = p.chair_id,
					is_ready = true,
				})
			end
		end)

		-- 通知自己准备
		self:broadcast2client("SC_Ready", {
			ready_chair_id = player.chair_id,
			is_ready = true,
		})

		self:check_start(false)
	end)
end

function base_table:reconnect(player)
	-- 重新上线
	log.info("---------base_table:reconnect,%s-----------",player.guid)
	log.info("set Dropped is false")
	log.info("set online is true")
	player.inactive = nil
	log.info("set player[%d] in_game true" ,player.guid)
	self:on_reconnect(player)
	self:cancel_delay_kickout(player)
end

-- 检查是否可准备
function base_table:check_ready(player)
	return true
end

function base_table:can_stand_up(player,reason)
	if  reason == enum.STANDUP_REASON_FORCE or 
		reason == enum.STANDUP_REASON_DISMISS then
		--掉线 用于结算
		log.info("set Dropped true")
		return true
	end

	if reason == enum.STANDUP_REASON_OFFLINE then
		return false
	end

	return self.room_:get_ready_mode() ~= enum.GAME_READY_MODE_NONE
end

-- 检查开始
function base_table:check_start(part)
	local ready_mode = self.room_:get_ready_mode()
	log.info("ready_mode %s,%s",ready_mode,part)
	if ready_mode == enum.GAME_READY_MODE_PART then
		local n = table.nums(self.ready_list)
		if n >= 2 then
			self:start(n)
		end
	end

	if part then
		return
	end

	if ready_mode == enum.GAME_READY_MODE_ALL then
		local n = table.nums(self.ready_list)
		if n ~= self.start_count  then
			return
		end

		self:start(n)
	end
end

function base_table:send_playerinfo(player)
	return true
end

function base_table:send_info_to_player(player)
	
end

function base_table:on_pre_start(player_count)
	self.round_id = self:get_next_game_id()
	local money_id = self:get_money_id()
	self.old_moneies = table.map(self.players,function(p)
		return p.guid,player_money[p.guid][money_id]
	end)
end

function base_table:room_conf()
	return self.room_.conf
end

function base_table:room_private_conf()
	return self.room_.conf.private_conf
end

function base_table:private_table_conf()
	if not self.private_id then
		log.info("base_table:private_table_conf,not private table,return nil.")
		return nil
	end

	return base_private_table[self.private_id]
end

function base_table:get_money_id()
	local club = self:get_club()
	return club and club_money_type[club.id] or -1
end

function base_table:get_club()
	local private_table = self:private_table_conf()
	if not private_table then
		log.error("base_table:get_club [%d] got nil private conf",self.private_id)
		return
	end

	local club_id = private_table.club_id
	if not club_id or club_id == 0 then
		log.warning("base_table:get_club [%d] got nil private club.",self.private_id)
		return
	end

	local club = base_clubs[club_id]
	return club
end

function base_table:cost_private_fee()
	if not self.private_id then
		return
	end

	local private_table = base_private_table[self.private_id]
	if not private_table then
		log.error("base_table:cost_private_fee [%d] got nil private table",self.private_id)
		return
	end

	local rule = self.rule
	if not rule then
		log.error("base_table:cost_private_fee [%d] got nil private rule",self.private_id)
		return
	end

	log.dump(rule)

	if game_util.is_private_fee_free(self.conf.club) then
		log.warning("base_table:cost_private_fee private fee switch is closed.")
		return true
	end

	local money = self.room_.conf.private_conf.fee[(rule.round.option or 0) + 1]
	local pay = rule.pay
	if pay.option == enum.PAY_OPTION_AA then
		local money_each = money
		for _,p in pairs(self.players) do
			p:incr_money({{
				money_id = 0,
				money = -money_each,
			}},enum.LOG_MONEY_OPT_TYPE_ROOM_FEE,self.ext_round_id)
		end
	elseif pay.option == enum.PAY_OPTION_BOSS then
		local root = club_utils.root(private_table.club_id)
		if not root then
			log.error("base_table:cost_private_fee [%d] got nil root [%d].",self.private_id,private_table.club_id)
			return
		end

		local boss = base_players[root.owner]

		boss:incr_money({
			money_id = 0,
			money = - money,
		},enum.LOG_MONEY_OPT_TYPE_ROOM_FEE,self.ext_round_id)
	elseif pay.option == enum.PAY_OPTION_ROOM_OWNER then
		local owner = base_players[private_table.owner]
		if not owner then
			log.error("base_table:cost_private_fee [%d] got nil owner [%d].",self.private_id,private_table.owner)
			return
		end

		owner:incr_money({{
			money_id = 0,
			money = -money,
		}},enum.LOG_MONEY_OPT_TYPE_ROOM_FEE,self.round_id)
	else
		log.error("base_table:cost_private_fee [%d] got wrong pay option.")
	end
end

function base_table:on_started(player_count)
	if not self.private_id then return end
	self.ext_round_status = EXT_ROUND_STATUS.GAMING

	self.player_count = player_count
	self.cur_round = (self.cur_round or 0) + 1

	local privatetb = base_private_table[self.private_id]
	if privatetb and privatetb.club_id then
		local club = base_clubs[privatetb.club_id]
		if club then
			local root = club_utils.root(club)
			root:recusive_broadcast("S2C_SYNC_TABLES_RES",{
				root_club = root.id,
				club_id = club.id,
				room_info = self:global_status_info(),
				sync_table_id = self.private_id,
				sync_type = enum.SYNC_UPDATE,
			})
		end
	end

	if self.cur_round == 1 then
		self:cost_private_fee()
		self:cost_tax()
	end

	self.start_time = os.time()
end

function base_table:balance(moneies,why)
	log.dump(moneies)

	local money_id = self:get_money_id() or -1
	if self.private_id and self.conf.club and self.conf.club.type  == enum.CT_UNION then
		local minrate = 1
		for pid,money in pairs(moneies) do
			local p = self.players[pid] or base_players[pid]
			local p_money = self.old_moneies and self.old_moneies[pid] or player_money[p.guid][money_id]
			if p_money + money < 0 then
				local r = math.abs(p_money) / math.abs(money)
				if minrate > r then minrate = r end
			end
		end

		for pid,_ in pairs(moneies) do
			moneies[pid] = math.floor(moneies[pid] * minrate)
		end

		log.dump(moneies)

		local club = self.conf.club

		for chair_or_guid,money in pairs(moneies) do
			if money ~= 0 then
				local p = self.players[chair_or_guid] or base_players[chair_or_guid]
				club:incr_member_money(p.guid,math.floor(money),why,self.round_id)
			end
		end

		return moneies
	end
	
	for chair_or_guid,money in pairs(moneies) do
		if money ~= 0 then
			local p = self.players[chair_or_guid] or base_players[chair_or_guid]
			p:incr_money({
				money_id = money_id,
				money = math.floor(money),
			},why,self.round_id)
		end
	end

	return moneies
end

function base_table:on_process_start(player_count)
	self.ext_round_id = self:hold_ext_game_id()
	if not self.private_id then 
		return
	end

	local private_table = base_private_table[self.private_id]
	if not private_table then 
		log.warning("base_table:on_process_start [%d] got nil private table.",self.private_id)
	end

	local club_id = private_table.club_id
	if not club_id then
		log.warning("base_table:on_process_start [%d] got private club.",self.private_id)
	end

	local template_id = private_table.template
	if not template_id then
		log.warning("base_table:on_process_start [%d] got nil template.",self.private_id)
	end

	channel.publish("db.?","msg","SD_LogExtGameRoundStart",{
		club = club_id,
		template = template_id,
		game_id = def_first_game_type,
		game_name = def_game_name,
		ext_round = self.ext_round_id,
		guids = table.series(self.players,function(p) return p.guid end),
		table_id = self.private_id
	})
end

function base_table:on_process_over(l)
	if not self.private_id then 
		log.warning("base_table:on_process_over [%s] got nil private id.",self.private_id)
		return
	end

	local private_table = base_private_table[self.private_id]
	if not private_table then 
		log.info("base_table:on_process_over [%s] got nil private table.",self.private_id)
	end

	local club_id = private_table.club_id
	if not club_id then
		log.info("base_table:on_process_over [%s] got private club.",self.private_id)
	end

	local template_id = private_table.template
	if not template_id then
		log.info("base_table:on_process_over [%s] got nil template.",self.private_id)
	end

	channel.publish("db.?","msg","SD_LogExtGameRoundEnd",{
		club = club_id,
		template = template_id,
		game_id = def_first_game_type,
		game_name = def_game_name,
		ext_round = self.ext_round_id,
		guids = table.series(self.players,function(p) return p.guid end),
		table_id = self.private_id,
		log = l,
	})

	local club = self.conf.club
	self:foreach(function(p)
		if p.inactive or p.trustee then 
			p:forced_exit()
			return
		end

		if club and not club:can_sit_down(self.rule,p) then
			p:forced_exit()
			return
		end
	end)

	self.ext_round_status = EXT_ROUND_STATUS.END
end

-- 开始游戏
function base_table:start(player_count)
	log.info("base_table:start %s,%s",self.chair_count,player_count)
	self:cancel_delay_dismiss()
	self:cancel_all_dealy_kickout()
	local result_ = self:check_single_game_is_maintain()
	if result_ == true then
		log.info("game is maintain cant start roomid[%d] tableid[%d]" ,self.room_.id, self.table_id_)
		return nil
	end

	if not self.cur_round then
		self:on_process_start(player_count)
	end

	self:on_pre_start(player_count)

	local ret = false
	if self.config_id ~= self.room_.config_id then
		log.info ("-------------configid:",self.config_id ,self.room_.config_id)
		log.info (self.room_.tax_show_, self.room_.tax_open_ , self.room_.tax_)
		self.tax_show_ = self.room_.tax_show_ -- 是否显示税收信息
		self.tax_open_ = self.room_.tax_open_ -- 是否开启税收
		self.tax_ = self.room_.tax_
		self.room_limit = self.room_.room_limit -- 房间分限制
		self.cell_score = self.room_.cell_score -- 底注
		self.game_switch_is_open = self.room_.game_switch_is_open

		if self.tax_show_ == 1 then
			self.notify_msg.flag = 3
		else
			self.notify_msg.flag = 4
		end

		self.config_id = self.room_.config_id

		ret = true
		log.info ("self.room_.room_cfg --------" ,self.room_.room_cfg )
		if self.room_.room_cfg ~= nil then
			self:load_lua_cfg()
		end
	end

	self:broadcast2client("SC_ShowTax", self.notify_msg)

	self:on_started(player_count)
	return ret
end

-- 检查是否维护
function base_table:check_game_maintain()
	if game_switch == 1 then--游戏将进入维护阶段
		log.warning("All Game will maintain..game_switch=[%d].....................",game_switch)
		for i,v in pairs (self.players) do
			if not v:is_android() and v.vip ~= 100 then
				send2client_pb(v, "SC_GameMaintain", {
					result = enum.GAME_SERVER_RESULT_MAINTAIN,
				})
				v:forced_exit()
			end
		end
		return true
	end
	return false
end

--准备玩家通知维护
function base_table:on_notify_ready_player_maintain(player)
	if game_switch == 1 and player.vip ~= 100 then--游戏将进入维护阶段
		send2client_pb(player, "SC_GameMaintain", {
		result = enum.GAME_SERVER_RESULT_MAINTAIN,
		})
		player:forced_exit()
		return true
	end
	return false
end

-- 清除准备
function base_table:clear_ready()
	self.ready_list = {}
end

-- 心跳
function base_table:tick()

end

function base_table:on_private_inited()
	
end

function base_table:private_init(private_id,rule,conf)
	self.private_id = private_id
	self.rule = rule
	self.start_count = conf.chair_count
	self.conf = conf
	self:cancel_delay_dismiss()
	self:cancel_all_dealy_kickout()
	self.ext_round_status = EXT_ROUND_STATUS.FREE
	self:on_private_inited()
end

function base_table:private_clear()
	if not self.private_id then return end
	
	self.rule = nil
	self.conf = nil
	self.private_id = nil
end

-- 检查单个游戏维护
function base_table:check_single_game_is_maintain()
	self:game_end()
	local iRet = false
	self.def_game_name = def_game_name
	self.def_game_id = def_game_id
	if self.room_.game_switch_is_open == 1 or game_switch == 1 then--游戏将进入维护阶段
		log.warning("game_name = [%s] gameid = [%d] game_switch_is_open[%d] get_db_status[%d] game_switch[%d] will maintain.....................",self.def_game_name,self.def_game_id,self.room_.game_switch_is_open,get_db_status(),game_switch)
		iRet = self:send_maintain_player()
		log.warning("game_name = [%s] gameid = [%d] game_switch_is_open[%d] get_db_status[%d] game_switch[%d] will maintain ret(%s).....................",self.def_game_name,self.def_game_id,self.room_.game_switch_is_open,get_db_status(),game_switch,tostring(iRet))
	end
	return iRet
end

function base_table:send_maintain_player()
	local iRet = false
	for i,v in pairs (self.players) do
		if  not v:is_android() and v.vip ~= 100 then
			send2client_pb(v, "SC_GameMaintain", {
			result = enum.GAME_SERVER_RESULT_MAINTAIN,
			})
			v:forced_exit()
			iRet = true
		end
	end
	return iRet
end

function base_table:notify_bankruptcy(code)
	self:broadcast2client("S2C_WARN_CODE_RES",{
		warn_code = code,
	})
end

-- 破产检测
function base_table:check_bankruptcy()
	local money_id = self:get_money_id()
	local limit = self.private_id and self.rule.union and self.rule.union.min_score or 0
	local bankruptcy = table.map(self.players,function(p)
		return p.guid,player_money[p.guid][money_id] < limit
	end)
	return bankruptcy
end

function base_table:is_bankruptcy(player)
	local club = self.conf.club
	if not club or club.type ~= enum.CT_UNION then
		return
	end

	local money_id = self:get_money_id()
	local limit = self.private_id and self.rule.union and self.rule.union.min_score or 0
	return player_money[player.guid][money_id] < limit
end

--玩家破产日志
function  base_table:save_player_collapse_log(player)
	if not player then
		return
	end
	local player_money = player:get_money()
	local player_bank_money = player:get_bank_money()
	log.info("save_player_collapse_log: player guid[%d],cur_money[%d] cur_bank[%d],player.channel_id[%s],player.platform_id[%s] platform_info[%s]",player.guid,player_money,player_bank_money,player.channel_id,player.platform_id,platform_info)

	--先判断身上的钱加上银行的钱是否小于该平台配置的默认值，若是则记录日志
	local player_money_total = player_money + player_bank_money
	local collapse_value = tonumber(reddb:get("platform:collapse_value:"..tostring(player.platform_id)))
	if collapse_value and player_money_total < collapse_value then
		log.info("player guid[%d] is collapse, player_money_total[%d] channel_id[%s] platform_id[%s]",player.guid,player_money_total,player.channel_id,player.platform_id)
		local nmsg = {
			guid = player.guid,
			channel_id = player.channel_id ,
			platform_id = player.platform_id,
		}
		channel.publish("db.?","msg","SD_SaveCollapseLog",nmsg)
	end
end

--检查玩家是否是黑名单列表玩家，若是则返回true，否则返回false
function base_table:check_blacklist_player( player_guid )
	return self.room_:check_player_is_in_blacklist(player_guid)
end

--游戏结算回调
function base_table:game_end()
	for _,guid in pairs(self.game_end_event) do
		local player = base_players.find(tonumber(guid))
		if player then
			player:do_game_end_event()
		end
	end
	self.game_end_event = {}
end

function base_table:log( str , level , number)
	if not self.logLevel then
		log.info(str)
	elseif self.logLevel >= level then
		if number == nil then
			log.info("%s [%s][%s][%s]" , str , debug.getinfo(2).short_src , debug.getinfo(2).name , debug.getinfo(2).currentline)
		else
			log.info("%s [%s][%s][%s]" , str , debug.getinfo(number).short_src , debug.getinfo(number).name , debug.getinfo(number).currentline)
		end
	else
		log.info(str)
	end
end

function base_table:log_important(str)
	if not self.logLevel then
		log.info("%s [%s][%s][%s]" , str , debug.getinfo(2).short_src , debug.getinfo(2).name , debug.getinfo(2).currentline)
	else
		self:log(str,self.logLevel,3)
	end
end

function base_table:log_error_msg(str)
	log.error("%s [%s][%s][%s]" , str , debug.getinfo(2).short_src , debug.getinfo(2).name , debug.getinfo(2).currentline)
end

function base_table:log_msg(str)
	self:log(str, 1 ,3)
end

function base_table:play_once_again(player)
	local club = self.conf.club
	if self.rule and not club:can_sit_down(self.rule,player) then
        return enum.ERROR_LESS_GOLD
	end
	
	self:ready(player)
	return enum.ERROR_NONE
end

function base_table:new_timer(timeout,fn,...)
	local timer
	timer = timer_manager:new_timer(timeout,function()
		log.info("base_table:new_timer timer timeout,timer:%s",timer.id)
		self:lockcall(fn)
	end,...)
	log.info("base_table:new_timer timer:%s",timer.id)
	return timer
end

function base_table:calllater(timeout,fn)
	local timer
	timer = timer_manager:calllater(timeout,function()
		self:lockcall(fn) 
	end)
	return timer
end

function base_table:kill_timer(timer)
	local id = type(timer) == "table" and timer.id or timer
	timer_manager:kill_timer(id)
end

function base_table:global_status_info()
	local seats = table.series(self.players,function(p,chair_id) 
		return {
			chair_id = chair_id,
			player_info = {
			    guid = p.guid,
			    icon = p.icon,
			    nickname = p.nickname,
			    sex = p.sex,
			},
			ready = self.ready_list[chair_id] and true or false,
		    }
	end)
    
	local private_conf = base_private_table[self.private_id]
    
	local info = {
	    table_id = self.private_id,
	    seat_list = seats,
	    room_cur_round = self.cur_round or 0,
	    rule = self.private_id and json.encode(self.rule) or "",
	    game_type = def_first_game_type,
	    template_id = private_conf and private_conf.template,
	}
    
	return info
end

return base_table