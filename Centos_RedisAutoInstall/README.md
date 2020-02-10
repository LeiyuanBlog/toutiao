#### 单机版Redis宕机导致数据丢失？来试试一主两从三哨兵吧，内附自动化部署脚本

1. 大家拉取代码后进入目录**Centos_RedisAutoInstall**中，修改配置文件**config**

   ```properties
   # 本机内网IP
   IP=10.0.4.16
   ## 1:HOST 2:CLUSTER 3:SENTINEL
   ## 2暂不支持
   REDIS_TYPE=1
   REDIS_PORT=6379
   REDIS_SENTINEL_PORT=26379
   # 主节点IP
   REDIS_MASTER=10.0.4.16
   REDIS_PASS=Hanshow123!@#
   ```

2. 配置完成后运行同目录中的**redis.sh**即可进行Redis的自动安装以及配置，对于配置文件大家如果有什么不理解的地方都可以提出来。