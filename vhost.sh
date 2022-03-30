#!/bin/bash

apacheSuffix=apache.conf
nginxSuffix=nginx.conf

read -p "vHost name (domain): " serverName
read -p "Alias name: " aliasName
read -p "Document root (without /var/www/): " documentRoot
documentRoot="/var/www/"$documentRoot



while true; do
      read -p "Create on Apache  ? " doApache
      case $doApache in
          [Yy] ) doApache="y" break;;
          [Nn] ) doApache="n" break;;
          * ) echo "Yes or No";;
      esac
done

if [ $doApache == "y" ]; then

    defaultApache=/etc/apache2/site-available/000-default-script.$apacheSuffix
    vHostApache=/etc/apache2/site-available/$serverName.$apacheSuffix

    while true; do
      read -p "Used with reverse proxy ?" reverse
      case $reverse in
          [Yy] ) reverse="y" break;;
          [Nn] ) reverse="n" break;;
          * ) echo "Yes or No";;
      esac
    done

    cp $defaultApache $vHostApache

    if [ $reverse == "y" ]; then
      read -p "Port used by Apache :" portUsed
      sed -i 's/${portUsed}/'$portUsed'/' $vHostApache
    else
      portUsed="80"
      sed -i 's/${portUsed}/'$portUsed'/' $vHostApache
    fi

    sed -i 's/${serverName}/'$serverName'/' $vHostApache
    sed -i 's/${aliasName}/'$aliasName'/' $vHostApache
    sed -i 's~${documentRoot}~'$documentRoot'~' $vHostApache
    sudo a2enconf $serverName
    sudo systemctl restart apache2
    echo "vHost created and enabled on Apache"
fi

while true; do
      read -p "Create on Nginx  ? " doNginx
      case $doNginx in
          [Yy] ) doNginx="y" break;;
          [Nn] ) doNginx="n" break;;
          * ) echo "Yes or No";;
      esac
done

if [ $doNginx == "y" ]; then
    defaultNginx=/etc/nginx/site-available/000-default-script.$nginxSuffix
    vHostNginx=/etc/nginx/site-available/$serverName.$nginxSuffix
    vHostEnabledNginx=/etc/nginx/site-enabled/$serverName.$nginxSuffix

    cp $defaultNginx $vHostNginx
    sed -i 's/${serverName}/'$serverName'/' $vHostNginx
    sed -i 's/${aliasName}/'$aliasName'/' $vHostNginx
    sed -i 's~${documentRoot}~'$documentRoot'~' $vHostNginx
    sudo ln -s $vHostNginx $vHostEnabledNginx
    sudo systemctl restart nginx
    echo "vHost created and enabled on NGINX"
fi

while true; do
      read -p "Create more vHost ? " moreVHost
      case $moreVHost in
          [Yy] ) moreVHost="y" break;;
          [Nn] ) moreVHost="n" break;;
          * ) echo "Yes or No";;
      esac
done

if [ $moreVHost == "y" ]; then
    addMoreVHost=$(readlink -f "$0")
    exec $addMoreVHost
else
  exit
fi