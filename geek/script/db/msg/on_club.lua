
local dbopt =  require "dbopt"
local log = require "log"
local enum = require "pb_enums"

function on_sd_create_club(msg)
    if not msg.owner or not msg.id then
        log.error("on_sd_create_club invalid id or owner,id:%s,owner:%s",msg.id,msg.owner)
        return
    end

    local gamedb = dbopt.game

    if msg.parent and msg.parent ~= 0 then
        local res = gamedb:query("SELECT * FROM t_club WHERE id = %d;",msg.parent)
        if res.errno then
            log.error("on_sd_create_club query parent error:%d,%s",res.errno,res.err)
            return
        end
    end

    local res = gamedb:query("SELECT COUNT(*) AS c FROM t_player WHERE guid = %d;",msg.owner)
    if res.errno then
        log.error("on_sd_create_club check owner id error:%d,%s",res.errno,res.err)
        return
    end

    if res[1].c ~= 1 then
        log.error("on_sd_create_club check owner got wrong owner count,owner:%s",msg.owner)
        return
    end

    gamedb:query("SET NAMES = utf8;")
    gamedb:query("SET AUTOCOMMIT = 0;")

    local transaction = {
        "BEGIN;",
        string.format("INSERT INTO t_club(id,name,owner,icon,type,parent) VALUES(%d,'%s',%d,'%s',%d,%d);",
                    msg.id,msg.name,msg.owner,msg.icon,msg.type,msg.parent),
        string.format("INSERT INTO t_club_money(id,money_type,money) VALUES(%d,%d,0);",msg.id,enum.ITEM_PRICE_TYPE_GOLD),
        string.format("INSERT INTO t_club_money(id,money_type,money) VALUES(%d,%d,0);",msg.id,enum.ITEM_PRICE_TYPE_ROOM_CARD),
        string.format("INSERT INTO t_club_member(id,guid) VALUES(%d,%d);",msg.id,msg.owner),
        "COMMIT;",
    }

    local trans = gamedb:transaction()
    res = trans:execute(table.concat(transaction,"\n"))
    if res.errno then
        log.error("on_sd_create_club transaction sql error:%d,%s",res.errno,res.err)
        trans:query("ROLLBACK;")
        return
    end

    return true
end

function on_sd_join_club(msg)
    local gamedb = dbopt.game

    local res = gamedb:query("SELECT COUNT(*) AS c FROM t_player WHERE guid = %d;",msg.guid)
    if res.errno then
        log.error("on_sd_join_club query player error:%d,%s",res.errno,res.err)
        return
    end

    if res[1].c ~= 1 then
        log.error("on_sd_join_club check player got wrong player count,guid:%s",msg.guid)
        return
    end

    local res = gamedb:query("SELECT COUNT(*) AS c FROM t_club WHERE id = %d;",msg.club_id)
    if res.errno then
        log.error("on_sd_join_club query player error:%d,%s",res.errno,res.err)
        return
    end

    if res[1].c ~= 1 then
        log.error("on_sd_join_club check club got wrong player count,club:%s",msg.club_id)
        return
    end

    local res = gamedb:query("SELECT COUNT(*) AS c FROM t_club_member WHERE guid = %d AND id = %d;",msg.guid,msg.club_id)
    if res.errno then
        log.error("on_sd_join_club query club member error:%d,%s",res.errno,res.err)
        return
    end

    if res[1].c > 0 then
        log.error("on_sd_join_club check club member exists,club:%s,guid:%s",msg.club_id,msg.guid)
        return
    end

    res = gamedb:query("INSERT INTO t_club_member(id,guid) VALUES(%d,%d);",msg.club_id,msg.guid)
    if res.errno then
        log.error("on_sd_join_club INSERT member error:%d,%s",res.errno,res.err)
        return
    end

    return true
end

function on_sd_exit_club(msg)
    local gamedb = dbopt.game

    local res = gamedb:query("DELETE FROM t_club_member WHERE guid = %d AND id = %d;",msg.guid,msg.club_id)
    if res.errno then
        log.error("on_sd_exit_club DELETE member error:%d,%s",res.errno,res.err)
        return
    end

    return true
end

function on_sd_dismiss_club(msg)

end