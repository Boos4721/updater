#!bin/bash

yum -y update
yum install -y java-1.8.0-openjdk
systemctl start firewalld
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --reload
mkdir -p /www/api && cd /www/api
yum install wget 
wget https://hub.fastgit.org/ZimoLoveShuang/wisedu-unified-login-api/releases/download/v1.0.19/wisedu-unified-login-api-v1.0.jar
nohup java -jar wisedu-unified-login-api-v1.0.jar --server.port=80>jinri.log 2>&1 &
echo -e "Done"
