#!/bin/bash

# CREATE DIR IF NOT EXIST
if [ ! -d generated_vhost ];then
   mkdir generated_vhost
fi

apacheSuffix=apache.conf
nginxSuffix=nginx.conf

pathSiteAvailableNginx="/etc/nginx/sites-available"
pathSiteEnabledNginx="/etc/nginx/sites-enabled"
pathSiteAvailableApache="/etc/apache2/sites-available"

read -rp "vHost name (domain): " serverName
read -rp "Alias name: " aliasName
read -rp "Document root (without /var/www/): " documentRoot
documentRoot="/var/www/"$documentRoot

while true; do
      read -rp "Create on Apache  ? " doApache
      case $doApache in
          [Yy] ) doApache="y" break;;
          [Nn] ) doApache="n" break;;
          * ) echo "Yes or No";;
      esac
done

# BLOCK FOR APACHE2'S VHOST
if [ "$doApache" == "y" ]; then

  vHostApache=$pathSiteAvailableApache/$serverName.$apacheSuffix
  touch "$vHostApache"
  cat base_vhost/apache/base >> "$vHostApache"

  while true; do
     read -rp "Used with reverse proxy ? " reverse
     case $reverse in
         [Yy]* ) reverse="y" break;;
         [Nn]* ) reverse="n" break;;
         * ) echo "Yes or No";;
     esac
  done

  #If Apache is used with a reverse_proxy
  if [ "$reverse" == "y" ]; then
    read -rp "Port used by Apache : " portUsed
    sed -i 's/${portUsed}/'"$portUsed"'/' "$vHostApache"

  else
      portUsed="80"
      sed -i 's/${portUsed}/'$portUsed'/' "$vHostApache"
  fi

  # MODIFY VHOST WITH INFORMATION'S
  sed -i 's/${serverName}/'"$serverName"'/' "$vHostApache"
  sed -i 's/${aliasName}/'"$aliasName"'/' "$vHostApache"
  sed -i 's~${documentRoot}~'"$documentRoot"'~' "$vHostApache"
  sudo a2ensite "$serverName"
  sudo systemctl restart apache2
  echo "vHost created and enabled on Apache"

  #Create files with variable. Will be used for https
  touch generated_vhost/"$vHostApache".variables

  # WRITE IN FILE
  {
    echo serverName="$serverName"
    echo aliasName="$aliasName"
    echo documentRoot="$documentRoot"
    echo portUsed="$portUsed"
  } >> generated_vhost/"$vHostApache".variables
  # END WRITE

fi

while true; do
      read -rp "Create on Nginx  ? " doNginx
      case $doNginx in
          [Yy] ) doNginx="y" break;;
          [Nn] ) doNginx="n" break;;
          * ) echo "Yes or No";;
      esac
done

if [ "$doNginx" == "y" ]; then

  vHostNginx=$pathSiteAvailableNginx/$serverName.$nginxSuffix
  vHostEnabled=$pathSiteEnabledNginx/$serverName.$nginxSuffix

  touch "$vHostNginx"
  cat base_vhost/nginx/base >> "$vHostNginx"

  # MODIFY VHOST WITH INFORMATION'S
  sed -i 's/${serverName}/'$serverName'/' "$vHostNginx"
  sed -i 's/${aliasName}/'$aliasName'/' "$vHostNginx"
  sed -i 's~${documentRoot}~'"$documentRoot"'~' "$vHostNginx"

  # ASK FOR PHP AND IF IT'S USED AS REVERSE PROXY
  while true; do
      read -rp "Activate PHP ? " activatePHP
      case $activatePHP in
          [Yy]* ) activatePHP="y" break;;
          [Nn]* ) activatePHP="n" break;;
          * ) echo "Yes or No";;
      esac
    done

  if [ "$activatePHP" == "y" ]; then

    while true; do
      read -rp "Nginx is a reverse_proxy ? " reverseProxy
      case $reverseProxy in
          [Yy]* ) reverseProxy="y" break;;
          [Nn]* ) reverseProxy="n" break;;
          * ) echo "Yes or No";;
      esac
    done

    if [ "$reverseProxy" == "y" ]; then
      read -rp "On which IP to send ? " ipToSend
      read -rp "On which port to send ? " portToSend

      sed -i '/}/d' "$vHostNginx"
      cat base_vhost/nginx/phpreverse >> "$vHostNginx"

      sed -i 's/${ipToSend}/'"$ipToSend"'/' "$vHostNginx"
      sed -i 's/${portToSend}/'"$portToSend"'/' "$vHostNginx"
    else
      read -rp "PHP version ? (e.g. 7.4) " phpVersion

      sed -i '/}/d' "$vHostNginx"
      cat base_vhost/nginx/php >> "$vHostNginx"
      sed -i 's/${phpVersion}/'"$phpVersion"'/' "$vHostNginx"
    fi
  fi
  # END PHP

  sudo ln -s "$vHostNginx" "$vHostEnabled"
  sudo systemctl restart nginx
  echo "vHost created and enabled on NGINX"

  #Create files with variable. Will be used for https
  touch generated_vhost/"$vHostNginx".variables

  # WRITE IN FILE
  {
    echo serverName="$serverName"
    echo aliasName="$aliasName"
    echo documentRoot="$documentRoot"
  } >> generated_vhost/"$vHostNginx".variables

  if [ -n "$portToSend" ] && [ -n "$ipToSend" ]; then
    {
      echo portToSend="$portToSend"
      echo ipToSend="$ipToSend"
    } >> generated_vhost/"$vHostNginx".variables
  fi

  if [ -n "$phpVersion" ]; then
    echo phpVersion="$phpVersion" >> generated_vhost/"$vHostNginx".variables
  fi
  # END WRITE
fi

while true; do
  read -rp "Create more vHost ? " moreVHost
  case $moreVHost in
    [Yy] ) moreVHost="y" break;;
    [Nn] ) moreVHost="n" break;;
    * ) echo "Yes or No";;
    esac
done

if [ "$moreVHost" == "y" ]; then
    addMoreVHost=$(readlink -f "$0")
    exec $addMoreVHost
else
  exit
fi