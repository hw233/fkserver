-- 注册诈金花消息

require "game.maajan.on_maajan"

local msgopt = require "msgopt"

msgopt:reg {
	CS_Maajan_Act_Win = on_cs_act_win,--胡
	CS_Maajan_Act_Double = on_cs_act_double,--加倍
	CS_Maajan_Act_Discard = on_cs_act_discard,--打牌
	CS_Maajan_Act_Peng = on_cs_act_peng,--碰
	CS_Maajan_Act_Gang = on_cs_act_gang,--杠
	CS_Maajan_Act_Pass = on_cs_act_pass,--过
	CS_Maajan_Act_Chi = on_cs_act_chi,--吃
	CS_Maajan_Act_Trustee = on_cs_act_trustee,--托管
	CS_Maajan_Act_BaoTing = on_cs_act_baoting,--报听
}



