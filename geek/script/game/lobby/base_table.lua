-- 桌子基类

require "game.net_func"
local log = require "log"
local enum = require "pb_enums"
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
local club_utils = require "game.club.club_utils"
local json = require "json"
local gutil = require "util"
local reddb = redisopt.default
local queue = require "skynet.queue"
local game_util = require "game.util"
local player_winlose = require "game.lobby.player_winlose"
local base_rule = require "game.lobby.base_rule"
local table_template = require "game.lobby.table_template"
local club_sync_cache = require "game.club.club_sync_cache"

local table = table
local string = string
local math = math
local tinsert = table.insert

local dismiss_request_timeout = 60
local auto_dismiss_timeout = 2 * 60
local auto_kickout_timeout = 5 * 60
local auto_ready_timeout = 10

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
	[enum.STANDUP_REASON_LESS_ROOM_FEE] = enum.DISMISS_REASON_LESS_ROOM_FEE,
	[enum.STANDUP_REASON_DELAY_KICKOUT_TIMEOUT] = enum.DISMISS_REASON_NORMAL,
}

local tranfer_owner_reason = {
	[enum.STANDUP_REASON_OFFLINE] = true,
	[enum.STANDUP_REASON_NORMAL] = true,
	[enum.STANDUP_REASON_DISMISS] = false,
	[enum.STANDUP_REASON_FORCE] = true,
	[enum.STANDUP_REASON_ADMIN_DISMISS_FORCE] = false,
	[enum.STANDUP_REASON_DISMISS_REQUEST] = false,
	[enum.STANDUP_REASON_DISMISS_TRUSTEE] = true,
	[enum.STANDUP_REASON_BANKRUPCY] = true,
	[enum.STANDUP_REASON_TABLE_TIMEOUT] = false,
	[enum.STANDUP_REASON_MAINTAIN] = false,
	[enum.STANDUP_REASON_ROUND_END] = true,
	[enum.STANDUP_REASON_BLOCK_GAMING] = true,
	[enum.STANDUP_REASON_CLUB_CLOSE] = false,
	[enum.STANDUP_REASON_LESS_ROOM_FEE] = false,
	[enum.STANDUP_REASON_DELAY_KICKOUT_TIMEOUT] = true,
}

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
	self.ready_list = {}

	self.ext_round_status = nil
	self.lock = queue()
end

function base_table:lockcall(fn,...)
	self.lock = self.lock or queue()
	return self.lock(fn,...)
end

function base_table:is_play( ... )
	log.info("base_table:is_play")
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
	self:broadcast_sync_table_info_2_club({
		opcode = enum.TSO_SEAT_CHANGE,
		table_id = self:id(),
		trigger = {
			chair_id = player.chair_id,
			player_info = {
				guid = player.guid,
			},
			online = true,
		},
	})

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

function base_table:log_statistics_money(money_id,money,reason)
	game_util.log_statistics_money(money_id,money,reason,self.club_id)
end

function base_table:request_dismiss(player)
	return self:lockcall(function()
		log.info("player %s request dismiss table_id %s",player.guid,self:id())
		if not self:is_alive() then
			send2client_pb(player.guid,"SC_DismissTableReq",{
				result = enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
			})
			return
		end

		if self.dismiss_request then
			send2client_pb(player.guid,"SC_DismissTableReq",{
				result = enum.ERROR_OPERATION_REPEATED
			})
			return
		end

		local timer = self:new_timer(dismiss_request_timeout,function()
			self:foreach(function(p)
				if not self.dismiss_request then
					return
				end

				if self.dismiss_request.commissions[p.chair_id] == nil then
					self:commit_dismiss(p,true)
				end
			end)
		end)

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
			timeout = dismiss_request_timeout,
		})

		self:broadcast2client("SC_DismissTableCommit",{
			result = enum.ERROR_NONE,
			chair_id = player.chair_id,
			guid = player.guid,
			agree = true,
		})

		return enum.ERROR_NONE
	end)
end

function base_table:clear_dismiss_request()
	if not self.dismiss_request then return end

	if self.dismiss_request.timer then
		self.dismiss_request.timer:kill()
		self.dismiss_request.timer = nil
	end

	self.dismiss_request = nil
end

function base_table:clear_player_dismiss_request(player)
	if not self.dismiss_request then return end
	if not self.dismiss_request.commissions then return end

	local commissions = self.dismiss_request.commissions
	commissions[player.chair_id] = nil
