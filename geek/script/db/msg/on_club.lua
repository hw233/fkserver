
local dbopt =  require "dbopt"
local log = require "log"
local enum = require "pb_enums"

function on_sd_create_club(msg)
    log.dump(msg)
    local club_info = msg.info
    local money_info = msg.money_info
    if not club_info.owner or not club_info.id then
        log.error("on_sd_create_club invalid id or owner,id:%s,owner:%s",club_info.id,club_info.owner)
        return
    end

    if club_info.parent and club_info.parent ~= 0 then
        local res = dbopt.game:query("SELECT * FROM t_club WHERE id = %d;",club_info.parent)
        if res.errno then
            log.error("on_sd_create_club query parent error:%d,%s",res.errno,res.err)
            return
        end
    end

    local transqls = {
        string.format([[INSERT INTO t_club(id,name,owner,icon,type,parent,created_at,updated_at) VALUES(%s,"%s",%s,"%s",%s,%s,%s,%s);]],
                    club_info.id,club_info.name,club_info.owner,club_info.icon,club_info.type,club_info.parent,os.time(),os.time()),
        string.format([[INSERT INTO t_club_money_type(money_id,club) VALUES(%d,%d);]],money_info.id,club_info.id),
        string.format([[INSERT INTO t_club_money(club,money_id,money) VALUES(%d,%d,0),(%d,0,0);]],club_info.id,money_info.id,club_info.id),
        string.format([[INSERT INTO t_club_member(club,guid) VALUES(%d,%d);]],club_info.id,club_info.owner),
        string.format([[INSERT INTO t_player_money(guid,money_id,money) VALUES(%s,%s,0);]], club_info.owner,money_info.id),
    }

    log.dump(transqls)

    local res = dbopt.game:query(table.concat(transqls,"\n"))
    if res.errno then
        log.error("on_sd_create_club transaction sql error:%d,%s",res.errno,res.err)
        return
    end

    return true
end

function on_sd_join_club(msg)
    log.dump(msg)
    local club_id = msg.club_id
    local guid = msg.guid
    local res = dbopt.game:query("SELECT * FROM t_club_money_type WHERE club = %d;",club_id)
    if res.errno then
        log.error("on_sd_join_club error:%d,%s",res.errno,res.err)
        return
    end

    log.dump(res)

    local money_id = res[1].money_id

    local sqls = {
        string.format([[INSERT INTO t_club_member(club,guid) VALUES(%d,%d);]],club_id,guid),
        string.format([[INSERT INTO t_player_money(guid,money_id,money,`where`) VALUES(%d,%d,0,0);]],guid,money_id),
    }

    log.dump(sqls)

    res = dbopt.game:query(table.concat(sqls,"\n"))
    if res.errno then
        log.error("on_sd_join_club error:%d,%s",res.errno,res.err)
        return
    end

    return true
end

function on_sd_batch_join_club(msg)
    local club_id = msg.club_id
    local guids = msg.guids

    if not club_id or not guids or table.nums(guids) == 0 then
        log.warning("on_sd_batch_join_club parameter is error!")
        return
    end

    local res = dbopt.game:query("SELECT * FROM t_club_money_type WHERE club = %d",club_id)
    if res.errno then
        log.error("on_sd_batch_join_club error:%d,%s",res.errno,res.err)
        return
    end

    local money_id = res[1].money_id

    local sqls = {
        "INSERT INTO t_club_member(club,guid,status) VALUES"..table.concat(table.agg(guids,{},function(tb,guid)
            table.insert(tb,string.format("(%d,%d,0)",club_id, guid))
            return tb
        end),",")..";",
        "INSERT INTO t_player_money(guid,money_id,money,`where`) VALUES"..table.concat(table.agg(guids,{},function(tb,guid)
            table.insert(tb,string.format("(%d,%d,0,0)",guid,money_id))
            return tb
        end),",")..";",
    }

    log.dump(sqls)

    res = dbopt.game:query(table.concat(sqls,"\n"))
    if res.errno then
        log.error("on_sd_batch_join_club error:%d,%s",res.errno,res.err)
        return
    end

    return true
end

