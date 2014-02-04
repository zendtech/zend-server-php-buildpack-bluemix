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
eval `cat /app/zend_cluster.sh`

if [ -n $ZEND_CF_DEBUG ]; then
    echo /app/nothing $MYSQL_HOSTNAME $MYSQL_PORT $MYSQL_USERNAME $MYSQL_PASSWORD $MYSQL_DBNAME $NODE_ID $WEB_API_KEY $WEB_API_KEY_HASH
fi

export LD_LIBRARY_PATH=.
if [ -z $MYSQL_HOSTNAME ] || [ -z $MYSQL_PORT ] || [ -z $MYSQL_USERNAME ] || [ -z $MYSQL_PASSWORD ] || [ -z $MYSQL_DBNAME ] || [ -z $NODE_ID ] || [ -z $WEB_API_KEY ] || [ -z $WEB_API_KEY_HASH ]; then
    exec /app/nothing
fi
exec /app/nothing $MYSQL_HOSTNAME $MYSQL_PORT $MYSQL_USERNAME $MYSQL_PASSWORD $MYSQL_DBNAME $NODE_ID $WEB_API_KEY $WEB_API_KEY_HASH
