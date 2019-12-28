local redisopt = require "redisopt"

local base_player = require "game.lobby.base_player"
local redismetadata = require "redismetadata"

local reddb = redisopt.default

local player_manager = {}

setmetatable(player_manager,{
	__index = function(t,guid)
        if type(guid) ~= "number" then
            return
        end
		
		local p = reddb:hgetall("player:info:"..tostring(guid))
		if not p then
			return nil
		end
		
		p = redismetadata.player.info:decode(p)

		p = table.nums(p) > 0 and p or nil
		if p then
			setmetatable(p,{__index = base_player})
		end

		t[guid] = p
		return p
	end,
})

function player_manager.foreach(func)
	for _, player in pairs(player_manager) do
		func(player)
	end
end

-- 广播所有人消息
function player_manager.broadcast2client_pb(msg_name, pb)
	for guid, player in pairs(player_manager) do
		if player.online then
			send2client_pb(player, msg_name, pb)
		end
	end
end

function player_manager.update_notice_everyone(msg)
	for guid, player in pairs(player_manager) do
		if player.online then
			player:update_notice(msg)
		end
	end
end

-- 删除公告
function player_manager.delete_notice_everyone(msg)
	for guid,player in pairs(player_manager) do
		if player.online then
			player:delete_notice(msg)
		end
	end
end

function player_manager.save_all()
	for guid, player in pairs(player_manager) do
		if type(guid) == "number" then
			if player.online then
				player:save()
			end
		end
	end
end

-- 公告或消息
function player_manager.update_notice(msg)
	--公告或跑马灯要区分平台
	if msg.msg_type == 2 or msg.msg_type == 3 then
		local right_plat = false
		for _,plat_id in ipairs(msg.platforms) do
			if platform_id == plat_id then
				right_plat = true
				break
			end
		end
		if right_plat == false then
			return
		end
	end
	

	if msg.msg_type == 3 then
		local notify = {
			id = msg.id,
			content = msg.content,
			start_time = msg.start_time,
			end_time = msg.end_time,
			number = msg.number,
			interval_time = msg.interval_time,
		}

		local msg_data = {
			pb_msg_data = {},
		}

		table.insert(msg_data.pb_msg_data,notify)
		send2client_pb(self,"SC_NewMarquee",msg_data)
		return
	end

	-- 更新服务器数据
	local notify = {
		id = msg.id,
		is_read = msg.is_read,
		msg_type = msg.msg_type,
		content = msg.content,
		start_time = msg.start_time,
		end_time = msg.end_time,
	}
	--下发新数据
	local msg_data = {
		pb_msg_data = {},
	}

	table.insert(msg_data.pb_msg_data,notify)
	send2client_pb(self,"SC_NewMsgData",msg_data)
end

-- 游戏中奖公告，需要客户端组装消息内容
function player_manager.update_game_notice_everyone(msg)
	for guid,player in pairs(player_manager) do
		if player.online then
			local send_to_player = false
			--只发给对应平台的玩家
			for i,platform_id in ipairs(msg.platform_ids) do
				if player.platform_id == platform_id then
					send_to_player = true
					break
				end
			end

			if send_to_player then
				local gameNotice = {
					pb_game_notice = msg.pb_game_notice
				}
				send2client_pb(player,"SC_GameNotice",gameNotice)
			end
		end
	end
end

return player_manager