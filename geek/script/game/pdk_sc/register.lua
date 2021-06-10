-- 注册斗地主消息

require "game.pdk_sc.on_pdk"

local msgopt = require "msgopt"
msgopt:reg({
	CS_PdkDoAction = on_cs_pdk_do_action
})