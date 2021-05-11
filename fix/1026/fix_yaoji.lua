local string = string
if not string.match(package.path,"%./%?%.lua") then
	package.path = package.path .. ";./?.lua"
end

local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"

local rule = require "game.maajan_yaoji.base.rule"
local def = require "game.maajan_yaoji.base.define"
local maajian_is_hu = require "game.maajan_yaoji.base.maajian_is_hu"
local maajan_table = require "game.maajan_yaoji.table"
local log = require "log"
local mj_util = require "game.maajan_yaoji.base.mang_jiang_util"

local HU_TYPE = def.HU_TYPE
local UNIQUE_HU_TYPE = def.UNIQUE_HU_TYPE
local SECTION_TYPE = def.SECTION_TYPE

local TY_VALUE = 21
local FSM_S  = def.FSM_state
local tinsert = table.insert

function maajan_table:huan_pai()
    if not self.rule.huan or table.nums(self.rule.huan) == 0 then
        self:ding_que()
        return
    end

    self:update_state(FSM_S.HUAN_PAI)
    self:broadcast2client("SC_AllowHuanPai",{})

    local trustee_type,trustee_seconds = self:get_trustee_conf()
    if trustee_type and (trustee_type == 1 or (trustee_type == 2 and self.cur_round > 1))  then
        local function random_choice(alltiles,count)
            local ats = clone(alltiles)
            local tiles = {}
            for _ = 1,count do
                local i,tile = table.choice(ats)
                tinsert(tiles,tile)
                table.remove(ats,i)
            end

            return tiles
        end

        local function auto_huan_pai(p,huan_type,huan_count)
            if huan_type ~= 1 then
                local shou_pai_tiles = self:tile_count_2_tiles(p.pai.shou_pai,{[TY_VALUE] = p.pai.shou_pai[TY_VALUE] })--剔除替用
                local huan_tiles = random_choice(shou_pai_tiles,huan_count)
                log.dump(huan_tiles)
                self:lockcall(function()
                    self:on_huan_pai(p,{
                        tiles = huan_tiles
                    })
                end)
                return
            end

            local men_tiles = table.group(p.pai.shou_pai,function(_,tile) return mj_util.tile_men(tile) end)

            local c = 0
            local ty_men = mj_util.tile_men(TY_VALUE)
            local tilecounts
            local curmen 
            repeat
                curmen,tilecounts = table.choice(men_tiles)
                c = table.sum(tilecounts)
            until c >= huan_count and  curmen ~= ty_men

            local huan_tiles = random_choice(self:tile_count_2_tiles(tilecounts),huan_count)
            self:lockcall(function()
                self:on_huan_pai(p,{tiles = huan_tiles})
            end)
            return
        end

        local huan_count = self:get_huan_count()
        local huan_type = self:get_huan_type()
        log.info("%s,%s",huan_type,huan_count)
        self:begin_clock_timer(trustee_seconds,function()
            self:foreach(function(p)
                if p.pai.huan then return end

                self:set_trusteeship(p,true)
                auto_huan_pai(p,huan_type,huan_count)
            end)
        end)

        self:foreach(function(p)
            if not p.trustee then return end
            
            self:begin_auto_action_timer(p,math.random(1,2),function()
                auto_huan_pai(p,huan_type,huan_count)
            end)
        end)
    end
end


local is_hu = maajian_is_hu.is_hu


local function table_entire_key(tb)
	table.sort(tb)
	return table.concat(tb,",")
end

local function merge_same_type(alltypes)
	local types = {}

	for _,ts in pairs(alltypes) do
		local key = table_entire_key(table.keys(ts))
		types[key] = ts
	end

	return table.values(types)
end


local function is_qing_yi_se(pai,cache)
	local men_counts = table.fill(nil,0,0,5)

	table.agg(cache,men_counts,function(tb,c,tile)
		table.incr(tb,rule.tile_men(tile),c)
		return tb
	end)

	table.agg(pai.ming_pai,men_counts,function(tb,s)
		table.incr(tb,rule.tile_men(s.tile))
		return tb
	end)

	local total_men_count = table.sum(men_counts,function(c,men)
		return (c > 0 and men < 3) and 1 or 0
	end)

	return total_men_count == 1
end

