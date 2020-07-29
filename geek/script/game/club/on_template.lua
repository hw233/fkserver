local onlineguid = require "netguidopt"
local enum = require "pb_enums"
local base_clubs = require "game.club.base_clubs"
local base_players = require "game.lobby.base_players"
local log = require "log"
local club_template_conf = require "game.club.club_template_conf"
local club_team_template_conf = require "game.club.club_team_template_conf"
local club_member = require "game.club.club_member"
local club_role = require "game.club.club_role"
local club_template = require "game.club.club_template"
local table_template = require "game.lobby.table_template"
local club_partners = require "game.club.club_partners"
local club_partner_template_commission = require "game.club.club_partner_template_commission"
local club_member_partner = require "game.club.club_member_partner"
local club_partner_template_default_commission = require "game.club.club_partner_template_default_commission"
local redisopt = require "redisopt"


local reddb = redisopt.default


local function get_real_partner_template_commission_rate(club_id,template_id,partner_id)
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

local function recusive_get_club_templates(club)
    if not club then return end

    local templates = {}
    for tid,_ in pairs(club_template[club.id]) do
        local template = table_template[tid]
        if template then
            table.insert(templates,template)
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
    local partner_id = msg.partner_id

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_GET_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_CLUB_NOT_FOUND
        })
        return
    end
    
    if not club_member[club_id][guid] then
        onlineguid.send(guid,"S2C_GET_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_PLAYER_NO_RIGHT
        })
        return
    end

    local role = club_role[club_id][guid]
    if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS and role ~= enum.CRT_PARTNER then 
        onlineguid.send(guid,"S2C_GET_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_PLAYER_NO_RIGHT
        })
        return
    end

    guid = role == enum.CRT_ADMIN and club.owner or guid
    if role == enum.CRT_PARTNER and not club_partners[club_id][guid] then
        onlineguid.send(guid,"S2C_GET_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_PLAYER_NO_RIGHT
        })
        return
    end
    
    local confs = {}
    local template_id = msg.template_id
    if not template_id or template_id == 0 then
        local templates = recusive_get_club_templates(club)
        for _,template in pairs(templates) do
            table.insert(confs,{
                template_id = template.template_id,
                partner_id = partner_id,
                my_commission_rate = get_real_partner_template_commission_rate(club_id,template.template_id,guid),
                team_commission_rate = get_real_partner_template_commission_rate(club_id,template.template_id,partner_id),
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
            my_commission_rate = get_real_partner_template_commission_rate(club_id,template.template_id,guid),
            team_commission_rate = get_real_partner_template_commission_rate(club_id,template.template_id,partner_id),
        })
    end

    onlineguid.send(guid,"S2C_GET_CLUB_TEMPLATE_COMMISSION",{
        result = enum.ERROR_NONE,
        club_id = club_id,
        partner_id = partner_id,
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
    if not conf then 
        onlineguid.send(guid,"S2C_CONFIG_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_OPERATION_INVALID
        })
        return
    end

    local club_id = msg.club_id
    local template_id = conf.template_id
    local partner_id = conf.partner_id

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_CONFIG_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_CLUB_NOT_FOUND
        })
        return
    end

    if not club_member[club_id][guid] then
        onlineguid.send(guid,"S2C_CONFIG_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_PLAYER_NO_RIGHT
        })
        return
    end

    local role = club_role[club_id][guid]
    if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS and role ~= enum.CRT_PARTNER then
        onlineguid.send(guid,"S2C_CONFIG_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_PLAYER_NO_RIGHT
        })
        return
    end

    guid = role == enum.CRT_ADMIN and club.owner or guid

    if role == enum.CRT_PARTNER and not club_partners[club_id][partner_id] then
        onlineguid.send(guid,"S2C_CONFIG_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_PARAMER_ERROR
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

    local my_commission_rate = get_real_partner_template_commission_rate(club_id,template.template_id,guid)

    if not conf.team_commission_rate or conf.team_commission_rate > 10000 or conf.team_commission_rate < 0 or my_commission_rate < conf.team_commission_rate then
        log.error("on_cs_config_club_template_commission illegal template [%d].",template_id)
        onlineguid.send(guid,"S2C_CONFIG_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERORR_PARAMETER_ERROR
        })
        return
    end

    reddb:hmset(string.format("club:template:commission:%s:%s",club_id,template_id),{
        [partner_id] = conf.team_commission_rate,
    })

    onlineguid.send(guid,"S2C_CONFIG_CLUB_TEMPLATE_COMMISSION",{
        result = enum.ERROR_NONE,
        club_id = club_id,
        conf = {
            partner_id = partner_id,
            template_id = template_id,
            team_commission_rate = conf.team_commission_rate,
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
    if not conf then
        onlineguid.send(guid,"S2C_CONFIG_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_OPERATION_INVALID
        })
        return
    end

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
            result = enum.ERROR_NOT_MEMBER
        })
        return
    end

    local role = club_role[club_id][guid]
    if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS and role ~= enum.CRT_PARTNER then
        onlineguid.send(guid,"S2C_CONFIG_CLUB_TEAM_TEMPLATE",{
            result = enum.ERROR_PLAYER_NO_RIGHT
        })
        return
    end

    guid = role == enum.CRT_ADMIN and club.owner or guid

    local template = table_template[template_id]
    if not template then
        log.error("on_cs_config_club_table_template illegal template.")
        onlineguid.send(guid,"S2C_CONFIG_CLUB_TEAM_TEMPLATE",{
            result = enum.ERORR_PARAMETER_ERROR
        })
        return
    end

    local my_commission_rate = get_real_partner_template_commission_rate(club_id,template.template_id,guid)

    if not conf.team_commission_rate or conf.team_commission_rate > 10000 or conf.team_commission_rate < 0 or my_commission_rate < conf.team_commission_rate then
        log.error("on_cs_config_club_table_template illegal template [%d].",template_id)
        onlineguid.send(guid,"S2C_CONFIG_CLUB_TEAM_TEMPLATE",{
            result = enum.ERORR_PARAMETER_ERROR
        })
        return
    end

    reddb:hset(string.format("club:template:commission:default:%s:%s",club_id,template_id),guid,conf.team_commission_rate)

    onlineguid.send(guid,"S2C_CONFIG_CLUB_TEAM_TEMPLATE",{
        result = enum.ERROR_NONE,
        club_id = club_id,
        conf = {
            team_commission_rate = conf.team_commission_rate,
            template_id = template_id,
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

    local role = club_role[club_id][guid]
    if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS and role ~= enum.CRT_PARTNER then
        onlineguid.send(guid,"S2C_GET_CLUB_TEAM_TEMPLATE_CONFIG",{
            result = enum.ERROR_PLAYER_NO_RIGHT
        })
        return
    end

    guid = role == enum.CRT_ADMIN and club.owner or guid

    local confs = {}
    if not template_id or template_id == 0 then
        local templates = recusive_get_club_templates(club)
        for _,template in pairs(templates) do
            local my_commission_rate = get_real_partner_template_commission_rate(club_id,template.template_id,guid)
            local partner_commission_rate = club_partner_template_default_commission[club_id][template.template_id][guid]
            table.insert(confs,{
                template_id = template.template_id,
                team_commission_rate = partner_commission_rate and partner_commission_rate or 0,
                my_commission_rate = my_commission_rate,
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

        local my_commission_rate = get_real_partner_template_commission_rate(club_id,template.template_id,guid)
        local partner_commission_rate = club_partner_template_default_commission[club_id][template.template_id][guid]
        table.insert(confs,{
            template_id = template.id,
            team_commission_rate = partner_commission_rate and partner_commission_rate or 0,
            my_commission_rate = my_commission_rate,
        })
    end

    onlineguid.send(guid,"S2C_GET_CLUB_TEAM_TEMPLATE_CONFIG",{
        result = enum.ERROR_NONE,
        club_id = club_id,
        confs = confs,
    })
end