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
PROXY_TOOL=SS
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

[[ $EUID -ne 0 ]] && echo -e "Error: This script must be run as root!" && exit 1
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
	
easy_install pip
	
TMP_DIR=/root/centos-ssh-ssr-vps/
chmod +x $TMP_DIR/bbr.sh
cp -rf $TMP_DIR/etc/* /etc/
cp -f $TMP_DIR/ddns_update.sh /root/ddns_update.sh
chmod +x /root/ddns_update.sh

# -----------------------------------------------------------------------------
# Configure SSH
# -----------------------------------------------------------------------------
sed -i \
	-e 's/^#\?Port 22/Port '${SSHD_PORT:-22}'/g' \
	-e 's/^#\?PermitRootLogin.*/PermitRootLogin no/g' \
	-e 's/^#\?UsePAM.*/UsePAM yes/g' \
	/etc/ssh/sshd_config

rm -f /etc/ssh/ssh*key*

ssh-keygen -q -t rsa -b 2048 -f /etc/ssh/ssh_host_rsa_key -N ''
ssh-keygen -q -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N ''
ssh-keygen -q -t dsa -f /etc/ssh/ssh_host_ed25519_key  -N ''
	
# -----------------------------------------------------------------------------
# Install & configure Shadowsocks(R)
# -----------------------------------------------------------------------------
[ "$PROXY_TOOL" == "SS" ] && {
	pip install git+https://github.com/shadowsocks/shadowsocks.git@master
	
	sed -i \
		-e 's/"server_port".*/"server_port": '${SS_PORT:-1000}',/' \
		-e 's/"password".*/"password": "'${SS_PASSWORD:-none}'",/' \
		-e 's/"method".*/"method": "'${SS_METHOD:-aes-256-cfb}'",/' \
		/etc/ss_config.json
		
	sed -i \
		-e 's/^autostart=.*/autostart=true/g' \
		/etc/supervisord.d/shadowsocks.conf
}

[ "$PROXY_TOOL" == "SSR" ] && {
	git clone -b manyuser https://github.com/shijh666/shadowsocksr-origin.git /root/shadowsocksr/
	
	sed -i \
		-e 's/"server_port".*/"server_port": '${SS_PORT:-1000}',/' \
		-e 's/"password".*/"password": "'${SS_PASSWORD:-none}'",/' \
		-e 's/"method".*/"method": "'${SS_METHOD:-rc4-md5}'",/' \
		-e 's/"protocol".*/"protocol": "'${SS_PROTOCOL:-auth_sha1_v4}'",/' \
		-e 's/"obfs".*/"obfs": "'${SS_OBFS:-tls1.2_ticket_auth}'",/' \
		/etc/ssr_config.json
		
	sed -i \
		-e 's/^autostart=.*/autostart=true/g' \
		/etc/supervisord.d/shadowsocksr.conf
}

firewall-cmd --zone=public --add-port=${SS_PORT:-1000}/tcp --permanent
firewall-cmd --zone=public --add-port=${SS_PORT:-1000}/udp --permanent
firewall-cmd --reload

# -----------------------------------------------------------------------------
# Install & configure DDNS
# -----------------------------------------------------------------------------
sed -i \
	-e 's/^USERNAME=.*/USERNAME='${DDNS_USERNAME:-root}'/g' \
	-e 's/^PASSWORD=.*/PASSWORD='${DDNS_PASSWORD:-none}'/g' \
	/root/ddns_update.sh

# -----------------------------------------------------------------------------
# Install & configure supervisor
# -----------------------------------------------------------------------------
easy_install supervisor

sed -i \
	-e 's/port=.*/port='0.0.0.0:${SVD_PORT:-1080}'/' \
	-e 's/username=.*/username='${SVD_USERNAME:-root}'/' \
	-e 's/password=.*/password='${SVD_PASSWORD:-none}'/' \
	/etc/supervisord.conf

firewall-cmd --zone=public --add-port=${SVD_PORT:-1080}/tcp --permanent
firewall-cmd --reload

wget --no-check-certificate https://raw.githubusercontent.com/Supervisor/initscripts/master/centos-systemd-etcs \
	-O /lib/systemd/system/supervisord.service

systemctl enable supervisord.service

# -----------------------------------------------------------------------------
# Configure root password
# -----------------------------------------------------------------------------
echo "root:${ROOT_PASSWORD:-$DEFAULT_PASSWORD}" | chpasswd

# -----------------------------------------------------------------------------
# Install bbr
# -----------------------------------------------------------------------------
$TMP_DIR/bbr.sh
