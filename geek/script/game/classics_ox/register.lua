-- 注册牛牛消息

require "game.classics_ox.on_classics"


--------------------------------------------------------------------
-- 注册客户端发过来的消息分派函数
register_dispatcher("CS_ClassicsEnter",on_cs_classics_enter)
register_dispatcher("CS_ClassicsNextGame",on_cs_classics_reEnter)
register_dispatcher("CS_ClassicsLeave",on_cs_classics_leave)
register_dispatcher("CS_ClassicsContend",on_cs_classics_contend)
register_dispatcher("CS_ClassicsPlayerBet",on_cs_classics_bet)
register_dispatcher("CS_ClassicsPlayerGuessCards",on_cs_classics_guess)
register_dispatcher("CS_ClassicsLastRecord",on_cs_quest_last_record)


