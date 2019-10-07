#ifndef LUA_RESTY_RADIXTREE_H
#define LUA_RESTY_RADIXTREE_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdio.h>
#include <ctype.h>


#ifdef BUILDING_SO
    #ifndef __APPLE__
        #define LSH_EXPORT __attribute__ ((visibility ("protected")))
    #else
        /* OSX does not support protect-visibility */
        #define LSH_EXPORT __attribute__ ((visibility ("default")))
    #endif
#else
    #define LSH_EXPORT
#endif

/* **************************************************************************
 *
 *              Export Functions
 *
 * **************************************************************************
 */

int lua_redis_crc16(char *key, int keylen);

#ifdef __cplusplus
}
#endif

#endif
