# vim:set ft= ts=4 sw=4 et:

use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

my $pwd = cwd();

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;;";
    lua_package_cpath "/usr/local/openresty-debug/lualib/?.so;/usr/local/openresty/lualib/?.so;;";
    lua_shared_dict redis_cluster_slot_locks 32k;
    init_by_lua '
        require("luacov")
    ';
};


no_long_string();
#no_diff();

run_tests();

__DATA__

=== TEST 1: set and get
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '

            local config = {
                            name = "testCluster",                   --rediscluster name
                            serv_list = {                           --redis cluster node list(host and port),
                                            { ip = "127.0.0.1", port = 7000 },
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
            local redis = require "resty.rediscluster"
            local red, err = redis:new(config)

            if err then
                ngx.say("failed to create: ", err)
                return
            end


            local res, err = red:set("dog", "an animal")
            if not res then
                ngx.say("failed to set dog: ", err)
                return
            end

            ngx.say("set dog: ", res)

            for i = 1, 2 do
                local res, err = red:get("dog")
                if err then
                    ngx.say("failed to get dog: ", err)
                    return
                end

                if not res then
                    ngx.say("dog not found.")
                    return
                end

                ngx.say("dog: ", res)
            end
        ';
    }
--- request
GET /t
--- response_body
set dog: OK
dog: an animal
dog: an animal
--- no_error_log
[error]

=== TEST 2: flushall , Note this will be executed only on 1 node in cluster
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local config = {
                            name = "testCluster",                   --rediscluster name
                            serv_list = {                           --redis cluster node list(host and port),
                                            { ip = "127.0.0.1", port = 7000 },
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
            local redis = require "resty.rediscluster"
            local red, err = redis:new(config)

            if err then
                ngx.say("failed to create: ", err)
                return
            end

            local res, err = red:flushall()
            if not res then
                ngx.say("failed to flushall: ", err)
                return
            end
            ngx.say("flushall: ", res)
        ';
    }
--- request
GET /t
--- response_body
flushall: true
--- no_error_log
[error]

=== TEST 3: get nil bulk value
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local config = {
                            name = "testCluster",                   --rediscluster name
                            serv_list = {                           --redis cluster node list(host and port),
                                            { ip = "127.0.0.1", port = 7000 },
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
            local redis = require "resty.rediscluster"
            local red, err = redis:new(config)

            if err then
                ngx.say("failed to create: ", err)
                return
            end

            local res, err = red:flushall()
            if not res then
                ngx.say("failed to flushall: ", err)
                return
            end

            ngx.say("flushall: ", res)

            for i = 1, 2 do
                res, err = red:get("not_found")
                if err then
                    ngx.say("failed to get: ", err)
                    return
                end

                if res == ngx.null then
                    ngx.say("not_found not found.")
                    return
                end

                ngx.say("get not_found: ", res)
            end

            
        ';
    }
--- request
GET /t
--- response_body
flushall: true
not_found not found.
--- no_error_log
[error]

=== TEST 4: get nil list
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local config = {
                            name = "testCluster",                   --rediscluster name
                            serv_list = {                           --redis cluster node list(host and port),
                                            { ip = "127.0.0.1", port = 7000 },
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
            local redis = require "resty.rediscluster"
            local red, err = redis:new(config)

            if err then
                ngx.say("failed to create: ", err)
                return
            end

            local res, err = red:flushall()
            if not res then
                ngx.say("failed to flushall: ", err)
                return
            end

            ngx.say("flushall: ", res)

            for i = 1, 2 do
                res, err = red:lrange("nokey", 0, 1)
                if err then
                    ngx.say("failed to get: ", err)
                    return
                end

                if res == ngx.null then
                    ngx.say("nokey not found.")
                    return
                end

                ngx.say("get nokey: ", #res, " (", type(res), ")")
            end

            
        ';
    }
--- request
GET /t
--- response_body
flushall: true
get nokey: 0 (table)
get nokey: 0 (table)
--- no_error_log
[error]

=== TEST 5: incr and decr
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local config = {
                            name = "testCluster",                   --rediscluster name
                            serv_list = {                           --redis cluster node list(host and port),
                                            { ip = "127.0.0.1", port = 7000 },
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
            local redis = require "resty.rediscluster"
            local red, err = redis:new(config)

            if err then
                ngx.say("failed to create: ", err)
                return
            end

            local res, err = red:set("connections", 10)
            if not res then
                ngx.say("failed to set connections: ", err)
                return
            end

            ngx.say("set connections: ", res)

            res, err = red:incr("connections")
            if not res then
                ngx.say("failed to set connections: ", err)
                return
            end

            ngx.say("incr connections: ", res)

            local res, err = red:get("connections")
            if err then
                ngx.say("failed to get connections: ", err)
                return
            end

            res, err = red:incr("connections")
            if not res then
                ngx.say("failed to incr connections: ", err)
                return
            end

            ngx.say("incr connections: ", res)

            res, err = red:decr("connections")
            if not res then
                ngx.say("failed to decr connections: ", err)
                return
            end

            ngx.say("decr connections: ", res)

            res, err = red:get("connections")
            if not res then
                ngx.say("connections not found.")
                return
            end

            ngx.say("connections: ", res)

            res, err = red:del("connections")
            if not res then
                ngx.say("failed to del connections: ", err)
                return
            end

            ngx.say("del connections: ", res)

            res, err = red:incr("connections")
            if not res then
                ngx.say("failed to set connections: ", err)
                return
            end

            ngx.say("incr connections: ", res)

            res, err = red:get("connections")
            if not res then
                ngx.say("connections not found.")
                return
            end

            ngx.say("connections: ", res)

            
        ';
    }
--- request
GET /t
--- response_body
set connections: OK
incr connections: 11
incr connections: 12
decr connections: 11
connections: 11
del connections: 1
incr connections: 1
connections: 1
--- no_error_log
[error]

=== TEST 6: bad incr command format
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local config = {
                            name = "testCluster",                   --rediscluster name
                            serv_list = {                           --redis cluster node list(host and port),
                                            { ip = "127.0.0.1", port = 7000 },
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
            local redis = require "resty.rediscluster"
            local red, err = redis:new(config)

            if err then
                ngx.say("failed to create: ", err)
                return
            end

            local res, err = red:incr("connections", 12)
            if not res then
                ngx.say("failed to set connections: ", res, ": ", err)
                return
            end

            ngx.say("incr connections: ", res)
        ';
    }
--- request
GET /t
--- response_body
failed to set connections: nil: ERR wrong number of arguments for 'incr' command
--- no_error_log
[error]

=== TEST 7: lpush and lrange
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local config = {
                            name = "testCluster",                   --rediscluster name
                            serv_list = {                           --redis cluster node list(host and port),
                                            { ip = "127.0.0.1", port = 7000 },
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
            local redis = require "resty.rediscluster"
            local red, err = redis:new(config)

            if err then
                ngx.say("failed to create: ", err)
                return
            end

            local res, err = red:flushall()
            if not res then
                ngx.say("failed to flushall: ", err)
                return
            end
            ngx.say("flushall: ", res)

            local res, err = red:lpush("mylist", "world")
            if not res then
                ngx.say("failed to lpush: ", err)
                return
            end
            ngx.say("lpush result: ", res)

            res, err = red:lpush("mylist", "hello")
            if not res then
                ngx.say("failed to lpush: ", err)
                return
            end
            ngx.say("lpush result: ", res)

            res, err = red:lrange("mylist", 0, -1)
            if not res then
                ngx.say("failed to lrange: ", err)
                return
            end
            local cjson = require "cjson"
            ngx.say("lrange result: ", cjson.encode(res))

            
        ';
    }
--- request
GET /t
--- response_body
flushall: true
lpush result: 1
lpush result: 2
lrange result: ["hello","world"]
--- no_error_log
[error]

=== TEST 8: blpop expires its own timeout
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local config = {
                            name = "testCluster",                   --rediscluster name
                            serv_list = {                           --redis cluster node list(host and port),
                                            { ip = "127.0.0.1", port = 7000 },
                                            { ip = "127.0.0.1", port = 7001 },
                                            { ip = "127.0.0.1", port = 7002 },
                                            { ip = "127.0.0.1", port = 7003 },
                                            { ip = "127.0.0.1", port = 7004 },
                                            { ip = "127.0.0.1", port = 7005 },
                                            { ip = "127.0.0.1", port = 7006 }
                                        },
                            keepalive_timeout = 60000,              --redis connection pool idle timeout
                            keepalive_cons = 1000,                  --redis connection pool size
                            connection_timout = 2500,               --timeout while connecting
                            max_redirection = 5                     --maximum retry attempts for redirection
                            
            }
            local redis = require "resty.rediscluster"
            local red, err = redis:new(config)

            if err then
                ngx.say("failed to create: ", err)
                return
            end

            local res, err = red:flushall()
            if not res then
                ngx.say("failed to flushall: ", err)
                return
            end
            ngx.say("flushall: ", res)

            local res, err = red:blpop("key", 1)
            if err then
                ngx.say("failed to blpop: ", err)
                return
            end

            if res == ngx.null then
                ngx.say("no element popped.")
                return
            end

            local cjson = require "cjson"
            ngx.say("blpop result: ", cjson.encode(res))

            
        ';
    }
--- request
GET /t
--- response_body
flushall: true
no element popped.
--- no_error_log
[error]
--- timeout: 3

=== TEST 9: blpop expires cosocket timeout
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local config = {
                            name = "testCluster",                   --rediscluster name
                            serv_list = {                           --redis cluster node list(host and port),
                                            { ip = "127.0.0.1", port = 7000 },
                                            { ip = "127.0.0.1", port = 7001 },
                                            { ip = "127.0.0.1", port = 7002 },
                                            { ip = "127.0.0.1", port = 7003 },
                                            { ip = "127.0.0.1", port = 7004 },
                                            { ip = "127.0.0.1", port = 7005 },
                                            { ip = "127.0.0.1", port = 7006 }
                                        },
                            keepalive_timeout = 60000,              --redis connection pool idle timeout
                            keepalive_cons = 1000,                  --redis connection pool size
                            connection_timout = 200,               --timeout while connecting
                            max_redirection = 5                     --maximum retry attempts for redirection
                            
            }
            local redis = require "resty.rediscluster"
            local red, err = redis:new(config)

            if err then
                ngx.say("failed to create: ", err)
                return
            end

            local res, err = red:flushall()
            if not res then
                ngx.say("failed to flushall: ", err)
                return
            end
            ngx.say("flushall: ", res)

            local res, err = red:blpop("key", 1)
            if err then
                ngx.say("failed to blpop: ", err)
                return
            end

            if not res then
                ngx.say("no element popped.")
                return
            end

            local cjson = require "cjson"
            ngx.say("blpop result: ", cjson.encode(res))

            
        ';
    }
--- request
GET /t
--- response_body
flushall: true
failed to blpop: timeout
--- error_log
lua tcp socket read timed out

=== TEST 10: mget
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local config = {
                            name = "testCluster",                   --rediscluster name
                            serv_list = {                           --redis cluster node list(host and port),
                                            { ip = "127.0.0.1", port = 7000 },
                                            { ip = "127.0.0.1", port = 7001 },
                                            { ip = "127.0.0.1", port = 7002 },
                                            { ip = "127.0.0.1", port = 7003 },
                                            { ip = "127.0.0.1", port = 7004 },
                                            { ip = "127.0.0.1", port = 7005 },
                                            { ip = "127.0.0.1", port = 7006 }
                                        },
                            keepalive_timeout = 60000,              --redis connection pool idle timeout
                            keepalive_cons = 1000,                  --redis connection pool size
                            connection_timout = 200,               --timeout while connecting
                            max_redirection = 5                     --maximum retry attempts for redirection
                            
            }
            local redis = require "resty.rediscluster"
            local red, err = redis:new(config)

            if err then
                ngx.say("failed to create: ", err)
                return
            end

            ok, err = red:flushall()
            if not ok then
                ngx.say("failed to flush all: ", err)
                return
            end

            local res, err = red:set("dog{111}", "an animal")
            if not res then
                ngx.say("failed to set dog: ", err)
                return
            end

            ngx.say("set dog: ", res)
            

            local res, err = red:mget("dog{111}", "cat{111}", "dog{111}")
            if err then
                ngx.say("failed to get dog: ", err)
                return
            end

            local cjson = require "cjson"
            ngx.say("mget result: ", cjson.encode(res))

            
        ';
    }
--- request
GET /t
--- response_body
set dog: OK
mget result: ["an animal",null,"an animal"]
--- no_error_log
[error]

=== TEST 11: hmget array_to_hash
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local config = {
                            name = "testCluster",                   --rediscluster name
                            serv_list = {                           --redis cluster node list(host and port),
                                            { ip = "127.0.0.1", port = 7000 },
                                            { ip = "127.0.0.1", port = 7001 },
                                            { ip = "127.0.0.1", port = 7002 },
                                            { ip = "127.0.0.1", port = 7003 },
                                            { ip = "127.0.0.1", port = 7004 },
                                            { ip = "127.0.0.1", port = 7005 },
                                            { ip = "127.0.0.1", port = 7006 }
                                        },
                            keepalive_timeout = 60000,              --redis connection pool idle timeout
                            keepalive_cons = 1000,                  --redis connection pool size
                            connection_timout = 200,               --timeout while connecting
                            max_redirection = 5                     --maximum retry attempts for redirection
                            
            }
            local redis = require "resty.rediscluster"
            local red, err = redis:new(config)

            if err then
                ngx.say("failed to create: ", err)
                return
            end

            ok, err = red:flushall()
            if not ok then
                ngx.say("failed to flush all: ", err)
                return
            end

            local res, err = red:hmset("animals", { dog = "bark", cat = "meow", cow = "moo" })
            if not res then
                ngx.say("failed to set animals: ", err)
                return
            end

            ngx.say("hmset animals: ", res)

            local res, err = red:hmget("animals", "dog", "cat", "cow")
            if not res then
                ngx.say("failed to get animals: ", err)
                return
            end

            ngx.say("hmget animals: ", res)

            local res, err = red:hgetall("animals")
            if err then
                ngx.say("failed to get animals: ", err)
                return
            end

            if not res then
                ngx.say("animals not found.")
                return
            end

            local array_to_hash = function (t)
                    local n = #t
                    -- print("n = ", n)
                    local h = {}
                    for i = 1, n, 2 do
                        h[t[i]] = t[i + 1]
                    end
                    return h
                end

            local h = array_to_hash(res)

            ngx.say("dog: ", h.dog)
            ngx.say("cat: ", h.cat)
            ngx.say("cow: ", h.cow)

            
        ';
    }
--- request
GET /t
--- response_body
hmset animals: OK
hmget animals: barkmeowmoo
dog: bark
cat: meow
cow: moo
--- no_error_log
[error]

=== TEST 12: boolean args
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local config = {
                            name = "testCluster",                   --rediscluster name
                            serv_list = {                           --redis cluster node list(host and port),
                                            { ip = "127.0.0.1", port = 7000 },
                                            { ip = "127.0.0.1", port = 7001 },
                                            { ip = "127.0.0.1", port = 7002 },
                                            { ip = "127.0.0.1", port = 7003 },
                                            { ip = "127.0.0.1", port = 7004 },
                                            { ip = "127.0.0.1", port = 7005 },
                                            { ip = "127.0.0.1", port = 7006 }
                                        },
                            keepalive_timeout = 60000,              --redis connection pool idle timeout
                            keepalive_cons = 1000,                  --redis connection pool size
                            connection_timout = 1000,                --timeout while connecting
                            max_redirection = 5                     --maximum retry attempts for redirection
                            
            }
            local redis = require "resty.rediscluster"
            local red, err = redis:new(config)

            if err then
                ngx.say("failed to create: ", err)
                return
            end

            ok, err = red:set("foo", true)
            if not ok then
                ngx.say("failed to set: ", err)
                return
            end

            local res, err = red:get("foo")
            if not res then
                ngx.say("failed to get: ", err)
                return
            end

            ngx.say("foo: ", res, ", type: ", type(res))

            ok, err = red:set("foo", false)
            if not ok then
                ngx.say("failed to set: ", err)
                return
            end

            local res, err = red:get("foo")
            if not res then
                ngx.say("failed to get: ", err)
                return
            end

            ngx.say("foo: ", res, ", type: ", type(res))

            ok, err = red:set("foo", nil)
            if not ok then
                ngx.say("failed to set: ", err)
            end

            local res, err = red:get("foo")
            if not res then
                ngx.say("failed to get: ", err)
                return
            end

            ngx.say("foo: ", res, ", type: ", type(res))
        ';
    }
--- request
GET /t
--- response_body
foo: true, type: string
foo: false, type: string
failed to set: ERR wrong number of arguments for 'set' command
foo: false, type: string
--- no_error_log
[error]

=== TEST 13: connection refused
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local config = {
                            name = "testCluster",                   --rediscluster name
                            serv_list = {                           --redis cluster node list(host and port),
                                            { ip = "127.0.0.1", port = 700 },
                                            { ip = "127.0.0.1", port = 701 },
                                            { ip = "127.0.0.1", port = 702 },
                                            { ip = "127.0.0.1", port = 703 },
                                            { ip = "127.0.0.1", port = 704 },
                                            { ip = "127.0.0.1", port = 705 },
                                            { ip = "127.0.0.1", port = 706 }
                                        },
                            keepalive_timeout = 60000,              --redis connection pool idle timeout
                            keepalive_cons = 1000,                  --redis connection pool size
                            connection_timout = 200,               --timeout while connecting
                            max_redirection = 5                     --maximum retry attempts for redirection
                            
            }
            package.loaded["resty.rediscluster"] = nil
            local redis = require "resty.rediscluster"
            local red, err = redis:new(config)

            if err then
                ngx.say("failed to create: ", err)
                return
            end

            ngx.say("connected")
        ';
    }
--- request
GET /t
--- response_body_like
^.*failed to fetch slots: connection refused.*$
--- timeout: 3
--- no_error_log
[alert]