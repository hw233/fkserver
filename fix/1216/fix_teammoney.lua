
local dump = require "fix.dump"
require "functions"
local club_money_type = require "game.club.club_money_type"
local player_money = require "game.lobby.player_money"
local club_partner_member = require "game.club.club_partner_member"
local club_role = require "game.club.club_role"
local enum = require "pb_enums"

local club_id = 66118398
local money_id = club_money_type[club_id]

local function sum_money(team)
	return table.sum(club_partner_member[club_id][team],function(_,guid)
		if club_role[club_id][guid] == enum.CRT_PARTNER then
			return sum_money(guid) + player_money[guid][money_id]
		end

		return player_money[guid][money_id]
	end)
end


dump(print,sum_money(385843))
dump(print,sum_money(547859))
dump(print,sum_money(568686))
