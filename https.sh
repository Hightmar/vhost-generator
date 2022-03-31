#!/bin/bash

apacheSuffix=apache.conf
nginxSuffix=nginx.conf

pathSiteAvailableNginx="/etc/nginx/sites-available"
pathSiteAvailableApache="/etc/apache2/sites-available"

echo "################################################"
echo "##    CERTIFICATES LET'S ENCRYPT CREATED ?    ##"
echo "################################################"

while true; do
    read  -rp "Certificates generated ? (y/n) " certbotUsed
    case $certbotUsed in
        [Yy]* ) certbotUsed="y" break;;
        [Nn]* ) certbotUsed="n" break;;
        * ) echo "Yes, y/No, n.";;
    esac
done

if [ "$certbotUsed" == "y" ]; then
    while true; do
        read -rp "Activate on Apache or Nginx ? " servWeb
        case $servWeb in
            "apache" ) servWeb="apache" break;;
            "nginx" ) servWeb="nginx" break;;
            * ) echo "Apache ou Nginx.";;
        esac
    done

    read -rp "Which vHost to edit ? (name without suffix) " siteName

    while true; do
        read -rp "Activate HSTS ? (y/n) " hsts
        case $hsts in
            [Yy]* ) hsts="y" break;;
            [Nn]* ) hsts="n" break;;
            * ) echo "Yes, y/No, n.";;
        esac
    done

    ##
    # APACHE2
    ##

    if [ "$servWeb" == "apache" ]; then
      vHostEdit=$pathSiteAvailableApache/$siteName.$apacheSuffix
      source generated_vhost/"$vHostEdit".variables

      sed -i '/\/VirtualHost/d' "$vHostEdit"
      sed -i '/#deleteifhttps/d' "$vHostEdit"

      # ADD SSL BLOCK
      cat base_vhost/apache/ssl >> "$vHostEdit"

      sed -i 's/${serverName}/'"$serverName"'/' "$vHostEdit"
      sed -i 's/${aliasName}/'"$aliasName"'/' "$vHostEdit"
      sed -i 's~${documentRoot}~'"$documentRoot"'~' "$vHostEdit"

      if [ "$hsts" == "y" ]; then
        sed -i 's/#hsts//' "$vHostEdit"
      else
        sed -i '/#hsts/d' "$vHostEdit"
      fi

      sudo systemctl restart apache2
      echo "vhost updated to handle HTTPS on Apache"

      # DELETE FILE WITH VARIABLES
      rm generated_vhost/"$vHostEdit".variables
    fi

    ##
    # NGINX
    ##

    if [ "$servWeb" == "nginx" ]; then
      vHostEdit=$pathSiteAvailableNginx/$siteName.$nginxSuffix
      source generated_vhost/"$vHostEdit".variables

      # ADD SSL BLOCK
      cat base_vhost/nginx/ssl >> "$vHostEdit"

      sed -i 's/${serverName}/'"$serverName"'/' "$vHostEdit"
      sed -i 's/${aliasName}/'"$aliasName"'/' "$vHostEdit"
      sed -i 's~${documentRoot}~'"$documentRoot"'~' "$vHostEdit"

      if [ "$hsts" == "y" ]; then
        sed -i 's/#hsts//' "$vHostEdit"
      else
        sed -i '/#hsts/d' "$vHostEdit"
      fi

      phpUsed=$(cat "$vHostEdit" | grep fastcgi_pass)

      if [ -n "$phpUsed" ]; then
        sed -i '/#deleteifhttps/d' "$vHostEdit"
        sed -i '/#end/d' "$vHostEdit"

        # ADD PHP BLOCK
        cat base_vhost/nginx/php >> "$vHostEdit"

        sed -i 's/${phpVersion}/'"$phpVersion"'/' "$vHostEdit"
        sed -i 's/ #deleteifhttps//' "$vHostEdit"

      elif [ -z "$phpUsed" ]; then
        phpUsed=$(cat "$vHostEdit" | grep proxy_pass)

        if [ -n "$phpUsed" ]; then
          sed -i '/#deleteifhttps/d' "$vHostEdit"
          sed -i '/#end/d' "$vHostEdit"

          # ADD REVERSE_PROXY BLOCK
          cat base_vhost/nginx/phpreverse >> "$vHostEdit"

          sed -i 's/${ipToSend}/'"$ipToSend"'/' "$vHostEdit"
          sed -i 's/${portToSend}/'"$portToSend"'/' "$vHostEdit"
          sed -i 's/ #deleteifhttps//' "$vHostEdit"
        fi
      fi

      sudo systemctl restart nginx
      echo "vhost updated to handle HTTPS on NGINX"

      # DELETE FILE WITH VARIABLES
      rm generated_vhost/"$vHostEdit".variables
    fi

else
  echo "Create Let's Encrypt certificates first (see CertBot)"
  while true; do
      read -rp "Start Certbot ? (y/n)" certbot
      case $certbot in
          [Yy]* ) certbot="y" break;;
          [Nn]* ) certbot="n" break;;
          * ) echo "Yes, y/No, n.";;
      esac
  done

  if [ "$certbot" == "y" ]; then
    while true; do
      read -rp "Which webserver ? (apache/nginx/exit) " certServWeb
      case $certServWeb in
          "apache" ) certServWeb="apache" break;;
          "nginx" ) certServWeb="nginx" break;;
          "exit" ) exit;;
          * ) echo "apache or nginx";;
      esac
    done

    if [ "$certServWeb" == "apache" ]; then
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