#!/bin/sh
random() {
	tr </dev/urandom -dc A-Za-z0-9 | head -c5
	echo
}

array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)
gen64() {
	ip64() {
		echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
	}
	echo "$1:$(ip64):$(ip64):$(ip64):$(ip64)"
}
install_3proxy() {
	URL="https://github.com/z3APA3A/3proxy/archive/0.8.13.tar.gz"
    wget -qO- $URL | bsdtar -xvf-
    cd 3proxy-0.8.13
    make -f Makefile.Linux
    mkdir -p /usr/local/etc/3proxy/{bin,logs,stat}
    cp src/3proxy /usr/local/etc/3proxy/bin/
    cp ./scripts/rc.d/proxy.sh /etc/init.d/3proxy
    chmod +x /etc/init.d/3proxy
    chkconfig 3proxy on
    cd $WORKDIR
}

gen_3proxy() {
    cat <<EOF
#This file was automatically generated by CreateProxy.com
daemon
log /var/log/3proxy/3proxy.log D
nscache 65536

auth iponly
allow * 188.165.205.32,46.105.101.74,144.217.64.10,158.69.126.183,144.217.183.123,14.248.83.36
deny * *
socks -a -p3128
flush

$(awk -F "/" '{print "auth iponly\n" \
"allow * 188.165.205.32,46.105.101.74,144.217.64.10,158.69.126.183,144.217.183.123,14.248.83.36\n" \
"deny * * \n" \
"proxy -6 -n -a -p" $4 " -i" $3 " -e"$5"\n" \
"flush\n"}' ${WORKDATA})
EOF
}

gen_proxy_file_for_user() {
    cat >proxy.txt <<EOF
$(awk -F "/" '{print $3 ":" $4 ":" $1 ":" $2 }' ${WORKDATA})
EOF
}

#upload_proxy() {
#curl -d "auth=IP&key=00051082282d920b259307e7eecf0a84&account=VULTRDUCDATTV61ee42ea42fb3&type=ipv6&provider=vultr&ip=$IP4&data=$(cat /home/proxy-installer/proxy.txt)" -H "Content-Type: application/x-www-form-urlencoded" -X POST https://createproxy.com/listener/
#rm /home/proxy-installer/proxy.txt
#}

gen_data() {
    seq $FIRST_PORT $LAST_PORT | while read port; do
        echo "avgdha/ddhaJzgx/$IP4/$port/$(gen64 $IP6)"
    done
}

gen_iptables() {
    cat <<EOF
    $(awk -F "/" '{print "iptables -I INPUT -p tcp --dport " $4 "  -m state --state NEW -j ACCEPT"}' ${WORKDATA})
EOF
}

gen_ifconfig() {
    cat <<EOF
$(awk -F "/" '{print "ifconfig eth0 inet6 add " $5 "/64"}' ${WORKDATA})
EOF
}
yum -y install gcc net-tools bsdtar zip >/dev/null

install_3proxy

echo "working folder = /home/proxy-installer"
WORKDIR="/home/proxy-installer"
WORKDATA="${WORKDIR}/data.txt"
mkdir $WORKDIR && cd $_

IP4=$(curl -4 -s icanhazip.com)
IP6=$(curl -6 -s icanhazip.com | cut -f1-4 -d':')

echo "Internal ip = ${IP4}. Exteranl sub for ip6 = ${IP6}"

echo "How many proxy do you want to create? Example 500"
read COUNT
#COUNT=100
FIRST_PORT=30000
LAST_PORT=$(($FIRST_PORT + $COUNT))

gen_data >$WORKDIR/data.txt
gen_iptables >$WORKDIR/boot_iptables.sh
gen_ifconfig >$WORKDIR/boot_ifconfig.sh
chmod +x boot_*.sh /etc/rc.local

gen_3proxy >/usr/local/etc/3proxy/3proxy.cfg

cat >>/etc/rc.local <<EOF
bash /home/proxy-installer/boot_iptables.sh
bash /home/proxy-installer/boot_ifconfig.sh
ulimit -n 300010
systemctl start 3proxy.service
EOF

bash /etc/rc.local

gen_proxy_file_for_user

#upload_proxy

#sudo groupadd --gid 65535 createproxy
#sudo useradd -u 65535 --gid 65535 createproxy

mkdir /var/log/3proxy

echo "* hard nofile 300010" >> /etc/security/limits.conf
echo "* soft nofile 300010" >> /etc/security/limits.conf
echo "root hard nofile 300010" >> /etc/security/limits.conf
echo "root soft nofile 300010" >> /etc/security/limits.conf
#echo "createproxy hard nofile 300010" >> /etc/security/limits.conf
#echo "createproxy soft nofile 300010" >> /etc/security/limits.conf
echo "* hard nproc 300010" >> /etc/security/limits.conf
echo "* soft nproc 300010" >> /etc/security/limits.conf
#echo "createproxy hard nproc 300010" >> /etc/security/limits.conf
#echo "createproxy soft nproc 300010" >> /etc/security/limits.conf
echo "root hard nproc 300010" >> /etc/security/limits.conf
echo "root soft nproc 300010" >> /etc/security/limits.conf
sysctl -w fs.file-max=400020
sysctl -p
sudo systemctl disable firewalld
sudo systemctl mask --now firewalld
reboot
