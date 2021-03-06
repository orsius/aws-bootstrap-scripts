#!/bin/bash
set -x
############################################################################ 
# [BOOTSTRAP] -- rhel7 -- elasticsearch-v5 --  single node 
############################################################################ 
# Owner: gautier.franchini@data-essential.com 
# Version: 1.0.0 
# creation: 08/10/2016 
# update: [date] [who] [what] 
#   xx/xx/201x: GF -- <here are my actions>
# ############################################################################

# ## java install ## #
#java -version || yum install -y java-1.8.0-openjdk.x86_64 -y --nogpgcheck
yum install -y wget &&  cd /var/tmp && wget --no-cookies --header "Cookie: gpw_e24=xxx; oraclelicense=accept-securebackup-cookie;" http://download.oracle.com/otn-pub/java/jdk/8u101-b13/jdk-8u101-linux-x64.rpm
yum localinstall /var/tmp/jdk-8u101-linux-x64.rpm -y

# ## epel rhel 7 repository ## #
yum install  https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y --nogpgcheck

# ## install elasticsearch v5 rpm repository:
# source: https://www.elastic.co/guide/en/elasticsearch/reference/5.0/rpm.html

# v 5.x /etc/yum.repos.d/
cat << EOF > /etc/yum.repos.d/elastic-v5.repo
[elasticsearch-5.x]
name=Elasticsearch repository for 5.x packages
baseurl=https://artifacts.elastic.co/packages/5.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF
# Add the necessary keys for verification:
/usr/bin/rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

# ## install elasticsearch ## #
yum install elasticsearch -y --nogpgcheck

# ## configure elasticsearch:
# source: https://www.elastic.co/guide/en/elasticsearch/reference/5.0/settings.html
cp /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.origin

# setup a custom config -- path: /etc/elasticsearch/elasticsearch.yml
# ## /usr/share/elasticsearch/bin/elasticsearch -Edefault.node.name=${HOSTNAME}

cat << EOF > /etc/elasticsearch/elasticsearch.yml
node.name: ${HOSTNAME}
http.port: 9200
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
EOF

#cp /etc/sysconfig/elasticsearch /etc/sysconfig/elasticsearch.origin
#cat << EOF > /etc/sysconfig/elasticsearch
#ES_HEAP_SIZE=15g 
#MAX_LOCKED_MEMORY=unlimited
#EOF

cp /etc/elasticsearch/jvm.options /etc/elasticsearch/jvm.options.origin
cat << EOF > /etc/elasticsearch/jvm.options
-Xms4g
-Xmx4g
-XX:+UseConcMarkSweepGC
-XX:CMSInitiatingOccupancyFraction=75
-XX:+UseCMSInitiatingOccupancyOnly
-XX:+DisableExplicitGC
-XX:+AlwaysPreTouch
-server
-Djava.awt.headless=true
-Dfile.encoding=UTF-8
-Djna.nosys=true
-Dio.netty.noUnsafe=true
-Dio.netty.noKeySetOptimization=true
-Dlog4j.shutdownHookEnabled=false
-Dlog4j2.disable.jmx=true
-Dlog4j.skipJansi=true
-XX:+HeapDumpOnOutOfMemoryError
EOF

#set the proper configuration file for the "pam_limits module" :

cat << EOF > /etc/security/limits.d/elasticsearch-pam.conf
## elasticsearch
* soft nofile 65000
* hard nofile 65000

elasticsearch soft memlock unlimited
elasticsearch hard memlock unlimited
EOF

# Increase max_map_count Parameter
VALUE=262144
# virtual memory 
sysctl vm.max_map_count=${VALUE}

sysctl vm.max_map_count
# thread
ulimit -u 65000
# The above changes will be reverted on machine reboot. To make the change permanent, do:
cat << EOF > /etc/sysctl.d/50-portalsearch.conf
vm.max_map_count = ${VALUE}
EOF
# Reload the config file:
sysctl -p


# check elasticsearch logs:
# sudo journalctl --unit elasticsearch --since today

# set the proper rights to the files: 
  chown elasticsearch:elasticsearch /etc/elasticsearch/*

# to avoid any memory allocation issue do
cp /usr/lib/systemd/system/elasticsearch.service /usr/lib/systemd/system/elasticsearch.service.origin
# Edit the service file and un-comment line 38 to set LimitMEMLOCK=infinity :
sed -i '/^\#LimitMEMLOCK=infinity/ { s/\#//; }' /usr/lib/systemd/system/elasticsearch.service
systemctl daemon-reload

# start the service:
  systemctl start elasticsearch && sleep 10 ; systemctl status elasticsearch

# enable the service at boot:
  systemctl enable elasticsearch

# access the web interface through: http://[your IP]:9200/
  echo "you can access the web interface through: http://${HOSTNAME}:9200 "
  curl -XGET "http://${HOSTNAME}:9200"

# ## configure elasticsearch plugin:
/usr/share/elasticsearch/bin/elasticsearch-plugin list
# The EC2 discovery plugin uses the AWS API for unicast discovery.
# -> Installed discovery-ec2
#/usr/share/elasticsearch/bin/elasticsearch-plugin install discovery-ec2 -b

# -> Downloading x-pack from elastic
#/usr/share/elasticsearch/bin/elasticsearch-plugin install x-pack -b

# filebeat metric beat to monitor es activity
#yum install filebeat metricbeat -y




