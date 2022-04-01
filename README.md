## vHost.sh

1. Generate the virtual host of without SSL

2. Indicate your domain name, it will be used for the file name

3. The alias of the site, leave **empty** if there is none

4. Add the name of the folder containing the site. 

By default `/var/www/` is added before the folder name. Change the
variable `documentroot` to change this setting.

Suffixes (`nginx/apache.conf`) are added to the vHost file name. You can change these with the `apacheSuffix` and 
`nginxSuffix` variables.

Path to `sites-availables` & `sites-enabled` for  Nginx are defined in `pathSiteAvailableNginx` 
`pathSiteEnabledNginx` `pathSiteAvailableApache` variables.

The script supports:
1. Port switching in the Apache vHost
2. Activation of PHP in NGINX
3. The configuration of PHP in `proxy_pass`

The variables are stored in a file so that the addition of the ssl block can be done without the information being re-requested (the file is deleted after the implementation of ssl)

### Upcoming additions:

Adding commands
`--help`
`--htpasswd`
`--apache`
`--nginx`
`--nginx-reverse`
