-- 邮件消息处理

local enum = require "pb_enums"
local redisopt = require "redisopt"
local log = require "log"
local json = require "cjson"

require "functions"

local reddb = redisopt.default
local base_players = require "game.lobby.base_players"
local player_mail = require "game.mail.player_mail"
local base_mails = require "game.mail.base_mails"
local base_mail = require "game.mail.base_mail"
local item_details_table = require "data.item_details_table"
local item_market_table = require "data.item_market_table"

require "game.net_func"
local send2client_pb = send2client_pb

-- 发送邮件
function on_cs_send_mail(msg,guid)
	local mail = msg.mail
	local sender = base_players[guid]
	if not sender then
		log.warning("on_cs_send_mail found illigel sender.guid:%s",guid)
		return
	end

	local receiver = base_players[mail.receiver.guid]
	if not receiver then
		log.warning("on_cs_send_mail found illigel receiver.guid:%s",mail.receiver.guid)
		return
	end

	base_mail.send_mail(
		base_mail.create_mail(sender,receiver,mail.title,mail.content)
	)

	print ("...................... on_cs_send_mail")
end

-- 删除邮件
function on_cs_del_mail(msg,guid)
	local mail_ids = msg.mail_ids
	local mails = player_mail[guid]
	for _,mail_id in pairs(mail_ids) do
		if mails[mail_id] then
			reddb:del("mail:"..mail_id)
		end
	end

	print ("...................... on_ce_del_mail")
end

-- 提取附件
function on_cs_receive_mail_attachment(msg,guid)
	local player = base_players[guid]
	if not player then
		log.error("on_cs_receive_mail_attachment no player.guid:%d",guid)
		return
	end

	local mail_id = msg.mail_id
	local mail = base_mails[mail_id]
	if not mail then
		log.error("on_cs_receive_mail_attachment no mail,mail_id:%s",mail_id)
		return
	end

	if os.time() >= mail.expire then
		base_mails[mail_id] = nil
		player_mail[guid][mail_id] = nil
		send2client_pb(guid, "SC_ReceiveMailAttachment", {
			result = enum.MAIL_OPT_RESULT_EXPIRATION,
			mail_id = mail_id,
		})
		return
	end
	
	if not mail.content.attachment or table.nums(mail.content.attachment) == 0 then
		send2client_pb(guid, "SC_ReceiveMailAttachment", {
			result = enum.MAIL_OPT_RESULT_NO_ATTACHMENT,
			mail_id = mail_id,
		})
		return
	end
	
	for _, v in ipairs(mail.content.attachment) do
		player:add_item(v.item_id, v.item_num)
	end
	
	send2client_pb(guid, "SC_ReceiveMailAttachment", {
		result = enum.MAIL_OPT_RESULT_SUCCESS,
		mail_id = mail_id,
		pb_attachment = table.values(mail.content.attachment),
	})
	
	print ("...................... on_cs_receive_mail_attachment")
end


function on_cs_pull_summary_mails(msg,guid)
	local player = base_players[guid]
	if not player then
		log.error("on_cs_pull_summary_mails illegal player.guid:%d",guid)
		return
	end

	local all_mail_ids = player_mail[guid]
	local mail_ids = {}
	if not msg.mail_ids or table.nums(msg.mail_ids) == 0 then
		mail_ids = all_mail_ids
	else
		for _,mail_id in pairs(msg.mail_ids) do
			if all_mail_ids[mail_id] then
				table.insert(mail_ids,mail_id)
			end
		end
	end

	local summary_mails = {}
	for _,mail_id in pairs(mail_ids) do
		local mail = base_mails[mail_id]
		if mail then
			table.insert(summary_mails,{
				id = mail_id,
				title = mail.title,
				create_time = mail.create_time,
				status = mail.status,
			})
		end
	end

	dump(summary_mails)

	send2client_pb(guid,"SC_PullMails",{
		mails = summary_mails,
	})
end

function on_cs_pull_mail_detail(msg,guid)
	local player = base_players[guid]
	if not player then
		log.error("on_cs_pull_mail_detail illegal player.guid:%d",guid)
		return
	end

	dump(msg)
	local mail_id = msg.mail_id
	if not player_mail[guid][mail_id] then
		log.error("on_cs_pull_mail_detail not mail to guid:%d",guid)
		return
	end

	local mail_info = base_mails[mail_id]
	if not mail_info then
		log.error("on_cs_pull_mail_detail not mail for mail_id:%s",mail_id)
		return
	end

	local sender = base_players[mail_info.sender]
	if not sender then
		log.error("on_cs_pull_mail_detail no sender.guid:%d",mail_info.sender)
		return
	end

	send2client_pb(guid,"SC_PullMailDetail",{
		mail = {
			id = mail_id,
			create_time = mail_info.create_time,
			sender = {
				guid = sender.guid,
				icon = sender.open_id_icon,
				nickname = sender.nickname,
				sex = sender.sex,
			},
			content = json.encode(mail_info.content),
			expiration = mail_info.expire,
			title = mail_info.title,
			status = mail_info.status,
		}
	})
end


function on_cs_read_mail(msg,guid)
	local player = base_players[guid]
	if not player then
		log.error("on_cs_read_mail illegal player.guid:%s",guid)
		return
	end

	if not msg.mail_id or not player_mail[guid][msg.mail_id] then
		log.error("on_cs_read_mail guid:%s not exists mail_id:%s",guid,msg.mail_id)
		return
	end

	reddb:hset("mail:"..msg.mail_id,"status",1)
end
