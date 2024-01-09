#!/bin/bash
#################################
# copyright by zk
# DATE:2020-12-3
#
#设置中文字符集
#关闭 Selinux 和防火墙
#时间同步
#配置yum源
#新建用户并加入visudo
#lvm逻辑卷自动创建
#优化内核参数/etc/sysctl.conf
#修改/etc/security/limits.conf
#################################
#配置变量
NTP_SERVER=192.168.1.1   # 定义NTP服务器
ISO=/root/CentOS-7-x86_64-Everything-1611.iso  # 定义系统iso文件的存放位置
#partition=/data                # 定义最终挂载的名称
#vgname=data-vg                 # 定义逻辑卷组的名称
#lvname=data-lv               # 定义逻辑卷的名称
#blk='/sdb,/sdc'   # 定义磁盘分区号，根据分区的实际情况修改

#Require root to run this script.
[ $(id -u) -gt 0 ] && echo "请用root用户执行此脚本！" && exit 1
[ -f ../ywtool.sh ]  && . ../ywtool.sh
#设置中文字符集
function zh_CN()
{
  echo ""
  echo -e "\033[33m***************************************************更改中文字符集****************************************************\033[0m"
  \cp /etc/locale.conf  /etc/locale.conf.$(date +%F)
cat >/etc/locale.conf<<EOF
LANG="zh_CN.UTF-8"
#LANG="en_US.UTF-8"
EOF
  source /etc/locale.conf
  grep LANG /etc/locale.conf
  echo -e "\033[33m***********************************************更改字符集zh_CN.UTF-8完成*********************************************\033[0m"
  echo ""
  sleep 3
}

#关闭 Selinux 和防火墙
function Firewall()
{
  echo ""
  echo -e "\033[33m*************************************************禁用selinux和防火墙*************************************************\033[0m"
  \cp /etc/selinux/config /etc/selinux/config.$(date +%F)
  systemctl stop firewalld && systemctl disable firewalld
  sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
  setenforce 0
  systemctl status firewalld
  echo '#grep SELINUX=disabled /etc/selinux/config ' 
  grep SELINUX=disabled /etc/selinux/config 
  echo '#getenforce '
  getenforce 
  echo -e "\033[33m************************************************完成禁用selinux和防火墙**********************************************\033[0m"
  echo ""
  menu_1
}

#时间同步
##$?是指上一次命令执行的成功或者失败的状态，成功为0，失败为1
function Time ()
{
  echo ""
  echo -e "\033[33m******************************************************配置时间同步***************************************************\033[0m"
  \cp /var/spool/cron/root /var/spool/cron/root.$(date +%F) 2>/dev/null
  NTPDATE=`grep ntpdate /var/spool/cron/root 2>/dev/null |wc -l`
  if [ $NTPDATE -eq 0 ];then
  	ping -c 4 0.asia.pool.ntp.org >/dev/null 2>&1
    if [ $? -eq 0 ];then
       echo "#times sync by hwb at $(date +%F)" >>/var/spool/cron/root
       echo "*/5 * * * * /usr/sbin/ntpdate 0.asia.pool.ntp.org;/sbin/hwclock -w &>/dev/null" >> /var/spool/cron/root
       hwclock --systohc  #同步到硬件
    else
       ping -c 4 $NTP_SERVER >/dev/null 2>&1
       if [ $? -eq 0 ];then
          echo "#times sync by hwb at $(date +%F)" >>/var/spool/cron/root
          echo "* 8 * * *  /usr/sbin/ntpdate $NTP_SERVER;/sbin/hwclock -w" >> /var/spool/cron/root
          hwclock --systohc  #同步到硬件
       else
          echo "==============网络不通，无法配置时间同步==========="
          #exit $?和exit $1区别
          exit $?
       fi
    fi 
    
  fi 
  echo '#crontab -l'  
  crontab -l
  echo -e "\033[33m*************************************************完成时间同步配置**************************************************\033[0m"
  echo ""
  sleep 3
}

#配置yum源
function Yum(){
  echo ""
  echo -e "\033[33m***************************************************开始配置yum源****************************************************\033[0m"
  ping -c 4  mirrors.aliyun.com  >/dev/null
  if [ $? -eq 0 ];then
     configAliyunYum
  else
     if [ -f $ISO ];then
       	configLocalYum
     else
        action "\033[33m**********************网络不通且本地没有yum源,请手动配置yum***********************\033[0m"  /bin/true
        exit $?
     fi
  fi 
}


