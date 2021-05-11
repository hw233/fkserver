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
local json = require "json"
local club_partner = require "game.club.club_partner"



local data = dbopt.log:query([[
	SELECT content FROM t_log_club_msg
	WHERE club = 66118398
	AND created_time > UNIX_TIMESTAMP('2021-12-13 12:09:35')
	AND created_time < UNIX_TIMESTAMP('2021-12-13 13:33:18')
	AND type = 2
]])

assert(not data.err)

data = table.series(data,function(v) return json.decode(v.content) end)

local member_partner = {}

for _,v in pairs(data) do
	local guid = v.guid
	local team = v.team
	assert(not member_partner[guid])
	member_partner[guid] = team
end

-- dump(print,member_partner)

local partner_member = {}
for guid,team in pairs(member_partner) do
	partner_member[team] = partner_member[team] or {}
	partner_member[team][guid] = true
end

-- dump(print,partner_member)

local roots = {}

for guid,team in pairs(member_partner) do
	local p = team
	while true do
		local p1 = member_partner[p]
		if not p1 then 
			roots[p] = roots[p] or partner_member[p]
			break 
		end
		partner_member[p1][p] = partner_member[p]
		p = p1
	end
end

dump(print,partner_member)

-- dump(print,partner_member[385843])
-- dump(print,partner_member[547859])
-- dump(print,partner_member[568686])

local club_id = 66118398
local club = base_clubs[club_id]
local owner = club.owner
local money_id = club_money_type[club_id]

local function join(team,tree)
	for guid,branch in pairs(tree) do
		if not club_member[club_id][guid] then
			club:full_join(guid,owner,owner)
		end
		
		if type(branch) == "table" then
			local role = club_role[club_id][guid]
			if not role then
				club_partner:create(club_id,guid,team)
			end
			join(guid,branch)
		end
	end
end

-- for guid,branch in pairs(roots) do
-- 	if not club_member[club_id][guid] then
-- 		club:full_join(guid,owner,owner)
-- 	end
-- 	local role = club_role[club_id][guid]
-- 	if not role then
-- 		club_partner:create(club_id,guid,owner)
-- 	end
-- 	join(guid,branch)
-- end

-- local data = dbopt.log:query([[
-- 	SELECT * FROM 
-- 	(
-- 	SELECT guid,old_money,created_time FROM t_log_money
-- 	WHERE created_time > UNIX_TIMESTAMP('2021-12-13 12:09:35') * 1000 
-- 	AND created_time < UNIX_TIMESTAMP('2021-12-13 13:33:18') * 1000 
-- 	AND money_id IN (
-- 		SELECT money_id FROM game.t_club_money_type 
-- 		WHERE club = 66118398
-- 	)
-- 	AND (reason = 49 OR reason = 48) 
-- 	AND (reason_ext = "")
-- 	) a
-- 	ORDER BY created_time ASC	
-- ]])

-- local member_money = {}

-- for _,v in pairs(data) do
-- 	if not member_money[v.guid] then
-- 		member_money[v.guid] = v.old_money
-- 	end
-- end

-- dump(print,member_money)

-- local function sum_money(team)
-- 	return table.sum(partner_member[team] or {},function(v,guid)
-- 		if type(v) == "table" then
-- 			return sum_money(guid) + (member_money[guid] or 0)
-- 		end

-- 		return (member_money[guid] or 0)
-- 	end)
-- end

-- dump(print,sum_money(385843),nil,385843)
-- dump(print,sum_money(547859),nil,547859)
-- dump(print,sum_money(568686),nil,568686)