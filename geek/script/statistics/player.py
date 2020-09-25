import pandas as pd
import sys
from sqlalchemy import create_engine as my_create_engine
import math
import time
import pymysql

args = sys.argv

file = args[0]
print(file)
real_args = args[1:]

my_conf = dict(zip(
    [real_args[i] for i in range(0,len(real_args),2)],
    [real_args[i] for i in range(1,len(real_args),2)],
    ))

print(my_conf)

assert(my_conf['host'])
assert(my_conf['port'])
assert(my_conf['user'])
assert(my_conf['password'])

db_engine = my_create_engine(
    "mysql+pymysql://{}:{}@{}:{}".format(
        my_conf['user'],
        my_conf['password'],
        my_conf['host'],
        my_conf['port']
    )
)

day_seconds = 60 * 60 * 24

log_create_table_sql = [
    "USE log;",
    """
        CREATE TABLE IF NOT EXISTS t_log_player_daily_play_count(
            id INT(8) NOT NULL AUTO_INCREMENT,
            guid INT(4) NOT NULL,
            club INT(8),
            count INT(4) NOT NULL,
            date INT(8) NOT NULL,
            PRIMARY KEY (`id`),
            UNIQUE(guid,club,date)
        )ENGINE=InnoDB DEFAULT CHARSET=UTF8;
    """,
    """
        CREATE TABLE IF NOT EXISTS t_log_player_daily_commission_contribute(
            id INT(8) NOT NULL AUTO_INCREMENT,
            parent INT(4) NOT NULL,
            son INT(4) NOT NULL,
            club INT(8),
            template INT(4),
            commission INT(8) NOT NULL,
            date INT(8) NOT NULL,
            PRIMARY KEY (`id`),
            UNIQUE(parent,son,club,date)
        )ENGINE=InnoDB DEFAULT CHARSET=UTF8;
    """,
    """
        CREATE TABLE IF NOT EXISTS t_log_team_daily_play_count(
            id INT(8) NOT NULL AUTO_INCREMENT,
            guid INT(4) NOT NULL,
            club INT(8),
            count INT(4) NOT NULL,
            date INT(8) NOT NULL,
            PRIMARY KEY (`id`),
            UNIQUE(guid,club,date)
        )ENGINE=InnoDB DEFAULT CHARSET=UTF8;
    """
]

game_create_table_sql = [
    "USE game;",
    """
        CREATE TABLE IF NOT EXISTS t_team_player_count(
            id INT(8) NOT NULL AUTO_INCREMENT,
            guid INT(4) NOT NULL,
            club INT(8),
            count INT(4) NOT NULL,
            PRIMARY KEY (`id`),
            UNIQUE(guid,club)
        )ENGINE=InnoDB DEFAULT CHARSET=UTF8;
    """,
    """
        CREATE TABLE IF NOT EXISTS t_team_money(
            id INT(8) NOT NULL AUTO_INCREMENT,
            guid INT(4) NOT NULL,
            club INT(8),
            money INT(4) NOT NULL,
            PRIMARY KEY (`id`),
            UNIQUE(guid,club)
        )ENGINE=InnoDB DEFAULT CHARSET=UTF8;
    """,
]

def create_table():
    for sql in log_create_table_sql:
        db_engine.execute(sql)
    
    for sql in game_create_table_sql:
        db_engine.execute(sql)

    pass

def pd_replace_into_sql(table,conn,keys,datas):
    def value_sql(row):
        return "({})".format(",".join(str(i) if not isinstance(i,str) else "'{}'".format(i) for i in row))
        pass

    sql = "REPLACE INTO {}({}) VALUES{}".format(
            '{}.{}'.format(table.schema, table.name) if table.schema else table.name,
            ", ".join(keys),
            ", ".join(value_sql(r) for r in datas)
        )

    conn.execute(sql)
    pass


def player_play_count():
    today = math.floor(time.time() / day_seconds)
    sql = """
        REPLACE INTO t_log_player_daily_play_count(guid,club,count,date)
        SELECT pr.guid,r.club,COUNT(DISTINCT(r.round)) count,pr.create_time div 86400 * 86400 date FROM 
            log.t_log_player_round pr
        LEFT JOIN
            log.t_log_round r
        ON pr.round = r.round
        WHERE pr.create_time > {} AND pr.create_time <= {}
        GROUP BY r.club,pr.guid,pr.create_time div 86400 * 86400;
    """.format(today * day_seconds,(today + 1) * day_seconds)
    db_engine.execute("USE log;")
    db_engine.execute(sql)

    pass

def first_members(alls):
    mems = pd.merge(
        alls,
        alls,
        left_on=['club','guid'],
        right_on=['club','partner'],
        how='left',
        copy=True)
    mems = mems[mems.guid_y.isna()][['club','guid_x','partner_x']].rename(columns={'guid_x':'guid','partner_x':'partner'})
    return mems
    pass

def club_deepest_members(cms):
    mems = pd.merge(cms,cms,how='left',left_on=['club','guid'],right_on=['club','partner'])
    if len(mems[mems.guid_y.notna()]) == 0:
        mems = mems[['club','guid_x','partner_x']].rename(columns={'guid_x':'guid','partner_x':'partner'})
        return mems
    mems = mems[mems.guid_y.notna()][['club','guid_y','partner_y']].rename(columns={'guid_y':'guid','partner_y':'partner'})
    return club_deepest_members(mems)


def deepest_members(alls):
    return alls.groupby('club').apply(club_deepest_members).reset_index(drop=True)
    pass

