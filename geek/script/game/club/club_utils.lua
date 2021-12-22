local base_clubs = require "game.club.base_clubs"
local base_players = require "game.lobby.base_players"
local runtime_conf = require "game.runtime_conf"
local onlineguid = require "netguidopt"
local log = require "log"
local channel = require "channel"
local club_template = require "game.club.club_template"
local table_template = require "game.lobby.table_template"
local club_team = require "game.club.club_team"
local club_team_template_conf = require "game.club.club_team_template_conf"
local club_table = require "game.club.club_table"
local base_private_table = require "game.lobby.base_private_table"
local club_member = require "game.club.club_member"
local club_role = require "game.club.club_role"
local club_template_conf = require "game.club.club_template_conf"
local club_partner_template_commission = require "game.club.club_partner_template_commission"
local club_member_partner = require "game.club.club_member_partner"
local club_partner_template_default_commission = require "game.club.club_partner_template_default_commission"
local enum = require "pb_enums"
local player_money = require "game.lobby.player_money"
local club_money = require "game.club.club_money"
local club_commission = require "game.club.club_commission"
local redisopt = require "redisopt"
local g_util = require "util"
local club_partner_member = require "game.club.club_partner_member"
local club_money_type = require "game.club.club_money_type"
local club_team_money = require "game.club.club_team_money"
local club_partner = require "game.club.club_partner"
local club_partner_conf = require "game.club.club_partner_conf"
local club_partner_commission_conf = require "game.club.club_partner_commission_conf"
local club_team_template = require "game.club.club_team_template"

local table = table
local string = string

local tinsert = table.insert

local reddb = redisopt.default

require "functions"

local utils = {}

function utils.parent(club)
    club = type(club) == "table" and club or base_clubs[club]
    if club.parent and club.parent ~= 0 then
        return base_clubs[club.parent]
    end
end

function utils.root(club)
    if not club then return end
    club = type(club) == "table" and club or base_clubs[club]
    local parent = utils.parent(club)
    if parent then
        return utils.root(parent)
    end

    return club
end

function utils.level(club,level)
    level = level and level + 1 or 1
    if not club then return level end
    club = type(club) == "table" and club or base_clubs[club]
    local parent = utils.parent(club)
    if parent then
        return utils.level(parent,level)
    end
    return level
end

function utils.get_game_list(guid,club_id)
    local player = base_players[guid]
    if player then
        local alive_games = g_util.alive_game_ids()
        local alives = table.map(alive_games,function(gameid) return gameid,true end)
		local conf_games = runtime_conf.get_game_conf(player.channel_id,player.promoter,club_id)
		if conf_games and #conf_games > 0 then
			return table.series(conf_games,function(gameid) return alives[gameid] and gameid or nil end)
        end
        
		return alive_games
	end
	return {}
end


local function is_template_visiable(club,template)
    local conf = club_team_template_conf[club.id][template.template_id]
    local visiable = (not conf or conf.visual == nil) and true or conf.visual
    if visiable and club.parent and club.parent ~= 0 then
        local parent = base_clubs[club.parent]
        visiable = visiable and is_template_visiable(parent,template)
    end
    return visiable
end

function utils.get_visiable_club_templates(club,getter_role)
    local tids = club_template[club.id]
    return table.series(tids,function(_,tid)
        local template = table_template[tid]
        local visiable = is_template_visiable(club,template)
        if  visiable or
            getter_role == enum.CRT_BOSS or
            getter_role == enum.CRT_ADMIN
        then
            return template
        end
    end)
end

function utils.get_club_tables(club,team_template_ids)
    if not club then return {} end

    local table_ids = club_table[club.id] or {}

    local room_table = {}
    for tid in pairs(table_ids) do
        repeat
            local tb = base_private_table[tid]
            if not tb then break end
            local room_id = tb.room_id
            if not room_id then break end
            if #team_template_ids ~= 0 and not team_template_ids[tb.template] then break end
            room_table[room_id] = room_table[room_id] or {}
            table.insert(room_table[room_id],tid)
        until true
    end

    local tables = {}

    for room_id,tids in pairs(room_table) do
        local tb_infos = channel.call("game."..room_id,"msg","GetTableStatusInfos",tids)
        for _,info in pairs(tb_infos) do
            table.insert(tables,info)
        end
    end

    return tables
