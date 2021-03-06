#!/bin/bash

echo "Installation paquets APT"
apt update
apt install -y mariadb-server mariadb-client
apt install -y php apache2 libapache2-mod-php php-mysql php-xml
apt install -y composer vim git snapd

echo "Config snapd + cerbot"
snap install core
snap refresh core
snap install --classic certbot
service apache2 start

CERTBOT=$(ls /usr/bin | grep certbot)
if [ -z "$CERTBOT" ]
then
  echo "On créé le lien /usr/bin/certbot"
  ln -s /snap/bin/certbot /usr/bin/certbot
fi

APACHE_CHECK=$(ls /etc/apache2/sites-available/ | grep 000-default.conf)
if [ -z "$APACHE_CHECK" ]
then
	touch /etc/apache2/sites-available/000-default.conf
fi

MD5_DEST=$(md5sum /etc/apache2/sites-available/000-default.conf | awk '{print $1}')
MD5_SRC=$(md5sum 000-default.conf | awk '{print $1}')

# if id fichier 1 != id fichier 2
#then
#on écrase fichier 1 avec fichier 2
#fin

if [ "$MD5_DEST" != "$MD5_SRC" ]
then
	echo "On écrase la conf apache"
	cp 000-default.conf /etc/apache2/sites-available/000-default.conf
	service apache2 restart
fi



mkdir -p /var/www/html

CHECK_GIT_CONFIG=$(cd /var/www/html && git config --get remote.origin.url)
if [ -z "$CHECK_GIT_CONFIG" ]
then
  	echo "Mise en place config git"
  	cd /var/www/html && rm -rf .git/
  	git init
  	git remote add origin https://github.com/NicolasFerchaud/examen_piscine.git
fi


echo "pull sources git"
cd /var/www/html
git pull origin master
composer install
chown -R www-data:www-data /var/www/html/
source .env.dev

echo "Configuration SSL / HTTPS"
certbot --apache -d nicolas.piscine.miicom.fr --redirect
