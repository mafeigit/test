#!/bin/bash
# Auto Install

# [ -f /etc/init.d/functions ] && . /etc/init.d/functions
RED_COLOR='\E[1;31m'
GREEN_COLOR='\E[1;32m'
COLOR_END='\E[0m'
IP=`ifconfig | awk -F '[ :]+' 'NR==2{print $4}'`
im_dir=/data/linkdood/im


check_env(){
check_fstab_res=`grep -v "^#" /etc/fstab | grep "/data" | awk '{print $4}'`
[ $check_fstab_res != "defaults" ] && echo -e "${RED_COLOR}/data does't have exec permission${COLOR_END}" && exit 1

[ $USER != root ] && echo "current user is not root" && exit 1
if [ `getenforce` = 'Disabled' ];then
  echo "SELINUX is disabled"
else
  sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config
fi
[ -d /data/linkdood/ ] && echo -e "${RED_COLOR}/data/linkdood/ exists,will delete this dir ${COLOR_END}" && mv /data/linkdood/ /data/bak_linkdood

cron_File=/var/spool/cron/root
sysctl_File=/etc/sysctl.conf
limit_File=/etc/security/limits.conf
nproc_File=/etc/security/limits.d/20-nproc.conf

echo "1 4 * * * /bin/find /data/linkdood/im/logs -name '*.log*' -type f -mtime +5 | xargs rm -f" >> $cron_File

cat >> $sysctl_File <<EOF
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_max_orphans = 3276800
net.core.somaxconn = 32768
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.ip_local_port_range = 15000 65535
vm.max_map_count = 262144
EOF
/usr/sbin/sysctl -p &> /dev/null

echo > $limit_File
cat >> $limit_File <<EOF
* soft nofile 65500
* hard nofile 65500
* hard nproc  65500
* soft nproc  65500
linkdood soft nproc  65500
linkdood hard nproc  65500
EOF

echo "127.0.0.1 `hostname`" >> /etc/hosts
ulimit -HSn 999999
ulimit -c 999999
# /usr/sbin/ntpdate cn.pool.ntp.org &> /dev/null

echo "*          soft    nproc     65535" > $nproc_File
echo "root       soft    nproc     unlimited" >> $nproc_File

check_profile_res=`grep "linkdood" /etc/profile|wc -l`
if [ $check_profile_res -eq 0 ];then
echo "ulimit -SHn 999999" >>/etc/profile
echo "ulimit -c 999999" >>/etc/profile
echo "export MYSQL_HOME=/data/linkdood/im/soft/mysql/bin" >>/etc/profile
echo "export JAVA_HOME=/usr/java/jdk1.8.0_191" >>/etc/profile
echo "export LD_LIBRARY_PATH=/usr/local/lib/" >>/etc/profile
echo 'export PATH=$JAVA_HOME/bin:$MYSQL_HOME:$PATH' >>/etc/profile
echo 'export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar' >>/etc/profile
echo 'export JRE_HOME=$JAVA_HOME/jre' >>/etc/profile
fi
}

decompress_tarfile(){
  if [ ! -f /root/linkdood-server.tar ];then
    echo "linkdood-server.tar is not exist in /root"
	exit 1
  fi
  echo -e "Decompressing linkdood-server.tar About ${GREEN_COLOR}Needs Ten Seconds$COLOR_END"
  [ -d /data/ ] || mkdir /data/
  tar xf /root/linkdood-server.tar -C /data/  &&\

  mv /data/data/linkdood/ /data/  && rm -rf /data/data/

  cd /data/linkdood/
  tar xf tools.tar.gz &
  echo -e "Decompressing tools.tar.gz About ${GREEN_COLOR}Needs Ten Seconds$COLOR_END"
  
  cd ${im_dir}/C++/
  tar xf dir-ap.tar.gz &
  tar xf dir-badword.tar.gz &
  tar xf dir-upload.tar.gz &
  tar xf prelogin.tar.gz &
  tar xf four_so.tar.gz &
  tar xf go-mail.tar.gz &
  tar xf chongzhuangxitong-need-so-dir.tar.gz &
  echo -e "Decompressing C++ program About ${GREEN_COLOR}Needs Ten Seconds$COLOR_END"
  
  cd ${im_dir}/soft/
  tar xf nginx.tar.gz &
  tar xf redis.tar.gz &
  tar xf fastdfs.tar.gz &
  tar xf mysql.tar.gz &> /dev/null &
  echo -e "Decompressing Third program About ${GREEN_COLOR}Needs Twenty Seconds$COLOR_END"
  
  cd ${im_dir}/vrv/
  tar xf apnsAgentConfig.tar.gz &
  tar xf elasticsearch.tar.gz &
  tar xf kafka.tar.gz &
  
  cd ${im_dir}
  tar xf IMServer.tar.gz &
  echo -e "Decompressing Java program About ${GREEN_COLOR}Needs Twenty Seconds$COLOR_END"
  sleep 180
  echo -e "${GREEN_COLOR}Decompressing Successfully...$COLOR_END"
}