end

local function team_branch_member(c,team_id)
    local cid = c.id
    local guids = {}
    for guid,_ in pairs(club_partner_member[cid][team_id] or {}) do
        tinsert(guids,guid)
        if club_role[cid][guid] == enum.CRT_PARTNER then
            guids = table.union(guids,team_branch_member(c,guid))
        end
    end
    return guids
end

local function transfer_money(club,from_guid,to_guid,money,reason)
    local money_id = club_money_type[club.id]
    local allmoney = player_money[from_guid][money_id]
    money = money or allmoney
    if allmoney < money then
        log.error("transfer_money leak %s < %s",allmoney,money)
        return
    end
    club:incr_member_money(from_guid,-money,reason)
    club:incr_member_money(to_guid,money,reason)
    return true
end

function utils.import_union_player_from_group(from,to)
    local root = utils.root(to)
    local members = club_member[from.id]
    local guids = table.series(members or {},function(_,guid)
        if not utils.is_recursive_in_club(root,guid) then
            return guid
        end
    end)

    to:batch_join(guids)
    return true
end

function utils.import_team_branch_member(from,to,team_id)
    local failed_info = {}
    local fid = from.id
    local tid = to.id
    local money_id_from = club_money_type[fid]
    local money_id_to = club_money_type[tid]
    local money_from = club_team_money[fid][team_id] or 0
    local money_to = player_money[team_id][money_id_to] or 0
    if money_to < money_from then
        return enum.ERROR_LESS_GOLD,{err = "所在目标联盟金币不足!"}
    end

    local function in_game_count(members)
        local c = 0
        local failed = {}

        table.foreach(members,function (_,guid)
            local og = onlineguid[guid]
            if og and og.table then 
                local tinfo = base_private_table[og.table]
                if  tinfo and (tinfo.club_id == fid or tinfo.club_id == tid) then 
                    failed[guid] = (failed[guid] or 0) | enum.IEC_IN_GAME
                    c = c + 1
                end 
            end
        end)

        return c,failed
    end

    local from_members = table.map(team_branch_member(from,team_id),function(guid) return guid,true end)
    local to_members = table.map(team_branch_member(to,team_id),function (guid) return guid,true end)
    local both_members = table.merge(from_members,to_members,function(l,r) return l or r end)
    local c,failed_info = in_game_count(both_members)
    if c > 0 then
        log.info("import_team_branch_member  from[%d] to[%d] team_id[%d] in_game_count[%d]",fid,tid,team_id,c) 
        log.dump(failed_info,"failed_info")
        return enum.GAME_SERVER_RESULT_IN_GAME, {err = "源/目标 联盟有玩家正在游戏中!",failed_info = failed_info}
    end

    local function take_snapshot(team,snapshot)
        snapshot.role = enum.CRT_PARTNER
        snapshot.member = snapshot.member or {}
        snapshot.guid = team

        local member = snapshot.member

        for guid in pairs(club_partner_member[fid][team] or {}) do
            local role = club_role[fid][guid]
            if role == enum.CRT_PARTNER then
                member[guid] = member[guid] or {}
                take_snapshot(guid,member[guid])
            else
                member[guid] = {money = player_money[guid][money_id_from] or 0}
            end
        end
        from:exchange_team_commission(team,-1)
        snapshot.money = player_money[team][money_id_from] or 0
    end

    local team_snapshot = {}
    take_snapshot(team_id,team_snapshot)

    local to_club_members = club_member[tid]
    local to_member_partner = club_member_partner[tid]
    local to_club_role = club_role[tid][nil]
    local to_money_id = club_money_type[tid]
    local from_money_id = club_money_type[fid]
    local function execute(snapshot)
        local count = 0 
        local failed = {}
        local scount = 0 
        local success = {}
        local team = snapshot.guid
        table.foreach(snapshot.member or {},function(c,guid) 
            local money = c.money or 0
            local frole = c.role
            if frole == enum.CRT_PARTNER then
                if not to_club_members[guid] then
                    to:full_join(guid,team_id,team)
                    club_partner:create(tid,guid,team)

                    success[guid] = money
                    scount = scount + 1

                    if money ~= 0 then
                        transfer_money(to,team_id,guid,money,enum.LOG_MONEY_OPT_TYPE_RECHAGE_MONEY_IN_CLUB)
                    end
    
                    local failed_count,team_failed,success_count,team_success = execute(c)
                    count = count + failed_count
                    table.mergeto(failed,team_failed,function(l,r) return (l or 0) | (r or 0) end)
                    
                    table.mergeto(success,team_success)
                    scount = scount + success_count

                    local fmoney = player_money[guid][from_money_id]
                    if fmoney ~= 0 then
                        transfer_money(from,guid,team_id,money,enum.LOG_MONEY_OPT_TYPE_CASH_MONEY_IN_CLUB)
                    end
                    if failed_count == 0 then
                        from:full_exit(guid,team)
                    end
                else
                    count = count + 1
                    local trole = to_club_role[guid]
                    if trole ~= frole then
                        failed[guid] = (failed[guid] or 0) | enum.IEC_ROLE
                        return
                    end
                    local tpartner = to_member_partner[guid]
                    if tpartner ~= team then
                        failed[guid] = (failed[guid] or 0) | enum.IEC_PARTNER
                        return
                    end

                    local failed_count,team_failed,success_count,team_success = execute(c)
                    count = count + failed_count
                    table.mergeto(failed,team_failed,function(l,r) return (l or 0) | (r or 0) end)

                    table.mergeto(success,team_success)
                    scount = scount + success_count
                end
                return 
            end

            if to_club_members[guid] then
                local trole = to_club_role[guid]
                if trole ~= frole then
                    failed[guid] = (failed[guid] or 0) | enum.IEC_ROLE | enum.IEC_IN_CLUB        
                end

                local tpartner = to_member_partner[guid]
                if tpartner ~= team then
                    failed[guid] = (failed[guid] or 0) | enum.IEC_PARTNER | enum.IEC_IN_CLUB
                end
                count = count + 1
                return 
            end
            
            success[guid] = money
            scount = scount + 1

            to:full_join(guid,team_id,team)
            if money ~= 0 then
                transfer_money(to,team_id,guid,money,enum.LOG_MONEY_OPT_TYPE_RECHAGE_MONEY_IN_CLUB)
            end

            if money ~= 0 then
                transfer_money(from,guid,team_id,money,enum.LOG_MONEY_OPT_TYPE_CASH_MONEY_IN_CLUB)
            end

            from:full_exit(guid,team)
        end)
        return count,failed,scount,success
    end

    local failed_count,failed_info,success_count,success_info = execute(team_snapshot)
    log.info("import_team_branch_member from[%d] to[%d] team_id[%d] success_count[%d] failed_count[%d] ",fid,tid,team_id,success_count,failed_count) 
    log.dump(success_info,"success_info")
    log.dump(failed_info,"failed_info")
  

    club_member[fid] = nil
    club_member_partner[fid] = nil
    club_partner_member[fid] = nil
    club_role[fid] = nil
    club_member[tid] = nil
    club_member_partner[tid] = nil
    club_partner_member[tid] = nil
    club_role[tid] = nil

    return  enum.ERROR_NONE,{err = "执行完成!",failed_info = failed_info,}
