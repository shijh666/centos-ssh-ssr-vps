#!/bin/sh

# =============================================================================
# shijh666/centos-ssh-vps
#
# CentOS 6 - SSH / SSR.
#
# =============================================================================

# -----------------------------------------------------------------------------
# Set environment variables
# -----------------------------------------------------------------------------
ROOT_PASSWORD=
SSHD_PORT=

SSR_PORT=
SSR_PASSWORD=
SSR_METHOD=
SSR_PROTOCOL=
SSR_OBFS=

SVD_PORT=
SVD_USERNAME=
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
    net-tool \
    wget \
    tcpdump \
    screen \
    lrzsz \
    unzip && \
yum clean all

# -----------------------------------------------------------------------------
# Configure root password
# -----------------------------------------------------------------------------
echo "root:${ROOT_PASSWORD:-$DEFAULT_PASSWORD}" | chpasswd

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
# Install & configure ShadowsocksR
# -----------------------------------------------------------------------------
cd /root/ && \
  git clone -b manyuser https://github.com/shijh666/shadowsocksr-origin.git shadowsocksr && \
  cp -nf shadowsocksr/config.json shadowsocksr/shadowsocks/user-config.json

sed -i \
	-e 's/"server_port".*/"server_port": '${SSR_PORT:-1000}',/' \
	-e 's/"password".*/"password": "'${SSR_PASSWORD:-password}'",/' \
	-e 's/"method".*/"method": "'${SSR_METHOD:-rc4-md5}'",/' \
	-e 's/"protocol".*/"protocol": "'${SSR_PROTOCOL:-auth_sha1_v4}'",/' \
	-e 's/"obfs".*/"obfs": "'${SSR_OBFS:-tls1.2_ticket_auth}'",/' \
	/root/shadowsocksr/shadowsocks/user-config.json

# -----------------------------------------------------------------------------
# Install & configure supervisor
# -----------------------------------------------------------------------------
mv ./

easy_install supervisor

sed -i \
	-e 's/port=.*/port='${SVD_PORT:-1080}'/' \
	-e 's/username=.*/username='${SVD_USERNAME:-root}'/' \
	-e 's/password=.*/password='${SVD_PASSWORD:-password}'/' \
	/etc/supervisord.conf

supervisord -c /etc/supervisord.conf
