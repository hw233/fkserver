-- 注册梭哈消息

require "game.multi_showhand.on_multi_showhand"


--------------------------------------------------------------------
-- 注册客户端发过来的消息分派函数
register_client_dispatcher("CS_Multi_ShowHandAddScore",on_cs_multi_showhand_add_score)
register_client_dispatcher("CS_Multi_ShowHandGiveUp",on_cs_multi_showhand_give_up)
register_client_dispatcher("CS_Multi_ShowHandPass",on_cs_multi_showhand_pass)
register_client_dispatcher("CS_Multi_ShowHandGiveUpEixt",on_cs_multi_showhand_give_up_eixt)
register_client_dispatcher("CS_MultiShowhand_Enter",on_cs_multi_showhand_enter)