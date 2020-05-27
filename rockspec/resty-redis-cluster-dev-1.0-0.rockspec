package = "resty-redis-cluster-dev"
version = "1.0-0"

source = {
    url = "https://github.com/steve0511/resty-redis-cluster/"
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
