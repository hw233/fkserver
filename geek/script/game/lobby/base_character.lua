-- 玩家和机器人基类
local pb = require "pb_files"
local redisopt = require "redisopt"
local reddb = redisopt.default

--local base_room = require "game.lobby.base_room"
local room = g_room

-- enum GAME_SERVER_RESULT
local GAME_SERVER_RESULT_SUCCESS = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")
local GAME_SERVER_RESULT_IN_GAME = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_IN_GAME")
local GAME_SERVER_RESULT_IN_ROOM = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_IN_ROOM")
local GAME_SERVER_RESULT_OUT_ROOM = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OUT_ROOM")
local GAME_SERVER_RESULT_NOT_FIND_ROOM = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_ROOM")
local GAME_SERVER_RESULT_NOT_FIND_TABLE = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_TABLE")
local GAME_SERVER_RESULT_NOT_FIND_CHAIR = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NOT_FIND_CHAIR")
local GAME_SERVER_RESULT_CHAIR_HAVE_PLAYER = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_CHAIR_HAVE_PLAYER")
local GAME_SERVER_RESULT_PLAYER_NO_CHAIR = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_PLAYER_NO_CHAIR")
local GAME_SERVER_RESULT_OHTER_ON_CHAIR = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_OHTER_ON_CHAIR")
local GAME_SERVER_RESULT_ROOM_LIMIT = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_ROOM_LIMIT")


local base_character = {}
-- 创建
function base_character:new()  
    local o = {}  
    setmetatable(o, {__index = self})
	
    return o 
end

-- 初始化
function base_character:init(guid_, account_, nickname_)  
    self.guid = guid_
    self.account = account_
    self.nickname = nickname_
	self.game_end_event = {}
end

-- 删除
function base_character:del()
end

-- 检查房间限制
function base_character:check_room_limit(score)
	return false
end

-- 进入房间并坐下
function base_character:on_enter_room_and_sit_down(room_id_, table_id_, chair_id_, result_, tb)
end

-- 站起并离开房间
function base_character:on_stand_up_and_exit_room(room_id_, table_id_, chair_id_, result_)
end

-- 切换座位
function base_character:on_change_chair(table_id_, chair_id_, result_, tb)
end

-- 进入房间
function base_character:on_enter_room(room_id_, result_)
end

-- 通知进入房间
function base_character:on_notify_enter_room(notify)
end

-- 离开房间
function base_character:on_exit_room(room_id_, result_)
end

-- 通知离开房间
function base_character:on_notify_exit_room(notify)
end

-- 坐下
function base_character:on_sit_down(table_id_, chair_id_, result_)
end

-- 通知坐下
function base_character:on_notify_sit_down(notify)
end
-- 站起
function base_character:on_stand_up()
end

-- 通知站起
function base_character:on_notify_stand_up(notify)
end

-- 通知空位置坐机器人
function base_character:on_notify_android_sit_down(room_id_, table_id_, chair_id_)
end

-- 得到等级
function base_character:get_level()
	return 1
end

-- 得到钱
function base_character:get_money()
	return 0
end

-- 得到头像
function base_character:get_header_icon()
	return 0
end

-- 花钱
function base_character:cost_money(price, opttype)
end

-- 加钱
function base_character:add_money(price, opttype)
end

--主动处理消息
function base_character:dispatch_msg(msgname, msg)
end

--通知客户端金钱变化
function base_character:notify_money(opttype,money_,changeMoney)
end

function base_character:add_game_end_event(fun)
	table.insert(self.game_end_event,fun)
end

function base_character:do_game_end_event()
	for _,f in pairs(self.game_end_event) do
		if f then
			f()
		end
	end
	self.game_end_event = {}
end


-- 检查强制踢出房间
function base_character:check_forced_exit(score)
	if self:check_room_limit(score) then
		self:forced_exit()
	end
end

-- 强制踢出房间
function base_character:forced_exit()
	local ret = 0
	if room == nil then
		print("room is nil")
		if g_room == nil then
			print("g_room is nil")
		else
			local ret = g_room:stand_up(self)
			print("ret is :"..ret)
			if ret == GAME_SERVER_RESULT_SUCCESS then
			   g_room:exit_room(self)
			end
		end
	else
		local ret = room:stand_up(self)
		print("ret is :"..ret)
		if ret == GAME_SERVER_RESULT_SUCCESS then
		   room:exit_room(self)
		end
	end
end

return base_character