end

function base_table:commit_dismiss(player,agree)
	return self:lockcall(function()
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
	end)
end

function base_table:base_multi()
	if self:is_private() then
        local private_table = base_private_table[self.private_id]
        local rule = private_table.rule
        return rule.union and rule.union.score_rate or 1
	end

	return 1
end

function base_table:score_money(score)
	return score * 100 * self:base_multi()
end

base_table.calc_score_money = base_table.score_money

function base_table:money_score(money)
	return money / 100 / self:base_multi()
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

	channel.publish("db.?","msg","SD_LogPlayerCommissionContributes",{
		parent = guid,
		guid = contributer,
		commission = commission,
		template = template_id,
		club = club.id,
	})

	club:incr_team_commission(guid,commission,self.ext_round_id)
end


function base_table:do_tax_commission(taxes)
	if not self:is_private() then 
		return
	end

	local money_id = self:get_money_id()
	if not money_id then
		log.error("base_table:do_tax_commission [%d] got nil private money id.",self.private_id)
		return
	end

	local club = self.conf.club
	if not club then
		log.error("base_table:do_tax_commission [%d] got private club.",self.private_id)
		return
	end

	local private_table = base_private_table[self.private_id]
	if not private_table then 
		log.error("base_table:do_tax_commission [%d] got nil private table.",self.private_id)
		return
	end

	local template_id = private_table.template
	if not template_id then
		log.error("base_table:do_tax_commission [%d] got nil template.",self.private_id)
		return
	end

	local club_id = self.club_id
	local rule = self.rule
	local taxconf = rule.union and rule.union.tax or nil
	if not taxconf and type(taxconf) ~= "table" then
		log.error("base_table:do_tax_commission got nil tax config,club:%s template:%s",club_id,template_id)
		return
	end

	local tree = club_utils.father_tree(club_id,table.keys(taxes))
	local teamsconf = table.map(tree,function(_,team_id)
		return team_id,club_utils.get_template_commission_conf(club_id,template_id,team_id)
	end)

	local branches = table.map(taxes,function(_,guid)
		return guid,club_utils.father_branch(club_id,tree,guid)
	end)

	local do_percentage = taxconf.percentage_commission

	local commissions = {}
	local contributions = {}
	
	local function do_branch_commission(guid,tax)
		local branch = branches[guid]
		local commission = tax
		local i = 1
		for i = 1,#branch do
			local myself = branch[i]
			local son = branch[i + 1] or guid
			local son_commission
			if son then
				son_commission = club_utils.team_commission(teamsconf[son],commission,do_percentage) or 0
			else
				son = guid
				son_commission = 0
			end
			son_commission = son_commission > 0 and son_commission or 0
			son_commission = son_commission < commission and son_commission or commission
			local my_commission = commission - son_commission
			commission = son_commission
			commissions[myself] = (commissions[myself] or 0) + my_commission

			if my_commission > 0 then
				tinsert(contributions,{
					parent = myself,
					son = son,
					commission = my_commission,
				})
			end

			log.info("base_table:do_tax_commission club:%s,partner:%s,commission:%s",club_id,myself,commission)

			if commission <= 0 then
				break
			end
		end
	end

	for guid,tax in pairs(taxes) do
		if tax > 0 then
			do_branch_commission(guid,tax)
		end
	end

	log.dump(contributions)
	log.dump(commissions)

	if #contributions > 0 then
		channel.publish("db.?","msg","SD_LogPlayerCommissionContributes",{
			contributions = contributions,
			template = template_id,
			club = club_id,
		})

		channel.publish("statistics.?","msg","SS_PlayerCommissionContributes",{
			contributions = contributions,
			template = template_id,
			club = club_id,
		})
	end

	for guid,commission in pairs(commissions) do
		commission = math.floor(commission + 0.0000001)
		if commission > 0 then
			club:incr_team_commission(guid,commission,self.ext_round_id)
		end
	end
end

function base_table:each_bigwin_commission_tax(bigwin_tax,bigwin_guids)
	local player_count = table.nums(self.players)
	local eachwin = math.floor(bigwin_tax / player_count)
	local taxes = table.map(self.players,function(p)
		return p.guid,eachwin
	end)

	local total_delta = bigwin_tax - (eachwin * player_count)

	local bigwin_any_guid = bigwin_guids[1]
	taxes[bigwin_any_guid] = taxes[bigwin_any_guid] + total_delta

	return taxes
