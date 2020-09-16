import redis

passwd = "123456"

c = redis.Redis(host='localhost', port=6379,db=0,password = passwd)

player_clubs = c.keys("player:club:[0-9]*")

for k in player_clubs:
    print(k)
    pid = int(str(k).strip("'").split(":")[2])
    cids = c.smembers(k)
    print(cids)
    for cid in cids:
        cid = cid.decode("utf")
        e = c.exists("club:info:{}".format(cid))
        print(e)
        if e != 1:
            c.srem(k,cid)