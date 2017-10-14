package = "resty-redis-cluster"
version = "1.0-1"
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
dependencies = {
}
build = {
    type = "builtin",
    modules = {
        ["resty-redis-cluster"] = "lib/rediscluster.lua"
    }
}
