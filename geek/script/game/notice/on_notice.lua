local skynet = require "skynetproto"
local onlineguid = require "netguidopt"
local enum = require "pb_enums"
local club_role = require "game.club.club_role"
local base_notices = require "game.notice.base_notices"
local club_notice = require "game.notice.club_notice"
local log = require "log"
local base_clubs = require "game.club.base_clubs"
local redisopt = require "redisopt"
local channel = require "channel"
local broadcast = require "broadcast"
local json = require "json"

local reddb = redisopt.default

local mail_expaired_seconds = 60 * 60 * 24 * 7

local function new_notice_id()
	return string.format("%d-%d", skynet.time() * 1000, math.random(10000))
end

function on_cs_publish_notice(msg, guid)
	local notice = msg.notice
	if not notice then
		onlineguid.send(guid,"SC_PUBLISH_NOTICE",{
			result = enum.ERROR_PARAMETER_ERROR
		})
		return
	end
	local club_id = notice.club_id
	if not club_id or club_id == 0 then
		onlineguid.send(guid,"SC_PUBLISH_NOTICE",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	local role = club_role[club_id][guid]
	if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS then
		onlineguid.send(guid,"SC_PUBLISH_NOTICE",{
			result = enum.ERROR_PLAYER_NO_RIGHT
		})
		return
	end

	local id = new_notice_id()

	notice.id = id
	notice.create_time = os.time()
	notice.where = 3

	reddb:hmset("notice:info:" .. id, notice)
	reddb:sadd("notice:all",id)
	if club_id and club_id ~= 0 then
		reddb:sadd(string.format("club:notice:%d", club_id), id)
	end

	channel.publish("db.?","msg","SD_AddNotice",notice)

	onlineguid.send(guid,"SC_PUBLISH_NOTICE",{
		result = enum.ERROR_NONE
	})
end

local function on_cs_pull_club_notices(club_id, guid)
	local nids = club_notice[club_id]
	local notices = table.series(nids or {},function(_,nid)
		return base_notices[nid]
	end)

	onlineguid.send(guid,"SC_NOTICE_RES",{
		result = enum.ERROR_NONE,
		notices = notices
	})
end

local function on_cs_pull_global_notices(guid)
	local notices = table.series(base_notices["*"] or {},function(n)
		if n.club_id then return end
		return n
	end)

	onlineguid.send(guid,"SC_NOTICE_RES",{
		result = enum.ERROR_NONE,
		notices = notices
	})
end

function on_cs_pull_notices(msg, guid)
	local club_id = msg.club_id
	if club_id and club_id ~= 0 then
		on_cs_pull_club_notices(club_id, guid)
		return
	end

	on_cs_pull_global_notices(guid)
end


function on_cs_edit_notice(msg,guid)
	local notice = msg.notice
	if not notice then
		onlineguid.send(guid,"SC_EDIT_NOTICE",{
			result = enum.ERROR_PARAMETER_ERROR
		})
		return
	end

	local club_id = notice.club_id
	if not club_id or club_id == 0 then
		onlineguid.send(guid,"SC_EDIT_NOTICE",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	local role = club_role[club_id][guid]
	if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS then
		onlineguid.send(guid,"SC_EDIT_NOTICE",{
			result = enum.ERROR_PLAYER_NO_RIGHT
		})
		return
	end

	local id = notice.id
	if not id or id == "" then
		onlineguid.send(guid,"SC_EDIT_NOTICE",{
			result = enum.ERROR_PARAMETER_ERROR
		})
		return
	end

	reddb:hmset(string.format("notice:info:%s",id),notice)

	channel.publish("db.?","msg","SD_EditNotice",notice)

	base_notices[id] = nil
	onlineguid.send(guid,"SC_EDIT_NOTICE",{
		result = enum.ERROR_NONE
	})
end

function on_cs_del_notice(msg,guid)
	local id = msg.id
	local notice = base_notices[id]
	if not notice then
		onlineguid.send(guid,"SC_DEL_NOTICE",{
			result = enum.ERROR_PARAMETER_ERROR
		})
		return
	end

	local club_id = notice.club_id
	if not club_id or club_id == 0 then
		onlineguid.send(guid,"SC_DEL_NOTICE",{
			result = enum.ERROR_OPERATION_INVALID
		})
		return
	end

	local role = club_role[club_id][guid]
	if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS then
		onlineguid.send(guid,"SC_DEL_NOTICE",{
			result = enum.ERROR_PLAYER_NO_RIGHT
		})
		return
	end

	reddb:del(string.format("notice:info:%s",id))
	reddb:srem(string.format("club:notice:%d", club_id), id)
	reddb:srem("notice:all",id)
	channel.publish("db.?","msg","SD_DelNotice",{id = id})

	base_notices[id] = nil
	onlineguid.send(guid,"SC_DEL_NOTICE",{
		result = enum.ERROR_NONE
	})
end


function on_bs_reload_notice(msg)
	for id,_ in pairs(base_notices) do
		base_notices[id] = nil
	end
end

function on_bs_publish_notice(msg)
	local content = msg.content
	if not content or content == "" then
		return
	end

	local club_id = msg.club_id
	if club_id and club_id ~= 0 and not base_clubs[club_id] then
		return
	end

	local id = new_notice_id()

	local notice = {
		id = id,
		create_time = os.time(),
		start_time = msg.start_time or os.time(),
		end_time = msg.end_time or -1,
		where = msg.where,
		type = msg.type,
		club_id = msg.club_id,
		content = json.encode({
			content = content,
			title = msg.title,
		}),
		play_count = msg.play_count or 1,
		interval = msg.interval,
	}

	local expireat = msg.end_time
	reddb:hmset("notice:info:" .. id, notice)	
	reddb:sadd("notice:all",id)

	if club_id and club_id ~= 0 then
		reddb:sadd(string.format("club:notice:%d", club_id), id)
		if expireat and expireat > os.time() then
			reddb:expireat(string.format("club:notice:%d", club_id),expireat)
		end
	end

	channel.publish("db.?","msg","SD_AddNotice",notice)

	broadcast.broadcast2online("SC_NotifyNotice",{
		op = enum.SYNC_ADD,
		notice = notice,
	})

	return id
end

function on_bs_edit_notice(msg)
	local content = msg.content
	if not content or content == "" then
		return
	end

	local id = msg.id
	if not id or id == "" then
		return
	end

	local club_id = msg.club_id
	if club_id and club_id ~= 0 and not base_clubs[club_id] then
		return
	end

	local notice = {
		id = id,
		create_time = os.time(),
		status = 0,
		where = msg.where,
		type = msg.type,
		club_id = msg.club_id,
		content = json.encode({
			content = content,
			title = msg.title,
		}),
		start_time = msg.start_time,
		end_time = msg.end_time,
		play_count = msg.play_count,
	}

	local expireat = msg.end_time
	reddb:hmset("notice:info:" .. id, notice)
	if club_id and club_id ~= 0 then
		reddb:sadd(string.format("club:notice:%d", club_id), id)
		if expireat and expireat > os.time() then
			reddb:expireat(string.format("club:notice:%d", club_id),expireat)
		end
	end

	channel.publish("db.?","msg","SD_EditNotice",notice)

	broadcast.broadcast2online("SC_NotifyNotice",{
		op = enum.SYNC_UPDATE,
		notice = notice,
	})

	return id
end


function on_bs_del_notice(msg)
	local id = msg.id
	local notice = base_notices[id]
	local club_id = notice and notice.club_id or nil

	reddb:del(string.format("notice:info:%s",id))
	if club_id then
		reddb:srem(string.format("club:notice:%d", club_id), id)
	end
	reddb:srem("notice:all",id)
	
	channel.publish("db.?","msg","SD_RemoveNotice",{id = id})

	broadcast.broadcast2online("SC_NotifyNotice",{
		op = enum.SYNC_DEL,
		notice = {
			id = id,
		},
	})

	base_notices[id] = nil
	return enum.ERROR_NONE
end