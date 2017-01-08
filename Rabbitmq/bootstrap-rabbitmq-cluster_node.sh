#!/bin/bash
set -x
############################################################################ 
# [BOOTSTRAP] -- rhel7 -- rabbitmq-server --  single node 
############################################################################ 
# Owner: gautier.franchini@data-essential.com 
# Version: 1.0.0 
# creation: 05/10/2016 
# update: [date] [who] [what] 
#   xx/xx/201x: GF -- <here are my actions>
# ############################################################################

APP_ENV_DIR="/applications/portalsearch/users/rabbitmq"
APP_CONFIG_DIR="/applications/portalsearch/users/rabbitmq/config"


# ## rabbitMQ TCP port list ## #
# 55672           - Broker connection
# 55672           – Management-agent connections between servers
# 15672           - Management connection
# 4369            - Erlang port
# 45000-45010     - Cluster ports. You can extend this port range in rabbitmq.config if you have more than 3 mirroring servers.


# ## install repel linux repository ## #
	cd /etc/yum.repos.d/ && curl -L -O http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-8.noarch.rpm && rpm -ivh epel-release-7-8.noarch.rpm
	yum info --enablerepo=epel erlang


# ## install erlang ## #
	yum install --enablerepo=epel erlang -y --nogpgcheck


# ## java install ## #
#	java -version || yum install -y java-1.8.0-openjdk.x86_64 -y --nogpgcheck


# ## install rabbitmq ## #
# Download the latest RabbitMQ package using wget:
  cd /root && curl -L -O https://www.rabbitmq.com/releases/rabbitmq-server/v3.6.5/rabbitmq-server-3.6.5-1.noarch.rpm

# Add the necessary keys for verification:
	rpm --import http://www.rabbitmq.com/rabbitmq-signing-key-public.asc

# Install the .RPM package	
	yum localinstall rabbitmq-server-3.6.5-1.noarch.rpm -y

# custom directory tree
  mkdir -p ${APP_CONFIG_DIR}/{logs,config,mnesia}
  chown -R rabbitmq /applications/portalsearch/users/rabbitmq

# plugin additionnal files:
  cp /root/rabbitmq_clusterer-3.6.x-667f92b0.ez /usr/lib/rabbitmq/lib/rabbitmq_server-3.6.*/plugins/.

# chekc erlang version
#  erl > /root/erlang_version_check || echo "erlang NOK"

# setup a custom config -- path: /etc/rabbitmq/rabbitmq.config
# source: https://github.com/rabbitmq/rabbitmq-server/blob/master/docs/rabbitmq.config.example

# environment variables file: (change the nodename value accordingly)
cat << EOF > ${APP_ENV_DIR}/rabbitmq.env
NODE_IP_ADDRESS=10.220.220.43
NODE_PORT=5672
NODENAME=rabbit@opsvc219
RABBITMQ_CONFIG_FILE=${APP_CONFIG_DIR}/rabbitmq
RABBITMQ_ENABLED_PLUGINS_FILE=${APP_CONFIG_DIR}/enabled_plugins
LOG_BASE=${APP_CONFIG_DIR}/logs
MNESIA_BASE=${APP_CONFIG_DIR}/mnesia
RABBITMQ_BOOT_MODULE=rabbit_clusterer
RABBITMQ_ERLANG_COOKIE=BDRMJZVGURRUSVREYSSE
EOF
 
ln -s ${APP_CONFIG_DIR}/rabbitmq.env /etc/rabbitmq/rabbitmq-env.config
ln -s ${APP_CONFIG_DIR}/rabbitmq.config /etc/rabbitmq/rabbitmq.config
 
# configuration files: (identical on each cluster members)
cat << EOF > ${APP_CONFIG_DIR}/config/rabbitmq.config
[
{kernel, [
     ]},
{rabbit, [
    {tcp_listeners, [5672]},
    {disk_free_limit, "1GB"},
    {collect_statistics_interval, 10000},
    {heartbeat, 30},
    {cluster_partition_handling, autoheal},
    ]},
{rabbitmq_management, [
    {http_log_dir,"${APP_CONFIG_DIR}/logs"},
    {listener, [{port, 15672 }]}
    ]},
{rabbitmq_clusterer, [
    {config, [ {version,1}, {nodes,["rabbit@centos-es-01", "rabbit@centos-es-02", "rabbit@centos-es-03"]} ]}
    ]}
].
EOF

#  enable rabbitmq plugins:
cat << EOF > ${APP_CONFIG_DIR}/config/enabled_plugins
[rabbitmq_clusterer,rabbitmq_management,rabbitmq_management_agent,rabbitmq_shovel,rabbitmq_shovel_management].
EOF


# set the proper rights to the files: 
  shown rabbitmq:rabbitmq /etc/rabbitmq/*
  chmod 400 /etc/rabbitmq/*

# start the service:
  systemctl start rabbitmq-server
  systemctl status rabbitmq-server && rabbitmqctl node_health_check

# check and enable the management plugin:
  rabbitmq-plugins list
  rabbitmq-plugins enable rabbitmq_management

# access the web interface through: http://[your droplet's IP]:15672/
  echo "you can access the web interface through: http://$HOSTNAME:15672/ "

# enable the service at boot:
  systemctl enable rabbitmq-server


# create a default user admin:
rabbitmqctl add_user portalsearch portalsearch
rabbitmqctl set_user_tags portalsearch administrator
rabbitmqctl set_permissions -p / portalsearch".*" ".*" ".*"



