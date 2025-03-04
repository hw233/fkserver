local rule = require "game.maajan_menhu.base.rule"
local def = require "game.maajan_menhu.base.define"
local log = require "log"
require "functions"

local mj_util 	= {}

local tile_names = {
	[0] = {"1万","2万","3万","4万","5万","6万","7万","8万","9万"},
	[1] = {"1筒","2筒","3筒","4筒","5筒","6筒","7筒","8筒","9筒"},
	[2] = {"1条","2条","3条","4条","5条","6条","7条","8条","9条"},
	[3] = {"东","南","西","北","中","发","白"},
	[4] = {"梅","兰","竹","菊","春","夏","秋","冬"},
}


local ACTION = def.ACTION
local SECTION_TYPE = def.SECTION_TYPE


function mj_util.printPai(pai)
	local names = {}
	for _,tile in pairs(pai) do
		table.insert(names,tile_names[math.floor(tile / 10)][tile % 10])
	end
	log.info(table.concat(names,","))
end

function mj_util.getPaiStr(pai)
	local names = {}
	for _,tile in pairs(pai) do
		table.insert(names,tile_names[math.floor(tile / 10)][tile % 10])
	end
	return table.concat(names,",")
end

function mj_util.check_tile(tile)
	if not tile then
		return false
	end

	local men = math.floor(tile / 10)
	local value = tile % 10

	return men >= 0 and men <= 4 and value > 0 and value < 10
end

function mj_util.tile_value(tile)
	return tile % 10
end

function mj_util.tile_men(tile)
	return math.floor(tile / 10)
end

function mj_util.get_actions(pai, mo_pai,in_pai)
	local actions = {}
	local counts = pai.shou_pai

	if mo_pai then
		for _,s in pairs(pai.ming_pai) do
			if s.tile == mo_pai and s.type == SECTION_TYPE.PENG then
				actions[ACTION.BA_GANG] = actions[ACTION.BA_GANG] or {}
				actions[ACTION.BA_GANG][s.tile] = true
			end
		end

		for tile,c in pairs(counts) do
			for _,s in pairs(pai.ming_pai) do
				if s.tile == tile and c > 0 and s.type == SECTION_TYPE.PENG then
					actions[ACTION.FREE_BA_GANG] = actions[ACTION.FREE_BA_GANG] or {}
					actions[ACTION.FREE_BA_GANG][s.tile] = true
				end
			end
		end

		if counts[mo_pai] and counts[mo_pai] == 3 then
			actions[ACTION.AN_GANG] = actions[ACTION.AN_GANG] or {}
			actions[ACTION.AN_GANG][mo_pai] = true
		end

		for t,c in pairs(counts) do
			if c == 4 then
				actions[ACTION.AN_GANG] = actions[ACTION.AN_GANG] or {}
				actions[ACTION.AN_GANG][t] = true
			end
		end
	end

	if in_pai then
		if counts[in_pai] and counts[in_pai] == 3 then
			actions[ACTION.MING_GANG] = actions[ACTION.MING_GANG] or {}
			actions[ACTION.MING_GANG][in_pai] = true
		end
	
		if counts[in_pai] and counts[in_pai] >= 2 then
			actions[ACTION.PENG] = actions[ACTION.PENG] or {}
			actions[ACTION.PENG] = {[in_pai] = true,}
		end
	end

	if in_pai and rule.is_hu(pai, in_pai)  then
		actions[ACTION.HU] = {[in_pai] = true,}
		actions[ACTION.MEN] = {[in_pai] = true,}
	end

	if mo_pai and rule.is_hu(pai,mo_pai) then
		actions[ACTION.ZI_MO] = {[mo_pai] = true,}
		actions[ACTION.MEN_ZI_MO] = {[mo_pai] = true,}
	end

	-- table.mergeto(actions,rule.is_chi(pai,inPai))
	return actions
end

function mj_util.is_hu(pai, inPai)
	return rule.is_hu(pai,inPai)
end

function mj_util.hu(pai,inPai)
	return rule.hu(pai,inPai)
end

function mj_util.panGangWithOutInPai(pai)
	local anGangList = {}
	local baGangList = {}

	local actions = {}
	local counts = pai.shou_pai
	for k,c in ipairs(counts) do
		if c == 4 then
			actions[ACTION.AN_GANG] = actions[ACTION.AN_GANG] or {}
			actions[ACTION.AN_GANG][k] = true
		end
	end

	for k,v in ipairs(pai.ming_pai) do
		if v.type == ACTION.PENG and counts[v.tile] == 1 then
			actions[ACTION.BA_GANG] = actions[ACTION.BA_GANG] or {}
			actions[ACTION.BA_GANG][k] = true
		end
	end

	return anGangList,baGangList
end

function mj_util.is_ting(pai)
	return rule.ting(pai)
end

function mj_util.is_ting_full(pai)
	return rule.ting_full(pai)
end

function mj_util.get_fan_table_res(base_fan_table)
	return rule.get_fan_table_res(base_fan_table)
end

-- local tiles = {2}
-- local shou_pai = table.fill(nil,0,1,50)
-- for _,tile in pairs(tiles) do
-- 	table.incr(shou_pai,tile)
-- end

-- local is = mj_util.is_hu({
-- 	shou_pai = shou_pai,
-- 	ming_pai = {},
-- },2)

return mj_util