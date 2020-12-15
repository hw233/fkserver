require "game.notice.on_notice"

register_dispatcher("CS_PUBLISH_NOTICE", on_cs_publish_notice)
register_dispatcher("CS_NOTICE_REQ", on_cs_pull_notices)
register_dispatcher("CS_EDIT_NOTICE",on_cs_edit_notice)
register_dispatcher("CS_DEL_NOTICE",on_cs_del_notice)
register_dispatcher("BS_ReloadNotice",on_bs_reload_notice)
register_dispatcher("BS_PublishNotice",on_bs_publish_notice)
register_dispatcher("BS_EditNotice",on_bs_edit_notice)
register_dispatcher("BS_DelNotice",on_bs_del_notice)