require "game.mail.on_mail"

local h = {
	CS_SendMail = on_cs_send_mail,
	CS_DelMail = on_cs_del_mail,
	CS_PullMailAttachment = on_cs_receive_mail_attachment,
	CS_PullSummaryMails = on_cs_pull_summary_mails,
	CS_PullMailDetail = on_cs_pull_mail_detail,
	CS_ReadMail = on_cs_read_mail,
}

local msgopt = require "msgopt"
msgopt:reg(h)