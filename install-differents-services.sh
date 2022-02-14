#!/bin/bash

if [ "$(whoami)" != "root" ] ; then
	echo "Please run as root"
	exit
fi

clear
read -p "	Choose a number on this list:
	1 - Install Nginx, Mariadb and Vsftpd
	2 - Install Zabbix Server v5.4, Mariadb, Nginx with php-fpm v7.4
	3 - Deploy Zabbix Agent to connect to Zabbix Server
	4 - Install GLPI (in a short time)
	5 - OpenVPN (in a short time)
	6 - WireGuard (in a short time)
" choise

case $choise in
	1)
	apt update
	apt upgrade -y
	apt install -y nginx mariadb-server php-fpm vsftpd
	cat /etc/nginx/sites-enabled/default | sed -e 56,63's/#//' > /etc/nginx/sites-enabled/default
	cat /etc/nginx/sites-enabled/default | sed -e 62's/fastcgi_pass 127.0.0.1:9000;/#fastcgi_pass 127.0.0.1:9000;/' > /etc/nginx/sites-enabled/default
	sed -i 's/index index.html index.htm index.nginx-debian.html;/index index.php index.html index.htm;/' /etc/nginx/sites-enabled/default
	systemctl restart nginx
	echo "<?php phpinfo(); ?>" > /var/www/html/index.php
	sed -i 's/listen=NO/listen=YES/' /etc/vsftpd.conf
	sed -i 's/listen_ipv6=YES/listen_ipv6=NO/' /etc/vsftpd.conf
	sed -i 's/#write_enable=YES/write_enable=YES/' /etc/vsftpd.conf
	sed -i 's/#local_umask=022/local_umask=022/' /etc/vsftpd.conf
	sed -i 's/#chroot_local_user=YES/chroot_local_user=YES/' /etc/vsftpd.conf
	sed -i 's/#chroot_list_enable=YES/chroot_list_enable=YES/' /etc/vsftpd.conf
	sed -i 's/#chroot_list_file=\/etc\/vsftpd.chroot_list/chroot_list_file=\/etc\/vsftpd.chroot_list/' /etc/vsftpd.conf
	sed -i 's/ssl_enable=NO/ssl_enable=YES/' /etc/vsftpd.conf
	sed -i 's/#xferlog_file=\/var\/log\/vsftpd.log/xferlog_file=\/var\/log\/vsftpd.log/' /etc/vsftpd.conf
	sed -i 's/#chown_uploads=YES/chown_uploads=YES/' /etc/vsftpd.conf
	sed -i 's/#chown_username=whoever/chown_username=www-data/' /etc/vsftpd.conf
	echo "allow_writeable_chroot=YES
dirlist_enable=YES" >> /etc/vsftpd.conf
	systemctl restart vsftpd
	read -p "You must create the first account for FTP :
What's the username ?
" username
	adduser $username
	echo $username > /etc/vsftpd.chroot_list
	;;
	
	2)
	cd /tmp
	wget https://repo.zabbix.com/zabbix/5.4/debian/pool/main/z/zabbix-release/zabbix-release_5.4-1+debian11_all.deb
	dpkg -i zabbix-release_5.4-1+debian11_all.deb
	apt update
	apt upgrade -y
	apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-nginx-conf zabbix-sql-scripts zabbix-agent mariadb-server
	echo "Mot de passe de l'utilisateur mysql zabbix"
	read -p "Password for mysql zabbix user:
	" password
	echo "create database zabbix character set utf8 collate utf8_bin;" | mysql
	echo "create user zabbix@localhost identified by '$password';" | mysql
	echo "grant all privileges on zabbix.* to zabbix@localhost;" | mysql
	echo "Entrez à nouveau votre mot de passe récemment créé"
	echo "Enter again your password recently created"
	zcat /usr/share/doc/zabbix-sql-scripts/mysql/create.sql.gz | mysql -uzabbix -p zabbix
	sed -i "s/# DBPassword=/# DBPassword=
	DBPassword\=$password/" /etc/zabbix/zabbix_server.conf
	sed -i 's/listen 80 default_server;/#listen 80 default_server;/' /etc/nginx/sites-enabled/default
	sed -i 's/listen [::]:80 default_server;/#listen [::]:80 default_server;/' /etc/nginx/sites-enabled/default
	systemctl restart zabbix-server zabbix-agent nginx php7.4-fpm
	systemctl enable zabbix-server zabbix-agent nginx php7.4-fpm
	;;
	
	3)
	cd /tmp
	wget https://repo.zabbix.com/zabbix/5.4/debian/pool/main/z/zabbix-release/zabbix-release_5.4-1+debian11_all.deb
	dpkg -i zabbix-release_5.4-1+debian11_all.deb
	apt update
	apt upgrade -y
	apt install zabbix-agent -y
	read -p "Quelle est l'adresse du serveur Zabbix ?
	" host
	sed -i "s/Server=127.0.0.1/Server\=$host/" /etc/zabbix/zabbix_agentd.conf
	systemctl restart zabbix-agent.service
	;;
	
	4)
	apt update
	apt upgrade -y
	apt install -y nginx php7.4 php7.4-fpm php-mysqli php-mbstring php-curl php-gd php-simplexml php-intl php-ldap php-apcu php-xmlrpc php-zip php-bz2 mariadb-server
	#In a short time
	systemctl restart nginx
	read -p "You must create a new SQL user to manager GLPI:
	" user
	read -p "Password for $user ?
	" password
	echo "CREATE DATABSE namedb;" | mysql
	echo "GRANT ALL PRIVILEGES ON glpidb.* TO 'glpiuser'@'localhost' IDENTIFIED BY 'password';" | mysql
	echo "FLUSH PRIVILEGES;" | mysql
	wget https://github.com/glpi-project/glpi/releases/download/9.5.7/glpi-9.5.7.tgz
	tar -xvf glpi-*.tgz
	mv glpi /var/www/html/
	chown -R www-data:www-data /var/www/html/
	chmod -R 755 /var/www/html/
	;;
	
	5)
	
	;;
esac