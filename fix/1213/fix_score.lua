local dbopt = require "dbopt"
local dump = require "fix.dump"
require "functions"
local enum = require "pb_enums"
local club_member = require "game.club.club_member"
local club_money_type = require "game.club.club_money_type"
local player_money = require "game.lobby.player_money"
local base_clubs = require "game.club.base_clubs"
local club_partner_member = require "game.club.club_partner_member"
local club_role = require "game.club.club_role"

local data = dbopt.log:query([[
	SELECT * FROM 
	(
	SELECT guid,(new_money - old_money) money,created_time FROM t_log_money
	WHERE created_time > UNIX_TIMESTAMP('2021-12-13 13:00:00') * 1000 
	AND created_time < UNIX_TIMESTAMP('2021-12-13 13:03:00') * 1000 
	AND money_id IN (
		SELECT money_id FROM game.t_club_money_type 
		WHERE club = 66118398
	)
	AND (reason = 49 OR reason = 48) 
	AND (reason_ext = "")
	) a
	ORDER BY created_time DESC	
]])

assert(not data.err)

dump(print,data)

local club_id = 66118398
local money_id = club_money_type[club_id]

local function transfer_money(club,from_guid,to_guid,money,reason)
    local allmoney = player_money[from_guid][money_id]
    money = money or allmoney
    if allmoney < money then
        print(string.format("transfer_money from[%s] to [%s] leak %s < %s",from_guid,to_guid,allmoney,money))
        return
    end
    club:incr_member_money(from_guid,-money,reason)
    club:incr_member_money(to_guid,money,reason)
    return true
end

local club = base_clubs[club_id]
local function snapshot_incr_money(team)
	for _,c in pairs(data) do
		local guid = c.guid
		local money = c.money
		club:incr_member_money(guid,-money,enum.LOG_MONEY_OPT_TYPE_RECHAGE_MONEY_IN_CLUB)
	end
end

local function snapshot_decr_money(team)
	for guid in pairs(club_partner_member[club_id][team] or {}) do
		local role = club_role[club_id][guid]
		if role == enum.CRT_PARTNER then
			snapshot_decr_money(guid)
		end

		local money = player_money[guid][money_id]
		if money ~= 0 then
			transfer_money(club,guid,team,money,enum.LOG_MONEY_OPT_TYPE_CASH_MONEY_IN_CLUB)
		end
	end
end

snapshot_decr_money(club.owner)
snapshot_incr_money(club.owner)