#!/bin/bash

# include .files when moving things around
shopt -s dotglob

# Preserve Cloud Foundry information
export LD_LIBRARY_PATH=/app/apache/lib:/app/zend/lib
export PHP_INI_SCAN_DIR=/app/zend/etc/conf.d
export PHPRC=/app/zend/etc
echo "Launching Zend Server..."
export ZEND_UID=`id -u`
export ZEND_GID=`id -g`
export GROUP=`id -g -n`
export ZS_EDITION=TRIAL
export APACHE_ENVVARS=/app/apache/etc/apache2/envvars
ZS_MANAGE=/app/zend/bin/zs-manage

# Install composer and run composer if composer.json file is present
if [[ -f /app/www/composer.json ]]; then
    curl -s http://getcomposer.org/installer | /app/zend/bin/php
    mv composer.phar /app/zend/bin/
    /app/zend/bin/php /app/zend/bin/composer.phar update -d /app/www -o --no-progress --no-ansi -n
fi

# Change UID in Zend Server configuration to the one used in the instance
sed "s/vcap/${ZEND_UID}/" ${PHP_INI_SCAN_DIR}/ZendGlobalDirectives.ini.erb > ${PHP_INI_SCAN_DIR}/ZendGlobalDirectives.ini

echo "Creating/Upgrading Zend databases. This may take several minutes..."
/app/zend/gui/lighttpd/sbin/php -c /app/zend/gui/lighttpd/etc/php-fcgi.ini /app/zend/share/scripts/zs_create_databases.php zsDir=/app/zend toVersion=7.0.0

# Generate default trial license
/app/zend/bin/zsd /app/zend/etc/zsd.ini --generate-license

# Setup log verbosity if needed
if [[ -n $ZEND_LOG_VERBOSITY ]]; then
    sed -i -e 's/zend_gui.logVerbosity = NOTICE/zend_gui.logVerbosity = DEBUG/' /app/zend/gui/config/zs_ui.ini
    sed -i -e 's/zend_gui.debugModeEnabled = false/zend_gui.debugModeEnabled = true/' /app/zend/gui/config/zs_ui.ini
    sed -i -e "s/zend_deployment.daemon.log_verbosity_level=2/zend_deployment.daemon.log_verbosity_level=$ZEND_LOG_VERBOSITY/" /app/zend/etc/zdd.ini
    sed -i -e "s/zend_server_daemon.log_verbosity_level=2/zend_server_daemon.log_verbosity_level=$ZEND_LOG_VERBOSITY/" /app/zend/etc/zsd.ini
fi

# Detect MySQL settings
./mysql_detect.sh
eval `cat /app/zend_mysql.sh`

# Run web server customization script
if [[ -z $ZEND_WEB_SERVER ]]; then
    ZEND_WEB_SERVER="apache"
fi

. customize-$ZEND_WEB_SERVER.sh

# Start Zend Server
echo "Starting Zend Server"

# Fix GID/UID until ZSRV-11165 is resolved
sed -e "s|^\(zend.httpd_uid[ \t]*=[ \t]*\).*$|\1$ZEND_UID|" -i /app/zend/etc/conf.d/ZendGlobalDirectives.ini
sed -e "s|^\(zend.httpd_gid[ \t]*=[ \t]*\).*$|\1$ZEND_GID|" -i /app/zend/etc/conf.d/ZendGlobalDirectives.ini
/app/zend/bin/zendctl.sh start

# Bootstrap Zend Server
echo "Bootstrap Zend Server"
if [ -z $ZS_ADMIN_PASSWORD ]; then
    # Generate a Zend Server admin password if one was not specificed in the manifest
    ZS_ADMIN_PASSWORD=`date +%s | sha256sum | base64 | head -c 8`
    echo ZS_ADMIN_PASSWORD=$ZS_ADMIN_PASSWORD
    echo $ZS_ADMIN_PASSWORD > /app/zend-password
fi
if [[ -z $ZEND_LICENSE_ORDER || -z $ZEND_LICENSE_KEY ]]; then
    ZEND_LICENSE_ORDER=cloudfoundry
    ZEND_LICENSE_KEY=1OVO7341801G21B08FD927480286D7CA
    export ZS_EDITION=FREE
fi

$ZS_MANAGE bootstrap-single-server -p $ZS_ADMIN_PASSWORD -a 'TRUE' -o $ZEND_LICENSE_ORDER -l $ZEND_LICENSE_KEY | head -1 > /app/zend/tmp/api_key

# Remove ZS_ADMIN_PASSWORD from env.log
sed '/ZS_ADMIN_PASSWORD/d' -i /home/vcap/logs/env.log 

# Get API key from bootstrap script output
WEB_API_KEY=`cut -s -f 1 /app/zend/tmp/api_key`
WEB_API_KEY_HASH=`cut -s -f 2 /app/zend/tmp/api_key`

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
    $ZS_MANAGE store-directive -d 'zend_sc.ha.use_broadcast' -v '0' -N $WEB_API_KEY -K $WEB_API_KEY_HASH
    $ZS_MANAGE store-directive -d 'session.save_handler' -v 'cluster' -N $WEB_API_KEY -K $WEB_API_KEY_HASH
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
touch /app/zend/var/log/codetracing.log

