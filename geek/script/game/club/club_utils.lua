local base_clubs = require "game.club.base_clubs"
local base_players = require "game.lobby.base_players"
local runtime_conf = require "game.runtime_conf"
local serviceconf = require "serviceconf"
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

local table = table

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

function utils.get_club_tables(club)
    if not club then return {} end
    local ct = club_table[club.id] or {}
    local tables = table.series(ct,function(_,tid)
        local priv_tb = base_private_table[tid]
        if not priv_tb then return end
        local tableinfo = channel.call("game."..priv_tb.room_id,"msg","GetTableStatusInfo",priv_tb.real_table_id)
        return tableinfo
    end)

    return tables
end

function utils.import_union_player_from_group(from,to)
    local root = utils.root(to)
    local members = club_member[from.id]
    local guids = table.series(members or {},function(_,guid)
        if not utils.is_recursive_in_club(root,guid) then
            return guid
        end
    end)

    if table.nums(guids) == 0 then
        return
    end

    to:batch_join(guids)
    return true
end

function utils.is_recursive_in_club(club,guid)
    if not club or not guid then return end
    return club_member[club.id][guid] or 
        table.logic_or(club_team[club] or {},function(_,teamid)
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

    return
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

    return
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

local function is_member_in_gaming(c)
    if not c then return false end
    return table.logic_or(club_member[c.id] or {},function(_,mid)
        local os = onlineguid[mid]
        return os and os.table
    end)
end

function utils.deep_is_member_in_gaming(c,money_id)
    local gaming = is_member_in_gaming(c)
    if gaming then return true end
    local teamids = club_team[c.id]
    return table.logic_or(teamids,function(_,teamid)
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
        local parent = club_member_partner[club_id][team_id]
        if not parent or parent == 0 then
            return nil
        end

        conf = club_partner_template_default_commission[club_id][template_id][parent]
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
        tinsert(branch,1,guid)
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

function utils.seek_commission(conf,tax)
    local s0 = 0
    for _,s in pairs(conf) do
        if tax > s0 and tax <= s.range then
            return s.value
        end

        s0 = s.range
    end

    return 0
end

return utils