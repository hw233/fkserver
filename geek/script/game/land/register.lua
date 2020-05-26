-- 注册斗地主消息

require "game.land.on_land"


--------------------------------------------------------------------
-- 注册客户端发过来的消息分派函数
register_dispatcher("CS_DdzDoAction",on_cs_land_do_action)
register_dispatcher("CS_DdzCallLandlord",on_cs_land_compete_landlord)