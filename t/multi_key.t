use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(1);

plan tests => 3 * blocks();

my $pwd = cwd();

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;$pwd/t/fixtures/?.lua;;";
    lua_package_cpath "/usr/local/openresty-debug/lualib/?.so;/usr/local/openresty/lualib/?.so;;";
    lua_shared_dict redis_cluster_slot_locks 32k;
};

no_long_string();

run_tests();

__DATA__

=== TEST 1: mget across slots keeps the order, nulls and duplicates
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local fake = require "fake_redis"
            package.loaded["resty.redis"] = fake

            fake.reset()
            local data = { foo = "F", bar = "B" }
            fake.handler = function(self, cmd, ...)
                if cmd == "mget" then
                    local out = {}
                    for i, k in ipairs({ ... }) do out[i] = data[k] or ngx.null end
                    return out
                end
                return "OK"
            end

            local redis = require "resty.rediscluster"
            local red = assert(redis:new({
                name = "mgetCluster",
                serv_list = { { ip = "127.0.0.1", port = 7001 } },
                dict_name = "redis_cluster_slot_locks",
                lock_timeout = 1,
            }))

            local res, err = red:mget("foo", "bar", "nokey", "foo")
            local out = {}
            for i = 1, 4 do out[i] = res[i] == ngx.null and "null" or res[i] end
            ngx.say("result: ", table.concat(out, ","), " err: ", tostring(err))

            local n = 0
            for _, e in ipairs(fake.events) do
                if e.ev == "cmd" and e.cmd == "mget" then n = n + 1 end
            end
            ngx.say("mget calls: ", n)
        ';
    }
--- request
GET /t
--- response_body
result: F,B,null,F err: nil
mget calls: 3
--- no_error_log
[error]

=== TEST 2: mset across slots sends one command per slot
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local fake = require "fake_redis"
            package.loaded["resty.redis"] = fake

            fake.reset()
            local redis = require "resty.rediscluster"
            local red = assert(redis:new({
                name = "msetCluster",
                serv_list = { { ip = "127.0.0.1", port = 7001 } },
                dict_name = "redis_cluster_slot_locks",
                lock_timeout = 1,
            }))

            local res, err = red:mset("foo", "1", "bar", "2")
            ngx.say("result: ", tostring(res), " err: ", tostring(err))

            local n = 0
            for _, e in ipairs(fake.events) do
                if e.ev == "cmd" and e.cmd == "mset" then n = n + 1 end
            end
            ngx.say("mset calls: ", n)

            res, err = red:mset("foo", "1", "bar")
            ngx.say("odd: ", tostring(res), " err: ", tostring(err))
        ';
    }
--- request
GET /t
--- response_body
result: OK err: nil
mset calls: 2
odd: nil err: wrong number of arguments for 'mset' command
--- no_error_log
[error]

=== TEST 3: keys that share a hash tag use a single command
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local fake = require "fake_redis"
            package.loaded["resty.redis"] = fake

            fake.reset()
            local redis = require "resty.rediscluster"
            local red = assert(redis:new({
                name = "tagCluster",
                serv_list = { { ip = "127.0.0.1", port = 7001 } },
                dict_name = "redis_cluster_slot_locks",
                lock_timeout = 1,
            }))

            red:mset("a{t}", "1", "b{t}", "2")
            red:mget("a{t}", "b{t}")

            local n = 0
            for _, e in ipairs(fake.events) do
                if e.ev == "cmd" and (e.cmd == "mget" or e.cmd == "mset") then n = n + 1 end
            end
            ngx.say("calls: ", n)
        ';
    }
--- request
GET /t
--- response_body
calls: 2
--- no_error_log
[error]

=== TEST 4: an error from one slot group is returned
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local fake = require "fake_redis"
            package.loaded["resty.redis"] = fake

            fake.reset()
            fake.handler = function(self, cmd)
                if cmd == "mset" and self._node == "127.0.0.1:7003" then
                    return false, "ERR boom"
                end
                return "OK"
            end

            local redis = require "resty.rediscluster"
            local red = assert(redis:new({
                name = "errCluster",
                serv_list = { { ip = "127.0.0.1", port = 7001 } },
                dict_name = "redis_cluster_slot_locks",
                lock_timeout = 1,
            }))

            local res, err = red:mset("bar", "1", "foo", "2")
            ngx.say("result: ", tostring(res), " err: ", tostring(err))
        ';
    }
--- request
GET /t
--- response_body
result: nil err: ERR boom
--- no_error_log
[error]

=== TEST 5: nil arguments are rejected and a pipeline queues the call
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local fake = require "fake_redis"
            package.loaded["resty.redis"] = fake

            fake.reset()
            local redis = require "resty.rediscluster"
            local red = assert(redis:new({
                name = "nilCluster",
                serv_list = { { ip = "127.0.0.1", port = 7001 } },
                dict_name = "redis_cluster_slot_locks",
                lock_timeout = 1,
            }))

            local res, err = red:mset("foo", nil, "bar", "2")
            ngx.say("nil: ", tostring(res), " err: ", tostring(err))

            red:init_pipeline()
            res, err = red:mset("foo")
            ngx.say("pipeline: ", tostring(res), " err: ", tostring(err))
            red:cancel_pipeline()
        ';
    }
--- request
GET /t
--- response_body
nil: nil err: nil argument for 'mset' command
pipeline: nil err: nil
--- no_error_log
[error]
