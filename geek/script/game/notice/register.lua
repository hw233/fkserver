require "game.notice.on_notice"

register_dispatcher("CS_PUBLISH_NOTICE", on_cs_publish_notice)
register_dispatcher("CS_NOTICE_REQ", on_cs_pull_notices)
register_dispatcher("CS_EDIT_NOTICE",on_cs_edit_notice)
register_dispatcher("CS_DEL_NOTICE",on_cs_del_notice)