end

function base_table:do_bigwin_commission(bigwin_tax,bigwin_guids)
	if not self:is_private() then 
		return
	end

	local money_id = self:get_money_id()
	if not money_id then
		log.error("base_table:do_bigwin_commission [%d] got nil private money id.",self.private_id)
		return
	end

	local club = self.conf.club
	if not club then
		log.error("base_table:do_bigwin_commission [%d] got private club.",self.private_id)
		return
	end

	local private_table = base_private_table[self.private_id]
	if not private_table then 
		log.error("base_table:do_bigwin_commission [%d] got nil private table.",self.private_id)
		return
	end

	local template_id = private_table.template
	if not template_id then
		log.error("base_table:do_bigwin_commission [%d] got nil template.",self.private_id)
		return
	end

	local club_id = self.club_id
	local rule = self.rule
	local taxconf = rule.union and rule.union.tax or nil
	if not taxconf and type(taxconf) ~= "table" then
		log.error("base_table:do_bigwin_commission got nil tax config,club:%s template:%s",club_id,template_id)
		return
	end

	local min_ensurance = taxconf.min_ensurance or 0
	min_ensurance = bigwin_tax > min_ensurance and min_ensurance or bigwin_tax
	bigwin_tax = bigwin_tax - min_ensurance
	log.dump(min_ensurance)
	log.dump(bigwin_tax)
	local taxes = self:each_bigwin_commission_tax(bigwin_tax,bigwin_guids)

	local tree = club_utils.father_tree(club_id,table.keys(taxes))
	local teamsconf = table.map(tree,function(_,team_id)
		return team_id,club_utils.get_template_commission_conf(club_id,template_id,team_id)
	end)

	local branches = table.map(taxes,function(_,guid)
		return guid,club_utils.father_branch(club_id,tree,guid)
	end)

	local commissions = {}
	local contributions = {}
	if min_ensurance > 0 then
		local each_ensurance = math.floor(min_ensurance / #bigwin_guids)
		for _,bigwin_guid in pairs(bigwin_guids) do
			local bigwin_branch = branches[bigwin_guid]
			local team = bigwin_branch[1] or self.owner_guid
			local son = branches[2] or bigwin_guid
			commissions[team] = (commissions[team] or 0) + each_ensurance
			tinsert(contributions,{
				parent = team,
				son = son,
				commission = min_ensurance,
			})
		end
	end

	local do_percentage = taxconf.percentage_commission
	local function do_branch_commission(guid,tax)
		local branch = branches[guid]
		local commission = tax
		for i = 1,#branch do
			local myself = branch[i]
			local son = branch[i + 1]
			local son_commission
			if son then
				son_commission = club_utils.team_commission(teamsconf[son],commission,do_percentage) or 0
			else
				son = guid
				son_commission = 0
			end
			son_commission = son_commission > 0 and son_commission or 0
			son_commission = son_commission < commission and son_commission or commission
			local my_commission = commission - son_commission
			commission = son_commission
			commissions[myself] = (commissions[myself] or 0) + my_commission

			if my_commission > 0 then
				tinsert(contributions,{
					parent = myself,
					son = son,
					commission = my_commission,
				})
			end

			log.info("base_table:do_bigwin_commission club:%s,partner:%s,commission:%s",club_id,myself,commission)

			if commission <= 0 then
				break
			end
		end
	end

	for guid,tax in pairs(taxes) do
		if tax > 0 then
			do_branch_commission(guid,tax)
		end
	end

	log.dump(contributions)
	log.dump(commissions)

	if #contributions > 0 then
		channel.publish("db.?","msg","SD_LogPlayerCommissionContributes",{
			contributions = contributions,
			template = template_id,
			club = club_id,
		})

		channel.publish("statistics.?","msg","SS_PlayerCommissionContributes",{
			contributions = contributions,
			template = template_id,
			club = club_id,
		})
	end

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
			if change ~= 0 then
				club:incr_member_money(p.guid,-change,enum.LOG_MONEY_OPT_TYPE_GAME_TAX,self.round_id)
				self:log_statistics_money(money_id,-change,enum.LOG_MONEY_OPT_TYPE_GAME_TAX)
			end
		end

		self:notify_game_money()
	end

	local AA = tonumber(taxconf.AA)
	if AA and AA > 0 then
		local tax = table.map(self.players,function(p) 
			return p.guid,taxconf.AA
		end)

		do_cost_tax_money(tax)
		self:do_tax_commission(tax)
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

		local maxwin = winloselist[1].change
		if maxwin <= 0 then
			log.warning("base_table:cost_tax [%d] invalid maxwin:%s.",self.private_id,maxwin)
			return
		end

		local bigwin_datas = table.select(winloselist,function(d) return d.change == maxwin end,true)
		local bigwin_tax = gutil.roulette_value(bigwin_conf,maxwin)
		if not bigwin_tax then
			log.warning("base_table:cost_tax [%d] invalid bigwin tax,maxwin:%s.",self.private_id,maxwin)
			return
		end

		log.dump(bigwin_datas)
		log.dump(bigwin_tax)
		
		local each_tax = math.floor(bigwin_tax / #bigwin_datas)
		local taxs = table.map(bigwin_datas,function(d)
			return d.guid,each_tax
		end)

		do_cost_tax_money(taxs)

		self:do_bigwin_commission(bigwin_tax,table.keys(taxs))
		return
	end
end

function base_table:notify_game_money(moneies)
	local player_moneys
	local money_id = self:get_money_id()
	if not moneies then
		player_moneys = table.series(self.players,function(p,chair) 
			return {
				chair_id = chair,
				money_id = money_id,
				money = player_money[p.guid][money_id] or 0,
			}
		end)
	else
		player_moneys = table.series(moneies,function(money,chair) 
			return {
				chair_id = chair,
				money_id = money_id,
				money = money,
			}
		end)
	end

	self:broadcast2client("SYNC_OBJECT",gutil.format_sync_info(
		"GAME",{},{
			players = player_moneys,
		}))
end

function base_table:wait_force_dismiss(reason)
	return self:wait_interrupt_dismiss(reason)
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
	local timer_id = self.kickout_no_ready_timer.id
	self:begin_clock_ex(timeout,timer_id)
	log.info("base_table:begin_kickout_no_ready_timer table_id:%s,timer:%s,timout:%s",self.table_id_,timer_id,timeout)
end

function base_table:sync_kickout_no_ready_timer(player)
	if not self.kickout_no_ready_timer then
		return
	end

	local remain_time = math.floor(self.kickout_no_ready_timer.remainder)
	local timer_id = self.kickout_no_ready_timer.id
	if player then
		send2client_pb(player,"SC_StartTimer",{
			id = timer_id,
			left_time = remain_time,
		})
		return
	end

	self:broadcast2client("SC_StartTimer",{
		id = timer_id,
		left_time = remain_time,
	})
end

function base_table:cancel_kickout_no_ready_timer()
	if not self.kickout_no_ready_timer then
		return
	end
	
	-- kill和设置nil提前,防止cancel_clock_ex时,延迟太长,无法同步
	local timer_id = self.kickout_no_ready_timer.id
	log.info("base_table:cancel_kickout_no_ready_timer table_id:%s,timer:%s",self.table_id_,timer_id)
	self.kickout_no_ready_timer:kill()
	self.kickout_no_ready_timer = nil

	self:cancel_clock_ex(timer_id)
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
	return (not p.active) or p.trustee or (club and club:can_sit_down(self.rule,p) ~= enum.ERROR_NONE)
end

function base_table:kickout_players_when_round_over()
	self:foreach(function(p)
		if self:can_kickout_when_round_over(p) then 
			p:async_force_exit(enum.STANDUP_REASON_NORMAL)
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
			if game_util.is_in_maintain() and 
				table.logic_or(self.players,function(p)
					return not p:is_vip()
				end)
			then
				self:force_dismiss(enum.STANDUP_REASON_MAINTAIN)
				return
			end

			if self:check_private_fee() ~= enum.ERROR_NONE then
				self:force_dismiss(enum.STANDUP_REASON_LESS_ROOM_FEE)
				return
			end

			local club = self.club_id and base_clubs[self.club_id] or nil
			if club then
				if club:is_block() or club:is_close() then
					self:force_dismiss(enum.STANDUP_REASON_CLUB_CLOSE)
					return
				end

				self:foreach(function(p)
					if club:is_block_gaming(p) then
						p:async_force_exit(enum.STANDUP_REASON_BLOCK_GAMING)
					end
				end)
			end

			-- 检查前面踢人时是否已解散房间
			if not self:is_private() then
				return
			end

			self:delay_normal_dismiss(enum.STANDUP_REASON_ROUND_END)
		end
		return
	end

	if self:is_round_gaming() then
		local is_trustee,_ = self:get_trustee_conf()
		if is_trustee then
			if self:can_dismiss_by_trustee() then
				self:force_dismiss(enum.STANDUP_REASON_DISMISS_TRUSTEE)
				return
			end

			self:incr_trustee_round()
		end

		if self:gaming_round() > self:total_round() then
			return 
		end

		local ready_timeout = base_rule.ready_timeout(self.rule) or auto_ready_timeout
		self:auto_ready(ready_timeout)
	end
end

-- 得到玩家
function base_table:get_player(chair_id)
	if not chair_id then
		return nil
	end
	return self.players[chair_id]
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
	-- log.info("%s",json.encode(gamelog or {}))
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
	local R = 6378137
	local radlat1 = pos1.latitude * math.pi / 180;
	local radlat2 = pos2.latitude * math.pi / 180;
	local a = radlat1 - radlat2
	local b = (pos1.longitude - pos2.longitude) * math.pi / 180;
	local s = 2 * math.asin(math.sqrt(math.sin(a /2) ^ 2 + math.cos(radlat1) * math.cos(radlat2) * math.sin(b / 2) ^ 2))

	return R * s
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
	player.active = true
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

function base_table:is_alive()
	return self.room_:is_table_exists(self.table_id_) and not self.dismissing
end

-- 玩家坐下
function base_table:player_sit_down(player, chair_id,reconnect)
	return self:lockcall(function()
		if not self:is_alive() then
			return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
		end

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

		reddb:hmset("player:online:guid:"..tostring(player.guid),{
			table = self.table_id_,
			chair = chair_id,
		})

		if self:is_private() then
			reddb:set("player:table:"..tostring(player.guid),self.private_id)
			reddb:sadd("table:player:"..tostring(self.private_id),player.guid)
		end

		self:on_player_sit_down(player,chair_id,reconnect)

		self:broadcast_sync_table_info_2_club({
			opcode = enum.TSO_JOIN,
			table_id = self:id(),
			trigger = {
				chair_id = chair_id,
				player_info = {
					guid = player.guid,
					nickname = player.nickname,
					icon = player.icon,
					sex = player.sex,
				}
			},
		})

		onlineguid[player.guid] = nil

		return enum.GAME_SERVER_RESULT_SUCCESS
	end)
end

function base_table:on_private_pre_dismiss(reason)
	
end

function base_table:on_private_dismissed(reason)

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
		if not self:exists() then
			log.trace("base_table do_dismiss but table:%s is not live,reason:%s",self:id(),reason)
		end

		log.info("base_table:dismiss %s",self.private_id)
		if not self:is_private() then
			log.warning("dismiss non-private table,real_table_id:%s",self.table_id)
			return enum.GAME_SERVER_RESULT_PRIVATE_ROOM_NOT_FOUND
		end

		if not self:can_dismiss() then
			return enum.ERROR_OPERATION_INVALID
		end

		self:clear_dismiss_request()
		self:cancel_delay_dismiss()
		self:cancel_ready_timer()
		self:cancel_all_delay_kickout()
		self:on_private_pre_dismiss()

		self:broadcast_sync_table_info_2_club({
			opcode = enum.TSO_DELETE,
			table_id = self:id(),
		})

		log.info("base_table:dismiss %s,%s",self.private_id,self.table_id_)
		local private_table_conf = base_private_table[self.private_id]
		local club_id = private_table_conf.club_id
		local private_table_id = private_table_conf.table_id
		local private_table_owner = private_table_conf.owner
		reddb:del("table:info:"..private_table_id)
		reddb:del("player:table:"..private_table_owner)
		reddb:del("table:player:"..private_table_id)
		reddb:srem("table:all",private_table_id)
		
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

		local payopt = self.rule.pay.option
		local roomfee = self:get_private_fee(self.rule)
		local function next_player(owner)
			local chair_id = owner.chair_id
			for i = chair_id,chair_id + self.chair_count - 2 do
				local p = self.players[i % self.chair_count + 1]
				if p and (
					payopt ~= enum.PAY_OPTION_ROOM_OWNER or not p:check_money_limit(roomfee,0)
				) then
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
			return enum.ERROR_LESS_ROOM_CARD
		end

		log.info("base_table:transfer_owner %s,%s,old:%s,new:%s",self.private_id,self.table_id_,old_owner.guid,new_owner.guid)
		reddb:del("player:table:"..old_owner.guid)
		reddb:hset("table:info:"..private_table_id,"owner",new_owner.guid)
		reddb:set("player:table:"..new_owner.guid,private_table_id)
		private_conf.owner = new_owner
		private_conf.owner_guid = new_owner.guid
		private_conf.owner_chair_id = new_owner.chair_id
		self.owner = new_owner
		self.owner_guid = new_owner.guid
		self.owner_chair_id = new_owner.chair_id

		self:broadcast2client("S2C_TRANSFER_ROOM_OWNER_RES",{
			table_id = self.private_id,
			old_owner = old_owner.guid,
			new_owner = new_owner.guid,
		})

		return enum.ERROR_NONE
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

function base_table:wait_interrupt_dismiss(reason)
	self.dismissing = true
	-- 解散时，清理准备列表，避免游戏check_start再开始
	self:clear_ready()
	self:clear_dismiss_request()
	local dreason = dismiss_reason[reason]
	local co = coroutine.running()
	local result = enum.ERROR_NONE
	--防止玩家锁与桌子锁死锁
	skynet.fork(function()
		if self:gaming_round() > 0 then
			self:on_final_game_overed(reason)
		end

		self:notify_dismiss(dreason)
		for _,p in pairs(self.players) do
			local r = p:force_exit(reason)
			if r ~= enum.ERROR_NONE then
				result = r
			end
		end
		self.dismissing = nil
		skynet.wakeup(co)
	end)
	skynet.wait(co)
	return result
end

function base_table:interrupt_dismiss(reason)
	self.dismissing = true
	-- 解散时，清理准备列表，避免游戏check_start再开始
	self:clear_ready()
	self:clear_dismiss_request()
	local dreason = dismiss_reason[reason]
	--防止玩家锁与桌子锁死锁
	skynet.fork(function()
		if self:gaming_round() > 0 then
			self:on_final_game_overed(reason)
		end

		self:notify_dismiss(dreason)
		self:foreach(function(p) p:force_exit(reason) end)
		self.dismissing = nil
	end)
end

function base_table:normal_dismiss(reason)
	self.dismissing = true
	-- 解散时，清理准备列表，避免游戏check_start再开始
	self:clear_ready()
	self:clear_dismiss_request()
	local dreason = dismiss_reason[reason]
	--防止玩家锁与桌子锁死锁
	skynet.fork(function()
		self:notify_dismiss(dreason)
		self:foreach(function(p) p:force_exit(reason) end)
		self.dismissing = nil
	end)
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
	if player.kickout_timer then
		log.info("delay_kickout exists kickout timer:%s.",player.kickout_timer.id)
		return
	end

	player.kickout_timer = self:new_timer(auto_kickout_timeout,function()
		self:cancel_delay_kickout(player)
		player:async_force_exit(reason)
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

function base_table:broadcast_sync_table_info_2_club(syncinfo)
	if not self:is_private() then
		return
	end

	if not self.club_id then
		return
	end
	
	local club = base_clubs[self.club_id]
	if not club then
		return
	end

	club_sync_cache.sync(self.club_id,syncinfo)
end


function base_table:exists()
	return self.room_:is_table_exists(self.table_id_)
end

-- 玩家站起
function base_table:player_stand_up(player, reason)
	return self:lockcall(function()
		if not self:exists() then
			return enum.GAME_SERVER_RESULT_NOT_FIND_TABLE
		end
		
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
			local list_guid = table.concat(table.extract(self.players,"guid"),",")
			log.info("set guid[%s] table_id[%s] is false player_list [%s]",guid,self:id(),chair_id , list_guid)
			self.player_count = self.player_count - 1
			if self:is_ready(chair_id) then
				self:cancel_ready(chair_id)
			end

			self:on_player_stand_up(player,reason)

			local transfer_result
			if self:is_private() and tranfer_owner_reason[reason] then
				if player == self.conf.owner and player_count > 1 then
					transfer_result = self:transfer_owner()
				end
			end

			player.table_id = nil
			player.chair_id = nil

			self.players[chair_id] = nil

			reddb:hdel("player:online:guid:"..tostring(guid),"global_table")
			reddb:hdel("player:online:guid:"..tostring(guid),"table")
			reddb:hdel("player:online:guid:"..tostring(guid),"chair")
			reddb:del("player:table:"..tostring(guid))
			reddb:srem("table:player:"..tostring(self.private_id),guid)
			onlineguid[guid] = nil

			self:on_player_stand_uped(player,reason)

			if transfer_result and transfer_result ~= enum.ERROR_NONE then
				self:interrupt_dismiss(enum.STANDUP_REASON_LESS_ROOM_FEE)
			elseif player_count == 1 then
				self:do_dismiss(dismiss_reason[reason])
			else
				self:broadcast_sync_table_info_2_club({
					opcode = enum.TSO_LEAVE,
					table_id = self:id(),
					trigger = {
						chair_id = chair_id,
						player_info = {
							guid = player.guid,
						}
					},
				})

				if 	reason == enum.STANDUP_REASON_OFFLINE or
					reason == enum.STANDUP_REASON_NORMAL or
					reason == enum.STANDUP_REASON_FORCE or
					reason == enum.STANDUP_REASON_BANKRUPCY or
					reason == enum.STANDUP_REASON_NO_READY_TIMEOUT
				then
					self:check_start()
				end
			end

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
	self:clear_player_dismiss_request(player)
end

function base_table:on_player_stand_uped(player,reason)
	self:cancel_delay_kickout(player)
	if reason ~= enum.STANDUP_REASON_OFFLINE then
		self:check_kickout_no_ready()
	end
end

function base_table:on_offline(player)
	player.active = nil
	self:notify_online(player,false)
	self:broadcast_sync_table_info_2_club({
		opcode = enum.TSO_SEAT_CHANGE,
		table_id = self:id(),
		trigger = {
			chair_id = player.chair_id,
			player_info = {
				guid = player.guid,
			},
			online = false,
		},
	})
end

function base_table:clear_trustee_status()
	self.is_someone_trustee = nil
	self.someone_trustee_round = nil
end

function base_table:clear_player_trustee()
	self:foreach(function(p) p.trustee = nil end)
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
						p:async_force_exit(enum.STANDUP_REASON_NO_READY_TIMEOUT)
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
		player:async_force_exit()
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

	self:lockcall(function()
		if not self:is_alive() then
			return
		end

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
	player.active = true
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
function base_table:check_start()
	log.info("check_start %s",self:id())
	local n = table.nums(self.ready_list)
	local min_count = self.start_count or self.room_.min_gamer_count or self.chair_count
	if n >= min_count then
		self:start(n)
	end
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

function base_table:check_private_fee()
	local rule = self.rule
	local payopt = rule.pay.option
	if payopt == enum.PAY_OPTION_AA then
		local all = table.logic_and(self.players,function(p) 
			return self.room_:check_room_fee(self.rule,self.conf.club,p) == enum.ERROR_NONE
		end)
		return not all and enum.ERROR_LESS_ROOM_CARD or enum.ERROR_NONE
	elseif payopt == enum.PAY_OPTION_OWNER then
		local owner = base_players[self.owner_guid]
		return self.room_:check_room_fee(self.rule,self.conf.club,owner)
	elseif payopt == enum.PAY_OPTION_BOSS then
		if not self.conf.club then
			return enum.ERROR_PARAMETER_ERROR
		end

		return self.room_:check_room_fee(self.rule,self.conf.club)
	end

	return enum.ERROR_NONE
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
			self:log_statistics_money(0,-money,enum.LOG_MONEY_OPT_TYPE_ROOM_FEE)
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
		self:log_statistics_money(0,-money,enum.LOG_MONEY_OPT_TYPE_ROOM_FEE)
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
		self:log_statistics_money(0,-money,enum.LOG_MONEY_OPT_TYPE_ROOM_FEE)
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

	if self.club_id then
		self:broadcast_sync_table_info_2_club({
			opcode = enum.TSO_STATUS_CHANGE,
			table_id = self:id(),
			cur_round = self:gaming_round(),
		})
	end

	if self:gaming_round() == 1 then
		self:cost_private_fee()
	end

	self.start_time = os.time()
end

function base_table:balance(moneies,why)
	log.dump(moneies)

	local money_id = self:get_money_id() or -1
	if self:is_private() and self.conf.club and self.conf.club.type  == enum.CT_UNION then
		-- local minrate = 1
		-- for pid,money in pairs(moneies) do
		-- 	local p = self.players[pid] or base_players[pid]
		-- 	local p_money = self.old_moneies and self.old_moneies[pid] or player_money[p.guid][money_id]
		-- 	if p_money + money < 0 then
		-- 		local r = math.abs(p_money) / math.abs(money)
		-- 		if minrate > r then minrate = r end
		-- 	end
		-- end

		-- for pid,_ in pairs(moneies) do
		-- 	moneies[pid] = math.floor(moneies[pid] * minrate)
		-- end

		-- log.dump(moneies)

		local club = self.conf.club

		self:lockcall(function()
			for chair_or_guid,money in pairs(moneies) do
				if money ~= 0 then
					money = math.floor(money)
					local p = self.players[chair_or_guid] or base_players[chair_or_guid]
					club:incr_member_money(p.guid,money,why,self.round_id)
					player_winlose.incr_money(p.guid,money_id,money)
					self:log_statistics_money(money_id,money,why)
				end
			end
		end)

		return moneies
	end
	
	for chair_or_guid,money in pairs(moneies) do
		if money ~= 0 then
			money = math.floor(money)
			local p = self.players[chair_or_guid] or base_players[chair_or_guid]
			p:incr_money({
				money_id = money_id,
				money = money,
			},why,self.round_id)

			player_winlose.incr_money(p.guid,money_id,money)

			self:log_statistics_money(money_id,money,why)
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

	self.ext_round_start_time = os.time()
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

	local msg = {
		club = club_id,
		template = template_id,
		game_id = def_first_game_type,
		game_name = def_game_name,
		ext_round = self.ext_round_id,
		guids = table.series(self.players,function(p) return p.guid end),
		table_id = self.private_id,
		log = l,
		rule = self.rule,
		start_time = self.ext_round_start_time,
		end_time = os.time(),
	}

	self.ext_round_start_time = nil

	channel.publish("db.?","msg","SD_LogExtGameRound",msg)
	channel.publish("statistics.?","msg","SS_GameRoundEnd",msg)

	self.ext_round_status = EXT_ROUND_STATUS.END

	if template_id and template_id ~= 0 then
		local template_info = table_template[template_id]
		self.rule = template_info.rule
	end
end

-- 开始游戏
function base_table:start(player_count)
	return self:lockcall(function()
		-- double check
		if self:is_play() then return end

		player_count = player_count or table.nums(self.players)
		log.info("base_table:start %s,%s",self.chair_count,player_count)
		self:cancel_delay_dismiss()
		-- self:cancel_all_delay_kickout()

		if not self:is_round_gaming() then
			self:on_process_start(player_count)
		end

		self:on_pre_start(player_count)

		self:on_started(player_count)
	end)
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
	self.max_round = nil
	self.owner = nil
	self.owner_guid = nil
	self.owner_chair_id = nil
	self.club = nil
	self.club_id = nil
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
	if not self:is_private() then
		return
	end

	local club = self.conf.club
	if not club or club.type ~= enum.CT_UNION then
		return
	end

	log.dump(self.rule.union)

	if not self.rule.union or not self.rule.union.min_score then
		return
	end

	local money_id = self:get_money_id()
	local limit = self.rule.union.min_score
	local money = player_money[player.guid][money_id]
	return money < limit
end

function base_table:play_once_again(player)
	return self:lockcall(function()
		-- double check
		if not self:exists() then
			log.error("base_table:play_once_again double check table not exists,%s",self:id())
			return enum.ERROR_TABLE_NOT_EXISTS
		end

		local room_fee_result = self:check_private_fee()
		if room_fee_result ~= enum.ERROR_NONE then
			return room_fee_result
		end

		local club = self.conf.club
		if club and self.rule and not club:can_sit_down(self.rule,player) then
			return enum.ERROR_LESS_GOLD
		end
		
		self:ready(player)
		return enum.ERROR_NONE
	end)
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
	if 	kicker.guid ~= self.conf.owner_guid or 
		self.rule.option.owner_kickout_player == false then
		return enum.ERROR_PLAYER_NO_RIGHT
	end

	if player.guid == kicker.guid then
		return enum.ERROR_OPERATION_INVALID
	end

	return player:force_exit(enum.STANDUP_REASON_FORCE)
end

function base_table:global_status_info(op)
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
			online = p.active,
		    }
	end)
    
	local private_conf = base_private_table[self.private_id]
    
	local info = {
	    table_id = self.private_id,
	    seat_list = seats,
	    room_cur_round = self:gaming_round(),
	    game_type = def_first_game_type,
	    template_id = private_conf and private_conf.template,
	}
    
	return info
end

return base_table