
import pymysql

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

conn = pymysql.connect(host=my_host, user=my_user,passwd=my_passwd,db="game")

cursor = conn.cursor()
club_mem_keys = rdc.keys("player:money:[0-9]*")
for k in club_mem_keys:
    guid = int(str(k).strip("'").split(":")[2])
    print(guid)
    monies = rdc.hgetall(k)
    for (mid,money) in monies.items():
        mid = mid.decode('utf-8')
        money = money.decode('utf-8')
        print(mid,money)
        
        sql = "REPLACE INTO game.t_player_money(guid,money_id,money,`where`) VALUES({},{},{},0);".format(guid,str(mid),str(money))
        print(sql)
        x = cursor.execute(sql)
        conn.commit()

cursor.close()
conn.close()