#!/bin/bash

# Customize port on which nginx should listen
sed "s/VCAP_PORT/${PORT}/" /app/nginx/conf/sites-available/default.erb > /app/nginx/conf/sites-available/default

# Change document root if needed
if [[ -n $ZEND_DOCUMENT_ROOT ]]; then
    sed -i -e "s|root[ \t]*/app/www|root /app/www/$ZEND_DOCUMENT_ROOT|" /app/nginx/conf/sites-available/default
    sed -i -e "s|root[ \t]*/app/www|root /app/www/$ZEND_DOCUMENT_ROOT|" /app/nginx/conf/alias-nginx.tpl
fi

# Replace zend-server-6-php-5.4/share/alias-nginx.tpl with one compatible with ZF2
cat /app/nginx/conf/alias-nginx.tpl > /app/zend-server-6-php-5.4/share/alias-nginx.tpl

# Setup site that nginx must serve
rm -rf /app/nginx/conf/sites-enabled
mkdir -p /app/nginx/conf/sites-enabled
ln -sf /app/nginx/conf/sites-available/default /app/nginx/conf/sites-enabled
