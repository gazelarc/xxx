#!/bin/sh

# initialisasi var
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0'`;
MYIP2="s/xxxxxxxxx/$MYIP/g";

# go to root
cd

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

# install wget and curl
apt-get update;apt-get -y install wget curl;

# set time GMT +7
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
service ssh restart

# set repo
wget -O /etc/apt/sources.list "https://raw.github.com/ykristanto/31337/master/debian/sources.list"
wget "http://www.dotdeb.org/dotdeb.gpg"
wget "http://www.webmin.com/jcameron-key.asc"
cat dotdeb.gpg | apt-key add -;rm dotdeb.gpg
cat jcameron-key.asc | apt-key add -;rm jcameron-key.asc

# remove unused
apt-get -y --purge remove samba*;
apt-get -y --purge remove apache2*;
apt-get -y --purge remove sendmail*;
apt-get -y --purge remove bind9*;

# update
apt-get update; apt-get -y upgrade;

# install webserver
apt-get -y install nginx php5-fpm php5-cli

# install essential package
echo "mrtg mrtg/conf_mods boolean true" | debconf-set-selections
apt-get -y install bmon iftop htop nmap axel nano iptables traceroute sysv-rc-conf dnsutils bc nethogs vnstat less screen psmisc apt-file whois ptunnel ngrep mtr git zsh mrtg snmp snmpd snmp-mibs-downloader unzip unrar rsyslog debsums rkhunter
apt-get -y install build-essential

# disable exim
service exim4 stop
sysv-rc-conf exim4 off

# update apt-file
apt-file update

# setting vnstat
vnstat -u -i venet0
service vnstat restart

# install screenfetch
cd
wget -O screenfetch 'https://raw.github.com/KittyKatt/screenFetch/master/screenfetch-dev'
mv screenfetch-dev /usr/bin/screenfetch
chmod +x /usr/bin/screenfetch
echo "clear" >> .profile
echo "screenfetch" >> .profile

# install webserver
cd
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
wget -O /etc/nginx/nginx.conf "https://raw.github.com/ykristanto/31337/master/debian/nginx/nginx.conf"
mkdir -p /home/vps/public_html
echo "<pre>Setup by ykristanto pin bb : 27b79eb5 </pre>" > /home/vps/public_html/index.html
echo "<?php phpinfo(); ?>" > /home/vps/public_html/info.php
wget -O /etc/nginx/conf.d/vps.conf "https://raw.github.com/ykristanto/31337/master/debian/nginx/vps.conf"
sed -i 's/listen = \/var\/run\/php5-fpm.sock/listen = 127.0.0.1:9000/g' /etc/php5/fpm/pool.d/www.conf
service php5-fpm restart
service nginx restart

# install openvpn
cd ~/
wget https://raw.github.com/cwaffles/ezopenvpn/master/ezopenvpn.sh --no-check-certificate -O ezopenvpn.sh; chmod +x ezopenvpn.sh; ./ezopenvpn.sh
mv ovpn-client.tar.gz /home/vps/public_html/
cd

# install badvpn
wget -O /usr/bin/badvpn-udpgw "https://raw.github.com/ykristanto/31337/master/debian/badvpn-udpgw"
if [ "$OS" == "x86_64" ]; then
wget -O /usr/bin/badvpn-udpgw "https://raw.github.com/ykristanto/31337/master/debian/badvpn-udpgw64"
fi
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300' /etc/rc.local
chmod +x /usr/bin/badvpn-udpgw
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300

# install mrtg
wget -O /etc/snmp/snmpd.conf "https://raw.github.com/ykristanto/31337/master/debian/snmpd.conf"
wget -O /root/mrtg-mem.sh "https://raw.github.com/ykristanto/31337/master/debian/mrtg-mem.sh"
chmod +x /root/mrtg-mem.sh
cd /etc/snmp/
sed -i 's/TRAPDRUN=no/TRAPDRUN=yes/g' /etc/default/snmpd
service snmpd restart
snmpwalk -v 1 -c public localhost 1.3.6.1.4.1.2021.10.1.3.1
mkdir -p /home/vps/public_html/mrtg
cfgmaker --zero-speed 100000000 --global 'WorkDir: /home/vps/public_html/mrtg' --output /etc/mrtg.cfg public@localhost
curl "https://raw.github.com/ykristanto/31337/master/debian/mrtg.conf" >> /etc/mrtg.cfg
sed -i 's/WorkDir: \/var\/www\/mrtg/# WorkDir: \/var\/www\/mrtg/g' /etc/mrtg.cfg
sed -i 's/# Options\[_\]: growright, bits/Options\[_\]: growright/g' /etc/mrtg.cfg
indexmaker --output=/home/vps/public_html/mrtg/index.html /etc/mrtg.cfg
if [ -x /usr/bin/mrtg ] && [ -r /etc/mrtg.cfg ]; then mkdir -p /var/log/mrtg ; env LANG=C /usr/bin/mrtg /etc/mrtg.cfg 2>&1 | tee -a /var/log/mrtg/mrtg.log ; fi
if [ -x /usr/bin/mrtg ] && [ -r /etc/mrtg.cfg ]; then mkdir -p /var/log/mrtg ; env LANG=C /usr/bin/mrtg /etc/mrtg.cfg 2>&1 | tee -a /var/log/mrtg/mrtg.log ; fi
if [ -x /usr/bin/mrtg ] && [ -r /etc/mrtg.cfg ]; then mkdir -p /var/log/mrtg ; env LANG=C /usr/bin/mrtg /etc/mrtg.cfg 2>&1 | tee -a /var/log/mrtg/mrtg.log ; fi
cd

