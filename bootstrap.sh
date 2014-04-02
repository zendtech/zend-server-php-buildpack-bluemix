#!/bin/bash

# include .files when moving things around
shopt -s dotglob

# Preserve Cloud Foundry information
export LD_LIBRARY_PATH=/app/zend-server-6-php-5.4/lib
export PHP_INI_SCAN_DIR=/app/zend-server-6-php-5.4/etc/conf.d
export PHPRC=/app/zend-server-6-php-5.4/etc
echo "Launching Zend Server..."
export ZEND_UID=`id -u`
export ZEND_GID=`id -g`
export ZS_EDITION=TRIAL
ZS_MANAGE=/app/zend-server-6-php-5.4/bin/zs-manage

# Set env. variables for DB2 if needed
if [[ $ZEND_DB2_DRIVER == 1 ]]; then
    export LD_LIBRARY_PATH=/app/clidriver/lib:$LD_LIBRARY_PATH
    export IBM_DB_HOME=/app/clidriver
fi

# Change UID in Zend Server configuration to the one used in the gear
sed "s/vcap/${ZEND_UID}/" ${PHP_INI_SCAN_DIR}/ZendGlobalDirectives.ini.erb > ${PHP_INI_SCAN_DIR}/ZendGlobalDirectives.ini
sed "s/VCAP_PORT/${PORT}/" /app/nginx/conf/sites-available/default.erb > /app/nginx/conf/sites-available/default

# Change document root if needed
if [[ -n $ZEND_DOCUMENT_ROOT ]]; then
    sed -i -e "s|root[ \t]*/app/www|root /app/www/$ZEND_DOCUMENT_ROOT|" /app/nginx/conf/sites-available/default
    sed -i -e "s|root[ \t]*/app/www|root /app/www/$ZEND_DOCUMENT_ROOT|" /app/nginx/conf/alias-nginx.tpl
fi

#replace zend-server-6-php-5.4/share/alias-nginx.tpl with one compatible with ZF2
cat /app/nginx/conf/alias-nginx.tpl > /app/zend-server-6-php-5.4/share/alias-nginx.tpl

rm -rf /app/nginx/conf/sites-enabled
mkdir -p /app/nginx/conf/sites-enabled
ln -f -s /app/nginx/conf/sites-available/default /app/nginx/conf/sites-enabled

echo "Creating/Upgrading Zend databases. This may take several minutes..."
/app/zend-server-6-php-5.4/gui/lighttpd/sbin/php -c /app/zend-server-6-php-5.4/gui/lighttpd/etc/php-fcgi.ini /app/zend-server-6-php-5.4/share/scripts/zs_create_databases.php zsDir=/app/zend-server-6-php-5.4 toVersion=6.2.0

# Generate default trial license
/app/zend-server-6-php-5.4/bin/zsd /app/zend-server-6-php-5.4/etc/zsd.ini --generate-license

# Setup log verbosity if needed
if [[ -n $ZEND_LOG_VERBOSITY ]]; then
    sed -i -e 's/zend_gui.logVerbosity = NOTICE/zend_gui.logVerbosity = DEBUG/' /app/zend-server-6-php-5.4/gui/config/zs_ui.ini
    sed -i -e 's/zend_gui.debugModeEnabled = false/zend_gui.debugModeEnabled = true/' /app/zend-server-6-php-5.4/gui/config/zs_ui.ini
    sed -i -e "s/zend_deployment.daemon.log_verbosity_level=2/zend_deployment.daemon.log_verbosity_level=$ZEND_LOG_VERBOSITY/" /app/zend-server-6-php-5.4/etc/zdd.ini
    sed -i -e "s/zend_server_daemon.log_verbosity_level=2/zend_server_daemon.log_verbosity_level=$ZEND_LOG_VERBOSITY/" /app/zend-server-6-php-5.4/etc/zsd.ini
fi

# Detect MySQL settings
./mysql_detect.sh
eval `cat /app/zend_mysql.sh`

# Start Zend Server
echo "Starting Zend Server"
# Fix GID/UID until ZSRV-11165 is resolved
sed -e "s|^\(zend.httpd_uid[ \t]*=[ \t]*\).*$|\1$ZEND_UID|" -i /app/zend-server-6-php-5.4/etc/conf.d/ZendGlobalDirectives.ini
sed -e "s|^\(zend.httpd_gid[ \t]*=[ \t]*\).*$|\1$ZEND_GID|" -i /app/zend-server-6-php-5.4/etc/conf.d/ZendGlobalDirectives.ini
/app/zend-server-6-php-5.4/bin/zendctl.sh start

# Bootstrap Zend Server
echo "Bootstrap Zend Server"
if [ -z $ZS_ADMIN_PASSWORD ]; then
    #Set the GUI admin password to "changeme" if a user did not
    ZS_ADMIN_PASSWORD="changeme"
    #Generate a Zend Server administrator password if one was not specificed in the manifest
    # ZS_ADMIN_PASSWORD=`date +%s | sha256sum | base64 | head -c 8` 
    # echo ZS_ADMIN_PASSWORD=$ZS_ADMIN_PASSWORD
fi
if [[ -z $ZEND_LICENSE_ORDER || -z $ZEND_LICENSE_KEY ]]; then
    ZEND_LICENSE_ORDER=cloudfoundry
    ZEND_LICENSE_KEY=AG12IG51401H51B08FD9C3A65E23D2CE
    export ZS_EDITION=FREE
