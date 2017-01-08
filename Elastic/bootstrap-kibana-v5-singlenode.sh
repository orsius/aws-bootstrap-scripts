#!/bin/bash
set -x
############################################################################ 
# [BOOTSTRAP] -- rhel7 -- kibana-v5 --  single node 
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


# ## install elastic v5 rpm repository:
# source: https://www.elastic.co/guide/en/elasticsearch/reference/5.0/rpm.html

# v 5.x
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
  cd /etc/yum.repos.d/ && rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

# ## install kibana ## #
yum install kibana -y --nogpgcheck

# ## configure kibana:
cd /etc/kibana/ && cp kibana.yml kibana.yml.origin

cat << EOF > /etc/kibana/kibana.yml
server.port: 5601
server.host: ${HOSTNAME}
elasticsearch.url: "http://${HOSTNAME}:9200"
kibana.index: ".kibana"
elasticsearch.username: "superdry"
elasticsearch.password: "superdry"
EOF

# check kibana logs:
# sudo journalctl --unit kibana --since today

# set the proper rights to the files: 
  chown kibana:kibana /etc/kibana/*

# start the service:
  systemctl start kibana && sleep 10 ; systemctl status kibana
# yum install iproute -y  
  ss -lntp | grep 5601 && logger -t INFO  "LISTEN: OK" || logger -t INFO "LISTEN: ERR"
# enable the service at boot:
  systemctl enable kibana

# access the web interface through: http://[your IP]:5601
  echo "you can access the web interface through: http://${HOSTNAME}:5601 "
  curl -XGET "http://${HOSTNAME}:5601"



