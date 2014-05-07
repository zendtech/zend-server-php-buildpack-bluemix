#!/bin/bash

# Customize port on which nginx should listen
sed "s/VCAP_PORT/${PORT}/" /app/nginx/conf/sites-available/default.erb > /app/nginx/conf/sites-available/default

# Change document root if needed
if [[ -n $ZEND_DOCUMENT_ROOT ]]; then
    sed -i -e "s|root[ \t]*/app/www|root /app/www/$ZEND_DOCUMENT_ROOT|" /app/nginx/conf/sites-available/default
    sed -i -e "s|root[ \t]*/app/www|root /app/www/$ZEND_DOCUMENT_ROOT|" /app/nginx/conf/alias-nginx.tpl
fi

# Configure Zend Server to work with nginx instead of apache
sed -i -e 's|zend_deployment.webserver.type=apache|zend_deployment.webserver.type=nginx|' /app/zend-server-6-php-5.4/etc/zdd.ini
sed -i -e 's|zend_server_daemon.webserver_config_file=.*$|zend_server_daemon.webserver_config_file=/app/nginx/conf/nginx.conf|' /app/zend-server-6-php-5.4/etc/zsd.ini
sed -i -e 's|zend_server_daemon.webserver.apache.ctl=.*$|zend_server_daemon.webserver.apache.ctl=/app/zend-server-6-php-5.4/bin/nginxctl.sh|' /app/zend-server-6-php-5.4/etc/zsd.ini

# Replace zend-server-6-php-5.4/share/alias-nginx.tpl with one compatible with ZF2
cat /app/nginx/conf/alias-nginx.tpl > /app/zend-server-6-php-5.4/share/alias-nginx.tpl

# Setup site that nginx must serve
rm -rf /app/nginx/conf/sites-enabled
mkdir -p /app/nginx/conf/sites-enabled
ln -sf /app/nginx/conf/sites-available/default /app/nginx/conf/sites-enabled
