import redis

passwd = "123456"

c = redis.Redis(host='localhost', port=6379,db=0,password = passwd)

club_mem_keys = c.keys("club:member:[0-9]*")

for k in club_mem_keys:
    cid = int(str(k).strip("'").split(":")[2])
    print(cid)
    mems = c.smembers(k)
    print(mems)
    roles = [c.hget("club:role:"+str(cid),m) or b'1' for m in mems]
    c.zadd("club:zmember:{}".format(cid),
        dict(zip(mems,roles))
        )
    t = c.hget("club:info:{}".format(cid),"type")
    for m in mems:
        c.sadd("player:club:{}:{}".format(m.decode("utf-8"),t.decode("utf-8")),cid)
    
partner_mem_keys = c.keys("club:partner:member:[0-9]*:[0-9]*")
for k in partner_mem_keys:
    ks = str(k).strip("'").split(":")
    cid = int(ks[3])
    pid = int(ks[4])
    print(cid,pid)
    mems = c.smembers(k)
    print(mems)
    roles = [c.hget("club:role:"+str(cid),m) or b'1' for m in mems]
    c.zadd("club:partner:zmember:{}:{}".format(cid,pid),
        dict(zip(mems,roles))
        )
    for m in mems:
        c.hset("club:member:partner:{}".format(cid),m.decode("utf-8"),pid)
