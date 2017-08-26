# resty-redis-cluster
Openresty lua client for redis cluster.

This client would support the usual access request to redis cluster.Currently openresty has no good client which can completely
support our project requirements, so I develop one. The client has some reference with cuiweixie's lua client:
https://github.com/cuiweixie/lua-resty-redis-cluster.   Thanks for this is a good baseline for me to start!

### feature list
1. resty-redis-cluster will cache slot->redis node mapping relationship, and support to calculate slot of key by CRC16, then access data by the cached mapping. while initializing, only 1 request per working will initial the slot mapping.

2. Support usual redis access and most command. 

3. Support pipeline operation. in case key is seperated in multiple nodes, resty-redis-cluster will organize and divide the slot which in same target nodes, then commit them with several pipeline.

4. Support hashtag. Just give you key like name{tag}

5. Support read from slave like Redisson/lettuce, both usual command and pipeline. While enable slave node read, resty-redis-cluster will randomly pickup a node mapping to the request key.

6. Support online resharding of redis cluster(both for usual command and pipeline. resty-redis-cluster will handle the #MOVED signal by re-cache the slot mapping and retrying. resty-redis-cluster will handle the #ASK signal by retrying with asking to redirection target nodes

7. Support error handling for the different failure scenario of redis cluster. (etc.Singel slave, master fail, cluster down)

8. fix some critical issues of https://github.com/cuiweixie/lua-resty-redis-cluster. 
   1) memory leak issues while high throughput. Cosocket operation will casue the suspend and swith of coroutine, so there would be multiple requests still have reference to the big slot mapping cache. This will cause LUAJIT VM crashed.
   
   2) we must refresh slot cache mapping in case any redis nodes connection failure, otherwise we will not get the latest slot cache mapping and always get failure. Refer to Jedis, same behaviour to referesh cache mapping while any unknown connection issue. 
   
   3) We must handle ASK redirection in usual/MOVED commands
   
   4) Pipeline must also handle MOVED signal with refreshing slot cache mapping and retry.



### Sample usage

1. Use normal commands:

```lua
local config = {
    name = "testCluster",
    serv_list = {
        { ip = "127.0.0.1", port = 7001 },
        { ip = "127.0.0.1", port = 7002 },
        { ip = "127.0.0.1", port = 7003 },
        { ip = "127.0.0.1", port = 7004 },
        { ip = "127.0.0.1", port = 7005 },
        { ip = "127.0.0.1", port = 7006 }
    },
    keepalive_timeout = 55000,
    keepalive_cons = 1000,
    connection_timout = 1000
}

local redis_cluster = require "rediscluster"
local red_c = redis_cluster:new(config)

local v, err = red_c:get("name")
if err then
    ngx.log(ngx.ERR, "err: ", err)
else
    ngx.say(v)
end
```

2. Use pipeline:

```lua
local cjson = require "cjson"

local config = {
    name = "testCluster",
    serv_list = {
        { ip = "127.0.0.1", port = 7001 },
        { ip = "127.0.0.1", port = 7002 },
        { ip = "127.0.0.1", port = 7003 },
        { ip = "127.0.0.1", port = 7004 },
        { ip = "127.0.0.1", port = 7005 },
        { ip = "127.0.0.1", port = 7006 }
    },
    keepalive_timeout = 55000,
    keepalive_cons = 1000,
    connection_timout = 1000
}

local redis_cluster = require "rediscluster"
local red_c = redis_cluster:new(config)


red_c:init_pipeline()
red_c:get("name")
red_c:get("name1")
red_c:get("name2")

local res, err = red_c:commit_pipeline()

if not res then
    ngx.log(ngx.ERR, "err: ", err)
else
    ngx.say(cjson.encode(res))
end
```

3. enable slave node read:

```lua
local cjson = require "cjson"

local config = {
    name = "testCluster",
    enableSlaveRead = true,
    serv_list = {
        { ip = "127.0.0.1", port = 7001 },
        { ip = "127.0.0.1", port = 7002 },
        { ip = "127.0.0.1", port = 7003 },
        { ip = "127.0.0.1", port = 7004 },
        { ip = "127.0.0.1", port = 7005 },
        { ip = "127.0.0.1", port = 7006 }
    },
    keepalive_timeout = 55000,
    keepalive_cons = 1000,
    connection_timout = 1000
}

local redis_cluster = require "rediscluster"
local red_c = redis_cluster:new(config)


red_c:init_pipeline()
red_c:zrange("item100")
red_c:zrange("item200")
red_c:zrange("item300")

local res, err = red_c:commit_pipeline()

if not res then
    ngx.log(ngx.ERR, "err: ", err)
else
    ngx.say(cjson.encode(res))
end
```

4. hashtag
```lua
local cjson = require "cjson"

local config = {
    name = "testCluster",
    enableSlaveRead = true,
    serv_list = {
        { ip = "127.0.0.1", port = 7001 },
        { ip = "127.0.0.1", port = 7002 },
        { ip = "127.0.0.1", port = 7003 },
        { ip = "127.0.0.1", port = 7004 },
        { ip = "127.0.0.1", port = 7005 },
        { ip = "127.0.0.1", port = 7006 }
    },
    keepalive_timeout = 55000,
    keepalive_cons = 1000,
    connection_timout = 1000
}

local redis_cluster = require "rediscluster"
local red_c = redis_cluster:new(config)


red_c:init_pipeline()
red_c:get("item100:sub1{100}")
red_c:get("item100:sub2{100}")
red_c:get("item300:sub3{100}")

local res, err = red_c:commit_pipeline()

if not res then
    ngx.log(ngx.ERR, "err: ", err)
else
    ngx.say(cjson.encode(res))
end
```

### Not support now

1. MSET, MGET operations 

2. transactions operations: MULTI DISCARD EXEC WATCH 

3. auto-discovery for new adding slave nodes, unless retrigger new slot mapping cached refresh

4. While enable slave node reading, if slave -> master link is down(maybe still under sync and recovery), resty-redis-cluster will not filter these nodes out. This is because cluster slots command will not filter them out.
   
   
