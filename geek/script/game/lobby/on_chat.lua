-- 聊天消息处理

local base_players = require "game.lobby.base_players"
local onlineguid = require "netguidopt"
local enum = require "pb_enums"
local log = require "log"
require "game.net_func"

local base_player = require "game.lobby.base_player"

local base_room = require "game.lobby.base_room"
local room = g_room

-- 世界聊天
function on_cs_chat_world(msg,guid)
	local player = base_players[guid]
	local chat = {
		chat_content = msg.chat_content,
		chat_guid = player.guid,
		chat_name = player.account,
	}
	room:broadcast2client_by_player("SC_ChatWorld", chat)
	
	print "...................................on_cs_chat_world"
end

-- 私聊
function on_cs_chat_private(msg,guid)
	local player = base_players[guid]
	local chat = {
		chat_content =  msg.chat_content,
		private_guid = msg.private_name,
		chat_name = player.account,
	}

	send2client_pb(player, "SC_ChatPrivate", chat)

	local target = base_player:find_by_account(msg.private_name)
	if target then
		send2client_pb(target,  "SC_ChatPrivate", chat)
	else
		channel.publish("login.?","msg","SC_ChatPrivate", chat)
	end
end

function on_sc_chat_private(msg,guid)
	local player = base_players[guid]
	local target = base_player:find_by_account(msg.private_name)
	if target then
		send2client_pb(target,  "SC_ChatPrivate", msg)
	end
end

-- 同服聊天
function on_cs_chat_server(msg,guid)
	local player = base_players[guid]
	local chat = {
		chat_content = msg.chat_content,
		chat_guid = player.guid,
		chat_name = player.account,
	}
	room:broadcast2client_by_player("SC_ChatServer", chat)
	
	print "...................................on_cs_chat_server"
end

-- 房间聊天
function on_cs_chat_room(msg,guid)
	local player = base_players[guid]
	local chat = {
		chat_content = msg.chat_content,
		chat_guid = player.guid,
		chat_name = player.account,
	}
	room:broadcast2client_by_player("SC_ChatRoom", chat)
	print "...................................on_cs_chat_room"
end

-- 同桌聊天
function on_cs_chat_table(msg,guid)
	local player = base_players[guid]
	local tb = room:find_table_by_player(player)
	if tb then
		local chat = {
			chat_content = msg.chat_content,
			chat_guid = player.guid,
			chat_name = player.account,
		}
		tb:broadcast2client("SC_ChatTable", chat)
	end

	print "...................................on_cs_chat_table"
end


function on_cs_player_interaction(msg,guid)
	log.dump(guid)
	local player = base_players[guid]
	if not player then
		onlineguid.send(guid,"S2CPlayerInteraction",{
			result = enum.ERROR_PLAYER_NOT_EXIST
		})
		return
	end

	local tb = g_room:find_table_by_player(player)
	if not tb then
		onlineguid.send(guid,"S2CPlayerInteraction",{
			result = enum.ERROR_TABLE_NOT_EXISTS
		})
		return
	end

	local receiver_chair = msg.receiver
	if receiver_chair  ~= 0 then
		local receiver = tb:get_player(receiver_chair)
		if not receiver then
			onlineguid.send(guid,"S2CPlayerInteraction",{
				result = enum.ERROR_PLAYER_NOT_EXIST
			})
			return
		end
	end

	tb:broadcast2client("S2CPlayerInteraction",{
		result = enum.ERROR_NONE,
		content_idx = msg.content_idx,
		type = msg.type,
		sender = player.chair_id,
		receiver = receiver_chair,
	})
end


function on_cs_voice_interactive(msg,guid)
	local content = msg.content
	local time = msg.time 
	local receiver = msg.receiver

	local player = base_players[guid]
	if not player then
		send2client_pb(guid,"S2C_VoiceInteractive",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	local tb = g_room:find_table_by_player(player)
	if not tb then
		send2client_pb(guid,"S2C_VoiceInteractive",{
			result = enum.ERROR_TABLE_NOT_EXISTS
		})
		return
	end

	tb:broadcast2client("S2C_VoiceInteractive",{
		result = enum.ERROR_NONE,
		content = content,
		time = time,
		sender = guid,
		receiver = receiver,
	})
end