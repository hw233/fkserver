local log = require "log"
local json = require "json"

local dbopt = require "dbopt"

function on_sd_add_notice(msg)
	local id = msg.id
	local tp = msg.type
	local where = msg.where
	local content = msg.content
	local club = msg.club_id
	local start_time = msg.start_time
	local end_time = msg.end_time
	local play_count = msg.play_count

	if (not id or id == "") or not tp or not where then
		log.error("on_sd_add_notice invalid id: %s",id)
		return
	end

	content = type(content) == "table" and json.encode(content) or content

	local ret = dbopt.game:query([[
			INSERT INTO t_notice(id,type,`where`,content,club,start_time,end_time,play_count,create_time,update_time)
			VALUES('%s',%s,%s,'%s',%s,%s,%s,%s,%s,%s)
			ON DUPLICATE KEY UPDATE
				type = VALUES(type),
				`where` = VALUES(`where`),
				content = VALUES(content),
				club = VALUES(club),
				start_time = VALUES(start_time),
				end_time = VALUES(end_time),
				update_time = %s
		]],
		id,tp,where,content,
		club or 'NULL',
		start_time or 'NULL',
		end_time or 'NULL',
		play_count or 'NULL',
		os.time(),os.time(),os.time()
	)
	if ret.errno then
		log.error("on_sd_add_notice sql error:%s",ret.err)
	end
end

function on_sd_del_notice(msg)
	local id = msg.id
	
	if not id or id == "" then
		log.error("on_sd_del_notice invalid id: %s",id)
		return
	end

	local ret = dbopt.game:query("DELETE FROM t_notice WHERE id = '%s';",id)
	if ret.errno then
		log.error("on_sd_del_notice sql error:%s",ret.err)
	end
end

function on_sd_edit_notice(msg)
	local id = msg.id
	local tp = msg.type
	local where = msg.where
	local content = msg.content
	local club = msg.club_id
	local start_time = msg.start_time
	local end_time = msg.end_time
	local play_count = msg.play_count

	if (not id or id == "") or not tp or not where then
		log.error("on_sd_edit_notice invalid id: %s",id)
		return
	end

	content = type(content) == "table" and json.encode(content) or content

	local ret = dbopt.game:query([[
			INSERT INTO t_notice(id,type,`where`,content,club,start_time,end_time,play_count,create_time,update_time)
			VALUES('%s',%s,%s,'%s',%s,%s,%s,%s,%s,%s)
			ON DUPLICATE KEY UPDATE 
				type = VALUES(type),
				`where` = VALUES(`where`),
				content = VALUES(content),
				club = VALUES(club),
				start_time = VALUES(start_time),
				end_time = VALUES(end_time),
				update_time = %s;
		]],
		id,tp,where,content,
		club or 'NULL',
		start_time or 'NULL',
		end_time or 'NULL',
		play_count or 'NULL',
		os.time(),os.time(),os.time()
	)
	if ret.errno then
		log.error("on_sd_edit_notice sql error:%s",ret.err)
	end
end