local function is_2_5_8(pai,cache)
	local is_shou_258 = table.logic_and(cache,function(c,tile)
		local num = rule.tile_value(tile)
		return c == 0 or (num == 2 or num == 5 or num == 8) or tile == TY_VALUE 
	end)
	local is_ming_258 = table.logic_and(pai.ming_pai,function(s)
		local num = rule.tile_value(s.tile)
		return num == 2 or num == 5 or num == 8
	end)

	return is_shou_258 and is_ming_258
end



local function is_duan_yao(pai,in_pai)
	local is_19 = table.logic_or(pai.shou_pai,function(c,tile)
		local num = rule.tile_value(tile)
		return c > 0 and (num == 1 or num == 9) and tile~= TY_VALUE
	end) or (table.nums(pai.ming_pai) > 0 and table.logic_or(pai.ming_pai,function(s)
		local num = rule.tile_value(s.tile)
		return num == 1 or num == 9
	end)) or (in_pai and   in_pai~= TY_VALUE and 
		(rule.tile_value(in_pai) == 1 or rule.tile_value(in_pai) == 9)
	)

	return not is_19
end

local function gou_count_wutiyong(pai,cache)
	local shou_gou  ,ming_gou = 0,0
	shou_gou = table.sum(cache,function(c) return c == 4 and 1 or 0 end)
	ming_gou = table.sum(pai.ming_pai,function(s) return ((s.type == SECTION_TYPE.PENG or s.type == SECTION_TYPE.RUANPENG) and cache[s.tile] == 1) and 1 or 0 end)
	return shou_gou + ming_gou
end
local function get_ty_can_gou_list(pai,cache,tynum)
	local ty_can_shougou_list = {}
	local ty_can_minggou_list = {}
	for tile, c in pairs(cache) do
		if c== 4-tynum then
			table.insert(ty_can_shougou_list,tile)
		end
	end
	if  tynum==1 then 
		for _, s in pairs(pai.ming_pai) do
			if (s.type == SECTION_TYPE.PENG or s.type == SECTION_TYPE.RUANPENG) and  (not cache[s.tile] or  cache[s.tile]==0 )  then 
				table.insert(ty_can_minggou_list,s.tile)
			end 
		end
	end 
	return table.merge_back(ty_can_shougou_list,ty_can_minggou_list)
end 
local function gou_count_tiyong_help(pai,state,ty_can_gou_list,ty_num)
	local gou_num = 0 
	local curlen = #ty_can_gou_list
	if ty_num == 2 then 
		if gou_num == 0 and curlen >=1  then  --1刻 加1TY 
			table.incr(state.counts,TY_VALUE)
			for i = 1, #ty_can_gou_list, 1 do
				table.incr(state.counts,ty_can_gou_list[i])
				if is_hu(state) then 
					gou_num = gou_count_wutiyong(pai,state.counts)
					return  gou_num 
				else
					table.decr(state.counts,ty_can_gou_list[i])
				end
			end
			table.decr(state.counts,TY_VALUE)
		end
		if gou_num == 0 then  --1对 加2TY 
			local ty_can_gou_list_dui =  get_ty_can_gou_list(pai,state.counts,2)
			for i = 1, #ty_can_gou_list_dui, 1 do
				table.incr(state.counts,ty_can_gou_list_dui[i],2)
				if is_hu(state) then 
					gou_num = gou_count_wutiyong(pai,state.counts)
					return  gou_num
				else
					table.decr(state.counts,ty_can_gou_list_dui[i],2)
				end
			end
		end
	elseif ty_num == 3 then
		if curlen >=2 then   --2刻 加2TY 
			table.incr(state.counts,TY_VALUE)
			for i = 1, #ty_can_gou_list-1, 1 do
				for j = i+1, #ty_can_gou_list, 1 do
					table.incr(state.counts,ty_can_gou_list[i])
					table.incr(state.counts,ty_can_gou_list[j])
					if is_hu(state) then 
						gou_num = gou_count_wutiyong(pai,state.counts)
						return  gou_num
					else
						table.decr(state.counts,ty_can_gou_list[i])
						table.decr(state.counts,ty_can_gou_list[j])
					end
				end
			end
			table.decr(state.counts,TY_VALUE)
		end
		local ty_can_gou_list_dui =  get_ty_can_gou_list(pai,state.counts,2)
		if gou_num == 0 and curlen >=1 and #ty_can_gou_list_dui >0 then  --1刻1TY  1队2ty
			for i = 1, #ty_can_gou_list, 1 do
				for j = 1, #ty_can_gou_list_dui, 1 do
					table.incr(state.counts,ty_can_gou_list[i])
					table.incr(state.counts,ty_can_gou_list_dui[j],2)
					if is_hu(state) then 
						gou_num = gou_count_wutiyong(pai,state.counts)
						return  gou_num
					else
						table.decr(state.counts,ty_can_gou_list[i])
						table.decr(state.counts,ty_can_gou_list_dui[j],2)
					end
				end
			end
		end
		if gou_num == 0 and curlen >=1  then   --1刻1TY 
			table.incr(state.counts,TY_VALUE,2)
			for i = 1, #ty_can_gou_list, 1 do
				table.incr(state.counts,ty_can_gou_list[i])
				if is_hu(state) then 
					gou_num = gou_count_wutiyong(pai,state.counts)
					return  gou_num 
				else
					table.decr(state.counts,ty_can_gou_list[i])
				end
			end
			table.decr(state.counts,TY_VALUE,2)
		end
		if gou_num == 0 and #ty_can_gou_list_dui >0 then  --1对2TY 
			table.incr(state.counts,TY_VALUE)
			for i = 1, #ty_can_gou_list_dui, 1 do
				table.incr(state.counts,ty_can_gou_list_dui[i],2)
				if is_hu(state) then 
					gou_num = gou_count_wutiyong(pai,state.counts)
					return  gou_num 
				else
					table.decr(state.counts,ty_can_gou_list_dui[i],2)
				end
			end
			table.decr(state.counts,TY_VALUE)
		end
		if gou_num == 0 then  --1张 3TY
			local ty_can_gou_list_dan =  get_ty_can_gou_list(pai,state.counts,3)
			for i = 1, #ty_can_gou_list_dan, 1 do
				table.incr(state.counts,ty_can_gou_list_dan[i],3)
				if is_hu(state) then 
					gou_num = gou_count_wutiyong(pai,state.counts)
					return  gou_num 
				else
					table.decr(state.counts,ty_can_gou_list_dan[i],3)
				end
			end
		end
	end 
	return gou_num
