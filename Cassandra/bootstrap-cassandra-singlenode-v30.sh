#!/bin/bash
set -x
############################################################################ 
# [BOOTSTRAP] -- rhel7 -- datastax -- cassandra --  single node 
############################################################################ 
# Owner: gautier.franchini@data-essential.com 
# Version: 1.0.0 
# creation: 08/10/2016 
# update: [date] [who] [what] 
#   14/01/2017: GF -- modified for datastax cassandra 3.0
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

# ############################################################################
# ## prerequisities
# ############################################################################

# create a uniq user, group
groupadd -g 42000 cassandra
useradd -g cassandra cassandra

# pam_limits module param
cat << EOF > /etc/sysctl.d/cassandra.conf
* - nproc 32768
EOF

# Increase max_map_count Parameter
VALUE=131072 
sysctl -w vm.max_map_count=${VALUE}
echo 65535 > /proc/sys/vm/max_map_count
sysctl -p
# The above changes will be reverted on machine reboot. To make the change permanent, do:
cat << EOF > /etc/sysctl.d/cassandra.conf
vm.max_map_count = ${VALUE}
EOF

## turn-off swap. This can be done with the following command:
swapoff --all

# ############################################################################
# ## install cassandra ## #
# ############################################################################
#yum install cassandra30.noarch cassandra30-tools.noarch -y --nogpgcheck
yum install dsc30 cassandra30-tools python-cassandra-driver.x86_64 -y --nogpgcheck

# ## configure cassandra:
cp /etc/cassandra/default.conf/cassandra-env.sh /etc/cassandra/default.conf/cassandra-env.sh.origin
# Search for: JVM_OPTS="$JVM_OPTS -Djava.rmi.server.hostname="
# add this if you’re having trouble connecting:
# JVM_OPTS=”$JVM_OPTS -Djava.rmi.server.hostname=<public name>”

# start the service:
systemctl daemon-reload
systemctl start cassandra && sleep 10 ; systemctl status cassandra

# enable the service at boot:
 systemctl enable cassandra

