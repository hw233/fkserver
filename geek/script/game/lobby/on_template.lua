local enum = require "pb_enums"
local base_clubs = require "game.club.base_clubs"
local club_memeber = require "game.club.club_member"
local table_template = require "game.lobby.table_template"
local log = require "log"

function on_cs_create_table_template(msg,guid)
    local template = msg.template
    if not template or not template.club_id then
        send2client_pb(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERORR_PARAMETER_ERROR
        })
        return
    end

    local club = base_clubs[template.club_id]
    if not club then
        send2client_pb(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERROR_CLUB_NOT_FOUND
        })
    end

    if not club_memeber[template.club_id][guid] then
        send2client_pb(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERROR_NOT_IS_CLUB_MEMBER
        })
        return
    end

    local ret,info = club:create_table_template(template.game_id,template.description,template.rule)
    send2client_pb(guid,"S2C_EDIT_TABLE_TEMPLATE",{
        result = ret,
        template = info,
    })
end

function on_cs_remove_table_template(msg,guid)
    if not msg.template then
        send2client_pb(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERORR_PARAMETER_ERROR
        })
        return
    end

    local template_id = msg.template.template_id
    if not template_id then
        send2client_pb(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERORR_PARAMETER_ERROR
        })
        return
    end

    local template = table_template[template_id]
    if not template then
        send2client_pb(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERROR_TABLE_TEMPLATE_NOT_FOUND
        })
        return
    end

    local club = base_clubs[template.club_id]
    if not club then
        send2client_pb(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERROR_CLUB_NOT_FOUND
        })
        return
    end

    if not club_memeber[template.club_id][guid] then
        send2client_pb(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERROR_NOT_IS_CLUB_MEMBER
        })
        return
    end

    local ret = club:remove_table_template(template_id)
    send2client_pb(guid,"S2C_EDIT_TABLE_TEMPLATE",{
        result = ret,
    })
end

function on_cs_modify_table_template(msg,guid)
    local template = msg.template
    if not template then
        send2client_pb(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERORR_PARAMETER_ERROR
        })
        return
    end

    local template_id = template.template_id
    if not template_id then
        send2client_pb(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERORR_PARAMETER_ERROR
        })
        return
    end

    local origin_template = table_template[template_id]
    if not origin_template then
        send2client_pb(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERROR_TABLE_TEMPLATE_NOT_FOUND,
        })
        return
    end

    if template.club_id ~= origin_template.club_id then
        send2client_pb(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERORR_PARAMETER_ERROR,
        })
        return
    end

    local club = base_clubs[template.club_id]
    if not club then
        send2client_pb(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERROR_CLUB_NOT_FOUND
        })
        return
    end

    if not club_memeber[template.club_id][guid] then
        send2client_pb(guid,"S2C_EDIT_TABLE_TEMPLATE",{
            result = enum.ERROR_NOT_IS_CLUB_MEMBER
        })
        return
    end

    local ret,info = club:modify_table_template(template_id,template.game_id,template.description,template.rule)
    send2client_pb(guid,"S2C_EDIT_TABLE_TEMPLATE",{
        result = ret,
        template = info,
    })
end

function on_cs_edit_table_template(msg,guid)
    local edit_operator = {
        [enum.OPERATION_ADD] = on_cs_create_table_template,
        [enum.OPERATION_DEL] = on_cs_remove_table_template,
        [enum.OPERATION_MODIFY] = on_cs_modify_table_template,
    }

    local template = msg.template
    if not template then
        send2client_pb(guid,"S2C_EDIT_TABLE_TEMPLATE",{
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