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

5. Support read from slave like Redisson/lettuce, both usual command and pipeline. 

6. Support online resharding of redis cluster(both for usual command and pipeline. resty-redis-cluster will handle the #MOVED signal by re-cache the slot mapping and retrying. resty-redis-cluster will handle the #ASK signal by retrying with asking to redirection target nodes

7. Support error handling for the different failure scenario of redis cluster. (etc.Singel slave, master fail, cluster down)

8. fix some critical issues of https://github.com/cuiweixie/lua-resty-redis-cluster. 
   1) memory leak issues while high throughput. Cosocket operation will casue the suspend and swith of coroutine, so there would be multiple requests still have reference to the big slot mapping cache. This will cause LUAJIT VM crashed.
   
   2) we must refresh slot cache mapping in case any redis nodes connection failure, otherwise we will not get the latest slot cache mapping and always get failure. Refer to Jedis, same behaviour to referesh cache mapping while any unknown connection issue. 
   
   3) We must handle ASK redirection in usual commands
   
   4) Pipeline must also handle ASK/MOVED singal.
   
