# resty-redis-cluster

Openresty lua client for redis cluster.

### Why we build this client?

Openresty has no official client which can support redis cluster. (We could see discussion at https://github.com/openresty/lua-resty-redis/issues/43). Also, looking around other 3rd party openresty redis cluster client , we do't find one can completely support redis cluster features as our project requirement.

Resty-redis-cluster is a new build openresty module which can currently support most of redis-cluster features.

While building the client, thanks for https://github.com/cuiweixie/lua-resty-redis-cluster which gave us some good reference.

### feature list

1.  resty-redis-cluster will cache slot->redis node mapping relationship, and support to calculate slot of key by CRC16, then access data by the cached mapping. The way we calculate CRC16 and caching is somewhat similar with https://github.com/cuiweixie/lua-resty-redis-cluster.

2.  Support usual redis cluster access and most command.

3.  Support pipe-line operation. in case key is seperated in multiple nodes, resty-redis-cluster will organize the slot which in same target nodes into groups, then commit them with several pipeline group.

4.  Support hashtag. Just give your key like name{tag}

5.  Support read from slave node by readonly mode, both usual command and pipeline. While enable slave node read, resty-redis-cluster will randomly pickup a node which is mapped to the request key, no matter it's master or slave.

6.  Support online resharding of redis cluster(both for usual command and pipeline. resty-redis-cluster will handle the #MOVED signal by re-cache the slot mapping and retrying. resty-redis-cluster will handle the #ASK signal by retrying with asking to redirection target nodes

7.  Support error handling for the different failure scenario of redis cluster. (etc.Singel slave, master fail, cluster down)

8.  fix some critical issues of https://github.com/cuiweixie/lua-resty-redis-cluster.

    1.  memory leak issues while there is high throughput. Socket request will cause the suspend and swith of coroutine, so there would be multiple requests still have reference to the big slot mapping cache. This will cause LUAJIT VM crashed.

    2.  we must refresh slot cache mapping in case any redis nodes connection failure, otherwise we will not get the latest slot cache mapping and always get failure. Refer to Jedis, same behaviour to referesh cache mapping while any unknown connection issue.

    3.  We must handle ASK redirection in usual/MOVED commands

    4.  Pipeline must also handle MOVED signal with refreshing slot cache mapping and retry.

### installation

1.  please compile and generate redis_slot.so from redis_slot.c (can done by gcc)

2.  please add redis_slot.so and rediscluster.lua at lualib, Also please add library:lua-resty-redis and lua-resty-lock
    nginx.conf like:

    lua_package_path "/path/lualib/?.lua;";
    lua_package_cpath "/path/lualib/?.so;";

3.  nginx.conf add config:

    lua_shared_dict redis_cluster_slot_locks 100k;

### Sample usage

1.  Use normal commands:

```lua
local config = {
    name = "testCluster",                   --rediscluster name
    serv_list = {                           --redis cluster node list(host and port),
        { ip = "127.0.0.1", port = 7001 },
        { ip = "127.0.0.1", port = 7002 },
        { ip = "127.0.0.1", port = 7003 },
        { ip = "127.0.0.1", port = 7004 },
        { ip = "127.0.0.1", port = 7005 },
        { ip = "127.0.0.1", port = 7006 }
    },
    keepalive_timeout = 60000,              --redis connection pool idle timeout
    keepalive_cons = 1000,                  --redis connection pool size
    connection_timout = 1000,               --timeout while connecting
    max_redirection = 5                     --maximum retry attempts for redirection
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

2.  Use normal commands via auth:

```lua
local config = {
    name = "testCluster",                   --rediscluster name
    serv_list = {                           --redis cluster node list(host and port),
        { ip = "127.0.0.1", port = 7001 },
        { ip = "127.0.0.1", port = 7002 },
        { ip = "127.0.0.1", port = 7003 },
        { ip = "127.0.0.1", port = 7004 },
        { ip = "127.0.0.1", port = 7005 },
        { ip = "127.0.0.1", port = 7006 }
    },
    auth = "password",                      --redis password
    keepalive_timeout = 60000,              --redis connection pool idle timeout
    keepalive_cons = 1000,                  --redis connection pool size
    connection_timout = 1000,               --timeout while connecting
    max_redirection = 5                     --maximum retry attempts for redirection
}

local redis_cluster = require "rediscluster"
local red_c = redis_cluster:new(config)

local count, err, v
if type(config.auth) == "string" and count == 0 then
    _, err = red_c:auth(config.auth)
end

if err then
    ngx.log(ngx.ERR, "err: ", err)
end

v, err = red_c:get("name")
if err then
    ngx.log(ngx.ERR, "err: ", err)
else
    ngx.say(v)
end
```

3.  Use pipeline:

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
    keepalive_timeout = 60000,
    keepalive_cons = 1000,
    connection_timout = 1000,
    max_redirection = 5
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

4.  enable slave node read:

    Note: Currently enableSlaveRead is only limited in pure read scenario.
    We don't support mixed read and write scenario(distingush read, write operation) in single config set with enableSlaveRead now.
    If your scenario is mixed with write operation, please disable the option.

    Also, you can isolate pure read scenaro into another config set.

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
    keepalive_timeout = 60000,
    keepalive_cons = 1000,
    connection_timout = 1000,
    max_redirection = 5
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

5.  hashtag

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
    keepalive_timeout = 60000,
    keepalive_cons = 1000,
    connection_timout = 1000,
    max_redirection = 5
}

local redis_cluster = require "rediscluster"
local red_c = redis_cluster:new(config)


red_c:init_pipeline()
red_c:get("item100:sub1{100}")
red_c:get("item100:sub2{100}")
red_c:get("item100:sub3{100}")

local res, err = red_c:commit_pipeline()

if not res then
    ngx.log(ngx.ERR, "err: ", err)
else
    ngx.say(cjson.encode(res))
end
```

### Limitation

1.  Doesn't support MSET, MGET operations yet

2.  Doesn't support transactions operations: MULTI DISCARD EXEC WATCH

3.  Doesn't support pub sub. Actually redis cluster didn't check slot for pub sub commands, so using normal resty redis client to conenct with specific node in a cluster still works.

4.  Limitation only for turn on enable slave read: If we need to discover new slave node(but without adding new master), must retrigger new slot mapping cache refresh, otherwise slot mapping still record the last version of node tables.(easiest way is rebooting nginx nodes)

5.  Limitation only for turn on enable slave read: If slave -> master link is down(maybe still under sync and recovery), resty-redis-cluster will not filter these nodes out. Thus, read from slave may return unexpected response. Suggest always catch the response parsing exception while enable slave read.
    This is because client depends on cluster slots command.

## Copyright and License

This module is licensed under the Apache License Version 2.0 .

Copyright (C) 2017, by steve.xu stevehui0511@gmail.com

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