fi
$ZS_MANAGE bootstrap-single-server -p $ZS_ADMIN_PASSWORD -a 'TRUE' -o $ZEND_LICENSE_ORDER -l $ZEND_LICENSE_KEY | head -1 > /app/zend-server-6-php-5.4/tmp/api_key

#Remove ZS_ADMIN_PASSWORD from env.log
sed '/ZS_ADMIN_PASSWORD/d' -i /home/vcap/logs/env.log 

# Get API key from bootstrap script output
WEB_API_KEY=`cut -s -f 1 /app/zend-server-6-php-5.4/tmp/api_key`
WEB_API_KEY_HASH=`cut -s -f 2 /app/zend-server-6-php-5.4/tmp/api_key`

# echo "Restarting Zend Server (using WebAPI)"
# $ZS_MANAGE restart-php -p -N $WEB_API_KEY -K $WEB_API_KEY_HASH

# Join the server to a cluster
HOSTNAME=`hostname`
APP_UNIQUE_NAME=$HOSTNAME

touch /app/zend_cluster.sh
if [[ -n $MYSQL_HOSTNAME && -n $MYSQL_PORT && -n $MYSQL_USERNAME && -n $MYSQL_PASSWORD && -n $MYSQL_DBNAME ]]; then
    # Get host's IP (there probably is a better way. No cloud foundry provided environment variable is suitable.
    APP_IP=`/sbin/ifconfig w-${HOSTNAME}-1| grep 'inet addr:' | awk {'print \$2'}| cut -d ':' -f 2`

    # Actually join cluster
    echo "Joining cluster"
    $ZS_MANAGE server-add-to-cluster -n $APP_UNIQUE_NAME -i $APP_IP -o $MYSQL_HOSTNAME:$MYSQL_PORT -u $MYSQL_USERNAME -p $MYSQL_PASSWORD -d $MYSQL_DBNAME -N $WEB_API_KEY -K $WEB_API_KEY_HASH -s | sed -e 's/ //g' > /app/zend_cluster.sh
    eval `cat /app/zend_cluster.sh`

    # Configure session clustering
    #$ZS_MANAGE store-directive -d 'zend_sc.ha.use_broadcast' -v '0' -N $WEB_API_KEY -K $WEB_API_KEY_HASH
    #$ZS_MANAGE store-directive -d 'session.save_handler' -v 'cluster' -N $WEB_API_KEY -K $WEB_API_KEY_HASH
fi

# ZCLOUD-131 - automatically import exported Zend Server config files
if [[ -z $ZEND_CONFIG_FILE ]]; then
  for ZEND_CONFIG_FILE in /app/www/.zend_config/zs_config*.zip
  do
    $ZS_MANAGE config-import $ZEND_CONFIG_FILE -N $WEB_API_KEY -K $WEB_API_KEY_HASH
  done
elif [ -f $ZEND_CONFIG_FILE ]; then 
  $ZS_MANAGE config-import $ZEND_CONFIG_FILE -N $WEB_API_KEY -K $WEB_API_KEY_HASH
fi
      

# ZCLOUD-161 - create certain log files if they are missing
touch /app/zend-server-6-php-5.4/var/log/codetracing.log
touch /app/zend-server-6-php-5.4/var/log/access.log
touch /app/zend-server-6-php-5.4/var/log/error.log

# Fix GID/UID until ZSRV-11165 is resolved.
VALUE=`id -u`
sed -e "s|^\(zend.httpd_uid[ \t]*=[ \t]*\).*$|\1$VALUE|" -i /app/zend-server-6-php-5.4/etc/conf.d/ZendGlobalDirectives.ini
sed -e "s|^\(zend.httpd_gid[ \t]*=[ \t]*\).*$|\1$VALUE|" -i /app/zend-server-6-php-5.4/etc/conf.d/ZendGlobalDirectives.ini

#ZCLOUD-160 - disable unsupported extensions in Free Edition
if [ $ZS_EDITION = "FREE" ] ; then
  $ZS_MANAGE extension-off -e 'Zend Page Cache' -N $WEB_API_KEY -K $WEB_API_KEY_HASH
  $ZS_MANAGE extension-off -e 'Zend Session Clustering' -N $WEB_API_KEY -K $WEB_API_KEY_HASH
fi

echo "Restarting Zend Server (using WebAPI)"
$ZS_MANAGE restart-php -p -N $WEB_API_KEY -K $WEB_API_KEY_HASH

function DEBUG_PRINT_FILE() {
    BASENAME=`basename $1`
    echo "--- Start $BASENAME ---"
    cat $1
    echo "--- End $BASENAME ---"
}

# Debug output
if [[ -n $ZEND_CF_DEBUG ]]; then
    echo UID=$VALUE
    grep 'zend\.httpd_[ug]id' /app/zend-server-6-php-5.4/etc/conf.d/ZendGlobalDirectives.ini
    DEBUG_PRINT_FILE /app/zend-server-6-php-5.4/tmp/api_key
    DEBUG_PRINT_FILE /app/zend_mysql.sh
    DEBUG_PRINT_FILE /app/zend_cluster.sh
    DEBUG_PRINT_FILE /app/zend-server-6-php-5.4/etc/zend_database.ini
    echo WEB_API_KEY=\'$WEB_API_KEY\'
    echo WEB_API_KEY_HASH=\'$WEB_API_KEY_HASH\'
    echo NODE_ID=\'$NODE_ID\'
    echo ZEND_DOCUMENT_ROOT=\'$ZEND_DOCUMENT_ROOT\'
    echo LD_LIBRARY_PATH=\'$LD_LIBRARY_PATH\'
    echo IBM_DB_HOME=\'$IBM_DB_HOME\'
fi
