import redis

passwd = "123456"

c = redis.Redis(host='localhost', port=6379,db=0,password = passwd)

notices = c.keys("notice:info:*")

for k in notices:
    print(k)
    nid = str(k).strip("'").split(":")[2]
    c.sadd("notice:all",nid)
    