# Fix GID/UID until ZSRV-11165 is resolved.
VALUE=`id -u`
sed -e "s|^\(zend.httpd_uid[ \t]*=[ \t]*\).*$|\1$VALUE|" -i /app/zend/etc/conf.d/ZendGlobalDirectives.ini
sed -e "s|^\(zend.httpd_gid[ \t]*=[ \t]*\).*$|\1$VALUE|" -i /app/zend/etc/conf.d/ZendGlobalDirectives.ini

#ZCLOUD-160 - disable unsupported extensions in Free Edition
if [ $ZS_EDITION = "FREE" ] ; then
  $ZS_MANAGE extension-off -e 'Zend Page Cache' -N $WEB_API_KEY -K $WEB_API_KEY_HASH
  $ZS_MANAGE extension-off -e 'Zend Session Clustering' -N $WEB_API_KEY -K $WEB_API_KEY_HASH
fi

# Setup default server name
SERVER_NAME=`/app/bin/json-env-extract.php VCAP_APPLICATION application_uris 0`
$ZS_MANAGE store-directive -d zend_gui.defaultServer -v $SERVER_NAME -N $WEB_API_KEY -K $WEB_API_KEY_HASH
echo

# Setup Z-Ray URI
$ZS_MANAGE store-directive -d 'zray.zendserver_ui_url' -v "http://$SERVER_NAME/ZendServer" -N $WEB_API_KEY -K $WEB_API_KEY_HASH
echo

# Setup correct session cookie name
$ZS_MANAGE store-directive -d 'zend_gui.sessionId' -v 'JSESSIONID' -N $WEB_API_KEY -K $WEB_API_KEY_HASH
echo

# Setup ZS UI timezone
$ZS_MANAGE store-directive -d 'zend_gui.timezone' -v 'UTC' -N $WEB_API_KEY -K $WEB_API_KEY_HASH
echo

# Setup ZS profile
$ZS_MANAGE store-directive -d 'zend_gui.serverProfile' -v 'Production' -N $WEB_API_KEY -K $WEB_API_KEY_HASH
echo

echo "Restarting Zend Server (using WebAPI)"
$ZS_MANAGE restart-php -p -N $WEB_API_KEY -K $WEB_API_KEY_HASH

# Enable ZS UI
if [ $ZEND_WEB_SERVER == "apache" ]; then
    sed -i -e "s|Alias /ZendServer /app/apache/wait.html||g" /app/apache/etc/apache2/sites-available/default
    sed -i -e "s|#Proxy|Proxy|g" /app/apache/etc/apache2/sites-available/default
    /app/apache/sbin/apache2ctl restart
elif [ $ZEND_WEB_SERVER == "nginx" ]; then
    sed -i -e "s|alias /app/nginx/conf/wait.html||g" /app/nginx/conf/sites-available/default
    sed -i -e "s|#proxy|proxy|g" /app/nginx/conf/sites-available/default
    /app/zend/bin/nginxctl.sh restart
fi

function DEBUG_PRINT_FILE() {
    BASENAME=`basename $1`
    echo "--- Start $BASENAME ---"
    cat $1
    echo "--- End $BASENAME ---"
}

# Deploy ZPK
for i in `find . -name "*.zpk"`; do $ZS_MANAGE app-deploy -p $i -b http://localhost/`basename $i .zpk` -d -a `basename $i .zpk` -N $WEB_API_KEY -K $WEB_API_KEY_HASH; done
for i in `find . -name "*.zpk"`; do $ZS_MANAGE library-deploy -p $i -N $WEB_API_KEY -K $WEB_API_KEY_HASH; done

# Debug output
if [[ -n $ZEND_CF_DEBUG ]]; then
    echo UID=$VALUE
    grep 'zend\.httpd_[ug]id' /app/zend/etc/conf.d/ZendGlobalDirectives.ini
    DEBUG_PRINT_FILE /app/zend/tmp/api_key
    DEBUG_PRINT_FILE /app/zend_mysql.sh
    DEBUG_PRINT_FILE /app/zend_cluster.sh
    DEBUG_PRINT_FILE /app/zend/etc/zend_database.ini
    DEBUG_PRINT_FILE /app/apache/etc/apache2/envvars
    DEBUG_PRINT_FILE /app/apache/etc/apache2/sites-available/default
    echo WEB_API_KEY=\'$WEB_API_KEY\'
    echo WEB_API_KEY_HASH=\'$WEB_API_KEY_HASH\'
    echo NODE_ID=\'$NODE_ID\'
    echo ZEND_DOCUMENT_ROOT=\'$ZEND_DOCUMENT_ROOT\'
    echo $ZS_MANAGE server-add-to-cluster -n $APP_UNIQUE_NAME -i $APP_IP -o $MYSQL_HOSTNAME:$MYSQL_PORT -u $MYSQL_USERNAME -p $MYSQL_PASSWORD -d $MYSQL_DBNAME -N $WEB_API_KEY -K $WEB_API_KEY_HASH -s
fi
