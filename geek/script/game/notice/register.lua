require "game.notice.on_notice"


register_dispatcher("CS_PUBLISH_NOTICE",on_cs_publish_notice)
register_dispatcher("CS_NOTICE_REQ",on_cs_pull_notices)