end 
local function gou_count_tiyong(pai,cache)
	local curcounts = clone(cache)
	local gou_num = 0 
	local ty_num = curcounts[TY_VALUE] or 0
	curcounts[TY_VALUE] =  nil 
	local ty_can_gou_list =  get_ty_can_gou_list(pai,curcounts,1)
	local ty_lenth = #ty_can_gou_list
	local state = { counts = curcounts }
	if ty_num == 1 then 
		if ty_lenth >0 then 
			for _, tile in pairs(ty_can_gou_list) do
				table.incr(state.counts,tile)
				if is_hu(state) then 
					gou_num = gou_count_wutiyong(pai,state.counts)
					return  gou_num
				else
					table.decr(state.counts,tile)
				end
			end

		end 	
	else 
		if ty_lenth >= 0 then 
			if ty_lenth >= ty_num then 
				if ty_num == 2 then 
					for i = 1, ty_lenth-1, 1 do --2刻 加2TY 
						for j = i+1, ty_lenth, 1 do
							table.incr(state.counts,ty_can_gou_list[i])
							table.incr(state.counts,ty_can_gou_list[j])
							if is_hu(state) then 
								gou_num = gou_count_wutiyong(pai,state.counts)
								return  gou_num
							else
								table.decr(state.counts,ty_can_gou_list[i])
								table.decr(state.counts,ty_can_gou_list[j])
							end
						end
					end
					if gou_num == 0 then 
						gou_num=gou_count_tiyong_help(pai,state,ty_can_gou_list,ty_num)
					end
				elseif ty_num == 3 then 
					for i = 1, ty_lenth-2, 1 do  --3刻 加3TY 
						for j = i+1, ty_lenth, 1 do
							for k = i+2, ty_lenth, 1 do
								table.incr(state.counts,ty_can_gou_list[i])
								table.incr(state.counts,ty_can_gou_list[j])
								table.incr(state.counts,ty_can_gou_list[k])
								if is_hu(state) then 
									gou_num = gou_count_wutiyong(pai,state.counts)
									return  gou_num
								else
									table.decr(state.counts,ty_can_gou_list[i])
									table.decr(state.counts,ty_can_gou_list[j])
									table.decr(state.counts,ty_can_gou_list[k])
								end
							end 
						end
					end
					if gou_num == 0 then 
						gou_num=gou_count_tiyong_help(pai,state,ty_can_gou_list,ty_num)
					end
				end
			else 
				gou_num=gou_count_tiyong_help(pai,state,ty_can_gou_list,ty_num)
			end 
		else 
			gou_num=gou_count_tiyong_help(pai,state,ty_can_gou_list,ty_num)
		end 
	end 
	if gou_num == 0 then 
		table.incr(state.counts,TY_VALUE,ty_num)
		if is_hu(state) then 
			gou_num = gou_count_wutiyong(pai,state.counts)
			return  gou_num
		else
			table.decr(state.counts,TY_VALUE,ty_num)
		end
	end
	return gou_num
