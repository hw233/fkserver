-- 注册斗地主消息

require "game.bigtwo.on_bigtwo"


--------------------------------------------------------------------
-- 注册客户端发过来的消息分派函数
register_dispatcher("CS_BTOutCard",on_cs_bigtwo_out_card)
register_dispatcher("CS_BTPassCard",on_cs_bigtwo_pass_card)
register_dispatcher("CS_BTTrusteeship",on_cs_bigtwo_Trusteeship)