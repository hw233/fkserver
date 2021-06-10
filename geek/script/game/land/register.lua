-- 注册斗地主消息

require "game.land.on_land"

local msgopt = require "msgopt"

msgopt:reg({
	CS_DdzDoAction = on_cs_land_do_action,
	CS_DdzCallLandlord = on_cs_land_compete_landlord,
})