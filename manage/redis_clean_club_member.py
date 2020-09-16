import redis

passwd = "123456"

c = redis.Redis(host='localhost', port=6379,db=0,password = passwd)

club_mem_keys = c.keys("club:member:[0-9]*")

for k in club_mem_keys:
    print(k)
    cid = int(str(k).strip("'").split(":")[2])
    e = c.exists("club:info:{}".format(cid))
    print(e)
    if e != 1:
        c.delete(k)
        c.delete("club:zmember:{}".format(cid))