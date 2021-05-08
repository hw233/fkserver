local onlineguid = require "netguidopt"
local enum = require "pb_enums"
local base_clubs = require "game.club.base_clubs"
local base_players = require "game.lobby.base_players"
local log = require "log"
local club_member = require "game.club.club_member"
local club_role = require "game.club.club_role"
local club_template = require "game.club.club_template"
local table_template = require "game.lobby.table_template"
local club_partners = require "game.club.club_partners"
local club_partner_template_default_commission = require "game.club.club_partner_template_default_commission"
local club_member_partner = require "game.club.club_member_partner"
local club_utils = require "game.club.club_utils"
local redisopt = require "redisopt"
local json = require "json"
require "functions"

local reddb = redisopt.default

local strfmt = string.format

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

    local template_id = msg.template_id
    local tids
    if template_id and template_id ~= 0 then
        local temp = table_template[template_id]
        if not temp then
            onlineguid.send(guid,"S2C_GET_CLUB_TEMPLATE_COMMISSION",{
                result = enum.ERROR_PARAMETER_ERROR
            })
            return
        end
        tids = {template_id}
    else
        local game_ids = table.map(club_utils.get_game_list(guid,club_id),function(gid) return gid,true end)
        tids = table.select(table.keys(club_template[club_id]),function(tid)
            local template = table_template[tid]
            return game_ids[template.game_id]
        end,true)
    end

    local parent = club_member_partner[club_id][guid]
    local mydefaultrate = (not parent or parent == 0) and 10000 or 0

    local confs = table.series(tids,function(tid)
        local myconf =  club_utils.get_template_commission_conf(club_id,tid,guid)
        local teamconf = club_utils.get_template_commission_conf(club_id,tid,partner_id)
        return {
            template_id = tid,
            partner_id = partner_id,
            my_commission_rate = myconf and myconf.percent or mydefaultrate,
            team_commission_rate = teamconf and teamconf.percent or 0,
            team_commission_conf = (teamconf and not teamconf.percent) and teamconf or nil,
        }
    end)

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

    if club_member_partner[club_id][partner_id] ~= guid then
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
            result = enum.ERROR_PARAMETER_ERROR
        })
        return
    end

    local template = table_template[template_id]
    if not template or not template.rule or not template.rule.union then
        log.error("on_cs_config_club_template_commission illegal template.")
        onlineguid.send(guid,"S2C_CONFIG_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_PARAMETER_ERROR
        })
        return
    end

    local rule = template.rule
    local taxconf = rule and rule.union and rule.union.tax or nil
    if not taxconf then
        onlineguid.send(guid,"S2C_CONFIG_CLUB_TEAM_TEMPLATE",{
            result = enum.ERROR_OPERATION_INVALID
        })
        return
    end

    if taxconf.percentage_commission then
        reddb:hset(strfmt("club:commission:template:%s:%s",club_id,template_id),partner_id,json.encode({
            percent = conf.team_commission_rate
        }))
    else
        reddb:hset(strfmt("club:commission:template:%s:%s",club_id,template_id),partner_id,json.encode(conf.team_commission_conf))
    end

    onlineguid.send(guid,"S2C_CONFIG_CLUB_TEMPLATE_COMMISSION",{
        result = enum.ERROR_NONE,
        club_id = club_id,
        conf = conf,
    })
end

function on_cs_reset_club_teamplate_commission(msg,guid)
    local player = base_players[guid]
    if not player then 
        onlineguid.send(guid,"S2C_RESET_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_PLAYER_NOT_EXIST
        })
        return
    end

    local club_id = msg.club_id
    local team_id = msg.team_id
    local template_id = msg.template_id
    local partner_id = msg.partner_id

    local club = base_clubs[club_id]
    if not club then
        onlineguid.send(guid,"S2C_RESET_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_CLUB_NOT_FOUND
        })
        return
    end

    if not club_member[club_id][guid] then
        onlineguid.send(guid,"S2C_RESET_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_PLAYER_NO_RIGHT
        })
        return
    end

    local role = club_role[club_id][guid]
    if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS and role ~= enum.CRT_PARTNER then
        onlineguid.send(guid,"S2C_RESET_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_PLAYER_NO_RIGHT
        })
        return
    end

    guid = role == enum.CRT_ADMIN and club.owner or guid

    if role == enum.CRT_PARTNER and not club_partners[club_id][partner_id] then
        onlineguid.send(guid,"S2C_RESET_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_PARAMETER_ERROR
        })
        return
    end

    local template = table_template[template_id]
    if not template or not template.rule or not template.rule.union then
        log.error("on_cs_config_club_template_commission illegal template.")
        onlineguid.send(guid,"S2C_RESET_CLUB_TEMPLATE_COMMISSION",{
            result = enum.ERROR_PARAMETER_ERROR
        })
        return
    end

    reddb:hdel(strfmt("club:commission:template:%s:%s",club_id,template_id),partner_id)

    onlineguid.send(guid,"S2C_RESET_CLUB_TEMPLATE_COMMISSION",{
        result = enum.ERROR_NONE,
    })
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
            result = enum.ERROR_PARAMETER_ERROR
        })
        return
    end

    local rule = template.rule
    local taxconf = rule and rule.union and rule.union.tax or nil
    if not taxconf then
        onlineguid.send(guid,"S2C_CONFIG_CLUB_TEAM_TEMPLATE",{
            result = enum.ERROR_OPERATION_INVALID
        })
        return
    end

    if taxconf.percentage_commission then
        reddb:hset(strfmt("club:commission:template:default:%s:%s",club_id,template_id),guid,json.encode({
            percent = conf.team_commission_rate
        }))
    else
        reddb:hset(strfmt("club:commission:template:default:%s:%s",club_id,template_id),guid,json.encode(conf.team_commission_conf))
    end

    onlineguid.send(guid,"S2C_CONFIG_CLUB_TEAM_TEMPLATE",{
        result = enum.ERROR_NONE,
        club_id = club_id,
        conf = conf,
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

    local tids
    if template_id and template_id ~= 0 then
        local template = table_template[template_id]
        if not template then
            onlineguid.send(guid,"S2C_GET_CLUB_TEAM_TEMPLATE_CONFIG",{
                result = enum.ERROR_PARAMETER_ERROR
            })
            return
        end
        tids = {template_id}
    else
        local game_ids = table.map(club_utils.get_game_list(guid,club_id),function(gid) return gid,true end)
        tids = table.select(table.keys(club_template[club_id]),function(tid)
            local template = table_template[tid]
            return game_ids[template.game_id]
        end,true)
    end

    local parent = club_member_partner[club_id][guid]
    local mydefaultrate = (not parent or parent == 0) and 10000 or 0
    
    local confs = table.series(tids,function(tid)
        local myconf = club_utils.get_template_commission_conf(club_id,tid,guid)
        local teamconf = club_partner_template_default_commission[club_id][tid][guid]
        return {
            template_id = tid,
            my_commission_rate = myconf and myconf.percent or mydefaultrate,
            team_commission_rate = teamconf and teamconf.percent or 0,
            team_commission_conf = (teamconf and not teamconf.percent) and teamconf or nil,
        }
    end)

    onlineguid.send(guid,"S2C_GET_CLUB_TEAM_TEMPLATE_CONFIG",{
        result = enum.ERROR_NONE,
        club_id = club_id,
        confs = confs,
    })
end

