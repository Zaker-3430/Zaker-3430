#!/bin/bash
#调用函数库
[ -f /etc/init.d/functions ] && source /etc/init.d/functions
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
source /etc/profile

#Require root to run this script.
[ $(id -u) -gt 0 ] && echo "请用root用户执行此脚本！" && exit 1

if [ $# != 1 ]; then
	echo "Usage: java-install.sh jdk*.tgz"
	exit 1
fi

echo "Unarchiving jdk..."
tar -xzf $1 -C /usr/local/
mv /usr/local/jdk* /usr/local/jdk

echo "make /etc/profile..."
cat >> /etc/profile << EOF
export JAVA_HOME=/usr/local/jdk
export JRE_HOME=/usr/local/jdk/jre
export CLASSPATH=.:/usr/local/jdk/lib:/usr/local/jdk/lib
export PATH=/usr/local/jdk/bin:$PATH
EOF

source /etc/profile 
java -version
[ $? -eq 0 ] && echo "java安装完成"
echo "安装路径：/usr/local/jdk"
