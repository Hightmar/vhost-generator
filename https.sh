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

    read -p "Which vHost to edit ? " siteName

    while true; do
        read -p "Activate HSTS ? (y/n)" hsts
        case $hsts in
            [Yy]* ) hsts="y" break;;
            [Nn]* ) hsts="n" break;;
            * ) echo "Yes, y/No, n.";;
        esac
    done

    if [ $servWeb == "apache" ]; then
        vHostEdit=/etc/apache2/sites-enabled/$siteName.$apacheSuffix
    else
        vHostEdit=/etc/nginx/sites-enabled/$siteName.$nginxSuffix
    fi

    sed -i 's/#https//' $vHostEdit
    sed -i '4d' $vHostEdit

    if [ $hsts == "y" ]; then
        sed -i 's/#hsts//' $vHostEdit
    fi

    if [ $servWeb == "apache" ]; then
        sudo systemctl restart apache2
    else
        sudo systemctl reload nginx
    fi

    if [ $moreVHost == "y" ]; then
        addMoreVHost=$(readlink -f "$0")
        exec $addMoreVHost
    else
        exit
    fi

else
    echo "Create Let's Encrypt certificates first (see CertBot)"
fi