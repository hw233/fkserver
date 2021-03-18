import pymysql
import redis
import pandas as pd
from sqlalchemy import create_engine as my_create_engine
import math

import sqlalchemy

pymysql.install_as_MySQLdb()

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

db_engine.execute("USE game;")

redpasswd = "123456"

c = redis.Redis(host='localhost', port=6379,db=0,password = redpasswd)

notices = c.keys("notice:info:*")

ns = pd.DataFrame(columns=[
	"id","club_id","where","type","content","start_time","end_time","update_time","create_time"
	])
for k in notices:
    print(k)
    nid = str(k).strip("'").split(":")[2]
    ninfo = c.hgetall("notice:info:{}".format(nid))
    if ninfo is None:
	    continue

    ns = ns.append(pd.DataFrame({
			"id" : str(ninfo[b"id"],encoding = "utf-8"),
			"club_id" : math.floor(float(ninfo[b"club_id"])) if b'club_id' in ninfo else None,
			"where" : math.floor(float(ninfo[b"where"])),
			"type" : math.floor(float(ninfo[b"type"])),
			"content" : str(ninfo[b"content"],encoding = "utf-8"),
			"play_count": math.floor(float(ninfo[b'play_count'])) if b'play_count' in ninfo else None,
			"start_time" : math.floor(float(ninfo[b"start_time"])) if b'start_time' in ninfo else None,
			"end_time" : math.floor(float(ninfo[b"end_time"])) if b'end_time' in ninfo else None,
			"create_time" : math.floor(float(ninfo[b"create_time"])),
			"update_time" : math.floor(float(ninfo[b"create_time"])),
		},copy=True,index={"id":True}))


ns.reset_index(drop=True,inplace=True)
ns = ns.set_index(["id"])

ns.to_sql("t_notice",db_engine,index=True,dtype = {
	"id":sqlalchemy.VARCHAR(64),
	"content":sqlalchemy.TEXT,
	"play_count":sqlalchemy.Integer,
	"type":sqlalchemy.Integer,
	"where":sqlalchemy.Integer,
	"club_id":sqlalchemy.Integer,
})