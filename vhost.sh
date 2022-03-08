#!/bin/bash

apacheSuffix=apache.conf
nginxSuffix=nginx

read -p "vHost name (domain): " serverName
read -p "Alias name: " aliasName
read -p "Document root (sans /var/www/): " documentRoot
documentRoot="/var/www/"$documentRoot

defaultApache=/etc/apache2/site-available/000-default-script.$apacheSuffix
vHostApache=/etc/apache2/site-available/$serverName.$apacheSuffix

cp $defaultApache $vHostApache
sed -i 's/${serverName}/'$serverName'/' $vHostApache
sed -i 's/${aliasName}/'$aliasName'/' $vHostApache
sed -i 's/${documentRoot}/'$documentRoot'/' $vHostApache
sudo a2enconf $serverName
sudo systemctl restart apache2

defaultNginx=/etc/nginx/site-available/000-default-script.$nginxSuffix
vHostNginx=/etc/nginx/site-available/$serverName.$nginxSuffix
vHostEnabledNginx=/etc/nginx/site-enabled/$serverName.$nginxSuffix

cp $defaultNginx $vHostNginx
sed -i 's/${serverName}/'$serverName'/' $vHostNginx
sed -i 's/${aliasName}/'$aliasName'/' $vHostNginx
sed -i 's~${documentRoot}~'$documentRoot'~' $vHostNginx
sudo ln -s $vHostNginx $vHostEnabledNginx
sudo systemctl restart nginx
echo "vHost created"
