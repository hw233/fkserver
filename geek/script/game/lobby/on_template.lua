local enum = require "pb_enums"
local base_clubs = require "game.club.base_clubs"
local club_memeber = require "game.club.club_member"
local table_template = require "game.lobby.table_template"
local onlineguid = require "netguidopt"
local club_role = require "game.club.club_role"
local json = require "cjson"
local log = require "log"

function on_cs_create_table_template(msg,guid)
    local club_template = msg.template
    if not club_template or not club_template.club_id then
        onlineguid.send(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERORR_PARAMETER_ERROR
        })
        return
    end

    local club = base_clubs[club_template.club_id]
    if not club then
        onlineguid.send(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERROR_CLUB_NOT_FOUND
        })
    end

    if not club_memeber[club_template.club_id][guid] then
        onlineguid.send(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERROR_NOT_IS_CLUB_MEMBER
        })
        return
    end

    local template  = club_template.template

    local ret,info = club:create_table_template(template.game_id,template.description,template.rule,template.advanced_rule)
    onlineguid.send(guid,"S2C_EDIT_TABLE_TEMPLATE",{
        result = ret,
        template = {
            club_id = club_template.club_id,
            template = info,
        },
    })
end

function on_cs_remove_table_template(msg,guid)
    local club_template = msg.template
    if not club_template then
        onlineguid.send(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERORR_PARAMETER_ERROR
        })
        return
    end

    local template = club_template.template
    local template_id = template and template.template_id or nil
    if not template or not template_id then
        onlineguid.send(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERORR_PARAMETER_ERROR
        })
        return
    end

    if not table_template[template_id] then
        onlineguid.send(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERROR_TABLE_TEMPLATE_NOT_FOUND
        })
        return
    end

    local club = base_clubs[club_template.club_id]
    if not club then
        onlineguid.send(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERROR_CLUB_NOT_FOUND
        })
        return
    end

    if not club_memeber[club_template.club_id][guid] then
        onlineguid.send(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERROR_NOT_IS_CLUB_MEMBER
        })
        return
    end

    local ret = club:remove_table_template(template_id)
    onlineguid.send(guid,"S2C_EDIT_TABLE_TEMPLATE",{
        result = ret,
    })
end

function on_cs_modify_table_template(msg,guid)
    local club_template = msg.template
    if not club_template then
        onlineguid.send(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERORR_PARAMETER_ERROR
        })
        return
    end

    local ok,rule = pcall(json.decode,club_template.template.rule or "")
    if not ok then
        onlineguid.send(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERORR_PARAMETER_ERROR
        })
        return
    end

    club_template.template.rule = rule

    local ok,advanced_rule = pcall(json.decode,club_template.template.advanced_rule or "")
    if not ok then
        onlineguid.send(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERORR_PARAMETER_ERROR
        })
        return
    end

    club_template.template.advanced_rule = advanced_rule

    local template_id = club_template.template.template_id
    if not template_id then
        onlineguid.send(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERORR_PARAMETER_ERROR
        })
        return
    end

    local origin_template = table_template[template_id]
    if not origin_template then
        onlineguid.send(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERROR_TABLE_TEMPLATE_NOT_FOUND,
        })
        return
    end

    if club_template.club_id ~= origin_template.club_id then
        onlineguid.send(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERORR_PARAMETER_ERROR,
        })
        return
    end

    local club = base_clubs[club_template.club_id]
    if not club then
        onlineguid.send(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERROR_CLUB_NOT_FOUND
        })
        return
    end

    if not club_memeber[club_template.club_id][guid] then
        onlineguid.send(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERROR_NOT_IS_CLUB_MEMBER
        })
        return
    end

    local role = club_role[club_template.club_id][guid]
    if role ~= enum.CRT_ADMIN and role ~= enum.CRT_BOSS then
        onlineguid.send(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERROR_NOT_IS_CLUB_BOSS
        })
        return
    end

    local template = club_template.template
    local ret,info = club:modify_table_template(template_id,template.game_id,template.description,
            template.rule,template.advanced_rule)
    onlineguid.send(guid,"S2C_EDIT_TABLE_TEMPLATE",{
        result = ret,
        template = {
            template = info,
            club_id = club_template.club_id,
        },
    })
end

function on_cs_edit_table_template(msg,guid)
    local edit_operator = {
        [enum.OPERATION_ADD] = on_cs_create_table_template,
        [enum.OPERATION_DEL] = on_cs_remove_table_template,
        [enum.OPERATION_MODIFY] = on_cs_modify_table_template,
    }

    dump(msg)

    local template = msg.template
    if not template then
        onlineguid.send(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERORR_PARAMETER_ERROR
        })
        return
    end
    
    local op = edit_operator[msg.edit_op]
    if not op then
        log.error("edit table template unknown operator,%s",msg.edit_op)
        return
    end

    op(msg,guid)
end