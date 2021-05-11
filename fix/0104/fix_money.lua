

local enum = require "pb_enums"
local base_clubs = require "game.club.base_clubs"
local onlineguid = require "netguidopt"
local club_member = require "game.club.club_member"
local club_role = require "game.club.club_role"
local pb = require "pb_files"
local club_partner = require "game.club.club_partner"
local club_member_partner = require "game.club.club_member_partner"
local club_partner_commission = require "game.club.club_partner_commission"
local club_money_type = require "game.club.club_money_type"
local club_partner_member = require "game.club.club_partner_member"
local player_money = require "game.lobby.player_money"
local club_partners = require "game.club.club_partners"
local log = require "log"

local getupvalue = require "fix.getupvalue"
local dump = require "fix.dump"

local CLUB_OP = {
    ADD_ADMIN    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","ADD_ADMIN"),
    REMOVE_ADMIN    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","REMOVE_ADMIN"),
    JOIN_AGREED    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","JOIN_AGREED"),
    JOIN_REJECTED    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","JOIN_REJECTED"),
    EXIT_AGREED    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","EXIT_AGREED"),
    APPLY_EXIT    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","APPLY_EXIT"),
    ADD_PARTNER = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","ADD_PARTNER"),
    REMOVE_PARTNER = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","REMOVE_PARTNER"),
    CANCEL_FORBID = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","CANCEL_FORBID"),
    FORBID_GAME = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","FORBID_GAME"),
    BLOCK_CLUB = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","BLOCK_CLUB"),
    UNBLOCK_CLUB    = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","UNBLOCK_CLUB"),
    CLOSE_CLUB = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","CLOSE_CLUB"),
    OPEN_CLUB = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","OPEN_CLUB"),
    DISMISS_CLUB = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","DISMISS_CLUB"),
    BLOCK_TEAM = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","BLOCK_TEAM"),
    UNBLOCK_TEAM = pb.enum("C2S_CLUB_OP_REQ.C2S_CLUB_OP_TYPE","UNBLOCK_TEAM"),
}

local function on_cs_club_partner(msg,guid)
	log.info("on_cs_club_partner %s",guid)
    local club_id = msg.club_id
    local target_guid = msg.target_id
    local res = {
        club_id = club_id,
        target_id = target_guid,
        op = msg.op,
        result = enum.ERROR_NONE,
    }

    local club = base_clubs[club_id]
    if not club then
        res.result = enum.ERROR_CLUB_NOT_FOUND
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end

    if not club_member[club_id][target_guid] then
        res.result = enum.ERROR_NOT_MEMBER
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end

    local role = club_role[club_id][guid]
    if not role or role == enum.CRT_PLAYER then
        res.result = enum.ERROR_PLAYER_NO_RIGHT
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end

    if msg.op == CLUB_OP.ADD_PARTNER then
        local target_role = club_role[club_id][target_guid]
        if target_role == enum.CRT_BOSS or target_role == enum.CRT_PARTNER or target_role == enum.CRT_ADMIN  then
            res.result = enum.ERROR_PLAYER_NO_RIGHT
            onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
            return
        end

        local parent = guid
        if role == enum.CRT_BOSS or role == enum.CRT_ADMIN then
            parent = club.owner
        end

        local result = club_partner:create(club_id,target_guid,parent)
        res.result = result
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end

    if msg.op == CLUB_OP.REMOVE_PARTNER then
        local target_role = club_role[club_id][target_guid]
        if target_role ~= enum.CRT_PARTNER then
            res.result = enum.ERROR_OPERATION_INVALID
            onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
            return
        end

        if target_role == enum.CRT_BOSS or target_role == enum.CRT_ADMIN  then
            res.result = enum.ERROR_PLAYER_NO_RIGHT
            onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
            return
        end

        if role == enum.CRT_PARTNER then
            local parent = club_member_partner[club_id][target_guid]
            while parent do
                if parent == guid then
                    break
                end

                parent = club_member_partner[club_id][parent]
            end

            if not parent then
                res.result = enum.ERROR_PLAYER_NO_RIGHT
                onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
                return
            end
        end
        local is_empty = true   
        local function recursive_sum_member_all_money(c,partner_id)
            local sum = club_partner_commission[c.id][partner_id] or 0
            local money_id = club_money_type[c.id]
            for mem_id,_ in pairs(club_partner_member[c.id][partner_id] or {}) do
                local mrole = club_role[c.id][mem_id]
                if mrole == enum.CRT_PARTNER then
                    sum = sum + recursive_sum_member_all_money(c,mem_id)
                end

                local curplayer_money = player_money[mem_id][money_id]
                sum = sum + curplayer_money
                if  curplayer_money ~= 0 then
                    is_empty = false
                end
            end

            return sum
        end

        local function recursive_dismiss_partner(c,partner_id)
            local partner = club_partners[club_id][partner_id]
            for mem_id,_ in pairs(club_partner_member[c.id][partner_id]) do
                local mrole = club_role[c.id][mem_id]
                if mrole == enum.CRT_PARTNER then
                    local result = recursive_dismiss_partner(c,mem_id)
                    if result ~= enum.ERROR_NONE then
                        return result
                    end
                end
                c:full_exit(mem_id,guid)
            end

            return partner:dismiss()
        end

        if recursive_sum_member_all_money(club,target_guid) > 0 or not is_empty then
            res.result = enum.ERROR_MORE_MAX_LIMIT
            onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
            return
        end

        local result = recursive_dismiss_partner(club,target_guid)
        res.result = result
        onlineguid.send(guid,"S2C_CLUB_OP_RES",res)
        return
    end
end


local msgopt = _P.msg.msgopt
local upval = getupvalue(msgopt.C2S_CLUB_OP_REQ)
local operator = upval.operator
operator[CLUB_OP.ADD_PARTNER] = on_cs_club_partner
operator[CLUB_OP.REMOVE_PARTNER] = on_cs_club_partner
dump(print,upval)