def club_team_play_count(cpcs):
    today = math.floor(time.time() / day_seconds) * day_seconds
    sons = club_deepest_members(cpcs)
    while len(sons) > 0:
        sons = cpcs[cpcs.partner.isin(sons.partner)]
        sons_counts = sons.groupby(['club','partner','date']).sum().reset_index()[['club','partner','count','date']].rename(columns={'partner':'guid'})
        teams_counts = pd.merge(cpcs,sons_counts,how='outer',left_on=['club','guid','date'],right_on=['club','guid','date'])
        teams_counts['count_x'].fillna(0,inplace=True)
        teams_counts['count_y'].fillna(0,inplace=True)
        teams_counts['count'] = teams_counts['count_x'] + teams_counts['count_y']
        cpcs = teams_counts[['club','guid','partner','count','date']]
        sons = cpcs[cpcs.guid.isin(sons.partner)]

    return cpcs

def team_play_count():
    today = math.floor(time.time() / day_seconds) * day_seconds
    members = pd.read_sql_query('SELECT club,guid,partner FROM game.t_partner_member;',db_engine)
    play_counts = pd.read_sql_query('SELECT club,guid,count,date FROM log.t_log_player_daily_play_count WHERE date >= {};'.format(today),db_engine)
    play_counts = pd.merge(members,play_counts,how='left',on=['club','guid'])
    play_counts['count'].fillna(0,inplace=True)
    play_counts['date'] = today
    play_counts = play_counts.groupby('club').apply(club_team_play_count).reset_index(drop=True)
    play_counts = play_counts[['club','guid','count','date']]

    play_counts.to_sql(
            't_log_team_daily_play_count',db_engine,schema = 'log',if_exists='append',
            index=False,chunksize=200,method=pd_replace_into_sql
        )

    pass

def club_team_player_count(cms):
    sons = club_deepest_members(cms)
    player_counts = cms.groupby(['club','partner']).count().reset_index().rename(columns={'guid':'count','partner':'guid'})
    while len(sons) > 0:
        sons = cms[cms.partner.isin(sons.partner)]
        son_team_counts = pd.merge(sons,player_counts,how='left',on=['club','guid'])
        son_team_counts = son_team_counts[['club','guid','partner','count']]
        son_team_counts['count'].fillna(0,inplace=True)
        son_team_counts = son_team_counts.groupby(['club','partner']).sum().reset_index()[['club','partner','count']]
        counts = pd.merge(player_counts,son_team_counts,how='left',left_on=['club','guid'],right_on=['club','partner'])
        counts['count_y'].fillna(0,inplace=True)
        counts['count_x'].fillna(0,inplace=True)
        counts['count'] = counts['count_x'] + counts['count_y']
        player_counts = counts[['club','guid','count']]
        sons = cms[cms.guid.isin(sons.partner)]

    return player_counts
    pass

def team_player_count():
    members = pd.read_sql_query('SELECT club,guid,partner FROM game.t_partner_member;',db_engine)
    counts = members.groupby('club').apply(club_team_player_count).reset_index(drop=True)
    counts.to_sql('t_team_player_count',db_engine,schema='game',if_exists='append',index=False,chunksize=200,method=pd_replace_into_sql)
    pass

def club_team_money(cpms):
    sons = club_deepest_members(cpms)
    team_moneys = pd.DataFrame(columns=['club','guid','money'])
    while len(sons) > 0:
        sons = cpms[cpms.partner.isin(sons.partner)]
        son_team_money = pd.merge(sons,team_moneys,how='left',on=['club','guid'])
        son_team_money['money_x'].fillna(0,inplace=True)
        son_team_money['money_y'].fillna(0,inplace=True)
        son_team_money['money'] = son_team_money['money_x'] + son_team_money['money_y']
        son_team_money = son_team_money[['club','guid','partner','money']]
        son_team_money = son_team_money.groupby(['club','partner']).sum().reset_index()[['club','partner','money']]
        son_team_money.rename(columns={'partner':'guid'},inplace=True)
        team_moneys = team_moneys.append(son_team_money[['club','guid','money']])
        sons = cpms[cpms.guid.isin(sons.partner)]

    return team_moneys
    pass


def team_money():
    moneies = pd.read_sql_query('''
        SELECT m.club,m.guid,m.partner,pm.money FROM 
            game.t_partner_member m
        LEFT JOIN 
            game.t_club_money_type mt
        ON m.club = mt.club
        LEFT JOIN
            game.t_player_money pm
        ON mt.money_id = pm.money_id AND pm.guid = m.guid
    ''',db_engine)
    cpms = moneies.groupby('club').apply(club_team_money).reset_index(drop=True)
    cpms.to_sql('t_team_money',db_engine,schema='game',if_exists='append',index=False,chunksize=200,method=pd_replace_into_sql)
    pass


def player_commission_contribute():
    today = math.floor(time.time() / day_seconds)
    
    db_engine.execute('''
        REPLACE INTO log.t_log_player_daily_commission_contribute(parent,son,commission,template,club,date)
        SELECT parent,son,SUM(commission) commission,template,club,create_time div 86400 * 86400 date 
        FROM log.t_log_player_commission_contribute
        WHERE create_time > {} AND create_time <= {}
        GROUP BY parent,son,template,club,create_time div 86400 * 86400;
    '''.format(today * day_seconds,(today + 1) * day_seconds))

    pass

create_table()
# team_player_count()
# team_money()
player_play_count()
team_play_count()
player_commission_contribute()