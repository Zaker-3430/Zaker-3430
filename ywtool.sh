#!/bin/bash
#
[ -f /etc/init.d/functions ] && . /etc/init.d/functions
[ -f ./shell/sysinit.sh ] && . ./shell/sysinit.sh
##基础变量
DATE=`date +"%F-%T"`
IPADDR=`hostname -I |awk '{print$1}'`
HOSTNAME=`hostname -s`
USER=`whoami`


menu_1(){
cat << EOF
----------------------------------------------
|       Please Enter Your Choice:[1-9]       |
----------------------------------------------
*   `echo -e "\033[35m 1)禁用selinux和防火墙\033[0m"`
*   `echo -e "\033[35m 2)设置中文字符集\033[0m"`
*   `echo -e "\033[35m 3)新建用户\033[0m"`
*   `echo -e "\033[35m 4)配置YUM源\033[0m"`
*   `echo -e "\033[35m 5)创建lvm逻辑卷并挂载文件系统\033[0m"`
*   `echo -e "\033[35m 6)优化内核参数/etc/sysctl.conf\033[0m"`
*   `echo -e "\033[35m 7)优化文件描述符限制/etc/security/limits.conf\033[0m"`
*   `echo -e "\033[35m 8)返回主菜单\033[0m"`
*   `echo -e "\033[35m 9)退出\033[0m"`
EOF
read -p "please input optios[1-9]: " num1
case $num1 in 
  1)Firewall ;;
  2)zh_CN ;;
  3)AddUser ;;
  4)Yum ;;
  5)Auto_lvm ;;
  6)Sysctl ;;
  7)Limits ;;
  8)clear;main_menu ;;
  9)clear break ;;
  *)
   clear
   echo -e "\033[31mYour Enter was wrong,Please input again Choice:[1-9\033[0m"
   menu_1
esac
}

menu_2(){
cat << EOF
----------------------------------------------
|       Please Enter Your Choice:[1-10]       |
----------------------------------------------
*   `echo -e "\033[35m 1)安装Jdk\033[0m"`
*   `echo -e "\033[35m 2)安装MySQL 5.7.X\033[0m"`
*   `echo -e "\033[35m 3)安装MySQL 8.X\033[0m"`
*   `echo -e "\033[35m 4)安装Redis\033[0m"`
*   `echo -e "\033[35m 5)安装Nginx\033[0m"`
*   `echo -e "\033[35m 6)安装Docker\033[0m"`
*   `echo -e "\033[35m 7)安装Containerd\033[0m"`
*   `echo -e "\033[35m 8)安装Tomcat\033[0m"`
*   `echo -e "\033[35m 9)返回主菜单\033[0m"`
*   `echo -e "\033[35m 10)退出\033[0m"`
EOF
read -p "please input optios[1-10]: " num2
case $num2 in
  1)Jdk ;;
  2)Mysql_57 ;;
  3)Mysql_80 ;;
  4)Redis ;;
  5)Nginx ;;
  6)Docker ;;
  7)Containerd ;;
  8)Tomcat ;;
  9)clear;main_menu ;;
  10)clear break ;;
  *)
   clear
   echo -e "\033[31mYour Enter was wrong,Please input again Choice:[1-10]\033[0m"
   menu_2
esac
}

menu_3(){
cat << EOF
--------------------------------------------
|`echo -e "\033[31m     Please Enter Your Choice:[0-10]\033[0m"`      |
--------------------------------------------
*   `echo -e "\033[35m 0)系统基础信息\033[0m"`
*   `echo -e "\033[35m 1)CPU使用率前5进程\033[0m"`
*   `echo -e "\033[35m 2)内存使用率前5进程\033[0m"`
*   `echo -e "\033[35m 3)查找指定目录占用空间最大的目录或文件\033[0m"`
*   `echo -e "\033[35m 4)查看指定进程信息\033[0m"`
*   `echo -e "\033[35m 5)jstack堆栈打印\033[0m"`
*   `echo -e "\033[35m 6)jmap堆内存导出\033[0m"`
*   `echo -e "\033[35m 7)根据端口查进程\033[0m"`
*   `echo -e "\033[35m 8)一键备份目录|文件\033[0m"`
*   `echo -e "\033[35m 9)返回主菜单\033[0m"`
*   `echo -e "\033[35m 10)退出\033[0m"`
EOF
read -p "please input optios[1-10]: " num3
case $num3 in
  0)Systeminfo ;;
  1)Cpu_top5 ;;
  2)Mem_top5 ;;
  3)Duh ;;
  4)Psinfo ;;
  5)Jstack ;;
  6)Jmap ;;
  7)Port_process ;;
  8)Backfile ;;
  9)clear;main_menu ;;
  10)clear break ;;
  *)
   clear
   echo -e "\033[31mYour Enter was wrong,Please input again Choice:[1-10]\033[0m"
   menu_3
esac
}

main_menu(){
cat << EOF
------------System Infomation-----------------
DATE     : $DATE                          
HOSTNAME : $HOSTNAME                      
USER     : $USER                          
IP       : $IPADDR                        
----------------------------------------------
|       Please Enter Your Choice:[1-4]       |
----------------------------------------------
*   `echo -e "\033[35m 1)系统配置\033[0m"`
*   `echo -e "\033[35m 2)软件安装\033[0m"`
*   `echo -e "\033[35m 3)故障排查\033[0m"`
*   `echo -e "\033[35m 4)退出\033[0m"`
EOF
read -p "please input optios[1-4]: " num
case $num in
  1)menu_1 ;;
  2)menu_2 ;;
  3)menu_3 ;;
  4)clear break ;;
  *)
   clear
   echo -e "\033[31mYour Enter was wrong,Please input again Choice:[1-4]\033[0m"
   main_menu
esac
}
main_menu
