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

c = RedisCluster(startup_nodes=clusternodes,decode_responses=True,password=clusternodes[0]['auth'])

def setup_mem_count():
	clubs = c.smembers("club:all")
	for k in clubs:
		print(k)
		mems = c.smembers("club:member:{}".format(k))
		c.set("club:member:count:{}".format(k),len(mems))

setup_mem_count()