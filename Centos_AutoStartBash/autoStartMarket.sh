#!/bin/bash
#chkconfig:  2345 81 96
#description: market
## author：雷园
. /etc/autoStartMarket/autoStartMarket.conf
export JAVA_HOME=${JAVA_INSTALL_PATH}
export PATH=.:$JAVA_HOME/bin:$PATH
export PATH=.:/usr/local/bin:$PATH
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar

function startTomcat() {
    ${TOMCAT_PATH}/bin/startup.sh
}

function startZoo() {
    ${ZOO_PATH}/bin/zkServer.sh start
}

function startRedis() {
    ${REDIS_PATH}/src/redis-server ${REDIS_CONFIG_PATH}
}

function startEmqx() {
    systemctl start emqx
}

function startMysql() {
    systemctl start mysqld
}

function startFdfsAndNginx() {
    fdfs_trackerd ${FDFS_CONFIG_PATH}/tracker.conf
    fdfs_storaged ${FDFS_CONFIG_PATH}/storage.conf
    ${NGINX_PATH}/sbin/nginx
}
function startNtp() {
    systemctl start ntpd
}

function startMongo() {
    ${MONGO_PATH}/bin/mongod -f ${MONGO_CONFIG_PATH}
}

function main() {
    if [[ ${IS_INSTALL_REDIS} -eq 0 ]]; then
        startRedis
    fi
    if [[ ${IS_INSTALL_EMQX} -eq 0 ]]; then
        startEmqx
    fi
    if [[ ${IS_INSTALL_ZOO} -eq 0 ]]; then
        startZoo
    fi
    if [[ ${IS_INSTALL_MYSQL} -eq 0 ]]; then
        startMysql
    fi
    if [[ ${IS_INSTALL_FDFS} -eq 0 ]]; then
        startFdfsAndNginx
    fi
    if [[ ${IS_INSTALL_MONGO} -eq 0 ]]; then
        startMongo
    fi
    if [[ ${IS_INSTALL_TOMCAT} -eq 0 ]]; then
        startTomcat
    fi
    if [[ ${IS_INSTALL_NTP} -eq 0 ]]; then
        startNtp
    fi
}
main