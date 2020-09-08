import redis

passwd = "123456"

c = redis.Redis(host='localhost', port=6379,db=0,password = passwd)

club_mem_keys = c.keys("club:member:[0-9]*")

for k in club_mem_keys:
    cid = int(str(k).strip("'").split(":")[2])
    print(cid)
    mems = c.smembers(k)
    print(mems)
    c.zadd("club:zmember:"+str(cid),
        dict(zip(mems,[i for i in range(0,len(mems))]))
        )
    
