-- 注册诈金花消息

require "game.zhajinhua.on_zhajinhua"

local msgopt = require "msgopt"

msgopt:reg({
	CS_ZhaJinHuaAddScore = on_cs_zhajinhua_add_score,
	CS_ZhaJinHuaGiveUp = on_cs_zhajinhua_give_up,
	CS_ZhaJinHuaLookCard = on_cs_zhajinhua_look_card,
	CS_ZhaJinHuaCompareCards = on_cs_zhajinhua_compare_card,
	CS_ZhaJinHuaShowCards = on_cs_zhajinhua_show_cards,
	CS_ZhaJinHuaLastRecord = on_CS_ZhaJinHuaLastRecord,
	CS_ZhaJinHuaFollowBet = on_cs_zhajinhua_follow_bet,
	CS_ZhaJinHuaAllIn = on_cs_zhajinhua_all_in,
	CS_ZhaJinHuaStartGame = on_cs_zhajinhua_start_game,
})