# setting port ssh
sed -i '/Port 22/a Port 443' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 80' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 31337' /etc/ssh/sshd_config
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
service ssh restart


# install vnstat gui
cd /home/vps/public_html/
wget http://www.sqweek.com/sqweek/files/vnstat_php_frontend-1.5.1.tar.gz
tar xf vnstat_php_frontend-1.5.1.tar.gz
rm vnstat_php_frontend-1.5.1.tar.gz
mv vnstat_php_frontend-1.5.1 vnstat
cd vnstat
sed -i 's/eth0/venet0/g' config.php
sed -i "s/\$iface_list = array('venet0', 'sixxs');/\$iface_list = array('venet0');/g" config.php
sed -i "s/\$language = 'nl';/\$language = 'en';/g" config.php
sed -i 's/Internal/Internet/g' config.php
sed -i '/SixXS IPv6/d' config.php
cd

# install fail2ban
apt-get -y install fail2ban;service fail2ban restart

# install squid3
apt-get -y install squid3
wget -O /etc/squid3/squid.conf "https://raw.github.com/ykristanto/31337/master/debian/squid3.conf"
sed -i $MYIP2 /etc/squid3/squid.conf;
service squid3 restart

# install webmin
cd
wget http://prdownloads.sourceforge.net/webadmin/webmin_1.680_all.deb
dpkg -i --force-all webmin_1.680_all.deb;
apt-get -y -f install;
rm /root/webmin_1.680_all.deb
service webmin restart
service vnstat restart

# download script
cd
wget -O speedtest_cli.py "https://raw.github.com/sivel/speedtest-cli/master/speedtest_cli.py"
wget -O bench-network.sh "https://raw.github.com/ykristanto/31337/master/debian/bench-network.sh"
wget -O ps_mem.py "https://raw.github.com/pixelb/ps_mem/master/ps_mem.py"
wget -O login "https://raw.github.com/ykristanto/31337/master/debian/script/login"
wget -O member "https://raw.github.com/ykristanto/31337/master/debian/script/member"
wget -O userlmtop "https://raw.github.com/ykristanto/31337/master/debian/script/userlmtop"

chmod +x bench-network.sh
chmod +x speedtest_cli.py
chmod +x ps_mem.py
chmod +x login
chmod +x member
chmod +x userlmtop

# finishing
chown -R www-data:www-data /home/vps/public_html
service nginx start
service php-fpm start
service vnstat restart
service snmpd restart
service ssh restart
service fail2ban restart
service squid3 restart
service webmin restart
rm -rf ~/.bash_history && history -c
echo "unset HISTFILE" >> /etc/profile

# info
clear
echo "" | tee -a log-install.txt
echo "AUTOSCRIPT INCLUDES" | tee log-install.txt
echo "===============================================" | tee -a log-install.txt
echo "" | tee -a log-install.txt
echo "Service" | tee -a log-install.txt
echo "-------" | tee -a log-install.txt
echo "OpenSSH : 31337, 80, 443" | tee -a log-install.txt
echo "Squid3 : 8080 (limit to IP SSH)" | tee -a log-install.txt
echo "badvpn : badvpn-udpgw port 7300" | tee -a log-install.txt
echo "nginx : 81" | tee -a log-install.txt
echo "" | tee -a log-install.txt
echo "Tools" | tee -a log-install.txt
echo "-----" | tee -a log-install.txt
echo "axel" | tee -a log-install.txt
echo "bmon" | tee -a log-install.txt
echo "htop" | tee -a log-install.txt
echo "iftop" | tee -a log-install.txt
echo "mtr" | tee -a log-install.txt
echo "nethogs" | tee -a log-install.txt
echo "" | tee -a log-install.txt
echo "Script" | tee -a log-install.txt
echo "------" | tee -a log-install.txt
echo "screenfetch" | tee -a log-install.txt
echo "./ps_mem.py" | tee -a log-install.txt
echo "./speedtest_cli.py --share" | tee -a log-install.txt
echo "./bench-network.sh" | tee -a log-install.txt
echo "./login" | tee -a log-install.txt
echo "./member" | tee -a log-install.txt
echo "./userlmtop 2" | tee -a log-install.txt
echo "" | tee -a log-install.txt
echo "Fitur lain" | tee -a log-install.txt
echo "----------" | tee -a log-install.txt
echo "Webmin : https://$MYIP:10000/" | tee -a log-install.txt
echo "vnstat : http://$MYIP:81/vnstat/" | tee -a log-install.txt
echo "MRTG : http://$MYIP:81/mrtg/" | tee -a log-install.txt
echo "Timezone : Asia/Jakarta" | tee -a log-install.txt
echo "Fail2Ban : [on]" | tee -a log-install.txt
echo "IPv6 : [off]" | tee -a log-install.txt
echo "" | tee -a log-install.txt
echo "Thanks to Original Creator Kang Arie & Mikodemos" | tee -a log-install.txt
echo "" | tee -a log-install.txt
echo "SILAHKAN REBOOT VPS ANDA" | tee -a log-install.txt
echo "" | tee -a log-install.txt
echo "===============================================" | tee -a log-install.txt
