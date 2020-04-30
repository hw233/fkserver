-- 注册斗地主消息

require "game.pdk.on_pdk"


--------------------------------------------------------------------
-- 注册客户端发过来的消息分派函数
register_dispatcher("CS_PdkDoAction",on_cs_pdk_do_action)
