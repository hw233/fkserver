local rule = require "game.maajan_customized.base.rule"
local def = require "game.maajan_customized.base.define"
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


function mj_util.arraySortMJ(pai,anPaiIndex)
	anPaiIndex = anPaiIndex or 1
	local tmp = {}
	for i=anPaiIndex,#pai do
		tmp[#tmp + 1] = pai[i]
	end
	table.sort(tmp)
	for i=anPaiIndex,#pai do
		pai[i] = tmp[i-anPaiIndex + 1]
	end
end

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

function mj_util.get_actions(pai, inPai)
	local actions = {}

	local counts = pai.shou_pai
	if inPai then
		local pai_count = counts[inPai] or 0
		if pai_count >= 2 then
			actions[ACTION.PENG] = {[inPai] = true,}
		end

		if pai_count >= 3 then
			actions[ACTION.AN_GANG] = {[inPai] = true,}
		end

		if #rule.is_hu(pai,inPai) > 0 then
			actions[ACTION.HU] = {[inPai] = true,}
		end

		table.mergeto(actions,rule.is_chi(pai,inPai))
	end

	for _,s in ipairs(pai.ming_pai) do
		if s.type == ACTION.PENG and counts[s.tile] == 1 then
			actions[ACTION.BA_GANG] = actions[ACTION.BA_GANG] or {}
			actions[ACTION.BA_GANG][s.tile] = true
		end
	end

	for k,c in ipairs(counts) do
		if c == 4 then
			actions[ACTION.AN_GANG] = actions[ACTION.AN_GANG] or {}
			actions[ACTION.AN_GANG][k] = true
		end
	end

	return actions
end

function mj_util.panHu(pai, inPai)
	return rule.is_hu(pai,inPai)
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

function mj_util.panTing(pai)
	for i=1,16 do
		local info = rule.is_hu(pai,i)
		if #info > 0 then
			return true
		end
	end
	return false
end

function mj_util.panTing_14(pai)
	for k,v in pairs(pai.shou_pai) do
		local pai_tmp = clone(pai)
		pai_tmp.shou_pai[k] = pai_tmp.shou_pai[#pai_tmp.shou_pai]
		pai_tmp.shou_pai[#pai_tmp.shou_pai] = nil
		for i=1,16 do
			local info = rule.is_hu(pai,i)
			if #info > 0 then
				return true
			end
		end
	end
	return false
end

function mj_util.get_fan_table_res(base_fan_table)
	return rule.get_fan_table_res(base_fan_table)
end

return mj_util