-- 聊天，邮件消息处理

local pb = require "pb_files"

require "db.net_func"
local send2center_pb = send2center_pb
local send2game_pb = send2game_pb

local dbopt = require "dbopt"
local db_execute = db_execute
local db_execute_query = db_execute_query

local find_player = find_player

local def_expiration_time = 30*24*60*60 -- 邮件30天过期


-- 发送邮件
function on_sd_send_mail(game_id, msg)
	local mail_ = pb.decode(msg.pb_mail[1], msg.pb_mail[2])
	for i, item in ipairs(mail_.pb_attachment) do
		mail_.pb_attachment[i] = pb.decode(item[1], item[2])
	end
	
	local player = find_player(mail_.send_guid)
	if not player then
		log.warning("on_sd_send_mail guid[%d] not find in db", mail_.send_guid)
		return
	end
	
	mail_.expiration_time = os.time()+def_expiration_time
	
	local data = dbopt.game:query("CALL send_mail(%d, %d, %d, '%s', '%s', '%s', '%s');", mail_.expiration_time, mail_.guid,	mail_.send_guid,
		mail_.send_name, mail_.title, mail_.content, serialize_table(mail_.attachment))
	local gameid = game_id
	
	if not data then
		log.warning("on_sd_send_mail data = null")
		return
	end

	data = data[1]
	
	if data.ret ~= 0 then
		-- 没有找到收邮件的人
		log.warning("send mail data.ret = 0, guid:"..mail_.guid)
		return {
			ret = data.ret,
			pb_mail = mail_,
		}
	end
	
	mail_.mail_id = tostring(data.id)
	
	local target = find_player(mail_.guid)
	if target then
		target.pb_mail_list.mails = target.pb_mail_list.mails or {}
		table.insert(target.pb_mail_list.mails, mail_)
	end

	-- 通知收信人
	channel.publish("","msg","DES_SendMail", {
		ret = 0,
		pb_mail = mail_,
	})
	
	print ("...................... on_sd_send_mail")
		
	-- 给自己
	return {
		ret = 0,
		pb_mail = mail_,
	}
end

-- 删除邮件
function on_sd_del_mail(game_id, msg)
	local player = find_player(msg.guid)
	if not player then
		log.warning("on_sd_del_mail guid[%d] not find in db", msg.guid)
		return
	end
	
	if player.pb_mail_list and player.pb_mail_list.mails then
		for i, mail in ipairs(player.pb_mail_list.mails) do
			if mail.mail_id == msg.mail_id then
				table.remove(player.pb_mail_list.mails, i)
				break
			end
		end
	end
	
	dbopt.game:query("DELETE FROM t_mail WHERE id=%s;", msg.mail_id)
	
	print ("...................... on_sd_del_mail")
end

-- 提取附件
function on_sd_receive_mail_attachment(game_id, msg)
	local player = find_player(msg.guid)
	if not player then
		log.warning("on_sd_receive_mail_attachment guid[%d] not find in db", msg.guid)
		return
	end
	
	if player.pb_mail_list and player.pb_mail_list.mails then
		for i, mail in ipairs(player.pb_mail_list.mails) do
			if mail.mail_id == msg.mail_id then
				mail.attachment = nil
				break
			end
		end
	end
	
	dbopt.game:query("UPDATE t_mail SET attachment=NULL WHERE id=%s;", msg.mail_id)

	print ("...................... on_sd_receive_mail_attachment")
end

