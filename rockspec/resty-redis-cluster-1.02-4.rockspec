package = "resty-redis-cluster"
version = "1.02-4"
source = {
    url = "git://github.com/steve0511/resty-redis-cluster",
    tag = "1.02",
}
description = {
    summary = "Openresty lua client for redis cluster",
    detailed = [[
        Openresty environment lua client with redis cluster support.
        This is a wrapper around the 'resty.redis' library with cluster discovery
        and failover recovery support.
    ]],
    license = "Apache License 2.0"
}
build = {
    type = "builtin",
    modules = {
        ["resty.rediscluster"] = "lib/resty/rediscluster.lua",
        ["resty.xmodem"] = "lib/resty/xmodem.lua"
    }
}
