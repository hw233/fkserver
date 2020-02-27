local onlineguid = require "netguidopt"
local enum = require "pb_enums"
local base_clubs = require "game.club.base_clubs"
local base_players = require "game.lobby.base_players"
local log = require "log"
local club_template_conf = require "game.club.club_template_conf"
local club_team_template_conf = require "game.club.club_team_template_conf"
local club_member = require "game.club.club_member"
local club_team = require "game.club.club_team"
local club_role = require "game.club.club_role"
local club_template = require "game.club.club_template"
local table_template = require "game.lobby.table_template"
local redisopt = require "redisopt"


local reddb = redisopt.default


local function get_real_club_template_conf(club,template)
    local conf = club_template_conf[club.id][template.template_id]
    if not conf then
        club = base_clubs[club.parent]
        if not club then return end
        conf = club_team_template_conf[club.id][template.template_id]
        if not conf then return end
    end

    return conf
end


local function get_real_club_template_commission_rate(club,template)
    if not club or not club.parent or club.parent == 0 then
        return 1
    end

    local conf = get_real_club_template_conf(club,template)
    if not conf then
        return 0
    end

    local rate = (conf and conf.commission_rate or 0) / 10000
    return rate
end


local function calc_club_template_commission_rate(club,template)
    if not club or not club.parent or club.parent == 0 then
        return 1
    end

    local conf = get_real_club_template_conf(club,template)
    if not conf then
        return 0
    end

    local rate = (conf and conf.commission_rate or 0) / 10000
    if rate == 0 then
        return rate
    end

    return rate * calc_club_template_commission_rate(base_clubs[club.parent],template)
end

local function calc_club_template_commission(club,template)
    if not template or not template.rule or not template.rule.union then
        return 0
    end

    local tax = template.rule.union.tax
    local commission = tax and tax.AA or (tax.big_win[3] and tax.big_win[3][2] or 0)
    local commission_rate = calc_club_template_commission_rate(club,template)
    commission = commission * commission_rate
    return math.floor(commission)
end

local function get_club_team_template_conf(club,template)
    if not club then
        return
    end

    local conf = club_team_template_conf[club.id][template.id]
    if not conf then
        return get_club_team_template_conf(base_clubs[club.parent],template)
    end

    return conf
end

local function recusive_get_club_templates(club,visiable)
    if not club then return end

    local templates = {}
    for tid,_ in pairs(club_template[club.id]) do
        local template = table_template[tid]
        if template then
            if not visiable then
                local teamconf = club_team_template_conf[club.id][tid]
                if not teamconf or teamconf.visual then
                    table.insert(templates,template)
                end
            else
                table.insert(templates,template)
            end
        end
    end

    table.unionto(templates,recusive_get_club_templates(base_clubs[club.parent]) or {})

    return templates
end

function on_cs_get_club_template_commission(msg,guid)
    local player = base_players[guid]
    if not player then 
        onlineguid.send(guid,"S2C_GET_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_PLAYER_NOT_EXIST
        })
        return
    end

    local club_id = msg.club_id
    local team_id = msg.team_id

    if not club_member[club_id][guid] then
        onlineguid.send(guid,"S2C_GET_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_NOT_IS_CLUB_MEMBER
        })
        return
    end

    local role = club_role[club_id][guid]
    if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS then 
        onlineguid.send(guid,"S2C_GET_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_NOT_IS_CLUB_BOSS
        })
        return
    end

    local team = base_clubs[team_id]
    if not team then
        onlineguid.send(guid,"S2C_GET_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_CLUB_NOT_FOUND
        })
        return
    end

    if not club_team[club_id][team_id] then
        onlineguid.send(guid,"S2C_GET_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_NOT_IS_CLUB_MEMBER
        })
        return
    end
    
    local confs = {}
    local template_id = msg.template_id
    if not template_id or template_id == 0 then
        for _,template in pairs(recusive_get_club_templates(team)) do
            dump(template)
            table.insert(confs,{
                template_id = template.template_id,
                commission = calc_club_template_commission(base_clubs[club_id],template),
                commission_rate = get_real_club_template_commission_rate(team,template) * 10000,
            })
        end
    else
        local template = table_template[template_id]
        if not template then
            onlineguid.send(guid,"S2C_GET_CLUB_TEMPLATE_COMMISSION",{
                result = enum.ERORR_PARAMETER_ERROR
            })
            return
        end

        table.insert(confs,{
            template_id = template.id,
            commission = calc_club_template_commission(team,template),
            commission_rate = get_real_club_template_commission_rate(team,template) * 10000,
        })
    end

    onlineguid.send(guid,"S2C_GET_CLUB_TEMPLATE_COMMISSION",{
        result = enum.ERROR_NONE,
        club_id = club_id,
        confs = confs,
    })
end