end

local function gou_count_tiyong_qidui(cache)
	local curcounts = clone(cache)
	local ty_num = curcounts[TY_VALUE] or 0
	curcounts[TY_VALUE] = nil
	local count_tilemaps = table.group(curcounts,function(c,_) return   c end)
	local count_tiles = table.map(count_tilemaps,function(gp,c) return c,table.keys(gp) end)
	local one_count = count_tiles[1] and #count_tiles[1] or 0
	local two_count = count_tiles[2] and #count_tiles[2] or 0
	local three_count = count_tiles[3] and #count_tiles[3] or 0
	local gen_count = count_tiles[4] and #count_tiles[4] or 0
	if one_count >0 then 
		ty_num = ty_num - one_count
	end 
	if three_count >0 then 
		ty_num = ty_num - three_count
		gen_count = gen_count+three_count
	end 
	if ty_num >0 and two_count >0 and  ty_num%2 ==0 and ty_num/2 <= two_count  then 
		gen_count = gen_count+ty_num/2
	end 
	return  gen_count 
end 

-- flags 1 qidui 2 sidui 3 daduizi
local function gou_count(pai,cache,flags,ji_num)
	local ty_num = cache[TY_VALUE] or 0
	local gou_num = 0
	if ty_num ==0 then 
		gou_num = gou_count_wutiyong(pai,cache)
	else 
		if flags  == 1 then 
			gou_num= gou_count_tiyong_qidui(cache)
		elseif  flags  == 2 then 
			gou_num = gou_count_tiyong_qidui(cache)
		elseif  flags  == 3 then 
			gou_num = 0
		else
			if ji_num == 4 then  --4鸡顶翻不用算根
				gou_num = 0
			else 
				gou_num = gou_count_tiyong(pai,cache)
			end 
		end 
	end 
	return gou_num
end

local function get_hu_types(cache)
	local base_types = {}
	local curcounts = clone(cache)
	local ty_num = curcounts[TY_VALUE] or 0
	curcounts[TY_VALUE] = nil
	local count_tilemaps = table.group(curcounts,function(c,_) return   c end)
	local count_tiles = table.map(count_tilemaps,function(gp,c) return c,table.keys(gp) end)
	count_tiles[1] = count_tiles[1] or {}
	count_tiles[3] = count_tiles[3] or {}
	if count_tiles[4]  and #count_tiles[4]>0 then 
		for _, value in ipairs(count_tiles[4] ) do
			table.insert(count_tiles[3],value)
			table.insert(count_tiles[1],value)
		end
		count_tiles[4] =nil
	end
	local two_count = count_tiles[2] and #count_tiles[2] or 0
	local one_count = count_tiles[1] and #count_tiles[1] or 0	
	local ke_zi_bj =false 
	if one_count == 0 and two_count == 0 and ty_num == 2 then
		ke_zi_bj = true 
	end
	if not ke_zi_bj and ((one_count == 0 and two_count-ty_num ==1 ) or (two_count == 0 and one_count-ty_num ==0)) then
		ke_zi_bj = true 
	end
	if  not ke_zi_bj and two_count ~= 0 and one_count ~= 0   then
		local curty_num = ty_num
		local curtwo_count = two_count
		for i = 1, two_count-1, 1 do
			curty_num = curty_num -1
			curtwo_count = curtwo_count -1
		end
		if curtwo_count == 1 and  curty_num >=0 and curty_num == one_count*2 and (curty_num + one_count)%3 == 0 then
			ke_zi_bj = true 
		end
	end
	if ke_zi_bj then
		--if is_2_5_8(pai,cache) then
			--base_types[HU_TYPE.JIANG_DUI] = 1
		--else
			base_types[HU_TYPE.DA_DUI_ZI] = 1
		--end
	end
	--if is_all_1_9(pai) then
	---	base_types[HU_TYPE.QUAN_YAO_JIU] = 1
	--end

	if table.nums(base_types) == 0 then
		base_types[HU_TYPE.PING_HU] = 1
	end

	return base_types
