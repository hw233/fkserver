require "game.mail.on_mail"

register_dispatcher("CS_SendMail",on_cs_send_mail)
register_dispatcher("CS_DelMail",on_cs_del_mail)
register_dispatcher("CS_PullMailAttachment",on_cs_receive_mail_attachment)
register_dispatcher("CS_PullSummaryMails",on_cs_pull_summary_mails)
register_dispatcher("CS_PullMailDetail",on_cs_pull_mail_detail)
register_dispatcher("CS_ReadMail",on_cs_read_mail)