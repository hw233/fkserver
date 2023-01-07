local rule = require "game.changpai_zigong.base.rule"
local def = require "game.changpai_zigong.base.define"
local log = require "log"
require "functions"

local mj_util 	= {}
local all_tiles ={
	[1]={value=2,hong=2,hei=0,chongfan = true,index=1},
	[2]={value=3,hong=1,hei=2,chongfan = false,index=2},
	[3]={value=4,hong=1,hei=3,chongfan = true,index=3},
	[4]={value=4,hong=0,hei=4,chongfan = false,index=4},
	[5]={value=5,hong=5,hei=0,chongfan = true,index=5},
	[6]={value=5,hong=0,hei=5,chongfan = false,index=6},
	[7]={value=6,hong=0,hei=6,chongfan = false,index=7},
	[8]={value=6,hong=1,hei=5,chongfan = false,index=8},
	[9]={value=6,hong=4,hei=2,chongfan = false,index=9},
	[10]={value=7,hong=0,hei=7,chongfan = false,index=10},
	[11]={value=7,hong=1,hei=6,chongfan = false,index=11},
	[12]={value=7,hong=4,hei=3,chongfan = true,index=12},
	[13]={value=8,hong=0,hei=8,chongfan = false,index=13},
	[14]={value=8,hong=0,hei=8,chongfan = false,index=14},
	[15]={value=8,hong=8,hei=0,chongfan = true,index=15},
	[16]={value=9,hong=0,hei=9,chongfan = false,index=16},
	[17]={value=9,hong=4,hei=5,chongfan = true,index=17},
	[18]={value=10,hong=0,hei=10,chongfan = false,index=18},
	[19]={value=10,hong=4,hei=6,chongfan = false,index=19},
	[20]={value=11,hong=0,hei=11,chongfan = false,index=20},
	[21]={value=12,hong=6,hei=6,chongfan = true,index=21}
}
local tile_names = {
	"地牌","丁丁","河牌","长二","幺四","拐子","长三","咕咕儿","二红"
	,"二五","高药","叫鸡","板凳","三五","人牌","弯兵","九红","皮花"
	,"四六","牦牛","天牌"
}


local ACTION = def.ACTION
local SECTION_TYPE = def.SECTION_TYPE


function mj_util.printPai(pai)
	local names = {}
	for _,tile in pairs(pai) do
		table.insert(names,tile_names[tile])
	end
	log.info(table.concat(names,","))
end

function mj_util.getPaiStr(pai)
	local names = {}
	for _,tile in pairs(pai) do
		table.insert(names,tile_names[tile])
	end
	return table.concat(names,",")
end

function mj_util.check_tile(tile)
	if not tile then
		return false
	end
	local value = all_tiles[tile].value
	local index = all_tiles[tile].index

	return value >= 2 and value <= 12 and index >= 1 and index <= 21
end
function mj_util.tile_is_chongfan(v)
	return v and all_tiles[v].chongfan or false
end
function mj_util.tile_value(tile)
	return all_tiles[tile].value
end

function mj_util.tile_hong(tile)
	log.info("hong index %d------hong value %d",tile,all_tiles[tile].hong)
	return all_tiles[tile].hong
end

function mj_util.tile_hei(tile)
	return all_tiles[tile].hei
end
local function counts_2_tiles(counts)
	local tiles = {}
	for tile,c in pairs(counts) do
		if c > 0 then
			for _ = 1,c do
				table.insert(tiles,tile)
			end
		end
	end

	return tiles