function on_sd_exit_club(msg)
    local sqls = {
        string.format("DELETE FROM t_club_member WHERE guid = %d AND club = %d;",msg.guid,msg.club_id),
        string.format([[DELETE FROM t_player_money WHERE guid = %d AND 
                        money_id IN (SELECT money_id FROM t_club_money WHERE club = %d AND money_id != 0);]],
                        msg.guid,msg.club_id),
    }
    log.dump(sqls)
    local res = dbopt.game:query(table.concat(sqls,"\n"))
    if res.errno then
        log.error("on_sd_exit_club DELETE member error:%d,%s",res.errno,res.err)
        return
    end

    return true
end

function on_sd_dismiss_club(msg)
    local res = dbopt.game:query("UPDATE t_club SET status = 3, updated_at = %d WHERE id = %d;",os.time(),msg.club_id)
    if res.errno then
        log.error("on_sd_dismiss_club dismiss member error:%d,%s",res.errno,res.err)
        return
    end

    return true
end

function on_sd_add_club_member(msg)
    local club_id = msg.club_id
    local guid = msg.guid

    log.dump(msg)

    dbopt.game:query("INSERT INTO t_club_member(club,guid) VALUES(%d,%d);",club_id,guid)
end

local function incr_club_money(club,money_id,money,why,why_ext)
    local sqls = {
        string.format("SELECT money FROM t_club_money WHERE club = %d AND money_id = %d;",club,money_id),
        string.format("UPDATE t_club_money SET money = money + (%d) WHERE club = %d AND money_id = %d;",money,club,money_id),
        string.format("SELECT money FROM t_club_money WHERE club = %d AND money_id = %d;",club,money_id),
    }

    log.dump(sqls)

    local res = dbopt.game:query(table.concat(sqls,"\n"))
    if res.errno then
        log.error("incr_club_money insert UPDATE money error,errno:%d,err:%s",res.errno,res.err)
        return
    end

    local oldmoney = res[1] and res[1][1] and res[1][1].money or nil
    local newmoney = res[3] and res[3][1] and res[3][1].money or nil

    if oldmoney and newmoney then
        res = dbopt.log:execute("INSERT INTO t_log_money_club SET $FIELD$;", {
            club = club,
            money_id = money_id,
            old_money = oldmoney,
            new_money = newmoney,
            opt_type = why,
            opt_ext = why_ext,
        })
        if res.errno then
            log.error("incr_club_money insert log.t_log_money_club error,errno:%d,err:%s",res.errno,res.err)
            return
        end
    end

	return oldmoney,newmoney
end

function on_sd_change_club_money(items,why,why_ext)
    log.dump(items)
	local changes = {}
	for _,item in pairs(items) do
		local oldmoney,newmoney = incr_club_money(item.club,item.money_id,item.money,why,why_ext)
		table.insert(changes,{
			oldmoney = oldmoney,
			newmoney = newmoney,
		})
    end

	return changes
end

function on_sd_create_club_template(msg)
    log.dump(msg)
    local res = dbopt.game:query([[
        INSERT INTO t_template(id,club,rule,description,game_id,created_time,status)
        VALUES(%d,%d,'%s','%s',%d,%d,0);
        ]],msg.id,msg.club_id,msg.rule,msg.description,msg.game_id,os.time())
    if res.errno then
        log.error("on_sd_create_club_template INSERT template errno:%d,errstr:%s",res.errno,res.err)
    end
end

function on_sd_remove_club_template(msg)
    log.dump(msg)
    local res = dbopt.game:query([[UPDATE t_template SET status = 1 WHERE id = %d;]],msg.id)
    if res.errno then
        log.error("on_sd_remove_club_template UPDATE template errno:%d,errstr:%s",res.errno,res.err)
    end
end

function on_sd_edit_club_template(msg)
    local res = dbopt.game:query([[
        UPDATE t_template SET club = %d,rule = '%s',description = '%s',game_id = %d
        WHERE id = %d;
        ]],msg.club_id,msg.rule,msg.description,msg.game_id,msg.id)
    if res.errno then
        log.error("on_sd_edit_club_template UPDATE template errno:%d,errstr:%s",res.errno,res.err)
    end
end