-- 注册牛牛消息

require "game.banker_ox.on_banker"


--------------------------------------------------------------------
-- 注册客户端发过来的消息分派函数
register_dispatcher("CS_BankerEnter",on_cs_banker_enter)
register_dispatcher("CS_BankerNextGame",on_cs_banker_reEnter)
register_dispatcher("CS_BankerLeave",on_cs_banker_leave)
register_dispatcher("CS_BankerContend",on_cs_banker_contend)
register_dispatcher("CS_BankerPlayerBet",on_cs_banker_bet)
register_dispatcher("CS_BankerPlayerGuessCards",on_cs_banker_guess)
register_dispatcher("CS_BankerLastRecord",on_cs_quest_last_record)



