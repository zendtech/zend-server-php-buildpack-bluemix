#!/usr/bin/env bash

export APACHE_ENVVARS=/app/apache/etc/apache2/envvars

/bin/bash bootstrap.sh

# Start a binary that does nothing so that boot.sh never ends and warden does not kill the container
# This allows apache to be safely restarted by Zend Server (during deploy etc...).
echo "Keep container alive..."

# Keep the app alive so that the health managager does not kill it
eval `cat /app/zend_mysql.sh`
eval `cat /app/zend_cluster.sh`

if [ -n $ZEND_CF_DEBUG ]; then
    # Debug info print
    hostname
    /usr/bin/id
    grep uid /app/zend/etc/conf.d/ZendGlobalDirectives.ini
    # Debug info
    echo /app/nothing $MYSQL_HOSTNAME $MYSQL_PORT $MYSQL_USERNAME $MYSQL_PASSWORD $MYSQL_DBNAME $NODE_ID $WEB_API_KEY $WEB_API_KEY_HASH

    # uname system information
    uname -a
fi

export LD_LIBRARY_PATH=.:$LD_LIBRARY_PATH
if [ -z $MYSQL_HOSTNAME ] || [ -z $MYSQL_PORT ] || [ -z $MYSQL_USERNAME ] || [ -z $MYSQL_PASSWORD ] || [ -z $MYSQL_DBNAME ] || [ -z $NODE_ID ] || [ -z $WEB_API_KEY ] || [ -z $WEB_API_KEY_HASH ]; then
    exec /app/nothing
fi
exec /app/nothing $MYSQL_HOSTNAME $MYSQL_PORT $MYSQL_USERNAME $MYSQL_PASSWORD $MYSQL_DBNAME $NODE_ID $WEB_API_KEY $WEB_API_KEY_HASH
