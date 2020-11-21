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
local auto_dismiss_timeout = 2 * 60
local auto_kickout_timer = 2 * 60

local EXT_ROUND_STATUS = {
	NONE = enum.ERS_NONE,
	FREE = enum.ERS_FREE,
	GAMING = enum.ERS_GAMING,
	END = enum.ERS_END,
}

local dismiss_reason = {
	[enum.STANDUP_REASON_OFFLINE] = enum.DISMISS_REASON_NORMAL,
	[enum.STANDUP_REASON_NORMAL] = enum.DISMISS_REASON_NORMAL,
	[enum.STANDUP_REASON_DISMISS] = enum.DISMISS_REASON_NORMAL,
	[enum.STANDUP_REASON_FORCE] = enum.DISMISS_REASON_ADMIN_FORCE,
	[enum.STANDUP_REASON_ADMIN_DISMISS_FORCE] = enum.DISMISS_REASON_ADMIN_FORCE,
	[enum.STANDUP_REASON_DISMISS_REQUEST] = enum.DISMISS_REASON_REQUEST,
	[enum.STANDUP_REASON_DISMISS_TRUSTEE] = enum.DISMISS_REASON_TRUSTEE_AUTO,
	[enum.STANDUP_REASON_BANKRUPCY] = enum.DISMISS_REASON_BANKRUPCY,
	[enum.STANDUP_REASON_TABLE_TIMEOUT] = enum.DISMISS_REASON_TIMEOUT,
	[enum.STANDUP_REASON_MAINTAIN] = enum.DISMISS_REASON_MAINTAIN,
	[enum.STANDUP_REASON_ROUND_END] = enum.DISMISS_REASON_ROUND_END,
	[enum.STANDUP_REASON_BLOCK_GAMING] = enum.DISMISS_REASON_ROUND_END,
	[enum.STANDUP_REASON_CLUB_CLOSE] = enum.DISMISS_REASON_ROUND_END,
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
	log.info("base_table:get_next_game_id table_id:%s,round:%s",self:id(),sround_id)
	return sround_id
end

function base_table:get_ext_game_id()
	local sext_round_id = string.format("%03d-%03d-%04d-%s-%06d",def_game_id,self.room_.id, self.table_id_,os.date("%Y%m%d%H%M%S"),math.random(1,100000))
	log.info("base_table:get_ext_game_id table_id:%s,round:%s",self:id(),sext_round_id)
	return sext_round_id
end

function base_table:hold_game_id()
	self.round_id = self.round_id or self:get_next_game_id()
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

function base_table:begin_clock_ex(timeout,id,total_time,player)
	if player then 
		send2client_pb(player,"SC_StartTimer",{
			left_time = math.ceil(timeout),
			total_time = total_time and math.floor(total_time) or nil,
			id = id,
		})
		return
	end
	
	self:broadcast2client("SC_StartTimer",{
		left_time = timeout,
		total_time = total_time and math.floor(total_time) or nil,
		id = id,
	})
end

function base_table:cancel_clock_ex(id,player)
	if player then 
		send2client_pb(player,"SC_CancelTimer",{
			id = id,
		})
		return
	end
	
	self:broadcast2client("SC_CancelTimer",{
		id = id,
	})
end

function base_table:begin_clock(timeout,player,total_time)
	if player then 
		send2client_pb(player,"SC_TimeOutNotify",{
			left_time = math.floor(timeout + 0.0000001),
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
			reason = enum.DISMISS_REASON_REQUEST,
		})
		return
	end

	self:interrupt_dismiss(enum.STANDUP_REASON_DISMISS_REQUEST)
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
    if self:is_private() then
        local private_table = base_private_table[self.private_id]
        local rule = private_table.rule
        base_multi = rule.union and rule.union.score_rate or 1
	end
	
	return score * 100 * base_multi
end

function base_table:do_commission_standalone(guid,commission,contributer)
	if not self:is_private() then 
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
	if not self:is_private() then 
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
	local contributions = {}
	for guid,tax in pairs(taxes) do
		local last_rate = 0
		local p_guid = guid
		local s_guid = guid
		local remain = tax
		while p_guid and p_guid ~= 0 do
			local commission_rate = get_club_partner_template_commission_rate(club_id,template_id,p_guid)
			local commission = math.ceil(tax * (commission_rate - last_rate))
			last_rate = commission_rate

			commission = remain < commission and remain or commission
			remain = remain - commission
			commissions[p_guid] = (commissions[p_guid] or 0) + commission

			if commission > 0 then
				table.insert(contributions,{
					parent = p_guid,
					son = s_guid,
					commission = commission,
				})
			end

			log.info("base_table:do_commission club:%s,partner:%s,commission:%s",club_id,p_guid,commission)

			s_guid = p_guid
			p_guid = club_member_partner[club_id][p_guid]
		end
	end
	
	channel.publish("db.?","msg","SD_LogPlayerCommissionContributes",{
		contributions = contributions,
		template = template_id,
		club = club_id,
	})

	for guid,commission in pairs(commissions) do
		commission = math.floor(commission + 0.0000001)
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
	
	if not self:is_private() then
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
		if self:gaming_round() > 1 then
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

		local function each_bigwin_commission_tax(total,win_guid)
			local player_count = table.nums(self.players)
			local eachwin = math.floor(bigwin_tax / player_count)
			local commission_tax = table.map(self.players,function(p)
				return p.guid,eachwin
			end)

			local total_delta = bigwin_tax - (eachwin * player_count)

			commission_tax[win_guid] = commission_tax[win_guid] + total_delta

			return commission_tax
		end

		local commission_tax = each_bigwin_commission_tax(bigwin_tax,bigwin_guid)

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

function base_table:force_dismiss(reason)
	self:interrupt_dismiss(reason)
end

function base_table:game_over()
	self:on_game_overed()
end

function base_table:on_final_game_overed(reason)
	reason = reason or enum.STANDUP_REASON_NORMAL
	self:on_process_over(reason)

	self.round_id = nil
	self.ext_round_id = nil
	self.cur_round = nil
end

function base_table:get_trustee_conf()
	if not self:is_private() then return end

	local trustee = self.rule and self.rule.trustee or nil
	if trustee and trustee.type_opt ~= nil and trustee.second_opt ~= nil then
		local trustee_conf = self.room_.conf.private_conf.trustee
		if not trustee_conf then return end
	    local seconds = trustee_conf.second_opt[trustee.second_opt + 1]
	    local type = trustee_conf.type_opt[trustee.type_opt + 1]
	    return type,seconds
	end
    
	return nil
end

function base_table:incr_trustee_round()
	if not self.is_someone_trustee then
		return 
	end

	self.someone_trustee_round = (self.someone_trustee_round or 0) + 1
end

function base_table:begin_kickout_no_ready_timer(timeout,fn)
	if self.kickout_no_ready_timer then
		log.warning("base_table:begin_kickout_no_ready_timer timer not nil")
		self.kickout_no_ready_timer:kill()
	end

	self.kickout_no_ready_timer = self:new_timer(timeout,fn)
	self:begin_clock_ex(timeout,self.kickout_no_ready_timer.id)
	log.info("base_table:begin_kickout_no_ready_timer table_id:%s,timer:%s,timout:%s",self.table_id_,self.kickout_no_ready_timer.id,timeout)
end

function base_table:sync_kickout_no_ready_timer(player)
	if not self.kickout_no_ready_timer then
		return
	end

	local remain_time = math.floor(self.kickout_no_ready_timer.remainder)
	local id = self.kickout_no_ready_timer.id
	if player then
		send2client_pb(player,"SC_StartTimer",{
			id = id,
			left_time = remain_time,
		})
		return
	end

	self:broadcast2client("SC_StartTimer",{
		id = id,
		left_time = remain_time,
	})
end

function base_table:cancel_kickout_no_ready_timer()
	if not self.kickout_no_ready_timer then
		return
	end

	self:cancel_clock_ex(self.kickout_no_ready_timer.id)
	log.info("base_table:cancel_kickout_timer_when_no_ready table_id:%s,timer:%s",self.table_id_,self.kickout_no_ready_timer.id)
	self.kickout_no_ready_timer:kill()
	self.kickout_no_ready_timer = nil
end

function base_table:begin_ready_timer(timeout,fn)
	if self.ready_timer then 
		log.warning("base_table:begin_ready_timer timer not nil")
		self.ready_timer:kill()
	end

	self.ready_timer = self:new_timer(timeout,fn)
	self:begin_clock(timeout)
	log.info("base_table:begin_ready_timer table_id:%s,timer:%s,timout:%s",self.table_id_,self.ready_timer.id,timeout)
end

function base_table:cancel_ready_timer()
	if not self.ready_timer then
		return
	end

	log.info("base_table:cancel_ready_timer table_id:%s,timer:%s",self.table_id_,self.ready_timer.id)
	self.ready_timer:kill()
	self.ready_timer = nil
end

function base_table:can_kickout_when_round_over(p)
	local club = self.conf.club
	return p.inactive or p.trustee or not club or club:can_sit_down(self.rule,p) ~= enum.ERROR_NONE
end

function base_table:kickout_players_when_round_over()
	local club = self.conf.club
	self:foreach(function(p)
		if self:can_kickout_when_round_over(p) then 
			p:forced_exit(enum.STANDUP_REASON_NORMAL)
		end
	end)
end

function base_table:can_dismiss_by_trustee()
	local auto_dismiss = self.rule.room.auto_dismiss
	if auto_dismiss and auto_dismiss.trustee_round and self.is_someone_trustee then 
		if self.someone_trustee_round and self.someone_trustee_round >= auto_dismiss.trustee_round then
			return true
		end
	end
end

function base_table:auto_ready(seconds)
	log.info("begin auto_ready %s,%s",self.private_id,seconds)
	self:foreach(function(p)
		if p.trustee then 
			self:calllater(math.random(2,3),function()
				if not self.ready_list[p.chair_id] then
					self:ready(p)
				end
			end)
		end
	end)

	self:begin_ready_timer(seconds,function()
		self:cancel_ready_timer()
		self:foreach(function(p)
			if not self.ready_list[p.chair_id] then
				self:ready(p)
				if not p.trustee then
					self:set_trusteeship(p,true)
				end
			end
		end)
	end)
end

function base_table:on_game_overed()
	self.old_moneies = nil
	self:clear_ready()
	if not self:is_private() then
		return
	end

	if table.logic_or(self.players,function(p) return self:is_bankruptcy(p) end) then
		self:notify_bankruptcy(enum.ERROR_BANKRUPTCY_WARNING)
		self:force_dismiss(enum.STANDUP_REASON_BANKRUPCY)
		return
	end

	if self:gaming_round() >= self:total_round() then
		self:on_final_game_overed()
		self:kickout_players_when_round_over()
		if self:is_private() then
			local club = self.club_id and base_clubs[self.club_id] or nil
			if club then
				if club:is_block() or club:is_close() then
					self:force_dismiss(enum.STANDUP_REASON_CLUB_CLOSE)
					return
				end

				self:foreach(function(p)
					if club:is_block_gaming(p) then
						p:forced_exit(enum.STANDUP_REASON_BLOCK_GAMING)
					end
				end)
			end

			if not game_util.is_in_maintain() then
				self:delay_normal_dismiss(enum.STANDUP_REASON_ROUND_END)
			else
				self:force_dismiss(enum.STANDUP_REASON_MAINTAIN)
			end
		end
		return
	end

	if self:is_round_gaming() then
		local is_trustee,seconds = self:get_trustee_conf()
		if not is_trustee then return end

		if self:can_dismiss_by_trustee() then
			self:force_dismiss(enum.STANDUP_REASON_DISMISS_TRUSTEE)
			return
		end

		self:incr_trustee_round()

		if self:gaming_round() > self:total_round() then
			return 
		end

		self:auto_ready(seconds)
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
function base_table:broadcast2client(msgname, msg,except)
	local guids = table.series(self.players,function(p) 
		return (p ~= except and p.guid ~= except) and p.guid or nil 
	end)
	onlineguid.broadcast(guids,msgname,msg)
end

function base_table:broadcast2client_except(except,msgname, msg)
	local guids = table.series(self.players,function(p) 
		return (p ~= except and p.guid ~= except) and p.guid or nil 
	end)
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

	if self:is_round_gaming() or self:is_play() then
		return enum.ERROR_TABLE_STATUS_GAMING
	end

	return enum.ERROR_NONE
end

function base_table:on_player_sit_down(player,chair_id,reconnect)
	player.inactive = nil
	if reconnect then
		self:notify_online(player)
	else
		self:notify_sit_down(player,chair_id)
	end
end

function base_table:on_player_sit_downed(player,reconnect)
	if not reconnect then
		self:check_kickout_no_ready()
	else
		self:sync_kickout_no_ready_timer(player)
	end
end

-- 玩家坐下
function base_table:player_sit_down(player, chair_id,reconnect)
	return self:lockcall(function() 
		local result =  self:can_sit_down(player,chair_id,reconnect)
		if result ~= enum.ERROR_NONE then
			return result
		end

		player.table_id = self.table_id_
		player.chair_id = chair_id
		self.players[chair_id] = player
		log.info("base_table:player_sit_down, guid %s, table_id %s, chair_id %s",
				player.guid,player.table_id,player.chair_id)

		self.player_count = self.player_count + 1
		
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

		if self:is_private() then
			reddb:set("player:table:"..tostring(player.guid),self.private_id)
			reddb:sadd("table:player:"..tostring(self.private_id),player.guid)
		end

		self:on_player_sit_down(player,chair_id,reconnect)

		self:broadcast_sync_table_info_2_club(enum.SYNC_UPDATE,self:global_status_info())

		onlineguid[player.guid] = nil

		return enum.GAME_SERVER_RESULT_SUCCESS
	end)
end



function base_table:on_private_pre_dismiss(reason)
	
end

function base_table:on_private_dismissed(reason)
	self:foreach(function(p)
		p:forced_exit(reason or enum.STANDUP_REASON_NORMAL)
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

function base_table:notify_dismiss(reason)
	log.warning("notfiy_dismiss %s",reason)
	self:broadcast2client("SC_DismissTable",{success = true,reason = reason or enum.DISMISS_REASON_NORMAL})
end

function base_table:do_dismiss(reason)
	return self:lockcall(function()
		log.info("base_table:dismiss %s",self.private_id)
		if not self.conf or not self:is_private() then
			log.warning("dismiss non-private table,real_table_id:%s",self.table_id)
			return enum.GAME_SERVER_RESULT_PRIVATE_ROOM_NOT_FOUND
		end

		if not self:can_dismiss() then
			return enum.ERROR_OPERATION_INVALID
		end

		self:cancel_delay_dismiss()
		self:cancel_ready_timer()
		self:cancel_all_delay_kickout()
		self:on_private_pre_dismiss()

		self:broadcast_sync_table_info_2_club(enum.SYNC_DEL)

		log.info("base_table:dismiss %s,%s",self.private_id,self.table_id_)
		local private_table_conf = base_private_table[self.private_id]
		local club_id = private_table_conf.club_id
		local private_table_id = private_table_conf.table_id
		local private_table_owner = private_table_conf.owner
		reddb:del("table:info:"..private_table_id)
		reddb:del("player:table:"..private_table_owner)
		reddb:del("table:player:"..private_table_id)
		
		if club_id then
			reddb:srem("club:table:"..club_id,private_table_id)
			club_table[club_id][private_table_id] = nil
		end

		base_private_table[self.private_id] = nil

		self.room_:del_table(self.private_id)
		
		self:on_private_dismissed()

		self:clear()
		
		self.private_id = nil
		self.conf = nil
		self.cur_round = nil
		self.start_count = self.chair_count
		self.ext_round_status = nil

		return enum.GAME_SERVER_RESULT_SUCCESS
	end)
end

function base_table:transfer_owner()
	return self:lockcall(function()
		log.info("transfer owner:%s,%s",self.conf.private_id,self.conf.owner.guid)
		if not self.conf or not self:is_private() then
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
		reddb:del("player:table:"..old_owner.guid)
		reddb:hset("table:info:"..private_table_id,"owner",new_owner.guid)
		reddb:set("player:table:"..new_owner.guid,private_table_id)
		private_conf.owner = new_owner
		private_conf.owner_guid = new_owner.guid

		self:broadcast2client("S2C_TRANSFER_ROOM_OWNER_RES",{
			table_id = self.private_id,
			old_owner = old_owner.guid,
			new_owner = new_owner.guid,
		})

		return enum.GAME_SERVER_RESULT_SUCCESS
	end)
end

function base_table:cancel_ready(chair_id)
	if self.ready_list[chair_id] then
		self.ready_list[chair_id] = nil
		self:broadcast2client("SC_Ready", {
			ready_chair_id = chair_id,
			is_ready = false,
		})
	end

	self:check_kickout_no_ready()
end

function base_table:is_ready(chair_id)
	return self.ready_list[chair_id] ~= nil	
end

function base_table:is_private()
	return self.private_id and self.conf
end

function base_table:id()
	return self.private_id or self.table_id_
end

function base_table:interrupt_dismiss(reason)
	local dreason = dismiss_reason[reason]
	if self:gaming_round() > 0 then
		self:on_final_game_overed(reason)
	end

	self:notify_dismiss(dreason)
	self:foreach(function(p)
		p:forced_exit(reason)
	end)
	self:do_dismiss(dreason)
end

function base_table:normal_dismiss(reason)
	local tb_dismiss_reason = dismiss_reason[reason]
	self:notify_dismiss(tb_dismiss_reason)
	self:foreach(function(p)
		p:forced_exit(reason)
	end)
	self:do_dismiss(tb_dismiss_reason)
end

function base_table:delay_normal_dismiss(reason)
	self.dismiss_timer = self:new_timer(auto_dismiss_timeout,function()
		log.info("base_table:delay_normal_dismiss timeout %s",self.private_id)
		self:normal_dismiss(reason)
	end)
	log.info("base_table:delay_normal_dismiss %s",self.dismiss_timer.id)
end

function base_table:cancel_delay_dismiss()
	log.info("base_table:cancel_delay_dismiss %s",self.dismiss_timer and self.dismiss_timer.id or nil)
	if not self.dismiss_timer then
		return
	end

	self.dismiss_timer:kill()
	self.dismiss_timer = nil
end

function base_table:delay_kickout(player,reason)
	log.info("delay_kickout %s",player.guid)
	player.kickout_timer = self:new_timer(auto_kickout_timer,function()
		self:cancel_delay_kickout(player)
		player:forced_exit(reason)
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

function base_table:cancel_all_delay_kickout()
	self:foreach(function(p)
		self:cancel_delay_kickout(p)
	end)
end

function base_table:broadcast_sync_table_info_2_club(type,roominfo)
	if not self:is_private() then
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
	return self:lockcall(function()
		local guid = player.guid
		local table_id = player.table_id
		local chair_id = player.chair_id
		log.info("base_table:player_stand_up, guid %s, table_id %s, chair_id %s, reason %s",
				guid,table_id,chair_id,reason)
		
		if not chair_id or not table_id then
			log.error("player_stand_up got nil table_id or chair_id,%s,%s",table_id,chair_id)
			return not table_id and 
				enum.GAME_SERVER_RESULT_NOT_FIND_TABLE or 
				enum.GAME_SERVER_RESULT_NOT_FIND_CHAIR
		end

		if self:can_stand_up(player, reason) then
			local player_count = table.nums(self.players)
			
			-- 玩家掉线不直接解散,针对邀请玩家进入房间情况
			if 	self:is_private() and 
				self:is_round_free() and 
				reason == enum.STANDUP_REASON_OFFLINE
			then
				self:on_offline(player)
				self:delay_kickout(player,enum.STANDUP_REASON_DELAY_KICKOUT_TIMEOUT)
				return enum.GAME_SERVER_RESULT_WAIT_LATER
			end
			log.info("base_table:player_stand_up table_id:%s,guid:%s,can_stand_up true.",self:id(),guid)
			local chairid = player.chair_id
			local p = self.players[chairid]
			local list_guid = table.concat(table.extract(self.players,"guid"),",")
			log.info("set guid[%s] table_id[%s] is false player_list [%s]",guid,table_id,chairid , list_guid)
			self.player_count = self.player_count - 1
			if self:is_ready(chairid) then
				self:cancel_ready(chairid)
			end

			self:on_player_stand_up(player,reason)

			if self:is_private() and player == self.conf.owner and player_count > 1 then
				self:transfer_owner()
			end

			player.table_id = nil
			player.chair_id = nil

			self.players[chairid] = nil

			self:on_player_stand_uped(player,reason)

			if 	player_count == 1 then
				self:do_dismiss(dismiss_reason[reason])
			else
				self:broadcast_sync_table_info_2_club(enum.SYNC_UPDATE,self:global_status_info())
				if 	reason == enum.STANDUP_REASON_OFFLINE or
					reason == enum.STANDUP_REASON_NORMAL or
					reason == enum.STANDUP_REASON_FORCE or
					reason == enum.STANDUP_REASON_BANKRUPCY or
					reason == enum.STANDUP_REASON_NO_READY_TIMEOUT
				then
					self:check_start()
				end
			end

			reddb:hdel("player:online:guid:"..tostring(guid),"global_table")
			reddb:hdel("player:online:guid:"..tostring(guid),"table")
			reddb:hdel("player:online:guid:"..tostring(guid),"chair")
			reddb:del("player:table:"..tostring(guid))
			reddb:srem("table:player:"..tostring(self.private_id),guid)
			onlineguid[guid] = nil

			return enum.ERROR_NONE
		end

		if reason == enum.STANDUP_REASON_OFFLINE then
			self:on_offline(player)
		end

		return enum.GAME_SERVER_RESULT_IN_GAME
	end)
end

function base_table:notify_sit_down(player,chair_id)
	local seat = {
		chair_id = player.chair_id,
		player_info = {
			guid = player.guid,
			icon = player.icon,
			nickname = player.nickname,
			sex = player.sex,
		},
		longitude = player.gps_longitude,
		latitude = player.gps_latitude,
		online = true,
		ready = false,
		is_trustee = player.trustee and true or false,
	}

	if self:is_private() then
		local money_id = self:get_money_id()
		seat.money = {
			money_id = money_id,
			count = player:get_money(money_id),
		}
	end
	
	self:broadcast2client_except(player,"SC_NotifySitDown",{
		table_id = self.private_id,
		seat = seat,
		is_online = true,
	})
end

function base_table:notify_stand_up(standup_player,reason)
	self:broadcast2client_except(standup_player,"SC_NotifyStandUp",{
		table_id = standup_player.table_id,
		chair_id = standup_player.chair_id,
		guid = standup_player.guid,
		reason = reason,
	})
end

function base_table:notify_online(online_player,is_online)
	if is_online == nil then is_online = true end

	self:broadcast2client_except(online_player,"SC_NotifyOnline",{
		chair_id = online_player.chair_id,
		guid = online_player.guid,
		is_online = is_online,
	})
end

function base_table:on_player_stand_up(player,reason)
	self:notify_stand_up(player,reason)
end

function base_table:on_player_stand_uped(player,reason)
	if resaon ~= enum.STANDUP_REASON_OFFLINE then
		self:check_kickout_no_ready()
	end
end

function base_table:on_offline(player)
	player.inactive = true
	self:notify_online(player,false)
end

function base_table:clear_trustee_status()
	self.is_someone_trustee = nil
	self.someone_trustee_round = nil
end

function base_table:clear_player_trustee()
	self:foreach(player,function(p) p.trustee = nil end)
end

function base_table:is_trustee(player)
	return player.is_trustee and true or false
end

function base_table:set_trusteeship(player,trustee)
	if not self:is_private() then return end

	if not self.rule.trustee or table.nums(self.rule.trustee) == 0 then
        return 
	end
	
	log.info("base_table:set_trusteeship,%s,%s",player.guid,trustee)
	if player.trustee and trustee then
        return
	end
	
	player.trustee = trustee
	self:broadcast2client("SC_Trustee",{
		result = enum.ERROR_NONE,
		chair_id = player.chair_id,
		is_trustee = trustee and true or false,
	})

	local has_player_trustee = table.sum(self.players,function(p) return p.trustee and 1 or 0 end) > 0
	self.is_someone_trustee = has_player_trustee or nil
	if has_player_trustee then
		self.someone_trustee_round = self.someone_trustee_round or 1
	else
		self.someone_trustee_round = nil
	end
end



function base_table:check_kickout_no_ready()
	self:lockcall(function() 
		if not self:is_round_free() then
			return
		end

		local ready_count = table.sum(self.players,function(p) 
			return self.ready_list[p.chair_id] and 1 or 0 
		end)

		local player_count = table.nums(self.players)
		if player_count - ready_count ~= 1 or player_count ~= self.start_count then
			self:cancel_kickout_no_ready_timer()
			return
		end

		local trustee,seconds = self:get_trustee_conf()
		if trustee and seconds > 0 then
			self:begin_kickout_no_ready_timer(seconds,function()
				self:foreach(function(p)
					if not self.ready_list[p.chair_id] then
						p:forced_exit(enum.STANDUP_REASON_NO_READY_TIMEOUT)
					end
				end)
			end)
		end
	end)
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

	self:lockcall(function()
		if self.ready_list[player.chair_id] then
			log.warning("chair_id[%d] ready already,guid[%d]", player.chair_id,player.guid)
			return true
		end

		self.ready_list[player.chair_id] = player

		log.info("set tableid [%d] chair_id[%d]  ready_list is [%s]",self:id(),player.chair_id,
			table.concat(table.series(self.ready_list,function(p) return p.guid end),","))

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

		self:check_kickout_no_ready()

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
	log.info("base_table:can_stand_up guid:%s,reason:%s",player.guid,reason)
    if reason == enum.STANDUP_REASON_NORMAL or
		reason == enum.STANDUP_REASON_OFFLINE or
		reason == enum.STANDUP_REASON_FORCE or 
		reason == enum.STANDUP_REASON_DELAY_KICKOUT_TIMEOUT
	then
        return not self:is_play(player) and not self:is_round_gaming()
	end

    return true
end

-- 检查开始
function base_table:check_start(part)
	local ready_mode = self.room_:get_ready_mode()
	log.info("check_start %s ready_mode %s,%s",self.table_id_,ready_mode,part)
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
	if not self:is_private() then
		log.info("base_table:private_table_conf,not private table,return nil.")
		return nil
	end

	return base_private_table[self.private_id]
end

function base_table:get_money_id()
	local club = self.conf.club
	return club and club_money_type[club.id] or -1
end

function base_table:get_private_fee(rule)
	return self.room_:get_private_fee(rule)
end

function base_table:cost_private_fee()
	if not self:is_private() then
		return
	end

	local club = self.conf.club
	local rule = self.rule
	if not rule then
		log.error("base_table:cost_private_fee [%d] got nil private rule",self.private_id)
		return
	end

	log.dump(rule)

	if game_util.is_private_fee_free(club) then
		log.warning("base_table:cost_private_fee private fee switch is closed.")
		return true
	end

	local money = self:get_private_fee(rule)
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
		local club_id = club and club.id or nil
		local root = club_utils.root(club_id)
		if not root then
			log.error("base_table:cost_private_fee [%s] got nil root [%s].",self.private_id,club_id)
			return
		end

		local boss = base_players[root.owner]

		boss:incr_money({
			money_id = 0,
			money = - money,
		},enum.LOG_MONEY_OPT_TYPE_ROOM_FEE,self.ext_round_id)
	elseif pay.option == enum.PAY_OPTION_ROOM_OWNER then
		local owner = self.conf.owner
		local owner_guid = self.conf.owner_guid
		if not owner or not owner_guid then
			log.error("base_table:cost_private_fee [%s] got nil owner [%s].",self.private_id,owner_guid)
			return
		end

		owner:incr_money({
			money_id = 0,
			money = -money,
		},enum.LOG_MONEY_OPT_TYPE_ROOM_FEE,self.ext_round_id)
	else
		log.error("base_table:cost_private_fee [%d] got wrong pay option.")
	end
end

function base_table:on_started(player_count)
	if not self:is_private() then return end
	self:cancel_ready_timer()
	self:cancel_kickout_no_ready_timer()
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

	if self:gaming_round() == 1 then
		self:cost_private_fee()
		self:cost_tax()
	end

	self.start_time = os.time()
end

function base_table:balance(moneies,why)
	log.dump(moneies)

	local money_id = self:get_money_id() or -1
	if self:is_private() and self.conf.club and self.conf.club.type  == enum.CT_UNION then
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
	if not self:is_private() then 
		return
	end

	self:clear_trustee_status()

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

function base_table:on_process_over(reason,l)
	if not self:is_private() then 
		log.warning("base_table:on_process_over [%s] got nil private id.",self.private_id)
		return
	end

	self:clear_trustee_status()

	self:cancel_kickout_no_ready_timer()
	self:cancel_ready_timer()
	self:cancel_delay_dismiss()
	self:cancel_all_delay_kickout()

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

	self.ext_round_status = EXT_ROUND_STATUS.END
end

-- 开始游戏
function base_table:start(player_count)
	player_count = player_count or table.nums(self.players)
	log.info("base_table:start %s,%s",self.chair_count,player_count)
	self:cancel_delay_dismiss()
	self:cancel_all_delay_kickout()

	if not self:is_round_gaming() then
		self:on_process_start(player_count)
	end

	self:on_pre_start(player_count)

	-- local ret = false
	-- if self.config_id ~= self.room_.config_id then
	-- 	log.info ("-------------configid:",self.config_id ,self.room_.config_id)
	-- 	log.info (self.room_.tax_show_, self.room_.tax_open_ , self.room_.tax_)
	-- 	self.tax_show_ = self.room_.tax_show_ -- 是否显示税收信息
	-- 	self.tax_open_ = self.room_.tax_open_ -- 是否开启税收
	-- 	self.tax_ = self.room_.tax_
	-- 	self.room_limit = self.room_.room_limit -- 房间分限制
	-- 	self.cell_score = self.room_.cell_score -- 底注
	-- 	self.game_switch_is_open = self.room_.game_switch_is_open

	-- 	if self.tax_show_ == 1 then
	-- 		self.notify_msg.flag = 3
	-- 	else
	-- 		self.notify_msg.flag = 4
	-- 	end

	-- 	self.config_id = self.room_.config_id

	-- 	ret = true
	-- 	log.info ("self.room_.room_cfg --------" ,self.room_.room_cfg )
	-- 	if self.room_.room_cfg ~= nil then
	-- 		self:load_lua_cfg()
	-- 	end
	-- end

	-- self:broadcast2client("SC_ShowTax", self.notify_msg)

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
	self.ext_round_status = EXT_ROUND_STATUS.FREE
	self.someone_trustee_round = nil
	self.is_someone_trustee = nil
	self:on_private_inited()
end

function base_table:is_round_end()
	return not self:is_private() or self.ext_round_status == EXT_ROUND_STATUS.END
end

function base_table:is_round_free()
	return not self:is_private() or 
		not self.ext_round_status or 
		self.ext_round_status == EXT_ROUND_STATUS.FREE
end

function base_table:is_round_gaming()
	return not self:is_private() or self.ext_round_status == EXT_ROUND_STATUS.GAMING
end

function base_table:gaming_round()
	if not self:is_private() then
		return 0
	end

	return self.cur_round or 0
end

function base_table:total_round()
	if not self:is_private() then
		return 0
	end

	return self.conf.round
end

function base_table:private_clear()
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
	local limit = self:is_private() and self.rule.union and self.rule.union.min_score or 0
	local bankruptcy = table.map(self.players,function(p)
		local money = player_money[p.guid][money_id]
		return p.guid,money <= 0 or money < limit
	end)
	return bankruptcy
end

function base_table:is_bankruptcy(player)
	local club = self.conf.club
	if not club or club.type ~= enum.CT_UNION then
		return
	end

	local money_id = self:get_money_id()
	local limit = self:is_private() and self.rule.union and self.rule.union.min_score or 0
	local money = player_money[player.guid][money_id]
	return money <= 0 or money < limit
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
	if club and self.rule and not club:can_sit_down(self.rule,player) then
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
	log.info("base_table:new_timer timer:%s,time:%s",timer.id,timeout)
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

function base_table:kickout_player(player,kicker)
	if 	kicker.guid ~= self.conf.owner_guid then
		return enum.ERROR_PLAYER_NO_RIGHT
	end

	if player.guid == kicker.guid then
		return enum.ERROR_OPERATION_INVALID
	end

	return player:forced_exit(enum.STANDUP_REASON_FORCE)
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
			is_trustee = p.trustee and true or false,
		    }
	end)
    
	local private_conf = base_private_table[self.private_id]
    
	local info = {
	    table_id = self.private_id,
	    seat_list = seats,
	    room_cur_round = self:gaming_round(),
	    rule = self:is_private() and json.encode(self.rule) or "",
	    game_type = def_first_game_type,
	    template_id = private_conf and private_conf.template,
	}
    
	return info
end

return base_table