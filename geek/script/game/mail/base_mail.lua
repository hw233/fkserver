local skynet = require "skynetproto"
local base_players = require "game.lobby.base_players"
local json = require "json"
local log = require "log"
local base_mails = require "game.mail.base_mails"
local redisopt = require "redisopt"
local player_mail = require "game.mail.player_mail"
local reddot = require "game.reddot.reddot"
local enum = require "pb_enums"

local reddb = redisopt.default

local mail_expaired_seconds = 60 * 60 * 24 * 7

local base_mail = {}

local function new_mail_id()
	return string.format("%d-%d",skynet.time() * 1000,math.random(10000))
end

function base_mail.create_mail(sender,receiver,title,content)
    sender = type(sender) == "table" and sender or base_players[sender]
    receiver = type(receiver) == "table" and receiver or base_players[receiver]
    
	local mail_info = {
		id = new_mail_id(),
		expiration = os.time() + mail_expaired_seconds,
		create_time = os.time(),
		sender = sender.guid,
		receiver = receiver.guid,
		title = title,
		content = content,
		status = 0,
    }

	reddb:sadd("mail:all",mail_info.id)
	reddb:hmset("mail:"..mail_info.id,mail_info)
	reddb:sadd("player:mail:"..tostring(mail_info.receiver),mail_info.id)
	local _ = base_mails[mail_info.id]
	player_mail[receiver.guid] = nil

    return mail_info
end

function base_mail.get_reddot_info(guid)
	local count = 0
	for mailid,_ in pairs(player_mail[guid]) do
		local mail = base_mails[mailid]
		if mail and mail.status == 0 then
			count = count + 1
		end
	end
	return {
		type = enum.REDDOT_TYPE_MAIL,
		count = count,
	}
end

function base_mail.send_mail(mail_info)
    local sender = base_players[mail_info.sender]
    if not sender then
        log.warning("send mail failed,invalid sender.")
        return
    end

    local receiver = base_players[mail_info.receiver]
    if not receiver then
        log.warning("send mail failed,invalid recevier.")
        return
	end
	
	local reddot_info = base_mail.get_reddot_info(receiver.guid)
	reddot.push(receiver.guid,reddot_info)

    send2client_pb(mail_info.receiver,"SC_ReceiveMail",{
		id = mail_info.id,
		expiration = mail_info.expiration,
		create_time = mail_info.create_time,
		sender = {
			guid = sender.guid,
			nickname = 	sender.nickname,
			sex = sender.sex,
			icon = sender.icon,
		},
		title = mail_info.title,
		content = mail_info.content,
		status = 0,
	})
end

return base_mail