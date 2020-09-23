
import pymysql
import pandas as pd
from sqlalchemy import create_engine as my_create_engine

import redis

pymysql.install_as_MySQLdb()

re_host = "localhost"
re_port = 6379
re_passwd = "123456"

rdc = redis.Redis(host=re_host, port=re_port,db=0,password = re_passwd)


my_host = "localhost"
my_port = 3306
my_user = "root"
my_passwd = "123456"


db_engine = my_create_engine(
    "mysql+pymysql://{}:{}@{}:{}".format(
        my_user,
        my_passwd,
        my_host,
        my_port
    )
)

clubs = pd.read_sql_query("SELECT * FROM game.t_club",db_engine)
print(clubs)
clubmembers = pd.read_sql_query("SELECT * FROM game.t_club_member",db_engine)
clubroles = pd.read_sql_query("SELECT * FROM game.t_club_role",db_engine)
clubpartners = pd.read_sql_query("SELECT * FROM game.t_partner_member",db_engine)
clubmoneytypes = pd.read_sql_query("SELECT * FROM game.t_club_money_type",db_engine)
clubtemplates = pd.read_sql_query("SELECT * FROM game.t_template",db_engine)

for label,c in clubs.iterrows():
    cid = c['id']
    ckey = 'club:info:{}'.format(cid)
    rdc.hset(ckey,'id',cid)
    rdc.hset(ckey,'name',c['name'])
    rdc.hset(ckey,'icon',c['icon'])
    rdc.hset(ckey,'type',c['type'])
    rdc.hset(ckey,'parent',c['parent'])
    rdc.hset(ckey,'owner',c['owner'])

print(clubmembers)

for label,mem in clubmembers.iterrows():
    rdc.sadd('club:member:{}'.format(str(mem['club'])),str(mem['guid']))

for label,r in clubroles.iterrows():
    rdc.hset('club:role:{}'.format(str(r['club'])),str(r['guid']),str(r['role']))

clubroles = pd.merge(clubmembers,clubroles,how='left',on=['club','guid'],copy=True)
clubroles['role'].fillna(1,inplace=True)
print(clubroles)
for label,role in clubroles.iterrows():
    cid = role['club']
    rdc.zadd('club:zmember:{}'.format(cid),dict({str(role['guid']):str(role['role'])}))
    pass

for label,p in clubpartners.iterrows():
    rdc.hset('club:member:partner:{}'.format(p['club']),str(p['guid']),str(p['partner']))
    rdc.zadd('club:partner:zmember:{}:{}'.format(p['club'],p['partner']),{str(p['guid']):1})
    rdc.sadd('club:partner:member:{}:{}'.format(p['club'],p['partner']),str(p['guid']))

for label,money in clubmoneytypes.iterrows():
    rdc.set('club:money_type:{}'.format(money['club']),str(money['money_id']))

for label,template in clubtemplates.iterrows():
    rdc.sadd('club:template:{}'.format(template['club']),str(template['id']))