-- 斗地主房间

local pb = require "pb"

local base_room = require "game.lobby.base_room"
require "game.land.land_table"
local redisopt = require "redisopt"

require "functions"

local get_second_time = get_second_time
local x = 1


-- enum GAME_SERVER_RESULT
local GAME_SERVER_RESULT_SUCCESS = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")

-- 等待开始
local LAND_STATUS_FREE = 1


land_room = base_room

--function test()
--	-- body
--	print("========================A")
--	--redis_command(string.format("hset %s %s %d","ab","a0",get_second_time() + math.random(54)))
--	redis_cmd_do(string.format("hset %s %s %d","ab","a0",get_second_time() + math.random(54)))
--	redis_cmd_do(string.format("hset %s %s %d","ab","a1",get_second_time() + math.random(54)))
--	redis_cmd_do(string.format("hset %s %s %d","ab","a2",get_second_time() + math.random(54)))
--	redis_cmd_do(string.format("hset %s %s %d","ab","a3",get_second_time() + math.random(54)))
--	redis_cmd_do(string.format("hset %s %s %d","ab","a4",get_second_time() + math.random(54)))
--	redis_cmd_do(string.format("hset %s %s %d","ab","a5",get_second_time() + math.random(54)))
--	redis_cmd_do(string.format("hset %s %s %d","ab","a6",get_second_time() + math.random(54)))
--	redis_cmd_do(string.format("hset %s %s %d","ab","a7",get_second_time() + math.random(54)))
--	redis_cmd_do(string.format("hset %s %s %d","ab","a8",get_second_time() + math.random(54)))
--	redis_cmd_do(string.format("hset %s %s %d","ab","a9",get_second_time() + math.random(54)))
--
--	print("========================0")
--	local reply = redis_cmd_do(string.format("hkeys %s","ab"))
--	if reply:is_array() then
--		local count = reply:size_element()
--		print("========================is array:"..count)
--		local notify = {}
--		for i = 0,count-1 do
--			local element = reply:get_element(i)
--			-- print(element)
--			if element:is_string() then
--				local  key = element:get_string()
--				print("string========"..key)
--				--element_reply =  redis_cmd_do(string.format("hget %s %s","ab",key))
--				--if element_reply:is_string() then
--				--	notify[key] = element_reply:get_string()
--				--end
--			end
--		end
--		for k,v in pairs(notify) do
--			print(string.format(" %s [%s]",k,v))
--		end
--	end
--end

dump = dump

function test( ... )
	-- body
	set_game_times("5_1",100,101,true)
	set_game_times("5_1",100,102,true)
	set_game_times("5_1",100,103,true)
	set_game_times("5_1",100,104,true)
	set_game_times("5_1",100,105,true)
	set_game_times("5_1",100,106,true)
	set_game_times("5_1",100,107,true)
	set_game_times("5_1",100,108,true)
	set_game_times("5_1",100,109,true)
	set_game_times("5_1",100,110,true)

	show("5_1",100)
end
require "table_func"
-- 初始化房间
function land_room:init(tb, chair_count, ready_mode, room_lua_cfg)
-- local tt = {}
-- tt[11] = "a1"
-- tt[21] = "a2"
-- local bb = json.encode(tt)
--
-- print(string.format("BBBBBB========================= %s" , tostring(bb)))

--local  timea = [[{
--	"playWithAndroid": {
--		"1": 1,
--		"2": 2,
--		"3": 3
--	}
--}]]
--local _config = json.decode(timea)
--dump(_config)
--local tt = {}
--for k,v in pairs(_config.playWithAndroid) do
--	tt[tonumber(k)] = v
--end
--dump(tt)
--print(string.format("AAAAAA========================= %s" , tostring(tt[1])))
--print(string.format("AAAAAA========================= %s" , tostring(tt[2])))
--print(string.format("AAAAAA========================= %s" , tostring(tt[3])))

--	test()
--	print("===========================")
--	base_room.init(self, tb, chair_count, ready_mode)
--	test()
--	test()
--	test()
--	test()
--	test()
--	test()
--	test()
--	test()
--	test()
--	test()
--	test()
--	inc_play_times("5_1",100,true)
--	getPlayTimes("5_1",100,true)
--	if judgePlayTime("5_1",100,101,1,true) then
--		print("=========================true")
--	else
--		print("=========================false")
--	end
	base_room.init(self, tb, chair_count, ready_mode, room_lua_cfg)
end

-- 创建桌子
function land_room:create_table()
	return land_table:new()
end

---- 坐下处理
function land_room:on_sit_down(player)
--	local tb = self:find_table_by_player(player)
--	if tb then
--		local chat = {
--			chat_content = player.account .. " sit down!",
--			chat_guid = player.guid,
--			chat_name = player.account,
--		}
--		tb:broadcast2client("SC_ChatTable", chat)
--	end
end

-- 快速坐下
function land_room:auto_sit_down(player)
	print "test land auto sit down ....................."

	local result_, table_id_, chair_id_ = base_room.auto_sit_down(self, player)
	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end

	return result_
end
function land_room:get_table_players_status( player )
	base_room:get_table_players_status( player )
	if not player.room_id then
		print("player room_id is nil")
		return nil
	end
	local room = self.room_list_[player.room_id]
	if not room then
		if player.room_id then
			print("room not find room_id:"..player.room_id)
		else
			print("room not find room_id")
		end
		return nil
	end
	local tb = room:find_table(player.table_id)
	if not tb then
		if player.table_id then
			print("tablelist not find table_id:"..player.table_id)
		else
			print("tablelist not find table_id")
		end
		return nil
	end
	print(string.format("table cunt is [%d] room_id is [%d] table_id is [%d] chair_id is [%d]",#tb:get_player_list(),player.room_id,player.table_id,player.chair_id))
	for i,p in ipairs(tb:get_player_list()) do
		if p then
			print(string.format("i [%d] ,chair_id [%d] guid[%d]",i,p.chair_id,p.guid))
			if p.chair_id == player.chair_id then
				-- 自己不处理
			end
			print("ready_list cunt is : "..#(tb.ready_list_))
			if tb.ready_list_[p.chair_id] then
				print("player is  ready charid:"..p.chair_id)
				local notify = {
					ready_chair_id = p.chair_id,
					is_ready = true,
					}
				send2client_pb(player, "SC_Ready", notify)
			end
		else
			print("p is false ")
		end
	end
end
-- 坐下
function land_room:sit_down(player, table_id_, chair_id_)
	print "test land sit down ....................."

	local result_, table_id_, chair_id_ = base_room.sit_down(self, player, table_id_, chair_id_)

	if result_ == GAME_SERVER_RESULT_SUCCESS then
		self:on_sit_down(player)
		return result_, table_id_, chair_id_
	end

	return result_
end

---- 站起
--function land_room:stand_up(player)
--	print "test land stand up ....................."
--
--	local tb = self:find_table_by_player(player)
--	if tb then
--		local chat = {
--			chat_content = player.account .. " stand up!",
--			chat_guid = player.guid,
--			chat_name = player.account,
--		}
--		tb:broadcast2client("SC_ChatTable", chat)
--	end
--	return base_room.stand_up(self, player)
--end
