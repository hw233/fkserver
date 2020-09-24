import redis

passwd = "123456"
rdc = redis.Redis(host='localhost', port=6379,db=0,password = passwd)


player_money_keys = rdc.keys("player:money:[0-9]*")

for k in player_money_keys:
    print(k)
    hks = rdc.hkeys(k)
    for hk in hks:
        hk = hk.decode('utf-8')
        if int(hk) != 0:
            print(hk)
            rdc.hdel(k,hk)
    