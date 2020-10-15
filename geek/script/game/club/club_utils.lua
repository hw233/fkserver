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
    return (parent and utils.root(parent) or club)
end

function utils.level(club,level)
    level = level and level + 1 or 1
    if not club then return level end
    club = type(club) == "table" and club or base_clubs[club]
    local parent = utils.parent(club)
    return parent and utils.level(parent,level) or level
end

function utils.all_game_ids()
	return table.series(channel.query(),function(_,item)
		local id = string.match(item,"game.(%d+)")
		if not id then return end
		id = tonumber(id)
		local sconf = serviceconf[id]
		if not sconf.conf or not sconf.conf.private_conf then return end
		return sconf.conf.first_game_type
	end)
end

function utils.get_game_list(guid,club_id)
    local player = base_players[guid]
	if player then
		local channel_id = player.channel_id
		channel_id = channel_id and channel_id ~= "" and channel_id or "default"

		local promoter = player.promoter
        promoter = promoter and promoter ~= 0 and promoter or nil

		local conf_games = runtime_conf.get_game_conf(channel_id,promoter)
		if conf_games and table.nums(conf_games) > 0 then
			log.dump(conf_games)
			return conf_games
		end

		conf_games = runtime_conf.get_game_conf("default")
		if conf_games and table.nums(conf_games) > 0 then
			log.dump(conf_games)
			return conf_games
		end

		conf_games = utils.all_game_ids()
		if conf_games and table.nums(conf_games) > 0 then
			log.dump(conf_games)
			return conf_games
		end
	end

	return
end

local function get_club_templates(club,getter_role)
    if not club then return {} end

    local ctt = club_template[club.id] or {}
    local templates = table.series(ctt,function(_,tid) return table_template[tid] end)

    table.unionto(templates,get_club_templates(base_clubs[club.parent],getter_role) or {})

    return templates
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
    local templates = get_club_templates(club,getter_role)
    return table.series(templates,function(template)
        local visiable = is_template_visiable(club,template)
        if  visiable or
            getter_role == enum.CRT_BOSS or getter_role == enum.CRT_ADMIN then
            return template
        end
    end)
end

local function get_club_tables(club)
    if not club then return {} end
    local ct = club_table[club.id] or {}
    local tables = table.series(ct,function(_,tid)
        local priv_tb = base_private_table[tid]
        local tableinfo = channel.call("game."..priv_tb.room_id,"msg","GetTableStatusInfo",priv_tb.real_table_id)
        return tableinfo
    end)

    return tables
end

function utils.deep_get_club_tables(club,getter_role)
    local tables = get_club_tables(club,getter_role)
    for teamid,_ in pairs(club_team[club.id]) do
        local team = base_clubs[teamid]
        if team then
            table.unionto(tables,utils.deep_get_club_tables(team,getter_role))
        end
    end

    return tables
end

function utils.import_union_player_from_group(from,to)
    local root = utils.root(to)
    local members = club_member[from.id]
    local guids = table.series(members or {},function(_,guid)
        if not utils.recusive_is_in_club(root,guid) then
            return guid
        end
    end)

    if table.nums(guids) == 0 then
        return
    end

    to:batch_join(guids)
    return true
end

function utils.recusive_is_in_club(club,guid)
    if not club or not guid then return end
    return table.logic_or(club_member[club.id] or {},function(_,pid) return guid == pid end)
        or table.logic_or(club_team[club] or {},function(_,teamid)
            return utils.recusive_is_in_club(base_clubs[teamid],guid)
        end)
end

function utils.rand_union_club_id()
    local id_begin = (math.random(10) > 5 and 6 or 8) * 10000000
    local id_end = id_begin + 9999999
    local id = math.random(id_begin,id_end)
    for _ = 1,1000 do
        if not base_clubs[id] then break end
        id = math.random(id_begin,id_end)
    end

    return id
end

function utils.rand_group_club_id()
    local id_begin = (math.random(10) > 5 and 6 or 8) * 100000
    local id_end = id_begin + 99999
    local id = math.random(id_begin,id_end)
    for _ = 1,1000 do
        if not base_clubs[id] then break end
        id = math.random(id_begin,id_end)
    end

    return id
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
    local gaming = is_member_in_gaming(c,money_id)
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

function utils.recusive_get_club_templates(club)
    if not club then return end

    local templates = table.series(club_template[club.id],function(_,tid) return table_template[tid] end)
    table.unionto(templates,utils.recusive_get_club_templates(base_clubs[club.parent]) or {})

    return templates
end

function utils.get_club_team_template_conf(club,template)
    if not club then
        return
    end

    local conf = club_team_template_conf[club.id][template.id]
    if not conf then
        return utils.get_club_team_template_conf(base_clubs[club.parent],template)
    end

    return conf
end

function utils.calc_club_template_commission(club,template)
    if not template or not template.rule or not template.rule.union then
        return 0
    end

    local function get_bigwin_commission(big_win)
        for _,s in pairs(big_win) do
            if s[2] and s[2] ~= 0 then
                return s[2]
            end
        end

        return 0
    end

    local tax = template.rule.union.tax
    local commission = tax and tax.AA or get_bigwin_commission(tax.big_win)
    local commission_rate = utils.calc_club_template_commission_rate(club,template)
    commission = commission * commission_rate
    return math.floor(commission)
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

function utils.get_real_club_template_commission_rate(club,template)
    if not club or not club.parent or club.parent == 0 then
        return 1
    end

    local conf = utils.get_real_club_template_conf(club,template)
    if not conf then
        return 0
    end

    local rate = (conf and conf.commission_rate or 0) / 10000
    return rate
end


function utils.get_real_partner_template_commission_rate(club_id,template_id,partner_id)
    local commission_rate = club_partner_template_commission[club_id][template_id][partner_id]
    if not commission_rate then
        partner_id = club_member_partner[club_id][partner_id]
        if not partner_id then
            return 10000
        end
        commission_rate = club_partner_template_default_commission[club_id][template_id][partner_id]
    end

    return commission_rate or 0
end

return utils