#!/usr/bin/env bash

/bin/bash bootstrap.sh

# Start a binary that does nothing so that boot.sh never ends and warden does not kill the container
# This allows apache to be safely restarted by Zend Server (during deploy etc...).
echo "Keep container alive..."

#Debugging info
hostname
/usr/bin/id
grep uid /app/zend-server-6-php-5.4/etc/conf.d/ZendGlobalDirectives.ini

###/Debugging info

# Keep the app alive so that the health managager does not kill it
eval `cat /app/zend_mysql.sh`
LD_LIBRARY_PATH=.
exec /app/nothing $MYSQL_HOSTNAME $MYSQL_PORT $MYSQL_USERNAME $MYSQL_PASSWORD db test
