#!/bin/sh

# =============================================================================
# shijh666/centos-ssh-vps
#
# CentOS 7 - SSH / SSR.
#
# =============================================================================

# -----------------------------------------------------------------------------
# Set environment variables
# -----------------------------------------------------------------------------
ROOT_PASSWORD=
SSHD_PORT=22

SS_PORT=1000
SS_PASSWORD=
SS_METHOD=aes-256-cfb

DDNS_USERNAME=
DDNS_PASSWORD=

SVD_PORT=1080
SVD_USERNAME=root
SVD_PASSWORD=

# -----------------------------------------------------------------------------
# Install necessary packages
# -----------------------------------------------------------------------------
yum update -y && \
yum install -y \
	gcc \
	gcc-c++z \
	libnet \
	libnet-devel \
	libpcap \
	libpcap-devel \
	openssl-devel \
	libnl3-devel \
	make \
	python-setuptools \
	git \
	net-tools \
	wget \
	tcpdump \
	screen \
	lrzsz \
	unzip && \
yum clean all

# -----------------------------------------------------------------------------
# Configure SSH
# -----------------------------------------------------------------------------
sed -i \
	-e 's/^#\?Port 22/Port '${SSHD_PORT:-22}'/g' \
	-e 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' \
	-e 's/^#\?UsePAM.*/UsePAM no/g' \
	/etc/ssh/sshd_config

ssh-keygen -q -t rsa -b 2048 -f /etc/ssh/ssh_host_rsa_key -N ''
ssh-keygen -q -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N ''
ssh-keygen -q -t dsa -f /etc/ssh/ssh_host_ed25519_key  -N ''
	
# -----------------------------------------------------------------------------
# Install & configure Shadowsocks
# -----------------------------------------------------------------------------
sed -i \
	-e 's/command=.*/command=ssserver -p '${SS_PORT:-1000}' -k '${SS_PASSWORD:-none}' -m '${SS_METHOD:-aes-256-cfb}'/g' \
	-e 's/^autostart=.*/autostart=true/g' \
	/root/centos-ssh-ssr-vps/etc/supervisord.d/shadowsocks.conf

easy_install pip
pip install git+https://github.com/shadowsocks/shadowsocks.git@master

firewall-cmd --zone=public --add-port=${SS_PORT:-1000}/tcp --permanent
firewall-cmd --zone=public --add-port=${SS_PORT:-1000}/udp --permanent

# -----------------------------------------------------------------------------
# Install & configure DDNS
# -----------------------------------------------------------------------------
sed -i \
	-e 's/^USERNAME=.*/USERNAME='${DDNS_USERNAME:-root}'/g' \
	-e 's/^PASSWORD=.*/PASSWORD='${DDNS_PASSWORD:-none}'/g' \
	/root/centos-ssh-ssr-vps/ddns_update.sh

cp /root/centos-ssh-ssr-vps/ddns_update.sh /root/ddns_update.sh -rf
chmod +x /root/ddns_update.sh

# -----------------------------------------------------------------------------
# Install & configure supervisor
# -----------------------------------------------------------------------------
cp /root/centos-ssh-ssr-vps/etc/* /etc/ -rf

easy_install supervisor

sed -i \
	-e 's/port=.*/port='0.0.0.0:${SVD_PORT:-1080}'/' \
	-e 's/username=.*/username='${SVD_USERNAME:-root}'/' \
	-e 's/password=.*/password='${SVD_PASSWORD:-none}'/' \
	/etc/supervisord.conf

supervisord -c /etc/supervisord.conf &

firewall-cmd --zone=public --add-port=${SVD_PORT:-1080}/tcp --permanent
firewall-cmd --reload
# -----------------------------------------------------------------------------
# Configure root password
# -----------------------------------------------------------------------------
echo "root:${ROOT_PASSWORD:-$DEFAULT_PASSWORD}" | chpasswd