#Config Yum lianyou.repo and save Yum file
configLocalYum(){
  echo ""
  echo -e "\033[33m***************************************************配置本地yum*************************************************\033[0m"
  for i in /etc/yum.repos.d/*.repo;do cp $i ${i%.repo}.bak;done
  rm -rf /etc/yum.repos.d/*.repo
  mkdir -p /mnt/cdrom && mount -o loop -t iso9660 $ISO /mnt/cdrom/
  echo "================配置YUM源文件===================="
cat << EOF > /etc/yum.repos.d/localyum.repo 
[InstallMedia]
name=Centos 7
baseurl=file:///mnt/cdrom/
enabled=1
gpgcheck=0 
EOF
  yum clean all && yum makecache  >/dev/null 2>&1
  yum repolist
  echo -e "\033[33m***********************************************完成本地yum配置**************************************************\033[0m"
  echo ""
  sleep 3
}


#Config Yum CentOS-Bases.repo and save Yum file
configAliyunYum(){
  echo ""
  echo -e "\033[33m***************************************************更新为阿里源*****************************************************\033[0m"
  for i in /etc/yum.repos.d/*.repo;do cp $i ${i%.repo}_bak;done
  rm -rf /etc/yum.repos.d/*.repo
  wget -P /etc/yum.repos.d/ http://mirrors.aliyun.com/repo/Centos-7.repo >/dev/null 2>&1
  wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo >/dev/null 2>&1
  echo "================配置YUM源文件===================="
  sed -i 's#keepcache=0#keepcache=1#g' /etc/yum.conf     
  grep keepcache /etc/yum.conf
  yum clean all >/dev/null 2>&1
  yum makecache  >/dev/null 2>&1
  yum repolist
  echo -e "\033[33m***************************************************完成阿里源配置***************************************************\033[0m"
  echo ""
  sleep 3
}

#新建用户并加入visudo
function AddUser(){
  echo ""
  echo -e "\033[33m*****************************************************新建用户*******************************************************\033[0m"
#add user
while true
do  
    read -p "请输入新用户名:" name
    NAME=`awk -F':' '{print $1}' /etc/passwd|grep -wx $name 2>/dev/null|wc -l`
    if [ ${#name} -eq 0 ];then
       echo "用户名不能为空，请重新输入。"
       continue
    elif [ $NAME -eq 1 ];then
       echo "用户名已存在，请重新输入。"
       continue
    fi
useradd $name
break
done
#create password
while true
do
    read -p "为 $name 创建一个密码:" pass1
    if [ ${#pass1} -eq 0 ];then
       echo "密码不能为空，请重新输入。"
       continue
    fi
    read -p "请再次输入密码:" pass2
    if [ "$pass1" != "$pass2" ];then
       echo "两次密码输入不相同，请重新输入。"
       continue
    fi
echo "$pass2" |passwd --stdin $name
break
done
sleep 1

#add visudo
echo "#####add visudo#####"
\cp /etc/sudoers /etc/sudoers.$(date +%F)
SUDO=`grep -w "$name" /etc/sudoers |wc -l`
if [ $SUDO -eq 0 ];then
    echo "$name  ALL=(ALL)       NOPASSWD: ALL" >>/etc/sudoers
    echo '#tail -1 /etc/sudoers'
    grep -w "$name" /etc/sudoers
    sleep 1
fi
  #action "创建用户$name并将其加入visudo完成"  /bin/true
  echo -e "\033[33m*********************************************创建用户$name并将其加入visudo完成******************************************\033[0m"
  echo ""
  sleep 3
}


#lvm逻辑卷自动创建
function Auto_lvm ()
{
  echo ""
  echo -e "\033[33m***************************************************开始配置lvm****************************************************\033[0m"
  read -p "输入挂载点：" dir
  read -p "输入vgname: " vgname
  read -p "输入lvname: " lvname
  read -p "输入文件系统格式：ext4|xfs " filetype
  read -p "输入要加入卷组的磁盘：sdb sdc " harddisk
 
  disk=  
  for i in $harddisk
  do 
    disk="$disk /dev/$i"
  done
 
  pvcreate $disk
  vgcreate $vgname $disk
  lvcreate -l 100%VG -n $lvmname $vgname
  mkfs.$filetype /dev/$vgname/$lvmname
 
  mkdir -p $dir
  echo "/dev/$vgname/$lvmname  $dir  ext4 defaults  0 0" >> /etc/fstab
  mount -a
  df -h |grep $dir

  echo -e "\033[33m*********************************************lvm自动创建挂载完成******************************************\033[0m"
  echo ""
  sleep 3
}

#修改/etc/sysctl.conf
function Sysctl ()
{  
  echo ""
  echo -e "\033[33m***************************************************开始配置sysctl.conf****************************************************\033[0m"
  cat >>/etc/sysctl.conf<<EOF
#系统优化参数
#关闭ipv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
#决定检查过期多久邻居条目
net.ipv4.neigh.default.gc_stale_time=120
#使用arp_announce / arp_ignore解决ARP映射问题
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.all.arp_announce=2
net.ipv4.conf.lo.arp_announce=2
# 避免放大攻击
net.ipv4.icmp_echo_ignore_broadcasts = 1
# 开启恶意icmp错误消息保护
net.ipv4.icmp_ignore_bogus_error_responses = 1
#关闭路由转发
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
#开启反向路径过滤
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
#处理无源路由的包
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
#关闭sysrq功能
kernel.sysrq = 0
#core文件名中添加pid作为扩展名
kernel.core_uses_pid = 1
# 开启SYN洪水攻击保护
net.ipv4.tcp_syncookies = 1
#修改消息队列长度
kernel.msgmnb = 65536
kernel.msgmax = 65536
#设置最大内存共享段大小bytes
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
#timewait的数量，默认180000
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096        87380   4194304
net.ipv4.tcp_wmem = 4096        16384   4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
#每个网络接口接收数据包的速率比内核处理这些包的速率快时，允许送到队列的数据包的最大数目
net.core.netdev_max_backlog = 262144
#限制仅仅是为了防止简单的DoS 攻击
net.ipv4.tcp_max_orphans = 3276800
#未收到客户端确认信息的连接请求的最大值
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0
#内核放弃建立连接之前发送SYNACK 包的数量
net.ipv4.tcp_synack_retries = 1
#内核放弃建立连接之前发送SYN 包的数量
net.ipv4.tcp_syn_retries = 1
#启用timewait 快速回收
net.ipv4.tcp_tw_recycle = 1
#开启重用。允许将TIME-WAIT sockets 重新用于新的TCP 连接
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 1
#当keepalive 起用的时候，TCP 发送keepalive 消息的频度。缺省是2 小时
net.ipv4.tcp_keepalive_time = 1800
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 15
#允许系统打开的端口范围
net.ipv4.ip_local_port_range = 1024    65000
#修改防火墙表大小，默认65536
net.netfilter.nf_conntrack_max=655350
net.netfilter.nf_conntrack_tcp_timeout_established=1200
# 确保无人能修改路由表
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
vm.swappiness = 10
kernel.panic = 5
#最大打开文件数
fs.file-max = 165535
# for high-latency network
net.ipv4.tcp_congestion_control = hybla
#maximize the available memory
vm.overcommit_memory = 1
vm.dirty_ratio = 1
vm.swappiness = 10
vm.vfs_cache_pressure = 110
#vm.zone_reclaim_mode = 0

#keep the IO performance steady
vm.dirty_background_ratio = 1
vm.dirty_writeback_centisecs = 100
vm.dirty_expire_centisecs = 100
EOF
  echo -e "\033[33m***************************************************sysctl.conf配置完成****************************************************\033[0m"
  echo ""
  sleep 3
}

#修改/etc/security/limits.conf
function Limits ()
{ 
  echo ""
  echo -e "\033[33m***************************************************开始配置limits.conf****************************************************\033[0m"
  if [ ! -f "/etc/security/limits.conf.bak" ]; then
    cp /etc/security/limits.conf /etc/security/limits.conf.bak
fi

cat > /etc/security/limits.conf << EOF
* soft nofile 1024000
* hard nofile 1024000
* soft nproc  1024000
* hard nproc  1024000
hive   - nofile 1024000
hive   - nproc  1024000
EOF
  echo -e "\033[33m***************************************************sysctl.conf配置完成****************************************************\033[0m"
  echo ""
  sleep 3
}


function menu ()
{ 
while true;
do
cat <<EOF
----------------------------------------
|****Please Enter Your Choice:[0-8]****|
----------------------------------------
(1) 设置中文字符集
(2) 关闭 Selinux 和防火墙
(3) 时间同步
(4) 配置yum源
(5) 新建用户并加入visudo
(6) lvm逻辑卷自动创建
(7) 优化内核参数/etc/sysctl.conf
(8) 修改/etc/security/limits.conf
(9) 退出
EOF
  read -p "Please enter your choice[0-9]: " input
  case $input in
  1)
    zh_CN
	;;
  2)
    Firewall
	;;
  3)
    Time
	;;
  4)
    Yum
	;; 
  5)
    AddUser
	;;
  6)
    Auto_lvm
	;;
  7)
    Sysctl
	;;
  8)
    Limits
	;;
  9)
    exit 0
	;;
  *)
   echo "----------------------------------"
   echo "|          Warning!!!            |"
   echo "|   Please Enter Right Choice!   |"
   echo "----------------------------------"
 esac
done
} 

function main()
{
    while true
    do
       menu
    done
}

#main


  
