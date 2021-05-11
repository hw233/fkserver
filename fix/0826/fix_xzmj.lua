
local string = string
if not string.match(package.path,"%./%?%.lua") then
	package.path = package.path .. ";./?.lua"
end

local dump = require "fix.dump"
local getupvalue = require "fix.getupvalue"


local maajan_table = require "game.maajan_xuezhan.maajan_table"
local def = require "game.maajan_xuezhan.base.define"

local SECTION_TYPE = def.SECTION_TYPE
local HU_TYPE_INFO = def.HU_TYPE_INFO
local HU_TYPE = def.HU_TYPE

function maajan_table:calculate_gang(p)
    local s2hu_type = {
        [SECTION_TYPE.MING_GANG] = HU_TYPE.MING_GANG,
        [SECTION_TYPE.AN_GANG] = HU_TYPE.AN_GANG,
        [SECTION_TYPE.BA_GANG] = HU_TYPE.BA_GANG,
    }

    local ss = table.select(p.pai.ming_pai,function(s) return  s2hu_type[s.type] ~= nil end)
    local gfan= table.group(ss,function(s) return  s2hu_type[s.type] end)
    local gangfans = table.map(gfan,function(gp,t)
        return t,{fan = HU_TYPE_INFO[t].fan,count = table.nums(gp)}
    end)

    local scores = table.agg(p.pai.ming_pai,{},function(tb,s)
        local t = s2hu_type[s.type]
        if not t then return tb end
        local hu_type_info = HU_TYPE_INFO[t]

        local who = s.dian_pao and self.players[s.dian_pao] or p
        
        if t == HU_TYPE.MING_GANG then
            tb[who.chair_id] = (tb[who.chair_id] or 0) + hu_type_info.score
            tb[s.whoee] = (tb[s.whoee] or 0) - hu_type_info.score
        elseif t == HU_TYPE.AN_GANG or t == HU_TYPE.BA_GANG then
            self:foreach_except(who,function(pi)
                if pi == p then return end
                if pi.hu and pi.hu.time < s.time then return end

                tb[who.chair_id] = (tb[who.chair_id] or 0) + hu_type_info.score
                tb[pi.chair_id] = (tb[pi.chair_id] or 0) - hu_type_info.score
            end)
        end

        return tb
    end)

    local fans = table.series(gangfans,function(v,t) return {type = t,fan = v.fan,count = v.count} end)
    return fans,scores
end


dump(print,maajan_table)