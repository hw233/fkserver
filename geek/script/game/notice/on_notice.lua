local skynet = require "skynetproto"
local onlineguid = require "netguidopt"
local enum = require "pb_enums"
local club_role = require "game.club.club_role"
local base_notices = require "game.notice.base_notices"
local club_notice = require "game.notice.club_notice"
local log = require "log"
local base_clubs = require "game.club.base_clubs"
local redisopt = require "redisopt"

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
	notice.expiration = os.time() + mail_expaired_seconds
	notice.status = 0
	notice.where = 3

	reddb:hmset("notice:info:" .. id, notice)
	if club_id and club_id ~= 0 then
		reddb:sadd(string.format("club:notice:%d", club_id), id)
	end

	onlineguid.send(guid,"SC_PUBLISH_NOTICE",{
		result = enum.ERROR_NONE
	})
end

local function on_cs_pull_club_notices(club_id, guid)
	local nids = club_notice[club_id]
	local notices = {}
	for nid, _ in pairs(nids) do
		local n = base_notices[nid]
		table.insert(notices, n)
	end

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

	local notices = {}
	for nid, n in pairs(base_notices["*"] or {}) do
		table.insert(notices, n)
	end

	onlineguid.send(guid,"SC_NOTICE_RES",{
		result = enum.ERROR_NONE,
		notices = notices
	})
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
		expiration = os.time() + msg.ttl or mail_expaired_seconds,
		status = 0,
		where = msg.where,
		type = msg.type,
		club_id = msg.club_id,
		content = msg.content,
	}

	local ttl = msg.ttl
	local expireat = msg.expireat
	reddb:hmset("notice:info:" .. id, notice)
	if ttl and ttl > 0 then
		reddb:expire("notice:info:" .. id,ttl)
	elseif expireat and expireat > os.time() then
		reddb:expireat("notice:info:" .. id,expireat)
	end

	if club_id and club_id ~= 0 then
		reddb:sadd(string.format("club:notice:%d", club_id), id)
		if ttl and ttl >0 then
			reddb:expire(string.format("club:notice:%d", club_id),ttl)
		elseif expireat and expireat > os.time() then
			reddb:expireat(string.format("club:notice:%d", club_id),expireat)
		end
	end

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
		expiration = os.time() + msg.ttl or mail_expaired_seconds,
		status = 0,
		where = msg.where,
		type = msg.type,
		club_id = msg.club_id,
		content = msg.content,
	}

	local ttl = msg.ttl
	local expireat = msg.expireat
	reddb:hmset("notice:info:" .. id, notice)
	if ttl and ttl > 0 then
		reddb:expire("notice:info:" .. id,ttl)
	elseif expireat and expireat > os.time() then
		reddb:expireat("notice:info:" .. id,expireat)
	end

	if club_id and club_id ~= 0 then
		reddb:sadd(string.format("club:notice:%d", club_id), id)
		if ttl and ttl >0 then
			reddb:expire(string.format("club:notice:%d", club_id),ttl)
		elseif expireat and expireat > os.time() then
			reddb:expireat(string.format("club:notice:%d", club_id),expireat)
		end
	end

	return id
end