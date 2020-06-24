local onlineguid = require "netguidopt"
local enum = require "pb_enums"
local club_role = require "game.club.club_role"
local base_notice = require "game.notice.base_notice"
local base_notices = require "game.notice.base_notices"
local club_notice = require "game.notice.club_notice"

function on_cs_publish_notice(msg,guid)
        local notice = msg.notice
        if not notice.club or notice.club == 0 then
                onlineguid.send(guid,"SC_PUBLISH_NOTICE",{
                        result = enum.ERROR_OPERATION_INVALID
                })
                return
        end

        local role = club_role[notice.club][guid]
        if role ~= enum.CRT_ADMIN and role ~= enum.OWNER then
                onlineguid.send(guid,"SC_PUBLISH_NOTICE",{
                        result = enum.ERROR_OPERATION_INVALID
                })
                return
        end

        base_notice.create(notice.type,notice.where,notice.content,notice.club)
        onlineguid.send(guid,"SC_PUBLISH_NOTICE",{
                result = enum.ERROR_NONE
        })
end

local function on_cs_pull_club_notices(club_id,guid)
        local nids = club_notice[club_id]
        local notices = {}
        for nid,_ in pairs(nids) do
                table.insert(notices,base_notices[nid])
        end

        onlineguid.send(guid,"SC_NOTICE_RES",{
                result = enum.ERROR_NONE,
                notices = notices,
        })
end

function on_cs_pull_notices(msg,guid)
        local club_id = msg.club_id
        if club_id and club_id ~= 0 then
                on_cs_pull_club_notices(club_id,guid)
                return
        end

        local notices = {}
        for nid,n in pairs(base_notices["*"] or {}) do
                table.insert(notices,n)
        end

        onlineguid.send(guid,"SC_NOTICE_RES",{
                result = enum.ERROR_NONE,
                notices = notices,
        })
end