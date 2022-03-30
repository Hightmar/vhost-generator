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

  vHostApache=$serverName.$apacheSuffix
  touch $vHostApache
  cat base_vhost/apache/base >> $vHostApache

  while true; do
     read -p "Used with reverse proxy ? " reverse
     case $reverse in
         [Yy]* ) reverse="y" break;;
         [Nn]* ) reverse="n" break;;
         * ) echo "Yes or No";;
     esac
  done

  #If Apache is used with a reverse_proxy
  if [ $reverse == "y" ]; then
    read -p "Port used by Apache : " portUsed
    sed -i 's/${portUsed}/'$portUsed'/' $vHostApache

  else
      portUsed="80"
      sed -i 's/${portUsed}/'$portUsed'/' $vHostApache
  fi

  sed -i 's/${serverName}/'$serverName'/' $vHostApache
  sed -i 's/${aliasName}/'$aliasName'/' $vHostApache
  sed -i 's~${documentRoot}~'$documentRoot'~' $vHostApache
  sudo a2ensite $serverName
  sudo systemctl restart apache2
  echo "vHost created and enabled on Apache"

  #Create files with variable. Will be used for https
  touch generated_vhost/$vHostApache.variables
  echo serverName=$serverName >> generated_vhost/$vHostApache.variables
  echo aliasName=$aliasName >> generated_vhost/$vHostApache.variables
  echo documentRoot=$documentRoot >> generated_vhost/$vHostApache.variables
  echo portUsed=$portUsed >> generated_vhost/$vHostApache.variables

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

  vHostNginx=$serverName.$nginxSuffix
  touch $vHostNginx
  cat base_vhost/nginx/base >> $vHostNginx

  while true; do
      read -p "Activate PHP ? " activatePHP
      case $activatePHP in
          [Yy]* ) activatePHP="y" break;;
          [Nn]* ) activatePHP="n" break;;
          * ) echo "Yes or No";;
      esac
    done

    #Ask version of PHP
    if [ $activatePHP == "y" ]; then

      while true; do
        read -p "Nginx is a reverse_proxy ? " reverseProxy
        case $reverseProxy in
            [Yy]* ) reverseProxy="y" break;;
            [Nn]* ) reverseProxy="n" break;;
            * ) echo "Yes or No";;
        esac
      done

    if [ $reverseProxy == "y" ]; then
      read -p "On which IP to send ? " ipToSend
      read -p "On which port to send ? " portToSend

      sed -i '/}/d' "$vHostNginx"
      cat base_vhost/nginx/phpreverse >> "$vHostNginx"

      sed -i 's/${ipToSend}/'$ipToSend'/' "$vHostNginx"
      sed -i 's/${portToSend}/'$portToSend'/' "$vHostNginx"
    else
      read -p "PHP version ? (e.g. 7.4) " phpVersion

      sed -i '/}/d' "$vHostNginx"
      cat base_vhost/nginx/php >> "$vHostNginx"
      sed -i 's/${phpVersion}/'$phpVersion'/' "$vHostNginx"
    fi

    sed -i 's/${serverName}/'$serverName'/' $vHostNginx
    sed -i 's/${aliasName}/'$aliasName'/' $vHostNginx
    sed -i 's~${documentRoot}~'$documentRoot'~' $vHostNginx

#    sudo ln -s $vHostNginx $vHostEnabledNginx
    sudo systemctl restart nginx
    echo "vHost created and enabled on NGINX"

    #Create files with variable. Will be used for https
    touch generated_vhost/"$vHostNginx".variables
    echo serverName="$serverName" >> generated_vhost/"$vHostNginx".variables
    echo aliasName="$aliasName" >> generated_vhost/"$vHostNginx".variables
    echo documentRoot="$documentRoot" >> generated_vhost/"$vHostNginx".variables

    if [ -n "$portToSend" ] && [ -n "$ipToSend" ]; then
      echo portToSend="$portToSend" >> generated_vhost/"$vHostNginx".variables
      echo portToSend="$ipToSend">> generated_vhost/"$vHostNginx".variables
    fi

    if [ -n "$phpVersion" ]; then
      echo phpVersion="$phpVersion" >> generated_vhost/"$vHostNginx".variables
    fi
  fi
fi
######################################################################
#if [ $doNginx == "y" ]; then
#    defaultNginx=000-default-script.$nginxSuffix
#    vHostNginx=$serverName.$nginxSuffix
#    vHostEnabledNginx=$serverName.$nginxSuffix
#
#    cp $defaultNginx $vHostNginx
#
#    while true; do
#      read -p "Activate PHP ? " activatePHP
#      case $activatePHP in
#          [Yy]* ) activatePHP="y" break;;
#          [Nn]* ) activatePHP="n" break;;
#          * ) echo "Yes or No";;
#      esac
#    done
#
#    #Ask version of PHP
#    if [ $activatePHP == "y" ]; then
#
#      while true; do
#      read -p "Nginx is a reverse_proxy ? " reversePorxy
#      case $reversePorxy in
#          [Yy]* ) reversePorxy="y" break;;
#          [Nn]* ) reversePorxy="n" break;;
#          * ) echo "Yes or No";;
#      esac
#    done
#
#    if [ $reversePorxy == "y" ]; then
#      read -p "portUsed " phpVersion
#
#      read -p "PHP version ? (e.g. 7.4) " phpVersion
#      sed -i 's/${phpVersion}/'$phpVersion'/' $vHostNginx
#
#      #Uncomment php block
#      sed -i 's/#activatephp//' $vHostNginx
#    else
#      #If no php, delete php block
#      sed -i '/#activatephp/d' $vHostNginx
#    fi
#
#    sed -i 's/${serverName}/'$serverName'/' $vHostNginx
#    sed -i 's/${aliasName}/'$aliasName'/' $vHostNginx
#    sed -i 's~${documentRoot}~'$documentRoot'~' $vHostNginx
#    sudo ln -s $vHostNginx $vHostEnabledNginx
#    sudo systemctl restart nginx
#    echo "vHost created and enabled on NGINX"
#fi

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