end

function utils.is_recursive_in_club(club,guid)
    if not club or not guid then return end
    return club_member[club.id][guid] or 
        table.Or(club_team[club] or {},function(_,teamid)
            return utils.is_recursive_in_club(base_clubs[teamid],guid)
        end)
end

function utils.is_recursive_in_team(club,team_id,guid)
    if not club or not guid or not team_id then 
        return
    end

    local parent = club_member_partner[club.id][guid]
    while parent and parent ~= 0 do
        if parent == team_id then
            return true
        end

        parent = club_member_partner[club.id][parent]
    end
end

function utils.rand_union_club_id()
    local id_begin = (math.random(10) > 5 and 6 or 8) * 10000000
    local id_end = id_begin + 9999999
    local id
    local exists
    for _ = 1,1000 do
        id = math.random(id_begin,id_end)
        exists = reddb:sismember("club:all",id)
        if not exists then
            return id
        end
    end
end

function utils.rand_group_club_id()
    local id_begin = (math.random(10) > 5 and 6 or 8) * 100000
    local id_end = id_begin + 99999
    local id
    local exists
    for _ = 1,1000 do
        id = math.random(id_begin,id_end)
        exists = reddb:sismember("club:all",id)
        if not exists then
            return id
        end
    end
end

local function member_money_sum(c,money_id)
    return table.sum(club_member[c.id] or {},function(_,mid)
        return player_money[mid][money_id] or 0
    end)
