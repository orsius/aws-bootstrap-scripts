#!/bin/bash
set -x
############################################################################ 
# [BOOTSTRAP] -- centos7 -- kubernates + docker --  
############################################################################ 
# Owner: gautier.franchini@data-essential.com 
# Version: 1.0.0 
# creation: 08/01/2017
# update: [date] [who] [what] 
#   xx/xx/201x: GF -- <here are my actions>
# ##########################################################################

# ## epel rhel 7 repository ## #
#yum install  https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y

# update server
yum update -y

# To avoid unsightly message like -bash: warning: setlocale: LC_CTYPE: cannot change locale (UTF-8): No such file or directory, edit /etc/environment on your instance
cat << EOF > /etc/environment
LANG=en_US.utf-8
LC_ALL=en_US.utf-8
EOF

# Install Docker on centos 7
# source: please refer to https://docs.docker.com/engine/installation/linux/centos/.

cat << EOF > /etc/yum.repos.d/docker.repo
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

yum install docker-engine -y --nogpgcheck
yum install lvm2 -y
fdisk -l

pvcreate /dev/xvdb
vgcreate docker /dev/xvdb
lvcreate --wipesignatures y -n thinpool docker -l 95%VG
lvcreate --wipesignatures y -n thinpoolmeta docker -l 1%VG
lvconvert -y --zero n -c 512K --thinpool docker/thinpool --poolmetadata docker/thinpoolmeta

mkdir /etc/systemd/system/docker.service.d
tee /etc/systemd/system/docker.service.d/docker-thinpool.conf <<-'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --storage-driver=devicemapper --storage-opt=dm.thinpooldev=/dev/mapper/docker-thinpool --storage-opt=dm.use_deferred_removal=true --storage-opt=dm.use_deferred_deletion=true
EOF

systemctl daemon-reload
systemctl start docker
docker info
# docker ps

# ##########################################################################

# install kubeadm
cat << EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://yum.kubernetes.io/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

sed -i '/^SELINUX./ { s/enforcing/disabled/; }' /etc/selinux/config
setenforce 0
yum install -y kubelet kubeadm kubectl kubernetes-cni -y
systemctl enable docker
systemctl enable kubelet && systemctl start kubelet


