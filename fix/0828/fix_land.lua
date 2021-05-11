

local land_table = require "game.land.land_table"
local enum = require "pb_enums"

local TABLE_STATUS = {
	NONE = 0,
	-- 等待开始
	FREE = 1,
	-- 开始倒记时
	START_COUNT_DOWN = 2,
	--叫地主
	COMPETE_LANDLORD = 3,
	-- 游戏进行
	PLAY = 4,
	-- 结束阶段
	END = 5,
}

function land_table:game_balance(winner)
	self.compete_first = winner.chair_id

	local is_chuntian = table.logic_and(self.players,function(p)
		if p.chair_id == self.landlord then return true end
		return not p.discard_count or p.discard_count == 0
	end)

	local is_fanchun = self.landlord ~= winner.chair_id and self.players[self.landlord].discard_count == 1

	local multi = 2 ^ (self.bomb + (self.multi or 0))
	if is_fanchun or is_chuntian then
		multi = multi * 2
	end

	local max_times = self:get_max_times()
	multi = max_times > multi and multi or max_times

	local function  is_win(chair)
		if winner.chair_id == self.landlord then
			return chair == self.landlord
		end

		return chair ~= self.landlord
	end

	local player_count = table.nums(self.players)
	local scores = table.map(self.players,function(_,chair)
		local score = multi * self.base_score
		if is_win(chair) then
			score = self.landlord == chair  and (player_count - 1) * score or score
		else
			score = self.landlord == chair and -((player_count - 1)) * score or -score
		end
		return chair,score
	end)

	self:foreach(function(p,chair)
		local score = scores[chair]
		if score >= 0 and (p.statistics.max_score or 0) < score then
			p.statistics.max_score = score
		end
	end)

	local moneies = table.map(scores,function(score,chair) return chair,self:calc_score_money(score) end)
	moneies = self:balance(moneies,enum.LOG_MONEY_OPT_TYPE_LAND)
	self:foreach(function(p,chair)
		p.total_score = (p.total_score or 0) + scores[chair]
		p.round_score = scores[chair]
		p.total_money = (p.total_money or 0) + moneies[chair]
		p.round_money = moneies[chair]
	end)

	self:foreach(function(p,chair)
		local plog = self.game_log.players[chair]
		plog.chair_id = chair
		plog.total_money = p.total_money
		plog.total_score = p.total_score
		plog.round_money = p.round_money
		plog.score = p.round_score
		plog.nickname = p.nickname
		plog.head_url = p.icon
		plog.guid = p.guid
		plog.sex = p.sex
	end)

	self:broadcast2client("SC_DdzGameOver",{
		player_balance = table.series(self.players,function(p,chair)
			return {
				chair_id = chair,
				base_score = self.base_score,
				times = multi,
				round_score = scores[chair],
				round_money = p.round_money,
				total_score = p.total_score,
				total_money = p.total_money,
				hand_cards = table.keys(p.hand_cards),
			}
		end),
		chun_tian = is_fanchun and 2 or (is_chuntian and 1 or 0),
		left_cards = self.left_cards,
	})

	self:notify_game_money()

	self:foreach(function(p)
		local plog = self.game_log.players[p.chair_id]
		plog.total_money = p.total_money
		plog.total_score = p.total_score
		plog.round_money = p.round_money
		plog.score = p.round_score
		plog.nickname = p.nickname
		plog.head_url = p.icon
		plog.guid = p.guid
		plog.sex = p.sex
	end)

	self.game_log.cur_round = self.cur_round
	self:save_game_log(self.game_log)

	self.last_discard = nil
	self:update_status(TABLE_STATUS.FREE)
	self:clear_ready()
	self:game_over()
end