end

function utils.deep_member_money_sum(c,money_id)
    local sum = member_money_sum(c,money_id) + (club_money[c.id][money_id] or 0) + (club_commission[c.id] or 0)
    local teamids = club_team[c.id]
    return sum + table.sum(teamids,function(_,teamid)
        local team = base_clubs[teamid]
        return team or utils.deep_member_money_sum(team) or 0
    end)
end

function utils.is_in_gaming(guid,club_id)
    local og = onlineguid[guid]
    if not og or not og.table then return end
    local tinfo = base_private_table[og.table]
    return tinfo and (not club_id or tinfo.club_id == club_id)
end

local function is_member_in_gaming(c)
    if not c then return false end
    return table.Or(club_member[c.id] or {},function(_,guid)
        return utils.is_in_gaming(guid,c.id)
    end)
end

function utils.deep_is_member_in_gaming(c,money_id)
    local gaming = is_member_in_gaming(c)
    if gaming then return true end
    local teamids = club_team[c.id]
    return table.Or(teamids,function(_,teamid)
        local team = base_clubs[teamid]
        return team and utils.deep_is_member_in_gaming(team,money_id)
    end)
end

function utils.deep_dismiss_club(c,money_id)
    local teamids = club_team[c.id]
    if not teamids or table.nums(teamids) == 0 then
        c:dismiss()
        if c.parent and c.parent ~= 0 then
            local role = club_role[c.parent][c.owner]
            if role == enum.CRT_PARTNER then
                reddb:hdel(string.format("club:role:%d",c.parent),c.id)
                club_role[c.parent][c.owner] = nil
            end
        end
    end

    return table.foreach(teamids,function(_,teamid)
        local team = base_clubs[teamid]
        return team and utils.deep_dismiss_club(team,money_id)
    end)
end

function utils.calc_club_template_commission_rate(club,template)
    if not club or not club.parent or club.parent == 0 then
        return 1
    end

    local conf = utils.get_real_club_template_conf(club,template)
    if not conf then
        return 0
    end

    local rate = (conf and conf.commission_rate or 0) / 10000
    if rate == 0 then
        return rate
    end

    return rate * utils.calc_club_template_commission_rate(base_clubs[club.parent],template)
end

function utils.get_real_club_template_conf(club,template)
    local conf = club_template_conf[club.id][template.template_id]
    if not conf then
        club = base_clubs[club.parent]
        if not club then return end
        conf = club_team_template_conf[club.id][template.template_id]
        if not conf then return end
    end

    return conf
end

function utils.get_template_commission_conf(club_id,template_id,team_id)
    local conf = club_partner_template_commission[club_id][template_id][team_id]
    if not conf or table.nums(conf) == 0 then
        
        local partner_commission_conf = club_partner_commission_conf[club_id][team_id]
        conf = partner_commission_conf and partner_commission_conf.commission or nil

        if not conf or table.nums(conf) == 0 then

            local parent = club_member_partner[club_id][team_id]
            if not parent or parent == 0 then
                return nil
            end
            conf = club_partner_template_default_commission[club_id][template_id][parent]
            
            if not conf or table.nums(conf) == 0 then
                local parent_conf = club_partner_conf[club_id][parent]
                conf = parent_conf and parent_conf.commission or nil
            end
        end 
    end

    return conf
end

function utils.get_partner_commission_conf(club_id,partner_id)
    local partner_commission_conf = club_partner_commission_conf[club_id][partner_id]

    local conf = partner_commission_conf and partner_commission_conf.commission or nil
    if not conf or table.nums(conf) == 0 then

        local parent = club_member_partner[club_id][partner_id]
        if not parent or parent == 0 then
            return {}
        end
        local parent_conf = club_partner_conf[club_id][parent]
        conf = parent_conf and parent_conf.commission or {}
    end
    return conf