end


local function is_qi_dui(counts)
	if table.sum(counts) ~= 14 then 
		return false 
	end 
	local curcounts = clone(counts)
	local ty_num = curcounts[TY_VALUE] or 0
	curcounts[TY_VALUE] = nil
	local count_tilemaps = table.group(curcounts,function(c,_) return   c end)
	local count_tiles = table.map(count_tilemaps,function(gp,c) return c,table.keys(gp) end)
	count_tiles[1] = count_tiles[1] or {}
	count_tiles[2] = count_tiles[2] or {}
	if count_tiles[3]  and #count_tiles[3]>0 then 
		for _, value in ipairs(count_tiles[3] ) do
			table.insert(count_tiles[2],value)
			table.insert(count_tiles[1],value)
		end
		count_tiles[3] = nil
	end 
	if count_tiles[4]  and #count_tiles[4]>0 then 
		for _, value in ipairs(count_tiles[4] ) do
			table.insert(count_tiles[2],value)
			table.insert(count_tiles[2],value)
		end
		count_tiles[4] =nil
	end 
	local even_count = count_tiles[2] and #count_tiles[2] or 0
	local one_count = count_tiles[1] and #count_tiles[1] or 0
	local cureven_count = 7 - even_count 
	local curty_num = ty_num
	if one_count >0 then 
		for i = 1, ty_num, 1 do
			one_count = one_count -1
			cureven_count = cureven_count - 1
			curty_num = curty_num -1
		end
	end 
	if cureven_count == 0 or  cureven_count == curty_num/2 then 
		return true
	end 

	return  false 
end

local function is_si_dui(counts)
	if table.sum(counts) ~= 8 then 
		return false 
	end 
	local curcounts = clone(counts)
	local ty_num = curcounts[TY_VALUE] or 0
	curcounts[TY_VALUE] = nil
	local count_tilemaps = table.group(curcounts,function(c,_) return   c end)
	local count_tiles = table.map(count_tilemaps,function(gp,c) return c,table.keys(gp) end)
	count_tiles[1] = count_tiles[1] or {}
	count_tiles[2] = count_tiles[2] or {}
	if count_tiles[3]  and #count_tiles[3]>0 then 
		for _, value in ipairs(count_tiles[3] ) do
			table.insert(count_tiles[2],value)
			table.insert(count_tiles[1],value)
		end
		count_tiles[3] = nil
	end 
	if count_tiles[4]  and #count_tiles[4]>0 then 
		for _, value in ipairs(count_tiles[4] ) do
			table.insert(count_tiles[2],value)
			table.insert(count_tiles[2],value)
		end
		count_tiles[4] =nil
	end 
	local even_count = count_tiles[2] and #count_tiles[2] or 0
	local one_count = count_tiles[1] and #count_tiles[1] or 0
	local cureven_count = 4 - even_count 
	local curty_num = ty_num
	if one_count >0 then 
		for i = 1, ty_num, 1 do
			one_count = one_count -1
			cureven_count = cureven_count - 1
			curty_num = curty_num -1
		end
	end 
	if cureven_count == 0 or  cureven_count == curty_num/2 then 
		return true
	end 

	return  false 
end


local function is_men_qing(pai)
	return table.nums(pai.ming_pai) == 0 or
		table.logic_and(pai.ming_pai,function(s) return s.type == SECTION_TYPE.AN_GANG or s.type == SECTION_TYPE.RUAN_AN_GANG end)
end

local function ji_count(pai,cache)
	local shou_ji =  cache[TY_VALUE] or 0
	local ming_ji = table.sum(pai.ming_pai,function(s) return (s.type ~= SECTION_TYPE.PENG ) and s.substitute_num or 0 end)

	return shou_ji + ming_ji
end

local function unique_hu_types(base_hu_types)
	local types = {}
	for unique_t,s in pairs(UNIQUE_HU_TYPE) do
		if table.logic_and(s,function(_,k) return base_hu_types[k] end) then
			for t,_ in pairs(s) do base_hu_types[t] = nil end
			types[unique_t] = 1
		end
	end

	return table.merge(types,base_hu_types,function(l,r) 
		local c = (l or 0) + (r or 0)
		return (c and c > 0) and c or nil
	end)
