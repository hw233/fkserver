-- 机器人基类
local base_character = require "game.lobby.base_character"

--local base_room = require "game.lobby.base_room"
local room = g_room

local android_manager = require "game.lobby.android_manager"


if not base_active_android then
	base_active_android = base_character:new()
	base_active_android.wait_active_android_ = {}	-- 等待中
	base_active_android.play_active_android_ = {}	-- 已经在玩
end

-- 初始化
function base_active_android:init(roomid_, guid_, account_, nickname_)
	base_character.init(self, guid_, account_, nickname_)
	self.is_android = true

	self.wait_active_android_[roomid_] = self.wait_active_android_[roomid_] or {}
	self.wait_active_android_[roomid_][guid_] = self

	room:enter_room(self, roomid_)
end

-- 减少机器人，<=0 全部删除
function base_active_android:sub_android(roomid_, count)
	local t = {}

	if count <= 0 then
		if self.wait_active_android_[roomid_] then
			for i, v in pairs(self.wait_active_android_[roomid_]) do
				table.insert(t, i)
			end
			self.wait_active_android_[roomid_] = {}
		end

		if self.play_active_android_[roomid_] then
			for i, v in pairs(self.play_active_android_[roomid_]) do
				room:stand_up(v)
				table.insert(t, i)
			end
			self.play_active_android_[roomid_] = {}
		end
	else
		if self.wait_active_android_[roomid_] then
			for i, v in pairs(self.wait_active_android_[roomid_]) do
				if count <= 0 then
					break
				end

				count = count - 1
				table.insert(t, i)
				self.wait_active_android_[roomid_][i] = nil
			end
		end

		if self.play_active_android_[roomid_] then
			for i, v in pairs(self.play_active_android_[roomid_]) do
				if count <= 0 then
					break
				end

				count = count - 1
				table.insert(t, i)
				room:stand_up(v)
				self.play_active_android_[roomid_][i] = nil
			end
		end
	end

	android_manager:destroy_android(t)
end

-- 查找一个主动机器人
function base_active_android:find_active_android(room_id_)
	if self.wait_active_android_[room_id_] then
		for i, v in pairs(self.wait_active_android_[room_id_]) do
			self.play_active_android_[room_id_] = self.play_active_android_[room_id_] or {}
			self.play_active_android_[room_id_][i] = v
			self.wait_active_android_[room_id_][i] = nil
			return v
		end
	end

	return nil
end

-- 玩家坐下时
function base_active_android:think_on_sit_down(room_id_, table_id_, chair_id_)
	if self.room_id ~= room_id_ then
		if self.room_id ~= 0 then
			room:exit_room(self)
		end

		room:enter_room(self, room_id_)
	end

	room:sit_down(self, table_id_, chair_id_)
end

-- 检查房间限制
function base_active_android:check_room_limit(score)
	return false
end

-- 通知站起
function base_active_android:on_notify_stand_up(notify)
	room:stand_up(self)
end

-- 得到钱
function base_active_android:get_money()
	return 1000
end



if not base_passive_android then
	base_passive_android = base_active_android:new()
	base_passive_android.init_passive_android_ = {}

	base_passive_android.rnd_state_wait = 70				-- 等待的概率
	base_passive_android.rnd_state_exit = 25				-- 换座位的概率

	base_passive_android.time_state_wait = {180,300}		-- 等待的时间
end

-- 初始化
function base_passive_android:init(roomid_, guid_, account_, nickname_)
	base_character.init(self, guid_, account_, nickname_)
	self.is_android = true

	self.init_passive_android_[roomid_] = self.init_passive_android_[roomid_] or {}
	self.init_passive_android_[roomid_][guid_] = self

	room:enter_room(self, roomid_)
end

-- 减少机器人，<=0 全部删除
function base_passive_android:sub_android(roomid_, count)
	local t = {}
	if count <= 0 then
		if self.init_passive_android_[roomid_] then
			for i, v in pairs(self.init_passive_android_[roomid_]) do
				room:stand_up(v)
				table.insert(t, i)
			end
			self.init_passive_android_[roomid_] = {}
		end
	else
		if self.init_passive_android_[roomid_] then
			for i, v in pairs(self.init_passive_android_[roomid_]) do
				if count <= 0 then
					break
				end

				count = count - 1
				table.insert(t, i)
				room:stand_up(v)
				self.init_passive_android_[roomid_][i] = nil
			end
		end
	end

	android_manager:destroy_android(t)
end

-- 通知站起
function base_passive_android:on_notify_stand_up(notify)
end

-- 每一帧调用
function base_passive_android:on_tick()
	local cur = get_second_time()

	for roomid, a in pairs(self.init_passive_android_) do
		for i, v in pairs(a) do
			if v.table_id and v.chair_id then
				-- 坐下等待状态
				if cur >= v.cur_time_ then
					local rnd = math.random(100)
					if rnd <= self.rnd_state_wait then
						v.cur_time_ = cur + math.random(self.time_state_wait[1], self.time_state_wait[2])
					elseif rnd <= self.rnd_state_wait + self.rnd_state_exit then
						room:stand_up(v)
					else
						room:stand_up(v)
					end
				end
			else
				-- 找座位
				local tableid, chairid = room:find_android_pos(roomid)
				if tableid then
					room:sit_down(self, tableid, chairid)
					v.cur_time_ = cur + math.random(self.time_state_wait[1], self.time_state_wait[2])
				end
			end
		end
	end
end