function on_cs_config_club_template_commission(msg,guid)
    local player = base_players[guid]
    if not player then 
        onlineguid.send(guid,"S2C_CONFIG_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_PLAYER_NOT_EXIST
        })
        return
    end

    local conf = msg.conf
    local club_id = msg.club_id
    local template_id = conf.template_id
    local team_id = conf.team_id

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_CONFIG_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_CLUB_NOT_FOUND
        })
        return
    end

    if not club_member[club_id][guid] then
        onlineguid.send(guid,"S2C_CONFIG_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_NOT_IS_CLUB_BOSS
        })
        return
    end

    local role = club_role[club_id][guid]
    if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS then
        onlineguid.send(guid,"S2C_CONFIG_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_NOT_IS_CLUB_BOSS
        })
        return
    end

    if not club_team[club_id][team_id] then
        onlineguid.send(guid,"S2C_CONFIG_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_NOT_IS_CLUB_MEMBER
        })
        return
    end

    local template = table_template[template_id]
    if not template or not template.rule or not template.rule.union then
        log.error("on_cs_config_club_template_commission illegal template.")
        onlineguid.send(guid,"S2C_CONFIG_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERORR_PARAMETER_ERROR
        })
        return
    end

    if not conf.commission_rate or conf.commission_rate > 10000 or conf.commission_rate < 0 then
        log.error("on_cs_config_club_template_commission illegal template [%d].",template_id)
        onlineguid.send(guid,"S2C_CONFIG_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERORR_PARAMETER_ERROR
        })
    end

    reddb:hmset(string.format("conf:%d:%d",team_id,template_id),{
        template_id = template_id,
        club_id = team_id,
        commission_rate = conf.commission_rate,
    })

    club_template_conf[team_id][template_id] = nil

    onlineguid.send(guid,"S2C_CONFIG_CLUB_TEMPLATE_COMMISSION",{
        result = enum.ERROR_NONE,
        club_id = club_id,
        conf = {
            team_id = team_id,
            template_id = template_id,
            commission_rate = conf.commission_rate,
        },
    })

    return
end

function on_cs_config_club_team_template(msg,guid)
    local player = base_players[guid]
    if not player then 
        onlineguid.send(guid,"S2C_CONFIG_CLUB_TEAM_TEMPLATE",{
            result = enum.ERROR_PLAYER_NOT_EXIST
        })
        return
    end

    local conf = msg.conf
    local club_id = msg.club_id
    local template_id = conf.template_id

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_CONFIG_CLUB_TEAM_TEMPLATE",{
            result = enum.ERROR_CLUB_NOT_FOUND
        })
        return
    end

    if not club_member[club_id][guid] then
        onlineguid.send(guid,"S2C_CONFIG_CLUB_TEAM_TEMPLATE",{
            result = enum.ERROR_NOT_IS_CLUB_BOSS
        })
        return
    end

    local role = club_role[club_id][guid]
    if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS then
        onlineguid.send(guid,"S2C_CONFIG_CLUB_TEAM_TEMPLATE",{
            result = enum.ERROR_NOT_IS_CLUB_BOSS
        })
        return
    end

    local template = table_template[template_id]
    if not template then
        log.error("on_cs_config_club_table_template illegal template.")
        onlineguid.send(guid,"S2C_CONFIG_CLUB_TEAM_TEMPLATE",{
            result = enum.ERORR_PARAMETER_ERROR
        })
        return
    end

    if not conf.commission_rate or conf.commission_rate > 10000 or conf.commission_rate < 0 then
        log.error("on_cs_config_club_table_template illegal template [%d].",template_id)
        onlineguid.send(guid,"S2C_CONFIG_CLUB_TEAM_TEMPLATE",{
            result = enum.ERORR_PARAMETER_ERROR
        })
    end

    reddb:hmset(string.format("team_conf:%d:%d",club_id,template_id),{
        club_id = club_id,
        template_id = template_id,
        visual = conf.visual,
        commission_rate = conf.commission_rate,
    })

    club_team_template_conf[club_id][template_id] = nil

    onlineguid.send(guid,"S2C_CONFIG_CLUB_TEAM_TEMPLATE",{
        result = enum.ERROR_NONE,
        club_id = club_id,
        conf = {
            commission_rate = conf.commission_rate,
            template_id = template_id,
            visual = conf.visual,
        },
    })
end

function on_cs_get_club_team_template_conf(msg,guid)
    local player = base_players[guid]
    if not player then 
        onlineguid.send(guid,"S2C_GET_CLUB_TEAM_TEMPLATE_CONFIG",{
            result = enum.ERROR_PLAYER_NOT_EXIST
        })
        return
    end

    local club_id = msg.club_id
    local template_id = msg.template_id
    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_GET_CLUB_TEAM_TEMPLATE_CONFIG",{
            result = enum.ERROR_CLUB_NOT_FOUND
        })
        return
    end

    local confs = {}
    if not template_id or template_id == 0 then
        local templates = recusive_get_club_templates(club,true)
        dump(templates)
        for _,template in pairs(templates) do
            local teamconf = club_team_template_conf[club.id][template.template_id]
            table.insert(confs,{
                template_id = template.template_id,
                commission = calc_club_template_commission(club,template),
                commission_rate = teamconf and teamconf.commission_rate or 0,
                visual = true,
            })
        end
    else
        local template = table_template[template_id]
        if not template then
            onlineguid.send(guid,"S2C_GET_CLUB_TEAM_TEMPLATE_CONFIG",{
                result = enum.ERORR_PARAMETER_ERROR
            })
            return
        end

        table.insert(confs,{
            template_id = template.id,
            commission = calc_club_template_commission(club,template),
            commission_rate = get_real_club_template_commission_rate(club,template),
        })
    end

    onlineguid.send(guid,"S2C_GET_CLUB_TEAM_TEMPLATE_CONFIG",{
        result = enum.ERROR_NONE,
        club_id = club_id,
        confs = confs,
    })
end