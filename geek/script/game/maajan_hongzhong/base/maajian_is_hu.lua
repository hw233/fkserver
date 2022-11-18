local maajan_data = require "game.maajan_hongzhong.base.maajan_data" 
local log = require "log"
local TY_VALUE = 35
local maajian_is_hu = {}
 function maajian_is_hu.counts_2_tiles(counts)
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
function maajian_is_hu.serialization(shou_pai) --把手牌换成序列化的9为字符串
	local tbl={0,0,0,0,0,0,0,0,0}
	for _,v in ipairs(shou_pai) do
		if v > 10 then 
			v = v%10
		end
		tbl[v]=tbl[v]+1
	end
	return table.concat(tbl)
end 

local function cur_tile_men(tile)
	return tile == TY_VALUE and 4 or (math.floor(tile / 10)+1)
end

function maajian_is_hu.is_hu(state)
	local counts = state.counts
	log.dump(counts,"is_hu counts")
	local tiles_shou_pai =  maajian_is_hu.counts_2_tiles(counts)
	table.sort(tiles_shou_pai,function(a,b) return a < b end )
	--local tiles_shou_pai_men = {tong_list = {},tiao_list = {},wan_list = {},laizi_list={}}
	log.dump(tiles_shou_pai,"is_hu tiles_shou_pai")
	local tiles_shou_pai_men = {{},{},{},{}}
	local jiang_list = {} 
	local bj = 1 
	local value = tiles_shou_pai[1]
	for i,v in ipairs(tiles_shou_pai) do
		if i ~= bj   then 
			if v == value and v ~= TY_VALUE then 
				table.insert(jiang_list,v)
				bj = i + 1 
				value = tiles_shou_pai[bj]
			else
				bj = i
				value = v
			end
		end 
		table.insert(tiles_shou_pai_men[cur_tile_men(v)],v)
	end
	log.dump(tiles_shou_pai_men,"is_hu tiles_shou_pai_men")
	local num_group_all_pai ={}
	local pai_men_ser = {}
	for i = 1, 3, 1 do
		table.insert(num_group_all_pai,#tiles_shou_pai_men[i]%3)
		if #tiles_shou_pai_men[i] >0 then
			table.insert(pai_men_ser,maajian_is_hu.serialization(tiles_shou_pai_men[i]))
		else
			table.insert(pai_men_ser,false)
		end
	end
	log.dump(pai_men_ser,"is_hu pai_men_ser")
	log.dump(num_group_all_pai,"is_hu num_group_all_pai")
	local subs_num = #tiles_shou_pai_men[4]
	local num_jiang_pai = num_group_all_pai[1]%2+num_group_all_pai[2]%2+num_group_all_pai[3]%2 
	local num_all_pai = num_group_all_pai[1]+num_group_all_pai[2]+num_group_all_pai[3]
	local jiang_num = 1
	local naizi_num = subs_num
	log.info("subs_num %d,num_jiang_pai %d, num_all_pai %d,",subs_num,num_jiang_pai,num_all_pai)
	if subs_num >0 then -- 有癞子  --所有可以胡的牌值列表1代表有将 2代表无将  maajan_data[1][1]代表有将的1哥鬼 maajan_data[1][2]代表有将的2哥鬼   maajan_data[1][5]代表无鬼	
		if subs_num == 1 then 
			if (num_jiang_pai ==0 and  num_all_pai == 4)    then
				for i,v in ipairs(num_group_all_pai) do
					if pai_men_ser[i] then
						if v==2 then --要么是有鬼无将 要么是又将无鬼
							if maajan_data[1][#maajan_data[1]][pai_men_ser[i]]  then 			 						
							elseif   maajan_data[2][subs_num][pai_men_ser[i]] then 
								naizi_num =naizi_num -subs_num 
							else
								return false
							end
						else
							if not maajan_data[2][#maajan_data[2]][pai_men_ser[i]] then --无鬼无将
								return false
							end
						end
					end
				end
				if  naizi_num >-1 then
					return true
				else
					return false
				end
			elseif  num_all_pai == 1  then
				for i,v in ipairs(num_group_all_pai) do
					if pai_men_ser[i] then
						if v==1 then
							if  maajan_data[1][subs_num][pai_men_ser[i]] then --有鬼有将
								jiang_num = jiang_num -1
								naizi_num =naizi_num -subs_num
							else
								return false
							end
						else
							if not maajan_data[2][#maajan_data[2]][pai_men_ser[i]] then --无鬼无将
								return false
							end
						end
					end
				end
				if jiang_num == 0 and naizi_num ==0 then
					return true
				else
					return false
				end
			else
				return false
			end	
		elseif subs_num == 2 then 
			if (num_jiang_pai ==1 and num_all_pai == 3 )  then 
				local bj = true
				for i,v in ipairs(num_group_all_pai) do
					if pai_men_ser[i] then
						if v==1 then
							if maajan_data[1][1][pai_men_ser[i]]  then
								jiang_num = jiang_num -1
								naizi_num = naizi_num -1
							else
								bj  =  false
								break
							end
						elseif v==2 then
							if   maajan_data[2][1][pai_men_ser[i]] then 
								naizi_num = naizi_num -1  
							else
								bj  = false
								break
							end
						else
							if  maajan_data[2][#maajan_data[2]][pai_men_ser[i]] then --无鬼无将
							else 
								bj  = false
								break
							end
						end
					end
				end
				if jiang_num == 0 and naizi_num ==0 and bj  then 
					return true
				else 
					jiang_num = 1
					naizi_num = 2
				end 
				for i,v in ipairs(num_group_all_pai) do
					if pai_men_ser[i] then
						if v==1 then 
							if   maajan_data[2][subs_num][pai_men_ser[i]] then 
								naizi_num = naizi_num -subs_num  
							else
								return false 
							end
						elseif v==2 then 
							if maajan_data[1][#maajan_data[1]][pai_men_ser[i]]  then 
								jiang_num = jiang_num -1  
							else
								return false 
							end	
						else
							if  maajan_data[2][#maajan_data[2]][pai_men_ser[i]] then --无鬼无将
							else 
								return false 
							end
						end
					end
				end
				if jiang_num == 0 and naizi_num ==0  then 
					return true
				else 
					return false 
				end
			elseif num_all_pai == 0  then  -- 无将无鬼缺鬼2
				for i,v in ipairs(num_group_all_pai) do
					if pai_men_ser[i] then
						if  maajan_data[2][#maajan_data[2]][pai_men_ser[i]] then --无鬼无将
						elseif maajan_data[1][subs_num][pai_men_ser[i]] then 
							jiang_num = jiang_num -1 
							naizi_num = naizi_num -subs_num
						else 
							return false 
						end	
					end
				end
				if (jiang_num == 0 and naizi_num >-1) or naizi_num ==2 then 
					return true
				else 
					return false 
				end 
			elseif num_all_pai == 6  then  -- 有将无鬼 或者有鬼吾将
				for i,v in ipairs(num_group_all_pai) do
					if pai_men_ser[i] then
						if v==2 then 
							if maajan_data[1][#maajan_data[1]][pai_men_ser[i]]  then 
							elseif   maajan_data[2][1][pai_men_ser[i]] then 
								naizi_num = naizi_num -1  
							else
								return false 
							end	
						else
								return false 
						end
					end
				end
				if  naizi_num >-1  then 
					return true
				else 
					return false 
				end 
			else
				return false 
			end	
		elseif subs_num == 3 then 
			if num_all_pai == 2    then --22 22 11 3个鬼都在将的哪一组          
				 local bj =true  ---1
				for i,v in ipairs(num_group_all_pai) do
					if pai_men_ser[i] then
						if v==2 then 
							if maajan_data[1][3][pai_men_ser[i]] then
								naizi_num = naizi_num -3
								jiang_num = jiang_num -1
							else
								bj =  false 
								break
							end	
						else
							if  maajan_data[2][#maajan_data[2]][pai_men_ser[i]] then --无鬼无将 
							else
								bj =  false 
								break
							end
						end
					end
				end	
				if jiang_num == 0 and naizi_num ==0 and bj  then 
					return true
				else 
					jiang_num = 1
					naizi_num = subs_num
					bj = true
				end 
			---------2    12   22  21 3哥鬼都再不是将的哪一组  
				for i,v in ipairs(num_group_all_pai) do
					if pai_men_ser[i] then					
						if v==2 then 
							if maajan_data[1][#maajan_data[1]][pai_men_ser[i]] then
							else
								bj =  false 
								break
							end	
						else
							if  maajan_data[2][#maajan_data[2]][pai_men_ser[i]] then --无鬼无将
							elseif maajan_data[2][3][pai_men_ser[i]] then
								naizi_num = naizi_num -3 
							else
								bj =  false 
								break
							end
						end
					end
				end	
				if  bj and naizi_num >-1 then 
					return true
				else 
					jiang_num = 1
					naizi_num = subs_num
					bj = true
				end 
				---------3  11 21 22 2哥鬼正在将1哥鬼再无疆      1
				for i,v in ipairs(num_group_all_pai) do
					if pai_men_ser[i] then
						if v==2 then 
							if   maajan_data[2][1][pai_men_ser[i]] then 
								naizi_num = naizi_num -1 
							else
								bj =  false 
								break
							end	
						else
							if  maajan_data[2][#maajan_data[2]][pai_men_ser[i]] then --无鬼无将
							elseif maajan_data[1][2][pai_men_ser[i]] then
								naizi_num = naizi_num -2								
							else
								bj =  false 
								break
							end
						end
					end
				end	
				if  naizi_num > -1 and bj  then 
					return true
				else 
					jiang_num = 1
					naizi_num = subs_num
					bj = true
				end 
				-----4 1 21 22 1哥鬼在将 2哥鬼不在将
					for i,v in ipairs(num_group_all_pai) do
					if pai_men_ser[i] then
						if v==1 then 
							if maajan_data[1][1][pai_men_ser[i]]  then 
								naizi_num = naizi_num -1
							elseif   maajan_data[2][2][pai_men_ser[i]] then 
								naizi_num = naizi_num -2  
							else
								return false 
							end
						else
							if  maajan_data[2][#maajan_data[2]][pai_men_ser[i]] then --无鬼无将
							else
								return false 
							end
						end
					end
				end	
				if  naizi_num >-1 and bj  then 
					return true
				else 
					return false 
				end 
			elseif  num_all_pai == 5 then --3个块没个块都分一个鬼
				local bj = true
				for i,v in ipairs(num_group_all_pai) do
					if pai_men_ser[i] then
						if v==1 then 
							if maajan_data[1][1][pai_men_ser[i]]  then 
								jiang_num = jiang_num -1 
								naizi_num = naizi_num -1
							else
								bj = false 
								break
							end
						elseif v==2 then 
							if   maajan_data[2][1][pai_men_ser[i]] then 
								naizi_num = naizi_num -1 
							else
								bj = false 
								break
							end	
						else
							bj = false 
							break
						end
					end
				end	
				if bj and  jiang_num == 0 and naizi_num ==0  then 
					return true
				else 
					jiang_num = 1
					naizi_num = subs_num
					bj = true
				end
				--武将1个分2个鬼 武将 1个分一个鬼 又将部分
				for i,v in ipairs(num_group_all_pai) do
					if pai_men_ser[i] then
						if v==1 then 
							if   maajan_data[2][2][pai_men_ser[i]] then 
								naizi_num = naizi_num -2 							
							else
								return false 
							end
						elseif v==2 then 
							if  maajan_data[1][#maajan_data[2]][pai_men_ser[i]] then --无鬼无将

							elseif   maajan_data[2][1][pai_men_ser[i]] then 
								naizi_num = naizi_num -1 
							else
								return false 
							end	
						else
							return false 
						end
					end
				end	
				if  naizi_num >-1  then 
					return true
				else 
					return false 
				end 	
			else
				return false 
			end			
		elseif subs_num == 4 then  
			if  num_all_pai == 4    then  --
			local  bj = true
			---1全部分配到无将的1个组上面   
				for i,v in ipairs(num_group_all_pai) do
					if pai_men_ser[i] then
						if v==2 then 
							if  maajan_data[1][#maajan_data[1]][pai_men_ser[i]]   then 
							elseif  maajan_data[2][4][pai_men_ser[i]]  then
								naizi_num = naizi_num -4
							else
								bj = false 
								break
							end	
						else
							if  maajan_data[2][#maajan_data[2]][pai_men_ser[i]] then --无鬼无将
							else
								bj = false 
								break
							end
						end
					end
				end	
				if  bj and naizi_num >-1 then 
					return true
				else 
					jiang_num = 1
					naizi_num = subs_num
					bj = true
				end
				-------2 --将分3个 非将分1个   
				for i,v in ipairs(num_group_all_pai) do
					if pai_men_ser[i] then
						if v==2 then 
							if  maajan_data[2][1][pai_men_ser[i]]  then
								naizi_num = naizi_num -1
							elseif maajan_data[1][3][pai_men_ser[i]] then
								naizi_num = naizi_num -3 
							else
								bj = false 
								break
							end	
						else
							if  maajan_data[2][#maajan_data[2]][pai_men_ser[i]] then --无鬼无将 
							else
								bj = false 
								break
							end
						end
					end
				end	
				if  bj and naizi_num >-1 then 
					return true
				else 
					jiang_num = 1
					naizi_num = subs_num
					bj = true
				end
				-------3  --将分2个 飞将没个分1个   
				for i,v in ipairs(num_group_all_pai) do
					if pai_men_ser[i] then
						if v==2 then 
							if maajan_data[2][1][pai_men_ser[i]]  then 
								naizi_num = naizi_num -1 
							else
								bj = false 
								break
							end
						else
							if maajan_data[1][2][pai_men_ser[i]] then
								naizi_num = naizi_num -2
							else
								bj = false 
								break
							end
						end
					end
				end	
				if  bj  and naizi_num >-1 then 
					return true
				else 
					jiang_num = 1
					naizi_num = subs_num
					bj = true
				end
				------4 --飞将1个分1个 1个分2个    将分1个
				for i,v in ipairs(num_group_all_pai) do
					if pai_men_ser[i] then
						if v==1 then 
							if  maajan_data[1][1][pai_men_ser[i]]   then 
								naizi_num = naizi_num -1
							elseif  maajan_data[2][2][pai_men_ser[i]]  then 
								naizi_num = naizi_num -2 
							else
								return false 
							end			
						elseif v==2 then 
							if maajan_data[2][1][pai_men_ser[i]] then
								naizi_num = naizi_num -1 
							else
								return false 
							end	
						else
								return false 
						end
					end
				end	
				if  naizi_num >-1  then 
					return true
				else 
					return false 
				end
			elseif  num_all_pai == 1 then  --将分2个非将分2个    
				local bj = true
				---1
				for i,v in ipairs(num_group_all_pai) do
					if pai_men_ser[i] then
						if v==1 then 
							if maajan_data[2][2][pai_men_ser[i]]  then 
								naizi_num =naizi_num -2			
							else
								bj = false 
								break
							end
						else
							if  maajan_data[2][#maajan_data[2]][pai_men_ser[i]] then --无鬼无将

							elseif maajan_data[1][2][pai_men_ser[i]] then
									naizi_num = naizi_num -2
							else
								bj = false 
								break 
							end
						end
					end
				end	
				if  bj and naizi_num>-1  then 
					return true
				else 
					jiang_num = 1
					naizi_num = subs_num
					bj = true
				end
				----2 --将分4个    
				for i,v in ipairs(num_group_all_pai) do
					if pai_men_ser[i] then
						if v==1 then 
							if   maajan_data[1][4][pai_men_ser[i]] then 
								naizi_num = naizi_num -4 
							else
								bj = false 
								break
							end
						else
							if  maajan_data[2][#maajan_data[2]][pai_men_ser[i]] then --无鬼无将
							else
								bj = false 
								break 
							end
						end
					end
				end	
				if  bj and naizi_num >-1 then 
					return true
				else 
					jiang_num = 1
					naizi_num = subs_num
					bj = true
				end
				----3 -- 飞将分3个 将分1个
				for i,v in ipairs(num_group_all_pai) do
					if pai_men_ser[i] then
						if v==1 then 
							if maajan_data[1][1][pai_men_ser[i]] then 
								naizi_num= naizi_num-1
							else
								return false
							end
						else
							if  maajan_data[2][#maajan_data[2]][pai_men_ser[i]] then --无鬼无将

							elseif maajan_data[2][3][pai_men_ser[i]] then
								naizi_num =naizi_num -3
							else
								return false
							end
						end
					end
				end	
				if naizi_num >-1 then 
					return true
				else 
					return  false
				end
			else
				return false 
			end	
		end 	
	else   --没有癞子
		if num_jiang_pai == 0 and num_all_pai == 2 then 
			for i,v in ipairs(num_group_all_pai) do
				if pai_men_ser[i] then
					if v==2 then --是又将无鬼
						if  maajan_data[1][#maajan_data[1]][pai_men_ser[i]]  then 
							jiang_num = jiang_num -1 
						else
							return false 
						end
					else
						if  maajan_data[2][#maajan_data[1]][pai_men_ser[i]]  then 
						else 
							return false 
						end
					end
				end
			end
			if jiang_num == 0 and naizi_num ==0  then 
				return true
			else 
				return false 
			end 
		else
			return false 
		end
	end 
	return false 
end
return maajian_is_hu