end

function utils.get_template_commission_fixed(club_id,template_id,team_id)
    local conf = utils.get_template_commission_conf(club_id,template_id,team_id)
    if not conf then
        return {}
    end

    if conf.percent then
        return nil
    end

    return conf
end

function utils.get_template_commission_percentage(club_id,template_id,team_id)
    local conf = utils.get_template_commission_conf(club_id,template_id,team_id)
    if not conf then
        return 0
    end

    if not conf.percent then
        return nil
    end

    return tonumber(conf.percent) / 10000
end

function utils.role_team_id(club,guid)
    club = type(club) == "number" and base_clubs[club] or club
    local role = club_role[club.id][guid]
    if role == enum.CRT_ADMIN then
        return club.owner
    end

    if role == enum.CRT_BOSS or role == enum.CRT_PARTNER then
        return guid
    end
end

function utils.team_tree(club_id,leavesguid)
    local root
    local teams = {}
    for _,guid in pairs(leavesguid) do
        local lastteam = guid
        teams[lastteam] = teams[lastteam] or {}
        local team = club_member_partner[club_id][guid]
        while team and team ~= 0 do
            teams[team] = teams[team] or {}
            teams[team][lastteam] = teams[lastteam] or {}
            lastteam = team
            team = club_member_partner[club_id][team]
        end

        root = root or teams[lastteam]
    end

    return {
        root = teams[root]
    }
end

function utils.father_tree(club_id,guids)
    local fathers = {}
    for _,guid in pairs(guids) do
        local f = guid
        while f and f ~= 0 do
            if fathers[f] then break end
            local tf = club_member_partner[club_id][f]
            fathers[f] = tf
            f = tf
        end
    end

    return fathers
end

function utils.father_branch(club_id,fathers,guid)
    local branch = {}
    local f
    local myrole = club_role[club_id][guid]
    if myrole == enum.CRT_PARTNER or myrole == enum.CRT_BOSS then
        f = guid
    else
        f = fathers[guid]
    end
    while f and f ~= 0 do
        tinsert(branch,1,f)
        f = fathers[f]
    end
    return branch
end

function utils.team_branch(club_id,guid)
    local team_ids = {}
    local role = club_role[club_id][guid]
    if role == enum.CRT_BOSS or role == enum.CRT_PARTNER then
        table.insert(team_ids,1,guid)
    end

    local team_id = club_member_partner[club_id][guid]
    while team_id and team_id ~= 0 do
        table.insert(team_ids,1,team_id)
        team_id = club_member_partner[club_id][team_id]
    end

    return team_ids
end

function utils.roulette_commission(conf,tax)
    table.sort(conf,function(l,r)
        return l.range < r.range
    end)

    local s0 = 0
    for _,s in pairs(conf) do
        if tax > s0 and tax <= s.range then
            return s.value
        end

        s0 = s.range
    end

    return 0
end

function utils.percentage_commission(conf,commission)
	local rate = conf and (tonumber(conf.percent) or 0) / 10000 or 0
	return math.floor(rate * commission)
end

function utils.fixed_commission(conf,commission)
	conf = (conf and not conf.percent) and conf or {}
	local value = utils.roulette_commission(conf,commission)
	if value > commission then value = commission end
	return value
end

function utils.team_commission(conf,commission,percentage)
	if percentage then
		return utils.percentage_commission(conf,commission) or 0
	else
		return utils.fixed_commission(conf,commission) or 0
	end
end

function utils.get_team_template_ids(club_id,guid,role)
    local team_template_ids ={}
    
    if role == enum.CRT_PARTNER then
        team_template_ids = club_team_template[club_id][guid]
    elseif role == enum.CRT_PLAYER then
        local partner_id = club_member_partner[club_id][guid]
        local partner_role = club_role[club_id][partner_id] or enum.CRT_PLAYER
        if partner_role == enum.CRT_PARTNER or  partner_role == enum.CRT_BOSS then
            team_template_ids = club_team_template[club_id][partner_id]
        end 
    end  
    return team_template_ids
end

return utils