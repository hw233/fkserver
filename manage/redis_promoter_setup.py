import redis

passwd = "123456"

club_id = "82533738"
promoter = "204084"

c = redis.Redis(host='localhost', port=6379,db=0,password = passwd)

club_mems = c.smembers("club:member:"+club_id)

for mid in club_mems:
    print(mid)
    k = "player:info:" + str(mid,encoding='utf-8')
    print(k)
    c.hset(k,"promoter",promoter)

