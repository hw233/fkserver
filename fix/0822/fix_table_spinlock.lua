local string = string
if not string.match(package.path,"%./%?%.lua") then
	package.path = package.path .. ";./?.lua"
end

local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"

local base_room = require "game.lobby.base_room"
local log = require "log"
local enum = require "pb_enums"
local redisopt = require "redisopt"
local spinlock = require "spinlock"

local reddb = redisopt.default

-- 创建私人房间
function base_room:create_private_table(player,chair_count,round, rule,club)
	log.info("create private room")
	if player.table_id or player.chair_id then
		log.info("player already in table, table_id is [%s] chair_id is [%s] guid[%s]",player.table_id,player.chair_id,player.guid)
		return enum.GAME_SERVER_RESULT_PLAYER_ON_CHAIR
	end

	local room_fee_result = self:check_room_fee(rule,club,player)
	if room_fee_result ~= enum.ERROR_NONE then
		return room_fee_result
	end

	local global_tid
	spinlock("table:spinlock",function()
		for _ = 1,10000 do
			global_tid = math.random(100000,999999)
			local exists = reddb:sismember("table:all",global_tid)
			if not exists then break end
		end

		reddb:sadd("table:all",global_tid)
	end)

	local table_id = global_tid
	local tb = self:new_table(table_id,chair_count)

	local chair_id = 1
	tb:private_init(global_tid,rule,{
		round = round,
		chair_count = chair_count,
		owner = player,
		owner_guid = player.guid,
		owner_chair_id = chair_id,
		rule = rule,
		club = club,
	})

	tb.private_id = global_tid
	tb.max_round = round
	tb.owner = player
	tb.owner_guid = player.guid
	tb.owner_chair_id = chair_id
	tb.rule = rule
	tb.club = club
	tb.club_id = club and club.id or nil

	return tb:lockcall(function()
		local result = tb:player_sit_down(player, chair_id)
		if result ~= enum.GAME_SERVER_RESULT_SUCCESS then
			log.info("base_room:create_private_table player_sit_down,%s,%s,%s,failed",player.guid,chair_id,result)
			tb:private_clear()
			self:del_table(table_id)
			reddb:srem("table:all",global_tid)
			return result
		end

		self:player_enter_room(player)

		reddb:hmset("table:info:"..tostring(global_tid),{
			room_id = def_game_id,
			table_id = global_tid,
			real_table_id = table_id,
			owner = player.guid,
			rule = rule,
			game_type = def_first_game_type,
			create_time = os.time(),
		})

		reddb:hset("player:online:guid:"..tostring(player.guid),"global_table",global_tid)

		return enum.GAME_SERVER_RESULT_SUCCESS,global_tid,tb
	end)
end
