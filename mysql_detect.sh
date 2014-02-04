#!/bin/bash

# Detect attached DB service, use ENV var or first available. 
if [ -z $ZS_DB ]; then
    for dbtype in "mysql-5.5" "user-provided" "mariadb"; do
        for dbnum in 0 1 2; do
            if [[ -z $MYSQL_HOSTNAME && -z $MYSQL_PORT && -z $MYSQL_USERNAME && -z $MYSQL_PASSWORD && -z $MYSQL_DBNAME ]]; then
                MYSQL_HOSTNAME=`/app/bin/json-env-extract.php VCAP_SERVICES $dbtype $dbnum credentials hostname`
                MYSQL_PORT=`/app/bin/json-env-extract.php VCAP_SERVICES $dbtype $dbnum credentials port`
                MYSQL_USERNAME=`/app/bin/json-env-extract.php VCAP_SERVICES $dbtype $dbnum credentials username`
                MYSQL_PASSWORD=`/app/bin/json-env-extract.php VCAP_SERVICES $dbtype $dbnum credentials password`
                MYSQL_DBNAME=`/app/bin/json-env-extract.php VCAP_SERVICES $dbtype $dbnum credentials name`
            fi
        done
    done
else
    for dbtype in "mysql-5.5" "user-provided" "mariadb"; do
        for dbnum in 0 1 2; do
            if [[ `/app/bin/json-env-extract.php VCAP_SERVICES $dbtype $dbnum name` == "$ZS_DB" ]]; then
                if [[ -z $MYSQL_HOSTNAME && -z $MYSQL_PORT && -z $MYSQL_USERNAME && -z $MYSQL_PASSWORD && -z $MYSQL_DBNAME ]]; then
                    MYSQL_HOSTNAME=`/app/bin/json-env-extract.php VCAP_SERVICES $dbtype $dbnum credentials hostname`
                    MYSQL_PORT=`/app/bin/json-env-extract.php VCAP_SERVICES $dbtype $dbnum credentials port`
                    MYSQL_USERNAME=`/app/bin/json-env-extract.php VCAP_SERVICES $dbtype $dbnum credentials username`
                    MYSQL_PASSWORD=`/app/bin/json-env-extract.php VCAP_SERVICES $dbtype $dbnum credentials password`
                    MYSQL_DBNAME=`/app/bin/json-env-extract.php VCAP_SERVICES $dbtype $dbnum credentials name`
                fi
            fi
        done
    done
fi

echo MYSQL_HOSTNAME=$MYSQL_HOSTNAME > /app/zend_mysql.sh
echo MYSQL_PORT=$MYSQL_PORT >> /app/zend_mysql.sh
echo MYSQL_USERNAME=$MYSQL_USERNAME >> /app/zend_mysql.sh
echo MYSQL_PASSWORD=$MYSQL_PASSWORD >> /app/zend_mysql.sh
echo MYSQL_DBNAME=$MYSQL_DBNAME >> /app/zend_mysql.sh
