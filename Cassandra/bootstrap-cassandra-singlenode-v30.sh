#!/bin/bash
set -x
############################################################################ 
# [BOOTSTRAP] -- rhel7 -- cassandra --  single node 
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
yum install  https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y

# ## install cassandra rpm repository:
# source: https://docs.datastax.com/en/cassandra/2.1/cassandra/install/installRHEL_t.html

cat << EOF > /etc/yum.repos.d/datastax.repo
[datastax] 
name = DataStax Repo for Apache Cassandra
baseurl = https://rpm.datastax.com/community
enabled = 1
gpgcheck = 0
EOF

# Add the necessary keys for verification:
#  cd /etc/yum.repos.d/ && rpm --import https://<website>/GPG-KEY-<filename>

# ## install cassandra ## #
yum install cassandra30.noarch cassandra30-tools.noarch -y --nogpgcheck

# ## configure cassandra:

# start the service:
  systemctl start cassandra && sleep 10 ; systemctl status cassandra

# enable the service at boot:
  systemctl enable cassandra