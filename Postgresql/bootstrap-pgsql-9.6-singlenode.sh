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

# source: https://wiki.postgresql.org/wiki/YUM_Installation , https://jack-brennan.com/centos-7-initialize-postgresql-9-4-with-defined-data-directory/ , 

# prerequisities have the repository installed; if ! just type the following:
yum install https://yum.postgresql.org/9.6/redhat/rhel-7-x86_64/pgdg-redhat96-9.6-3.noarch.rpm -y

# ## install the required packages :
yum install postgresql-server postgresql-contrib perl -y

# ## custom environement ## #
# source: https://www.postgresql.org/docs/9.6/static/libpq-envars.html

PGSQL_CUSTOM_DATA_DIR=/data/pgsql_data
# create a custom data directory
mkdir -p ${PGSQL_CUSTOM_DATA_DIR}

rm -rf /var/lib/pgsql/
ln -s /data/pgsql_data/ /var/lib/pgsql
mv /var/lib/pgsql/* /data/pgsql_data/.
 
#ONLY REQUIRED IF RUNNING SELINUX = ENFORCING
#Tag type of folder to "postgresql_db_t" so that pgsql can read and write to it
chcon -t postgresql_db_t ${PGSQL_CUSTOM_DATA_DIR}

# Post-installation commands
# After installing the packages, a database needs to be initialized and configured.
# For PostgreSQL version 9.0 and above, the <name> includes the major.minor version of PostgreSQL, e.g., postgresql-9.4
su - postgres -c "initdb -D ${PGSQL_CUSTOM_DATA_DIR}"
# /usr/bin/postgresql-setup initdb
ls -rtlh ${PGSQL_CUSTOM_DATA_DIR}

# Data Directory -- replace /var/lib/pgsql/9.6/data by our custome dir: ${PGSQL_CUSTOM_DATA_DIR}
# The PostgreSQL data directory contains all of the data files for the database. The variable PGDATA is used to reference this directory.
# systemd custom env -- source: http://fedoraproject.org/wiki/Systemd#How_do_I_customize_a_unit_file.2F_add_a_custom_unit_file.3F
mkdir -p /etc/systemd/system/postgresql.service.d

# create custom service file
cp /usr/lib/systemd/system/postgresql.service /etc/systemd/system/postgresql.service
# add custome variable(s)
perl -pi.back -e 's/Environment\=PGDATA\=\/var\/lib\/pgsql\/data/Environment\=PGDATA\=\/data\/pgsql_data/g;' /etc/systemd/system/postgresql.service

# ## modify postgresql config files ## #

# remove the .bash_profile of the postgres user: (to avoid "export PGDATA=/superdry/data ")
su - prostgres -c "mv ~/.bash_profile ${PGSQL_CUSTOM_DATA_DIR}/.bash_profile.origin"

# modify pg_hba.conf
cd ${PGSQL_CUSTOM_DATA_DIR} && cp pg_hba.conf pg_hba.conf.orig
# add the ip range of your network:
echo "host    all             all             10.222.222.0/24            trust" >> ${PGSQL_CUSTOM_DATA_DIR}/pg_hba.conf
# 	TYPE  DATABASE        USER            ADDRESS                 METHOD


# modify postgresql.conf
cd /var/lib/pgsql/data/ && cp postgresql.conf postgresql.conf.orig

# set hostname, log directory custom value
#	perl -pi.orgi -e "s/\#listen_addresses \= \'localhost\'         \# what IP address\(es\) to listen on\;/listen_addresses = '${HOSTNAME}\'/g;" ${PGSQL_CUSTOM_DATA_DIR}/postgresql.conf
echo "listen_addresses = '${HOSTNAME}' " >> ${PGSQL_CUSTOM_DATA_DIR}/postgresql.conf
echo "log_directory = '${PGSQL_CUSTOM_DATA_DIR}/pg_log'" >> ${PGSQL_CUSTOM_DATA_DIR}/postgresql.conf          

# Give ownership to postgres user
chown -R postgres:postgres ${PGSQL_CUSTOM_DATA_DIR}

# ## start and control service:
 systemctl enable postgresql.service
 systemctl start postgresql.service
 systemctl status postgresql.service

