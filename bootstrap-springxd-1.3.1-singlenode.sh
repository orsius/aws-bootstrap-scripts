#!/bin/bash
set -x
############################################################################ 
# [BOOTSTRAP] -- rhel7 -- postgreSQL-server-9.6 --  single node 
############################################################################ 
# Owner: gautier.franchini@data-essential.com 
# Version: 1.0.0 
# creation: 15/10/2016 
# update: [date] [who] [what] 
#   xx/xx/201x: GF -- <here are my actions>
# ############################################################################

# ## install the required packages :
# jdk 1.8
yum install java-1.8.0-openjdk.x86_64 -y
mkdir -p /applications/portalsearch/users/system/ ; ln -s /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.102-1.b14.el7_2.x86_64/jre/ /applications/portalsearch/users/system/java
# spring-xd 1.3.1
yum install https://repo.spring.io/libs-release-local/org/springframework/xd/spring-xd/1.3.1.RELEASE/spring-xd-1.3.1.RELEASE-1.noarch.rpm -y

# ## custom environement ## #
SPRING_XD_DIR="/applications/portalsearch/users/spring-xd"

# create a custom data directory
mkdir -p ${SPRING_XD_DIR}/{config,lib,custom-modules}


# ## Post-installation commands
# Data Directory -- move 'rpm' files info custome dir: ${SPRING_XD_DIR}
cp -r /opt/pivotal/spring-xd/xd/lib/* ${SPRING_XD_DIR}/lib/.
cp -r /opt/pivotal/spring-xd/xd/config/* ${SPRING_XD_DIR}/config/.

cat << EOF > /applications/portalsearch/users/spring-xd/spring-xd.env
JAVA_HOME=/applications/portalsearch/users/system/java/
PATH=${PATH}:/${JAVA_HOME}/bin
XD_INSTALL_DIR=/opt/pivotal/spring-xd
ADMIN_LOGFILE_DIR=/applications/portalsearch/users/spring-xd/logs
ADMIN_HTTP_PORT=9393
CONTAINER_LOGFILE_DIR=/applications/portalsearch/users/spring-xd/logs
CONTAINER_PROCESSES=1
EOF

mv /etc/sysconfig/spring-xd /etc/sysconfig/spring-xd.orig
ln -s ${SPRING_XD_DIR}/spring-xd.env /etc/sysconfig/spring-xd

# ## modify postgresql config files ## #

# Give ownership to spring-xd user
chown -R spring-xd:pivotal ${SPRING_XD_DIR}

mkdir -p /etc/systemd/system/spring-xd.service.d

# create custom service file
cp /usr/lib/systemd/system/spring-xd-*.service /etc/systemd/system/.

# add custome variable(s)
# perl -pi.back -e 's/Environment\=PGDATA\=\/var\/lib\/pgsql\/data/Environment\=PGDATA\=\/data\/pgsql_data/g;' /etc/systemd/system/postgresql.service



# ## start and control service:
 systemctl enable postgresql.service
 systemctl start postgresql.service
 systemctl status postgresql.service

