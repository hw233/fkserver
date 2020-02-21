
local dbopt =  require "dbopt"
local log = require "log"
local enum = require "pb_enums"

function on_sd_create_club(msg)
    dump(msg)
    local club_info = msg.info
    local money_info = msg.money_info
    if not club_info.owner or not club_info.id then
        log.error("on_sd_create_club invalid id or owner,id:%s,owner:%s",club_info.id,club_info.owner)
        return
    end

    local gamedb = dbopt.game

    local res 
    if club_info.parent and club_info.parent ~= 0 then
        res = gamedb:query("SELECT * FROM t_club WHERE id = %d;",club_info.parent)
        if res.errno then
            log.error("on_sd_create_club query parent error:%d,%s",res.errno,res.err)
            return
        end
    end

    gamedb:query("SET NAMES = utf8;")
    gamedb:query("SET AUTOCOMMIT = 0;")

    local transqls = {
        "BEGIN;",
        string.format([[INSERT INTO t_club(id,name,owner,icon,type,parent) SELECT %d,'%s',%d,'%s',%d,%d 
                        WHERE EXISTS (SELECT * FROM t_player WHERE guid = %d);]],
                    club_info.id,club_info.name,club_info.owner,club_info.icon,club_info.type,club_info.parent,club_info.owner),
        string.format("INSERT INTO t_club_money(club,money_id,money) VALUES(%d,%d,0);",club_info.id,money_info.id),
        string.format("INSERT INTO t_club_member(club,guid) VALUES(%d,%d);",club_info.id,club_info.owner),
        string.format([[INSERT INTO t_player_money(guid,money_id,money) SELECT %d,%d,0 
            WHERE NOT EXISTS (SELECT * FROM t_player_money WHERE guid = %d AND money_id = %d);]],
            club_info.owner,money_info.id,club_info.owner,money_info.id),
        string.format("INSERT INTO t_club_money_type(money_id,club) VALUES(%d,%d);",money_info.id,club_info.id),
        "COMMIT;",
    }

    local trans = gamedb:transaction()
    res = trans:execute(table.concat(transqls,"\n"))
    if res.errno then
        log.error("on_sd_create_club transaction sql error:%d,%s",res.errno,res.err)
        trans:rollback()
        return
    end

    return true
end

function on_sd_join_club(msg)
    dump(msg)
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

    res = gamedb:query("SELECT COUNT(*) AS c FROM t_club WHERE id = %d;",msg.club_id)
    if res.errno then
        log.error("on_sd_join_club query player error:%d,%s",res.errno,res.err)
        return
    end

    if res[1].c ~= 1 then
        log.error("on_sd_join_club check club got wrong player count,club:%s",msg.club_id)
        return
    end

    res = gamedb:query([[INSERT INTO t_club_member(club,guid) SELECT %d,%d 
        WHERE NOT EXISTS (SELECT * FROM t_club_member WHERE club = %d AND guid = %d);]],
        msg.club_id,msg.guid,msg.club_id,msg.guid,msg.guid)
    if res.errno then
        log.error("on_sd_join_club INSERT member error:%d,%s",res.errno,res.err)
        return
    end

    res = gamedb:query([[INSERT INTO t_player_money
        (SELECT %d,money_id,0,0 FROM (SELECT * FROM t_club_money_type WHERE club = %d) m
        WHERE NOT EXISTS (SELECT * FROM t_player_money WHERE guid = %d AND money_id = m.money_id));]],
        msg.guid,msg.club_id,msg.guid)
    if res.errno then
        log.error("on_sd_join_club INSERT player_money error:%d,%s",res.errno,res.err)
        return
    end

    return true
end

function on_sd_exit_club(msg)
    local res = dbopt.game:query("DELETE FROM t_club_member WHERE guid = %d AND club = %d;",msg.guid,msg.club_id)
    if res.errno then
        log.error("on_sd_exit_club DELETE member error:%d,%s",res.errno,res.err)
        return
    end

    return true
end

function on_sd_dismiss_club(msg)

end

function on_sd_add_club_member(msg)
    local club_id = msg.club_id
    local guid = msg.guid

    dump(msg)

    dbopt.game:query("INSERT INTO t_club_member(club,guid) VALUES(%d,%d);",club_id,guid)
end

local function incr_club_money(club,money_id,money,why)
	local res = dbopt.game:query("SELECT money FROM t_club_money WHERE club = %d AND money_id = %d;",club,money_id)
	if res.errno then
		log.error("incr_club_money SELECT money error,errno:%d,err:%s",res.errno,res.err)
		return
	end

    local oldmoney = tonumber(res[1].money)
	res = dbopt.game:query("UPDATE t_club_money SET money = money + (%d) WHERE club = %d AND money_id = %d;",money,club,money_id)
	if res.errno then
		log.error("incr_club_money change money error,errno:%d,err:%s",res.errno,res.err)
		return
    end

    res = dbopt.game:query("SELECT money FROM t_club_money WHERE club = %d AND money_id = %d;",club,money_id)
    if res.errno then
		log.error("incr_club_money select new money error,errno:%d,err:%s",res.errno,res.err)
		return
    end

	local newmoney = tonumber(res[1].money)

	res = dbopt.log:query("INSERT INTO log.t_log_money_club(club,money_id,old_money,new_money,opt_type) VALUES(%d,%d,%d,%d,%d)",
        club,money_id,oldmoney,newmoney,why)
    if res.errno then
        log.error("incr_club_money insert log.t_log_money_club error,errno:%d,err:%s",res.errno,res.err)
        return
    end

	return oldmoney,newmoney
end

function on_sd_change_club_money(items,why)
    dump(items)
	local changes = {}
	for _,item in pairs(items) do
		local oldmoney,newmoney = incr_club_money(item.club,item.money_id,item.money,why)
		table.insert(changes,{
			oldmoney = oldmoney,
			newmoney = newmoney,
		})
    end

	return changes
end