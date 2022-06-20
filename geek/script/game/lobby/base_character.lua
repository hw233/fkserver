-- 玩家和机器人基类
local log = require "log"
local enum = require "pb_enums"
local skynet = require "skynet"

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
function base_character:check_money_limit(score)
	return false
end

-- 进入房间并坐下
function base_character:on_enter_room_and_sit_down(room_id, table_id, chair_id, result, tb)
end

-- 站起并离开房间
function base_character:on_stand_up_and_exit_room(room_id, table_id, chair_id, result,reason)
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
function base_character:notify_sit_down(notify)
end
-- 站起
function base_character:on_stand_up()
end

-- 通知站起
function base_character:notify_stand_up(who,offline,reason)
end

--通知离线
function base_character:notify_online(is_online)

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
function base_character:_cost_money(price, opttype)
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
function base_character:check_forced_exit(score,money_id)
	if self:check_money_limit(score,money_id) then
		self:async_force_exit()
	end
end

-- 强制踢出房间
function base_character:async_force_exit(reason)
	-- 防止玩家与桌子互锁
	skynet.fork(function()
		reason = reason or enum.STANDUP_REASON_FORCE
		local chair_id = self.chair_id
		local table_id = self.table_id
		log.info("force exit,guid:%s,table_id:%s,chair_id:%s,reason:%s",self.guid,table_id,chair_id,reason)

		if not chair_id or not table_id then
			log.warning("force exit,guid:%s,table_id:%s,chair_id:%s,reason:%s,got nil table or chair",
				self.guid,table_id,chair_id,reason)
			return
		end

		local result = self:kickout_room(reason)
		if result ~= enum.ERROR_NONE then
			log.warning("force exit,guid:%s,table_id:%s,chair_id:%s,reason:%s,result %s,failed",
				self.guid,table_id,chair_id,reason,result)
			return result
		end
		
		self:on_stand_up_and_exit_room(def_game_id, table_id, chair_id, enum.ERROR_NONE,reason)
		log.warning("force exit,guid:%s,table_id:%s,chair_id:%s,reason:%s,success",self.guid,table_id,chair_id,reason)
		return enum.ERROR_NONE
	end)
end

function base_character:force_exit(reason)
	reason = reason or enum.STANDUP_REASON_FORCE
	local chair_id = self.chair_id
	local table_id = self.table_id
	log.info("force exit,guid:%s,table_id:%s,chair_id:%s,reason:%s",self.guid,table_id,chair_id,reason)

	local result = self:kickout_room(reason)
	if result ~= enum.ERROR_NONE then
		log.warning("force exit,guid:%s,table_id:%s,chair_id:%s,reason:%s,result %s,failed",
			self.guid,table_id,chair_id,reason,result)
		return result
	end
	
	self:on_stand_up_and_exit_room(def_game_id, table_id, chair_id, enum.ERROR_NONE,reason)
	log.warning("force exit,guid:%s,table_id:%s,chair_id:%s,reason:%s,success",self.guid,table_id,chair_id,reason)
	return enum.ERROR_NONE
end

function base_character:kickout(reason)
	return g_room:kickout_server(self,reason)
end

function base_character:kickout_room(reason)
	return g_room:kickout_room(self,reason)
end

function base_character:exit_room(reason)
	return g_room:exit_room(self,reason)
end

return base_character