end

function rule.hu(pai,in_pai,mo_pai)
	local cache = {}
	for i = 1,30 do cache[i] = pai.shou_pai[i] or 0 end
	if in_pai then table.incr(cache,in_pai) end
	
	--一万到九万，一筒到九筒，一条到九条， 东-南-西-北  -中-发-白-   春-夏-秋-冬-梅-兰-竹-菊--
	--1-9		  11-19  	21-29 		 	31-34		35-37		41-48
	
	local state = {  counts = clone(cache) }
	if is_hu(state) then state.hu  = true  end 
	local alltypes = {}

	local qi_dui = is_qi_dui(cache)
	local si_dui = is_si_dui(cache)
	if not state.hu and not qi_dui and not si_dui then
		return {{[HU_TYPE.WEI_HU] = 1}}
	end

	local qing_yi_se = is_qing_yi_se(pai,cache)
	local men_qing =  is_men_qing(pai)
	local duan_yao = is_duan_yao(pai,in_pai)
	local gou = 0 
	local ji_num  = ji_count(pai,cache)
	if qi_dui then
		local base_types = {}
		gou = gou_count(pai,cache,1,ji_num)
		if gou > 0 then
			base_types[HU_TYPE.LONG_QI_DUI] = 1
		else
			base_types[HU_TYPE.QI_DUI] = 1
		end

		if qing_yi_se then base_types[HU_TYPE.QING_YI_SE] = 1 end
		if duan_yao then base_types[HU_TYPE.DUAN_YAO] = 1 end
		if men_qing then base_types[HU_TYPE.MEN_QING] = 1 end
		if ji_num ==0 then base_types[HU_TYPE.WU_JI] = 1 end
		if ji_num ==4 then base_types[HU_TYPE.SI_JI] = 1 end
		table.insert(alltypes,base_types)
	end

	if si_dui then
		local base_types = {}
		gou = gou_count(pai,cache,2,ji_num)
		if gou > 0 then
			base_types[HU_TYPE.LONG_SI_DUI] = 1
		else
			base_types[HU_TYPE.SI_DUI] = 1
		end

		if qing_yi_se then base_types[HU_TYPE.QING_YI_SE] = 1 end
		if duan_yao then base_types[HU_TYPE.DUAN_YAO] = 1 end
		if men_qing then base_types[HU_TYPE.MEN_QING] = 1 end
		if ji_num ==0 then base_types[HU_TYPE.WU_JI] = 1 end
		if ji_num ==4 then base_types[HU_TYPE.SI_JI] = 1 end
		table.insert(alltypes,base_types)
	end
	if state.hu then 
		local common_types = {}
		if duan_yao then common_types[HU_TYPE.DUAN_YAO] = 1 end
		if men_qing then common_types[HU_TYPE.MEN_QING] = 1 end
		if qing_yi_se then common_types[HU_TYPE.QING_YI_SE] = 1 end
		if ji_num ==0 then common_types[HU_TYPE.WU_JI] = 1 end
		if ji_num ==4 then common_types[HU_TYPE.SI_JI] = 1 end
		local types = get_hu_types(cache)
		gou = gou_count(pai,cache,(types[HU_TYPE.JIANG_DUI] or types[HU_TYPE.DA_DUI_ZI]) and 3 or -1,ji_num )
		if gou > 0 then common_types[HU_TYPE.DAI_GOU] = gou end
		local sum = table.sum(pai.shou_pai)
		local ty_num = pai.shou_pai[TY_VALUE] or 0 
		if (sum == 1 and  (pai.shou_pai[in_pai] == 1 or in_pai == TY_VALUE or ty_num == 1 ))or
			(sum == 2 and not in_pai and (table.logic_or(pai.shou_pai,function(c,_) return c == 2 end) or ty_num >= 1 )) then
			common_types[HU_TYPE.DAN_DIAO_JIANG] = 1
		end

		table.mergeto(types,common_types,function(l,r) return (l or 0) + (r or 0) end)

		table.insert(alltypes,types)
	end 

	for i = 1,#alltypes do
		alltypes[i] = unique_hu_types(alltypes[i])
	end

	alltypes = merge_same_type(alltypes)

	return alltypes
end
