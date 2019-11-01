-- 红黑房间

local pb = require "pb_files"

local base_room = require "game.lobby.base_room"
local redblack_table = require "game.redblack.redblack_table"

-- enum GAME_SERVER_RESULT
local GAME_SERVER_RESULT_SUCCESS = pb.enum("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")


local redblack_room = base_room:new()

-- 创建桌子
function redblack_room:create_table()
	return redblack_table:new()
end

-- 坐下处理
function redblack_room:on_sit_down(player)
	local tb = self:find_table_by_player(player)
	if tb then
		local chat = {
			chat_content = player.account .. " sit down!",
			chat_guid = player.guid,
			chat_name = player.account,
		}
		tb:broadcast2client("SC_ChatTable", chat)
	end
end

-- 快速坐下
function redblack_room:auto_sit_down(player)
	if player.disable == 1 then
		print("auto_sit_down player is Freeaz forced_exit")
		return GAME_SERVER_RESULT_FREEZEACCOUNT
	end
	if not player.room_id then
		return GAME_SERVER_RESULT_OUT_ROOM
	end
	
	local room = self:find_room(player.room_id)
	if not room then
		return GAME_SERVER_RESULT_NOT_FIND_ROOM
	end

	for i,tb in ipairs(room:get_table_list()) do
		for j,v in ipairs(tb:get_player_list()) do
			if v and v.guid == player.guid then
				print("auto_sit_down",v.guid,"already in table")
				return self:sit_down(player, i, j)
			end
		end
	end
	
	for i,tb in ipairs(room:get_table_list()) do
		for j,v in ipairs(tb:get_player_list()) do
			if v == false then
				return self:sit_down(player, i, j)
			end
		end
	end

	return GAME_SERVER_RESULT_NOT_FIND_TABLE
end

-- 坐下
function redblack_room:sit_down(player, table_id_, chair_id_)
	if player.disable == 1 then
		print("sit_down player is Freeaz forced_exit")
		return GAME_SERVER_RESULT_FREEZEACCOUNT
	end
	if not player.room_id then
		return GAME_SERVER_RESULT_OUT_ROOM
	end
	
	if player.table_id or player.chair_id then
		log.info("base_room:sit_down error guid [%d] GAME_SERVER_RESULT_PLAYER_ON_CHAIR",player.guid)
		return GAME_SERVER_RESULT_PLAYER_ON_CHAIR
	end
	
	local room = self:find_room(player.room_id)
	if not room then
		return GAME_SERVER_RESULT_NOT_FIND_ROOM
	end
	
	local tb = room:find_table(table_id_)
	if not tb then
		return GAME_SERVER_RESULT_NOT_FIND_TABLE
	end
	
	local chair = tb:get_player(chair_id_)
	if chair and chair.guid ~= player.guid then
		return GAME_SERVER_RESULT_CHAIR_HAVE_PLAYER
	elseif chair == nil then
		return GAME_SERVER_RESULT_NOT_FIND_CHAIR
	end
	
	-- 通知消息
	local notify = {
		table_id = table_id_,
		pb_visual_info = {
			chair_id = chair_id_,
			guid = player.guid,
			account = player.account,
			nickname = player.nickname,
			level = player:get_level(),
			money = player:get_money(),
			header_icon = player:get_header_icon(),			
			ip_area = player.ip_area,
		},
	}

	tb:foreach(function (p)
		p:on_notify_sit_down(notify)
	end)

	tb:player_sit_down(player, chair_id_)
	self:on_sit_down(player)
	return GAME_SERVER_RESULT_SUCCESS, table_id_, chair_id_
end

-- 站起
function redblack_room:stand_up(player)
	print "test redblack stand up ....................."

	local tb = self:find_table_by_player(player)
	if tb then
		local chat = {
		chat_content = player.account .. " stand up!",
			chat_guid = player.guid,
			chat_name = player.account,
		}
		--tb:broadcast2client("SC_ChatTable", chat)
	end
	return base_room.stand_up(self, player)
end


return redblack_room