end
function mj_util.get_actions(pai,mo_pai,in_pai,can_eat,is_zhuang,can_ba)
	local actions = {}
	local counts = pai.shou_pai

	if mo_pai then
		--这里是摸牌之后，摆拍区有和莫进来的牌相同，并且摆拍区属于碰牌或者偷牌类型的话，就可以巴牌
		for _,s in pairs(pai.ming_pai) do
			if s.tile == mo_pai and (s.type == SECTION_TYPE.PENG or s.type == SECTION_TYPE.TOU) then
				actions[ACTION.BA_GANG] = actions[ACTION.BA_GANG] or {}
				actions[ACTION.BA_GANG][s.tile] = {tile = s.tile}
			end
		end
		--这里是摸牌之后，判断手牌中有和摆拍区相同得牌，而且摆拍区属于碰牌类型的或者偷牌类型的 可以巴牌
		for tile,c in pairs(counts) do
			for _,s in pairs(pai.ming_pai) do
				if s.tile == tile and c > 0 and (s.type == SECTION_TYPE.PENG or s.type == SECTION_TYPE.TOU )then
					actions[ACTION.BA_GANG] = actions[ACTION.BA_GANG] or {}
					actions[ACTION.BA_GANG][s.tile] = {tile = s.tile}
				end
			end
		end
		--这里是摸牌之后， 手牌中本身就有四张一样的牌，这个时候可以偷牌，偷拍之后还可以巴牌
		for t,c in pairs(counts) do
			if c == 4 or c == 3 then
				actions[ACTION.TOU] = actions[ACTION.TOU] or {}
				actions[ACTION.TOU][t] = {tile = t}
			end
		end
		if  rule.is_hu(pai,in_pai,is_zhuang)  then
			actions[ACTION.HU] = actions[ACTION.HU] or {}
			actions[ACTION.HU][mo_pai] = { tile= mo_pai,}
		end
	end

	if in_pai then
		--别人打出的牌，或者是翻出来的牌自己手里有两张以上一样的牌的时候，可以碰牌，当然碰完之后还可以偷
		if counts[in_pai] and counts[in_pai] >= 2 then
			actions[ACTION.PENG] = actions[ACTION.PENG] or {}
			actions[ACTION.PENG][in_pai] = {tile = in_pai,}
		end

		--吃牌只能上家翻出的或者出的牌并且有牌可以出
		local tiles =  counts_2_tiles(counts)
		if can_eat and #tiles>1 then
			for t,c in pairs(counts) do
				if c>0 and (mj_util.tile_value(t) + mj_util.tile_value(in_pai) ==14)  then
					actions[ACTION.CHI] = actions[ACTION.CHI] or {}
					actions[ACTION.CHI][t]={ tile=in_pai,othertile = t }
				end
			end
		end
		if rule.is_hu(pai,in_pai,is_zhuang)   then
			actions[ACTION.HU] = actions[ACTION.HU] or {}
			actions[ACTION.HU][in_pai] = { tile= in_pai,}
		end
		if can_ba  then
			for _,s in pairs(pai.ming_pai) do
				if (s.type == SECTION_TYPE.PENG or s.type == SECTION_TYPE.TOU)  and in_pai==s.tile then
					actions[ACTION.BA_GANG] = actions[ACTION.BA_GANG] or {}
					actions[ACTION.BA_GANG][s.tile] = {tile = s.tile}
				end
			end
		end
	end
	
	
	return actions
end


function mj_util.get_actions_first_turn(pai,mo_pai)
	local actions = {}
	local counts = pai.shou_pai

	for t,c in pairs(counts) do
		if c >= 3 then
			actions[ACTION.TOU] = actions[ACTION.TOU] or {}
			actions[ACTION.TOU][t] = {tile = t}
		end
	end
	for tile,c in pairs(counts) do
		for _,s in pairs(pai.ming_pai) do
			if s.tile == tile and c > 0 and (s.type == SECTION_TYPE.PENG or s.type == SECTION_TYPE.TOU) then
				actions[ACTION.BA_GANG] = actions[ACTION.BA_GANG] or {}
				actions[ACTION.BA_GANG][s.tile] =  {tile =s.tile}
			end
		end
	end
	return actions
end
function mj_util.tuos(pai,in_pai,mo_pai,is_zhuang)
	return rule.tuos(pai,in_pai,mo_pai,is_zhuang)
end
function mj_util.is_hu(pai,in_pai,is_zhuang)
	return rule.is_hu(pai,in_pai,is_zhuang)
end

function mj_util.hu(pai,in_pai,mo_pai,is_zhuang)
	return rule.hu(pai,in_pai,mo_pai,is_zhuang)
end

function mj_util.panGangWithOutInPai(pai)
	local anGangList = {}
	local baGangList = {}

	local actions = {}
	local counts = pai.shou_pai
	for k,c in ipairs(counts) do
		if c == 4 then
			table.get(actions,ACTION.TOU,{})[k] = true
		end
	end

	for k,v in ipairs(pai.ming_pai) do
		if v.type == ACTION.PENG and counts[v.tile] == 1 then
			table.get(actions,ACTION.BA_GANG,{})[k] = true
		end
	end

	return anGangList,baGangList
end

function mj_util.is_ting(pai,si_dui)
	return rule.ting(pai,si_dui)
end

function mj_util.is_ting_full(pai)
	return rule.ting_full(pai)
end

function mj_util.get_fan_table_res(base_fan_table)
	return rule.get_fan_table_res(base_fan_table)
end

return mj_util