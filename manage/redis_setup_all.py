import pymysql
import redis
import pandas as pd
from sqlalchemy import create_engine as my_create_engine
import math
from rediscluster import RedisCluster
import re
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

db_engine.execute("USE config;")

dbconfs = pd.read_sql("SELECT * FROM t_redis_cfg;",db_engine)

print(dbconfs)

clusterconf = dbconfs[dbconfs.cluster == 1]
print(clusterconf)

clusternodes = [{"host": c["host"],"port" : c["port"],"auth":c["auth"]} for i,c in clusterconf.iterrows()]

print(clusternodes)

singleconf = dbconfs[dbconfs.cluster.isna()]
singlenodes = [{"host": c["host"],"port" : c["port"],"auth":c["auth"]} for i,c in singleconf.iterrows()]

print(singlenodes)

c = redis.Redis(
	host=singlenodes[0]['host'], 
	port=singlenodes[0]['port'],
	db=0,
	password = singlenodes[0]['auth']
)

# cluster = RedisCluster(startup_nodes=clusternodes,decode_responses=True,password=clusternodes[0]['auth'])

def setup_all_key():
	for k in c.keys("club:info:*"):
		print(k)
		cid = re.search(r"club:info:(\d+)",str(k))
		if cid is not None:
			c.sadd("club:all",cid.group(1))

	for k in c.keys("player:info:*"):
		print(k)
		pid = re.search(r"player:info:(\d+)",str(k))
		if pid is not None:
			c.sadd("player:all",pid.group(1))

	for k in c.keys("notice:info:*"):
		print(k)
		nid = re.search(r"notice:info:(\d+\-\d+)",str(k))
		if nid is not None:
			c.sadd("notice:all",nid.group(1))

	for k in c.keys("request:*"):
		print(k)
		rid = re.search(r"request:(\d+)",str(k))
		if rid is not None:
			c.sadd("request:all",rid.group(1))

	for k in c.keys("mail:*"):
		print(k)
		mid = re.search(r"mail:(\d+\-\d+)",str(k))
		if mid is not None:
			c.sadd("mail:all",mid.group(1))

	for k in c.keys("template:*"):
		print(k)
		tid = re.search(r"template:(\d+)",str(k))
		if tid is not None:
			c.sadd("template:all",tid.group(1))

	for k in c.keys("money:info:*"):
		print(k)
		mid = re.search(r"money:info:(\d+)",str(k))
		if mid is not None:
			c.sadd("money:all",mid.group(1))

setup_all_key()