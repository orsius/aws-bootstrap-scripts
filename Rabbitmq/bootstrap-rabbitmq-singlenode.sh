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

# setup a custom config -- path: /etc/rabbitmq/rabbitmq.config
# source: https://github.com/rabbitmq/rabbitmq-server/blob/master/docs/rabbitmq.config.example

cat << EOF > /etc/rabbitmq/rabbitmq.config
% rabbitmq config: /etc/rabbitmq/rabbitmq.config
% rabbitmq env: /etc/rabbitmq/rabbitmq-env.conf
[
  {rabbit, [
    {default_user, <<"rabbit">>},
    {default_pass, <<"guest">>}
  ]},
  {kernel, [
    
  ]}
].
% EOF
EOF

# setup rabbit env
cat << EOF > /etc/rabbitmq/rabbitmq-env.conf
RABBITMQ_NODE_PORT=5672
EOF

# set the proper rights to the files: 
  shown rabbitmq:rabbitmq /etc/rabbitmq/*
  chmod 400 /etc/rabbitmq/*

# start the service:
  systemctl start rabbitmq-server
  systemctl status rabbitmq-server

# check and enable the management plugin:
  rabbitmq-plugins list
  rabbitmq-plugins enable rabbitmq_management

# access the web interface through: http://[your droplet's IP]:15672/
  echo "you can access the web interface through: http://$HOSTNAME:15672/ "

# enable the service at boot:
  systemctl enable rabbitmq-server


