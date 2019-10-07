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
    type = "make",
    build_variables = {
            CFLAGS="$(CFLAGS) -std=c99 -g",
            LIBFLAG="$(LIBFLAG)",
            LUA_LIBDIR="$(LUA_LIBDIR)",
            LUA_BINDIR="$(LUA_BINDIR)",
            LUA_INCDIR="$(LUA_INCDIR)",
            LUA="$(LUA)",
        },
        install_variables = {
            INST_PREFIX="$(PREFIX)",
            INST_BINDIR="$(BINDIR)",
            INST_LIBDIR="$(LIBDIR)",
            INST_LUADIR="$(LUADIR)",
            INST_CONFDIR="$(CONFDIR)",
        },
}
