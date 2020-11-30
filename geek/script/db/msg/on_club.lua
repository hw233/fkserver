
local dbopt =  require "dbopt"
local log = require "log"
local enum = require "pb_enums"
local json = require "json"

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
        {
            [[INSERT INTO t_club(id,name,owner,icon,type,parent,created_at,updated_at) VALUES(%s,"%s",%s,"%s",%s,%s,%s,%s);]],
            club_info.id,club_info.name,club_info.owner,club_info.icon,club_info.type,club_info.parent,os.time(),os.time()
        },
        {
            [[INSERT INTO t_club_role(club,guid,role) VALUES(%s,%s,4);]],club_info.id,club_info.owner
        },
        {   
            [[INSERT INTO t_club_money_type(money_id,club) VALUES(%d,%d);]],
            money_info.id,club_info.id
        },
        {
            [[INSERT INTO t_club_money(club,money_id,money) VALUES(%d,%d,0),(%d,0,0);]],club_info.id,money_info.id,club_info.id
        },
        {
            [[INSERT INTO t_club_member(club,guid) VALUES(%d,%d);]],
            club_info.id,club_info.owner
        },
        {
            [[INSERT IGNORE INTO t_player_money(guid,money_id,money) VALUES(%s,%s,0);]],
            club_info.owner,money_info.id
        },
    }

    log.dump(transqls)

    local res = dbopt.game:batchquery(transqls)
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
        {[[INSERT IGNORE INTO t_club_member(club,guid) VALUES(%d,%d);]],club_id,guid},
        {[[INSERT IGNORE INTO t_player_money(guid,money_id,money,`where`) VALUES(%d,%d,0,0);]],guid,money_id},
    }

    log.dump(sqls)

    res = dbopt.game:batchquery(sqls)
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
        "INSERT INTO t_club_member(club,guid,status) VALUES"..table.concat(table.series(guids,function(guid)
            return string.format("(%d,%d,0)",club_id, guid)
        end),",")..";",
        "INSERT INTO t_player_money(guid,money_id,money,`where`) VALUES"..table.concat(table.series(guids,function(guid)
            return string.format("(%d,%d,0,0)",guid,money_id)
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

function on_sd_del_club(msg)
    local club_id = msg.club_id
    local res = dbopt.game:batchquery({
        {"DELETE FROM t_club WHERE id = %d;",club_id},
        {"DELETE FROM t_club_member WHERE club = %d;",club_id},
        {"DELETE FROM t_club_money_type WHERE club = %d;",club_id},
        {"DELETE FROM t_club_role WHERE club = %d;",club_id},
        {"DELETE FROM t_partner_member WHERE club = %d;",club_id},
    })
    if res.errno then
        log.error("on_sd_del_club delete member error:%d,%s",res.errno,res.err)
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
        ]],msg.id,msg.club_id,json.encode(msg.rule),msg.description,msg.game_id,os.time())
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
        ]],msg.club_id,json.encode(msg.rule),msg.description,msg.game_id,msg.id)
    if res.errno then
        log.error("on_sd_edit_club_template UPDATE template errno:%d,errstr:%s",res.errno,res.err)
    end
end

function on_sd_create_partner(msg)
    local club = msg.club
    local guid = msg.guid
    
    local res = dbopt.game:query(table.concat({
        string.format([[
            INSERT INTO t_player_commission(club,guid,money_id,commission) SELECT %s,%s,money_id,0 FROM t_club_money_type WHERE club = %s;
                ]],club,guid,club),
        string.format([[
            INSERT INTO t_club_role(club,guid,role) VALUES(%s,%s,2) ON DUPLICATE KEY UPDATE role = 2;
                ]],club,guid),
    },""))
    if res.errno then
        log.error("on_sd_create_partner INSERT INTO t_player_commission errno:%d,errstr:%s",res.errno,res.err)
        return
    end

    return true
end

function on_sd_join_partner(msg)
    local club = msg.club
    local guid = msg.guid
    local partner = msg.partner

    local res = dbopt.game:query(string.format([[
        INSERT INTO t_partner_member(club,guid,partner) VALUES(%s,%s,%s);
    ]],club,guid,partner or "NULL"))
    if res.errno then
        log.error("on_sd_join_partner INSERT INTO t_partner_member errno:%d,errstr:%s",res.errno,res.err)
        return
    end

    return true
end

function on_sd_exit_partner(msg)
    local club = msg.club
    local guid = msg.guid
    local partner = msg.partner
    
    local r = dbopt.game:query([[
            DELETE FROM t_partner_member WHERE club = %s AND guid = %s AND partner = %s;
        ]],club,guid,partner)
    if r.errno then
        log.error("on_sd_exit_partner errno:%d,errstr:%s",r.errno,r.err)
        return
    end

    return true
end

function on_sd_dismiss_partner(msg)
    local club = msg.club
    local partner = msg.partner

    local res = dbopt.game:query(table.concat({
        string.format([[DELETE FROM t_partner_member WHERE club = %s AND partner = %s;]],club,partner),
        string.format([[DELETE FROM t_club_role WHERE club = %s AND guid = %s;]],club,partner)
    },""))
    if res.errno then
        log.error("on_sd_dismiss_partner DELETE FROM t_partner_member errno:%d,errstr:%s",res.errno,res.err)
        return
    end

    return true
end

function on_sd_edit_club_info(msg)
    local club = msg.club
    local name = msg.name
    local icon = msg.icon

    if not name and not icon then
        return
    end

    local fields = {}

    if name then
        fields.name = "'" .. dbopt.escapefield(name) .. "'"
    end

    if icon then
        fields.icon = "'" .. icon .. "'"
    end

    local r = dbopt.game:query(string.format(
        "UPDATE t_club SET %s WHERE id = %s;",
        table.concat(table.series(fields,function(v,k) return k .. "=" .. v end)),
        club
    ))
    if r.errno then
        log.error("on_sd_edit_club_info UPDATE t_club errno:%d,errstr:%s",r.errno,r.err)
        return
    end

    return true
end

function on_sd_set_club_role(msg)
    local club_id = msg.club_id
    local guid = msg.guid
    local role = msg.role

    if not club_id or not guid then
        return
    end

    if not role then
        local r = dbopt.game:query("DELETE FROM t_club_role WHERE club = %s AND guid = %s",club_id,guid)
        if r.errno then
            log.error("on_sd_set_club_role DELETE FROM t_club_role errno:%d,errstr:%s",r.errno,r.err)
        end
        return
    end

    local r = dbopt.game:query("INSERT INTO t_club_role(club,guid,role) VALUES(%s,%s,%s) ON DUPLICATE KEY UPDATE role = %s;",club_id,guid,role,role)
    if r.errno then
        if r.errno then
            log.error("on_sd_set_club_role INSERT INTO t_club_role errno:%d,errstr:%s",r.errno,r.err)
        end
    end
end