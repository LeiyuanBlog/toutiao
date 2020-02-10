#!/bin/bash
## author：雷园
. ./config
install_redis
function install_redis() {
    yum -y install unzip autoconf automake bzip2 bzip2-devel cmake freetype-devel gcc gcc-c++ git libtool make mercurial pkgconfig zlib-devel  >/dev/null 2>&1
    yum -y install zlib zlib-devel pcre pcre-devel gcc gcc-c++ openssl openssl-devel libevent libevent-devel perl wget unzip automake autoconf libtool make dos2unix  >/dev/null 2>&1
    echo '创建必备目录'
    mkdir -p /app/software/
    echo '开始安装Redis，密码：'${REDIS_PASS}'，安装时间较长，请耐心等待'
    tar -zxvf ./redis-5.0.5.tar.gz -C /app/software/ >/dev/null 2>&1
    mv /app/software/redis-5.0.5 /app/software/redis
    cd /app/software/redis && make >/dev/null 2>&1 && cd src && ln -s /app/software/redis/src/redis-server /usr/local/bin/redis-server && ln -s /app/software/redis/src/redis-cli /usr/local/bin/redis-cli && ln -s /app/software/redis/src/redis-sentinel /usr/local/bin/redis-sentinel

    # 安装并启动redis
    if [[ ${REDIS_TYPE} -eq 1 ]]; then
        echo '现在进行单实例模式配置'
        type_singleton
    elif [[ ${REDIS_TYPE} -eq 2 ]]; then
        type_name='集群模式'
    elif [[ ${REDIS_TYPE} -eq 3 ]]; then
        echo '现在进行一主两从三哨兵模式配置'
        type_sentinel
    fi
}

## 单实例模式
function type_singleton() {
    redis_config_dir="/etc/redis/${REDIS_PORT}"
    mkdir -p ${redis_config_dir}/
    \cp /app/software/redis/redis.conf ${redis_config_dir}/
    sed -i 's#daemonize no#daemonize yes#g' ${redis_config_dir}/redis.conf >/dev/null 2>&1
    sed -i 's/# requirepass foobared/requirepass '${REDIS_PASS}'/g' ${redis_config_dir}/redis.conf >/dev/null 2>&1
    sed -i 's/127.0.0.1/0.0.0.0/g' ${redis_config_dir}/redis.conf >/dev/null 2>&1
    sed -i 's/6379/'${REDIS_PORT}'/g' ${redis_config_dir}/redis.conf >/dev/null 2>&1
    redis-server ${redis_config_dir}/redis.conf >/dev/null 2>&1
}

## 集群模式
function type_cluster() {
    echo '暂未支持集群模式'
}

## 一主两从三哨兵
function type_sentinel() {
    echo "配置redis数据节点"
    redis_config_dir="/etc/redis/${REDIS_PORT}"
    mkdir -p ${redis_config_dir}/
    \cp /app/software/redis/redis.conf ${redis_config_dir}/
    sed -i 's/daemonize/# daemonize/g' ${redis_config_dir}/redis.conf >/dev/null 2>&1
    sed -i 's/port 6379/# port/g' ${redis_config_dir}/redis.conf >/dev/null 2>&1
    sed -i 's/masterauth/# masterauth/g' ${redis_config_dir}/redis.conf >/dev/null 2>&1
    sed -i 's/requirepass/# requirepass/g' ${redis_config_dir}/redis.conf >/dev/null 2>&1
    sed -i 's/protected-mode/# protected-mode/g' ${redis_config_dir}/redis.conf >/dev/null 2>&1
    sed -i 's/bind/# bind/g' ${redis_config_dir}/redis.conf >/dev/null 2>&1

    cat >>${redis_config_dir}/redis.conf<<EOF
daemonize yes
port ${REDIS_PORT}
masterauth ${REDIS_PASS}
requirepass ${REDIS_PASS}
protected-mode yes
# 服务器ip地址
bind 0.0.0.0
EOF
    if [[ ${IP} != ${REDIS_MASTER} ]]; then
        echo "slaveof ${REDIS_MASTER} ${REDIS_PORT}" >> ${redis_config_dir}/redis.conf
    fi
    redis-server ${redis_config_dir}/redis.conf >/dev/null 2>&1
    echo "配置redis哨兵节点"
    sentinel_config_dir="/etc/redis/${REDIS_SENTINEL_PORT}"
    mkdir -p ${sentinel_config_dir}/
    \cp /app/software/redis/sentinel.conf ${sentinel_config_dir}
    sed -i 's/port 26379/# port 26379/g' ${sentinel_config_dir}/sentinel.conf >/dev/null 2>&1
    sed -i 's/daemonize no/# daemonize no/g' ${sentinel_config_dir}/sentinel.conf >/dev/null 2>&1
    sed -i 's/sentinel monitor mymaster/# sentinel monitor mymaster/g' ${sentinel_config_dir}/sentinel.conf >/dev/null 2>&1
    sed -i 's/sentinel auth-pass mymaster/# sentinel auth-pass mymaster/g' ${sentinel_config_dir}/sentinel.conf >/dev/null 2>&1
    sed -i 's/sentinel down-after-milliseconds mymaster/# sentinel down-after-milliseconds mymaster/g' ${sentinel_config_dir}/sentinel.conf >/dev/null 2>&1
    sed -i 's/sentinel parallel-syncs mymaster/# sentinel parallel-syncs mymaster /g' ${sentinel_config_dir}/sentinel.conf >/dev/null 2>&1
    sed -i 's/sentinel failover-timeout mymaster/# sentinel failover-timeout mymaster/g' ${sentinel_config_dir}/sentinel.conf >/dev/null 2>&1
    sed -i 's/bind/# bind/g' ${sentinel_config_dir}/sentinel.conf >/dev/null 2>&1
    sed -i 's/protected-mode/# protected-mode/g' ${sentinel_config_dir}/sentinel.conf >/dev/null 2>&1
    cat >>${sentinel_config_dir}/sentinel.conf<<EOF
daemonize yes
port ${REDIS_SENTINEL_PORT}
sentinel monitor mymaster ${REDIS_MASTER} ${REDIS_PORT} 2
sentinel auth-pass mymaster ${REDIS_PASS}
sentinel down-after-milliseconds mymaster 15000
sentinel parallel-syncs mymaster 1
sentinel failover-timeout mymaster 80000
bind 0.0.0.0
protected-mode yes
EOF
    redis-sentinel ${sentinel_config_dir}/sentinel.conf
}