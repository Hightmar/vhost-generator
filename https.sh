#!/bin/bash

apacheSuffix=apache.conf
nginxSuffix=nginx.conf

echo "################################################"
echo "##    CERTIFICATES LET'S ENCRYPT CREATED ?    ##"
echo "################################################"

while true; do
    read  -p "Certificates generated ? (y/n) " cerbotUsed
    case $cerbotUsed in
        [Yy]* ) cerbotUsed="y" break;;
        [Nn]* ) cerbotUsed="n" break;;
        * ) echo "Yes, y/No, n.";;
    esac
done

if [ $cerbotUsed == "y" ]; then
    while true; do
        read -p "Activate on Apache or Nginx ? " servWeb
        case $servWeb in
            "apache" ) servWeb="apache" break;;
            "nginx" ) servWeb="nginx" break;;
            * ) echo "Apache ou Nginx.";;
        esac
    done

    read -p "Which vHost to edit ? (name without suffix) " siteName

    while true; do
        read -p "Activate HSTS ? (y/n) " hsts
        case $hsts in
            [Yy]* ) hsts="y" break;;
            [Nn]* ) hsts="n" break;;
            * ) echo "Yes, y/No, n.";;
        esac
    done

    ##
    # APACHE2
    ##

    if [ $servWeb == "apache" ]; then
      vHostEdit=$siteName.$apacheSuffix
      source generated_vhost/$vHostEdit.variables

      sed -i '/\/VirtualHost/d' $vHostEdit
      sed -i '/#deleteifhttps/d' $vHostEdit

      cat base_vhost/apache/ssl >> $vHostEdit

      sed -i 's/${serverName}/'$serverName'/' $vHostEdit
      sed -i 's/${aliasName}/'$aliasName'/' $vHostEdit
      sed -i 's~${documentRoot}~'$documentRoot'~' $vHostEdit

      if [ $hsts == "y" ]; then
        sed -i 's/#hsts//' $vHostEdit
      else
        sed -i '/#hsts/d' $vHostEdit
      fi

      sudo systemctl restart apache2
      echo "vhost updated to handle HTTPS on Apache"
    fi

    ##
    # NGINX
    ##

    if [ $servWeb == "nginx" ]; then
      vHostEdit=$siteName.$nginxSuffix
      source generated_vhost/$vHostEdit.variables

      sed -i '/#end/d' $vHostEdit
      sed -i '/#deleteifhttps/d' $vHostEdit

      cat base_vhost/nginx/ssl >> $vHostEdit

      sed -i 's/${serverName}/'$serverName'/' $vHostEdit
      sed -i 's/${aliasName}/'$aliasName'/' $vHostEdit
      sed -i 's~${documentRoot}~'$documentRoot'~' $vHostEdit

      if [ $hsts == "y" ]; then
        sed -i 's/#hsts//' $vHostEdit
      else
        sed -i '/#hsts/d' $vHostEdit
      fi

      phpUsed=$(cat $vHostEdit | grep fastcgi_pass)

      if [ -n "$phpUsed" ]; then
        sed -i '/#end/d' $vHostEdit
        cat base_vhost/nginx/php >> $vHostEdit
        sed -i 's/${phpVersion}/'$phpVersion'/' $vHostEdit

      elif [ -z "$phpUsed" ]; then
        phpUsed=$(cat $vHostEdit | grep proxy_pass)

        if [ -n "$phpUsed" ]; then
          sed -i '/#end/d' $vHostEdit
          cat base_vhost/nginx/phpreverse >> $vHostEdit
          sed -i 's/${ipToSend}/'$ipToSend'/' "$vHostEdit"
          sed -i 's/${portToSend}/'$portToSend'/' "$vHostEdit"
        fi
      fi

      sudo systemctl restard nginx
      echo "vhost updated to handle HTTPS on NGINX"
      rm generated_vhost/$vHostEdit.variables
    fi

else
    echo "Create Let's Encrypt certificates first (see CertBot)"
    while true; do
        read -p "Start Cerbot ? (y/n)" certbot
        case $certbot in
            [Yy]* ) certbot="y" break;;
            [Nn]* ) cerbot="n" break;;
            * ) echo "Yes, y/No, n.";;
        esac
    done

    if [ $certbot == "y" ]; then
      while true; do
        read -p "Which webserver ? (apache/nginx/exit) " certServWeb
        case $certServWeb in
            "apache" ) certServWeb="apache" break;;
            "nginx" ) certServWeb="nginx" break;;
            "exit" ) exit;;
            * ) echo "apache or nginx";;
        esac
      done

      if [ $certServWeb == "apache" ]; then
        sudo certbot certonly --apache
        enableCert=$(readlink -f "$0")
        exec $enableCert
      else
        sudo certbot certonly --nginx
        enableCert=$(readlink -f "$0")
        exec $enableCert
      fi
    fi
fi