#源码安装通用版mysql
#ldd --version  # 查看自己linux的glibc版本号，需要下载glibc对应的Linux-Generic源码包 https://dev.mysql.com/downloads/mysql/
#2023.12.22

#!/bin/bash
MYSQL_BASE=/usr/local
MYSQL_HOME=/data
MYSQL_PWD=123456
MYSQL_PORT=3306

echo "-----------新建mysql用户及数据目录------------"
getent group mysql;[ $? -ne 0 ] && groupadd -r mysql
id mysql || useradd -r -g mysql mysql -d /home/mysql -m
mkdir -p $MYSQL_HOME/datafile &&  mkdir -p $MYSQL_HOME/log
chown -R mysql:mysql $MYSQL_HOME && chmod -R 755 $MYSQL_HOME
echo "-----------mysql用户及数据目录创建完成:-----------"
id mysql
ls -ld $MYSQL_HOME

echo "-----------卸载系统自带mysql--------------"
rpm -qa|grep mysql|xargs -i rpm -e --nodeps {}
rpm -qa|grep "mariadb"|xargs -i rpm -e --nodeps {}

echo "-----------开始安装mysql------------------"
if [[ $# != 1 ]]; then
	echo "Usage: mysql-install.sh mysql-8*-linux-glibc*-x86_64.tar.xz"
	exit 1
fi
echo "-----------解压源码包---------------------"
tar -Jxf $1 -C ${MYSQL_BASE}
mv ${MYSQL_BASE}/mysql* ${MYSQL_BASE}/mysql

echo "-----------配置my.cnf---------------------"
cat << EOF > /etc/my.cnf 
[client]
port=${MYSQL_PORT}
socket=${MYSQL_HOME}/log/mysql.sock
[mysqld]
#解决时区问题
default-time-zone = '+8:00'
#解决mysql日志时间与系统时间不一致问题
log_timestamps=SYSTEM
port=${MYSQL_PORT}
basedir=${MYSQL_BASE}/mysql
datadir=${MYSQL_HOME}/datafile
socket=${MYSQL_HOME}/log/mysql.sock
pid-file=${MYSQL_HOME}/log/mysql.pid
log-error=${MYSQL_HOME}/log/mysqld.log
#mysql8默认禁用Symbolic links，无需再去标记禁用
#symbolic-links=0
bind-address=0.0.0.0
lower_case_table_names=1
character_set_server=utf8mb4
max_allowed_packet=500M
#SQL Mode的NO_AUTO_CREATE_USER取消
sql_mode=STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION
#InnoDB用于缓存数据、索引、锁、插入缓冲、数据字典等
innodb_buffer_pool_size=1G
#InnoDB的log buffer
innodb_log_buffer_size = 64M
#InnoDB redo log大小
innodb_log_file_size = 256M
#InnoDB redo log文件组
innodb_log_files_in_group = 2
innodb_flush_log_at_trx_commit = 2
#连接数
max_connections=600
max_connect_errors=1000
max_user_connections=400
#设置临时表最大值
max_heap_table_size = 100M
tmp_table_size = 100M
#每个连接都会分配的一些排序、连接等缓冲
sort_buffer_size = 2M
join_buffer_size = 2M
read_buffer_size = 2M
read_rnd_buffer_size = 2M
#mysql8自动关闭query cache
#query_cache_size = 0
#如果是以InnoDB引擎为主的DB，专用于MyISAM引擎的 key_buffer_size 可以设置较小，8MB 已足够,如果是以MyISAM引擎为主，可设置较大，但不能超过4G
key_buffer_size = 8M
#设置慢查询阀值，单位为秒
long_query_time = 60
slow_query_log=1         
log_output=table,File    #日志输出会写表，也会写日志文件，为了便于程序去统计，所以最好写表
slow_query_log_file=${MYSQL_HOME}/log/slow.log
#快速预热缓冲池
innodb_buffer_pool_dump_at_shutdown=1
innodb_buffer_pool_load_at_startup=1
#打印deadlock日志
innodb_print_all_deadlocks=1
#二进制配置
server-id = 1
log-bin = ${MYSQL_HOME}/log/mysql-bin.log
log-bin-index =${MYSQL_HOME}/log/binlog.index
log_bin_trust_function_creators=1
binlog_format = row
gtid_mode = ON
enforce_gtid_consistency = ON
#expire-logs-days参数取消，修改成binlog_expire_logs_seconds,单位为秒，以下代表15天
binlog_expire_logs_seconds=1296000
#schedule
event_scheduler = on
#unknown variable 'show_compatibility_56=on'
#show_compatibility_56=on
#处理TIMESTAMP with implicit DEFAULT value is deprecated
explicit_defaults_for_timestamp=true
#MySQL 8.0改了默认加密方式为“caching_sha2_password”，这里改回来
default_authentication_plugin=mysql_native_password
#禁用SSL提高性能
skip_ssl
#timeout
wait_timeout = 3600
interactive_timeout = 3600
net_read_timeout = 3600
net_write_timeout = 3600
EOF

echo "----------------初始化数据库--------------------"
${MYSQL_BASE}/mysql/bin/mysqld --defaults-file=/etc/my.cnf --initialize 
#各参数意义
#      --defaults-file: 指定配置文件 （放在--initialize-insecure前）
#      --user: 指定用户
#      --basedir: 指定安装目录
#      --datadir: 指定初始化数据目录
#      --initialize-insecure: 初始化不设置密码（若无该参数，则随机生成密码，需在 /data/mysql8/logs/mysql.log 查看）
chown -R mysql:mysql /data

echo "---------------------设置systemctl启动mysqld服务-----------------"
cat <<EOF >/lib/systemd/system/mysqld.service
[Unit]
Description=mysqld
After=network.target

[Service]
Type=forking
ExecStart=${MYSQL_BASE}/mysql/support-files/mysql.server start
ExecReload=${MYSQL_BASE}/mysql/support-files/mysql.server restart
ExecStop=${MYSQL_BASE}/mysql/support-files/mysql.server  stop
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

echo "---------------------设置环境变量-------------------------------"
cat <<EOF >>/etc/profile
export PATH=$PATH:${MYSQL_BASE}/mysql/bin
EOF
source /etc/profile 

echo "---------------------启动数据库并更改密码----------------------"
systemctl start mysqld.service
sleep 3
MYSQL_TEMP_PWD=$(grep "temporary password" ${MYSQL_HOME}/log/mysqld.log|cut -d "@" -f 2|awk '{print $2}')
#mysql 8密码策略validate_password_policy 变为validate_password.policy
#MYSQL 8.0内新增加mysql_native_password函数，通过更改这个函数密码来进行远程连接
mysql -hlocalhost  -P${MYSQL_PORT}  -uroot -p"${MYSQL_TEMP_PWD}" -e "set global validate_password.policy=0" --connect-expired-password
mysql -hlocalhost  -P${MYSQL_PORT}  -uroot -p"${MYSQL_TEMP_PWD}" -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_PWD}'"  --connect-expired-password
mysql -hlocalhost  -P${MYSQL_PORT}  -uroot -p"${MYSQL_PWD}" -e "CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_PWD}'"  --connect-expired-password
mysql -hlocalhost  -P${MYSQL_PORT}  -uroot -p"${MYSQL_PWD}" -e "grant all privileges on *.* to root@'%'"  --connect-expired-password

echo -e "\033[33m**************************************************完成mysql8.0数据库部署***************************************************\033[0m"
source /etc/profile
cat > /tmp/mysql.log  << EOF
mysql安装目录：${MYSQL_BASE}/mysql
mysql数据目录：${MYSQL_HOME}
mysql端口：${MYSQL_PORT}
mysql密码：${MYSQL_PWD}
EOF
cat /tmp/mysql.log
