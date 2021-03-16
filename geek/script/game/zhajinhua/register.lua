-- 注册诈金花消息

require "game.zhajinhua.on_zhajinhua"


-- 注册客户端发过来的消息分派函数
register_dispatcher("CS_ZhaJinHuaAddScore",on_cs_zhajinhua_add_score)
register_dispatcher("CS_ZhaJinHuaGiveUp",on_cs_zhajinhua_give_up)
register_dispatcher("CS_ZhaJinHuaLookCard",on_cs_zhajinhua_look_card)
register_dispatcher("CS_ZhaJinHuaCompareCards",on_cs_zhajinhua_compare_card)
register_dispatcher("CS_ZhaJinHuaShowCards",on_cs_zhajinhua_show_cards)
register_dispatcher("CS_ZhaJinHuaLastRecord",on_CS_ZhaJinHuaLastRecord)
register_dispatcher("CS_ZhaJinHuaFollowBet",on_cs_zhajinhua_follow_bet)
register_dispatcher("CS_ZhaJinHuaAllIn",on_cs_zhajinhua_all_in)
register_dispatcher("CS_ZhaJinHuaStartGame",on_cs_zhajinhua_start_game)