remove_tarfile(){
  # rm -f /root/linkdood-server.tar
  rm -f /data/linkdood/tools.tar.gz
  
  cd ${im_dir}/C++/
  rm -f dir-ap.tar.gz dir-badword.tar.gz dir-upload.tar.gz
  rm -f prelogin.tar.gz four_so.tar.gz go-mail.tar.gz chongzhuangxitong-need-so-dir.tar.gz
  
  mkdir /usr/lib64/
  /bin/cp -arf four_so/* /usr/local/lib/
  /bin/cp -arf four_so/libtched.so /usr/lib/
  /bin/cp -arf four_so/libjni_wrap_ssl.so /usr/lib/
  /bin/cp -arf four_so/libjni_wrap_ssl.so /usr/lib64/
  
  lib_file=${im_dir}/C++/chongzhuangxitong-need-so-dir/
  [ -d /usr/local/memcached ] && mv /usr/local/memcached{,_bak}
  /bin/cp -arf ${lib_file}usr-local-lib-so/* /usr/local/lib/
  /bin/cp -arf ${lib_file}ssl/ /usr/local/
  /bin/cp -arf ${lib_file}memcached/ /usr/local/
  
  echo > /etc/ld.so.conf
  echo -e "include /etc/ld.so.conf.d/*.conf\n/lib/\n/usr/local/lib/\n/usr/local/ssl/lib/" >> /etc/ld.so.conf
  echo -e "/data/linkdood/im/soft/mysql/lib\n/usr/local/memcached" >> /etc/ld.so.conf
  ldconfig &>/dev/null

  cd ${im_dir}/soft/
  rm -f nginx.tar.gz redis.tar.gz mysql.tar.gz fastdfs.tar.gz
  rm -f ${im_dir}/IMServer.tar.gz
  cd ${im_dir}/soft/fastdfs/
  /bin/cp -arf bin/* /usr/bin/ && /bin/cp -arf fastcommon /usr/include/
  /bin/cp -arf fastdfs /usr/include/ && /bin/cp -arf fdfs /etc/
  /bin/cp -arf so/* /usr/lib/
  /bin/cp -arf so/* /usr/lib64/
  /bin/cp -arf ${im_dir}/bin/linkd /usr/bin
  [ -d /usr/java ] && mv /usr/java{,_bak}
  /bin/cp -arf /data/linkdood/tools/java /usr/
  
  cd ${im_dir}/vrv/
  rm -f apnsAgentConfig.tar.gz elasticsearch.tar.gz kafka.tar.gz
  echo -e "${GREEN_COLOR}Prepare Lib-so Successfully...$COLOR_END"
}

change_file_ip(){
  old_IP=`grep "192" /etc/fdfs/client.conf |awk -F "[=:]" '{print $2}'`
  current_IP=`ifconfig | awk -F '[ :]+' 'NR==2{print $4}'`
  nginx_dir=/data/linkdood/im/soft/nginx/conf/conf.d
  http_file=${nginx_dir}/ngx_http.conf
  https_file=${nginx_dir}/ngx_https.conf
  
  c_dir=/data/linkdood/im/C++
  # apns_file=${c_dir}/apnsAgentConfig/server.json
  ap_file=${c_dir}/dir-ap/apd.json
  prelogin_file=${c_dir}/prelogin/apinfo.json
  
  conf_fir=/data/linkdood/im/conf
  main_file=${conf_fir}/liandoudou.conf
  test_json=${conf_fir}/yinhetest.json
  
  fdfs_c=/etc/fdfs/client.conf
  fdfs_m=/etc/fdfs/mod_fastdfs.conf
  fdfs_s=/etc/fdfs/storage.conf
  need_changeIP=($http_file $https_file $apns_file $ap_file $prelogin_file $main_file $test_json $fdfs_c $fdfs_m $fdfs_s)
  
  for i in ${need_changeIP[*]}
  do
    sed -ir "s#${old_IP}#${current_IP}#g" $i
  done
}

install_debPKG(){
  cd /data/linkdood/tools/
  tar xf pythonDev_needPKG.tar.gz
  cd pythonDev_needPKG
  dpkg -i *.deb &>/dev/null
  dpkg -i python_2.7.12-1~16.04_arm64.deb &>/dev/null
  dpkg -i python-dev_2.7.12-1~16.04_arm64.deb &>/dev/null
  
  cd /data/linkdood/tools/ && tar xf rpm.tar.gz &&cd rpm/
  dpkg -i libcc1-0_5.4.0-6kord1~16.04.5_arm64.deb &>/dev/null
  dpkg -i libitm1_5.4.0-6kord1~16.04.5_arm64.deb &>/dev/null
  dpkg -i libatomic1_5.4.0-6kord1~16.04.5_arm64.deb &>/dev/null
  dpkg -i libasan2_5.4.0-6kord1~16.04.5_arm64.deb &>/dev/null
  dpkg -i libubsan0_5.4.0-6kord1~16.04.5_arm64.deb &>/dev/null
  dpkg -i libgcc-5-dev_5.4.0-6kord1~16.04.5_arm64.deb &>/dev/null
  dpkg -i gcc-5_5.4.0-6kord1~16.04.5_arm64.deb &>/dev/null
  dpkg -i gcc_4%3a5.3.1-1kord1_arm64.deb &>/dev/null
  #apt-get -y install gcc &>/dev/null
}

init_mysql(){
  main_py=/data/linkdood/tools/init_db/main.py
  # [ !-f $main_py ] && echo -e "${RED_COLOR} $main_py does't exist${COLOR_END}" && exit 2
  cd /root && /bin/bash /data/linkdood/im/bin/init_mysql.sh
  
  cd /data/linkdood/tools/
  tar xf setuptools-0.6c11.tar.gz
  cd setuptools-0.6c11/
  python setup.py build &>/dev/null
  python setup.py install &>/dev/null
  
  cd /data/linkdood/tools/ && tar xf MySQL-python-1.2.3.tar.gz
  cd MySQL-python-1.2.3/
  echo "mysql_config = /data/linkdood/im/soft/mysql/bin/mysql_config" >> site.cfg
  python setup.py build &>/dev/null
  python setup.py install &>/dev/null
  rm -rf /data/linkdood/tools/MySQL-python-1.2.3/

  [ `ls /tmp | grep "db*.log" |wc -l` -ne 0 ] && /bin/rm -f `ls /tmp/db*.log`
  echo -e "${GREEN_COLOR}Init MySQL About Ten Minutes$COLOR_END"
  chmod +x /usr/java/jdk1.8.0_191/jre/bin/*
  python2.7  /data/linkdood/tools/init_db/main.py -p /data/linkdood/tools/jsondb -f install &&\
  /bin/bash /data/linkdood/im/bin/add_two_sql.sh &>/dev/null
  python2.7 /data/linkdood/im/bin/remakeindex.py &>/dev/null &&\
  
  jar_file=/data/linkdood/im/IMServer/server-datamove-jar/platformStatisticsShardTime-1.0-SNAPSHOT.jar
  /usr/java/jdk1.8.0_191/bin/java -jar $jar_file &>/dev/null &&\
  echo -e "${GREEN_COLOR}This is Admin's account and password ${COLOR_END}"
  python /data/linkdood/im/bin/dbpwd.py -s
  # admin_file=/data/linkdood/admin_passwd.txt
  # echo "$admin_passwd" > $admin_file
  echo -e "${RED_COLOR}Reboot Your Machine And Start All Services!!!${COLOR_END}"
}

start_soft(){
  export PATH=/usr/java/jdk1.8.0_191/bin/:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:/bin/
  ulimit -HSn 999999
  ulimit -c 999999
  # start soft
  echo -e "${GREEN_COLOR}Starting Soft Program...$COLOR_END"
  cd ${im_dir}/soft/redis/src && nohup ./redis-server ../redis.conf &> /dev/null &
  #
  /usr/bin/fdfs_trackerd /etc/fdfs/tracker.conf start &
  /usr/bin/fdfs_storaged /etc/fdfs/storage.conf start &
  cd ${im_dir}/vrv/kafka/bin && nohup ./zookeeper-server-start.sh ../config/zookeeper.properties &> /dev/null &
  sleep 10
  cd ${im_dir}/vrv/kafka/bin && nohup ./kafka-server-start.sh ../config/server.properties &> /dev/null &
  sleep 5
  cd ${im_dir}/vrv/elasticsearch/bin && nohup ./elasticsearch -d &> /dev/null &
  sleep 5
}

start_java(){
  mysql_up_down=`ps -ef | grep -v grep | grep mysql | wc -l`
  if [ $mysql_up_down -eq 0 ];then
    echo -e "{$RED_COLOR}MySQL is not Running,All Program CanT be Startted$COLOR_END"
    exist 1
  fi
  echo -e "${GREEN_COLOR}Starting Java Program...$COLOR_END"
  ${im_dir}/IMServer/servers.sh start

}

start_C++(){
  echo -e "${GREEN_COLOR}Starting C++ Program...$COLOR_END"
  cd ${im_dir}/C++/prelogin && nohup ./vrv-prelogin-golang &> /dev/null &
  cd ${im_dir}/C++/dir-upload && nohup ./upload.cgi &> /dev/null &
  # cd ${im_dir}/C++/dir-ap && nohup ./ap_vrv &> /dev/null &
  cd ${im_dir}/C++/dir-badword && nohup ./badword &> /dev/null &
  cd ${im_dir}/C++/go-mail && nohup ./go-mail &> /dev/null &
  ${im_dir}/soft/nginx/sbin/nginx -p /data/linkdood/im/soft/nginx &> /dev/null &
  # systemctl start iptables &> /dev/null
}

main(){
  check_env
  decompress_tarfile
  remove_tarfile
  change_file_ip
  install_debPKG
  init_mysql
}

main

