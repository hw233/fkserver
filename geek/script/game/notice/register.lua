require "game.notice.on_notice"

local h = {
	CS_PUBLISH_NOTICE =  on_cs_publish_notice,
	CS_NOTICE_REQ =  on_cs_pull_notices,
	CS_EDIT_NOTICE = on_cs_edit_notice,
	CS_DEL_NOTICE = on_cs_del_notice,
	BS_ReloadNotice = on_bs_reload_notice,
	BS_PublishNotice = on_bs_publish_notice,
	BS_EditNotice = on_bs_edit_notice,
	BS_DelNotice = on_bs_del_notice,
}

local msgopt = require "msgopt"
msgopt:reg(h)