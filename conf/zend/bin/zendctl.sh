#!/bin/bash
#

### BEGIN INIT INFO
# Provides:          zend-server
# Required-Start:    $local_fs $remote_fs $network $syslog
# Required-Stop:     $local_fs $remote_fs $network $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start/stop ZendServer daemons
### END INIT INFO
# For RHEL:

# chkconfig: 345 95 05
# description: Zend Server control script. Used to control Zend Daemons and Apache.


if [ -f /app/etc/zce.rc ];then
    . /app/etc/zce.rc
else
    echo "/app/etc/zce.rc doesn't exist!"
    exit 1;
fi
if [ -f $ZCE_PREFIX/bin/shell_functions.rc ];then
    . $ZCE_PREFIX/bin/shell_functions.rc
else
    echo "$ZCE_PREFIX/bin/shell_functions.rc doesn't exist!"
    exit 1;
fi
check_root_privileges
export ZEND_TMPDIR=$ZCE_PREFIX/tmp 

usage()
{
    $ECHO_CMD "Usage: $0 <action>"
    $ECHO_CMD ""
    for ACTION in start stop restart;do
        $ECHO_CMD "$ACTION\n\t$ACTION all $PRODUCT_NAME daemons"
        for SCRIPT in $ZCE_PREFIX/etc/rc.d/S*;do  
	    SCRIPT=`echo $SCRIPT|sed 's/S[0-9][0-9]//'`
            $ECHO_CMD "$ACTION-`basename $SCRIPT`\n\t$ACTION `basename $SCRIPT` only.";
        done
        $ECHO_CMD "\n"
    done
    $ECHO_CMD "setup-jb            Setup Java bridge"
    $ECHO_CMD "version             Print $PRODUCT_NAME version"
    $ECHO_CMD "status              Get $PRODUCT_NAME status"
    $ECHO_CMD ""
    $ECHO_CMD "For more information about this script see"
    $ECHO_CMD "http://files.zend.com/help/Zend-Server-6/zend-server.htm#linux_mac__package_setup_and_control_scripts.htm"
}
case $1 in
	"start")
		$ECHO_CMD "Starting $PRODUCT_NAME $PRODUCT_VERSION ..\n"
                if [ -d $ZCE_PREFIX/etc/rc.d ];then
                    for SCRIPT in $ZCE_PREFIX/etc/rc.d/S*;do
			SCRIPT=`echo $SCRIPT|sed 's/S[0-9][0-9]//'`
                        $0 $1-`basename $SCRIPT` %
                    done
                else
                    $0 $1-apache %
                    $0 $1-lighttpd %
                    $0 $1-monitor %
                fi
		$ECHO_CMD "\n$PRODUCT_NAME started..."
		;;

	"stop")
		$ECHO_CMD "Stopping $PRODUCT_NAME $PRODUCT_VERSION ..\n"
		if [ -d $ZCE_PREFIX/etc/rc.d ];then
			for SCRIPT in $ZCE_PREFIX/etc/rc.d/K*;do
				SCRIPT=`echo $SCRIPT|sed 's/K[0-9][0-9]//'`
				$0 $1-`basename $SCRIPT` %
			done
		else
			$0 $1-apache %
			$0 $1-lighttpd %
			$0 $1-monitor %
		fi
		$ZCE_PREFIX/bin/clean_semaphores.sh
        sleep 2 
		$ECHO_CMD "\n$PRODUCT_NAME stopped."
		;;

	"start-apache" | "apache-start")
                if [ -x $ZCE_PREFIX/bin/apachectl ];then
                    $ZCE_PREFIX/bin/apachectl start
                fi
		;;

	"graceful-apache" | "apache-graceful")
                if [ -x $ZCE_PREFIX/bin/apachectl ];then
                    $ZCE_PREFIX/bin/apachectl graceful
                fi
		;;

	"start-lighttpd" | "lighttpd-start")
		if [ -x $ZCE_PREFIX/bin/lighttpdctl.sh ];then
                	$ZCE_PREFIX/bin/lighttpdctl.sh start
		fi
		;;

	"start-nginx" | "nginx-start")
		if [ -x $ZCE_PREFIX/bin/nginxctl.sh ];then
			echo -n "Starting nginx: "
                	$ZCE_PREFIX/bin/nginxctl.sh start
			if [ $? -eq 0 ]; then
				echo "[OK]";
			else
				echo "[FAIL]";
			fi
		fi
		;;

	"start-fpm" | "fpm-start")
		if [ -x $ZCE_PREFIX/bin/php-fpm.sh ];then
                	$ZCE_PREFIX/bin/php-fpm.sh start
		fi
		;;

	"start-monitor" | "monitor-start")
                if [ -x $ZCE_PREFIX/bin/monitor-node.sh ];then
                    $ZCE_PREFIX/bin/monitor-node.sh start
                fi
                ;;
		
	"start-scd" | "scd-start")
                if [ -x $ZCE_PREFIX/bin/scd.sh ];then
                    $ZCE_PREFIX/bin/scd.sh start
                fi
		;;
		
	"start-jobqueue" | "jobqueue-start")
                if [ -x $ZCE_PREFIX/bin/jqd.sh ];then
                    $ZCE_PREFIX/bin/jqd.sh start
                fi
		;;
		
	"start-jb" | "jb-start")
                if [ -x $ZCE_PREFIX/bin/java_bridge.sh ];then
                    $ZCE_PREFIX/bin/java_bridge.sh start
		fi
		;;

	"start-deployment" | "deployment-start")
                if [ -x $ZCE_PREFIX/bin/zdd.sh ];then
                    $ZCE_PREFIX/bin/zdd.sh start
                fi
		;;

	"start-zsd" | "zsd-start")
                if [ -x $ZCE_PREFIX/bin/zsd.sh ];then
                    $ZCE_PREFIX/bin/zsd.sh start
                fi
		;;

	"stop-apache" | "apache-stop")
                if [ -x $ZCE_PREFIX/bin/apachectl ];then
                    $ZCE_PREFIX/bin/apachectl stop
			# Clean datacache SHM files (JIRA issue ZSRV-1952)
			for DIR in $ZCE_PREFIX/tmp /tmp; do
				rm -f $DIR/zshm_ZShmStorage_*
			done
                fi
		;;

	"stop-lighttpd" | "lighttpd-stop")
		if [ -x $ZCE_PREFIX/bin/lighttpdctl.sh ];then
                	$ZCE_PREFIX/bin/lighttpdctl.sh stop
		fi
		;;

	"stop-nginx" | "nginx-stop")
		if [ -x $ZCE_PREFIX/bin/nginxctl.sh ];then
			echo -n "Stopping nginx: "
                	$ZCE_PREFIX/bin/nginxctl.sh stop
			if [ $? -eq 0 ]; then
				echo "[OK]";
			else
				echo "[FAIL]";
			fi
		fi
		;;

	"stop-fpm" | "fpm-stop")
		if [ -x $ZCE_PREFIX/bin/php-fpm.sh ];then
                	$ZCE_PREFIX/bin/php-fpm.sh stop
		fi
		;;

	"stop-monitor" | "monitor-stop")
                if [ -x $ZCE_PREFIX/bin/monitor-node.sh ];then
                    $ZCE_PREFIX/bin/monitor-node.sh stop
                fi
		;;

	"stop-scd" | "scd-stop")
                if [ -x $ZCE_PREFIX/bin/scd.sh ];then
                    $ZCE_PREFIX/bin/scd.sh stop
                fi
		;;

	"stop-jobqueue" | "jobqueue-stop")
                if [ -x $ZCE_PREFIX/bin/jqd.sh ];then
                    $ZCE_PREFIX/bin/jqd.sh stop
                fi
		;;

	"stop-jb" | "jb-stop")
                if [ -x $ZCE_PREFIX/bin/java_bridge.sh ];then
                    $ZCE_PREFIX/bin/java_bridge.sh stop
		fi
		;;

	"stop-deployment" | "deployment-stop")
                if [ -x $ZCE_PREFIX/bin/zdd.sh ];then
                    $ZCE_PREFIX/bin/zdd.sh stop
                fi
		;;

	"stop-zsd" | "zsd-stop")
                if [ -x $ZCE_PREFIX/bin/zsd.sh ];then
                    $ZCE_PREFIX/bin/zsd.sh stop
                fi
		;;

	"restart-lighttpd" | "lighttpd-restart")
		if [ -x $ZCE_PREFIX/bin/lighttpdctl.sh ];then
                	$ZCE_PREFIX/bin/lighttpdctl.sh restart
		fi
		;;

	"restart-nginx" | "nginx-restart")
		if [ -x $ZCE_PREFIX/bin/nginxctl.sh ];then
                	$ZCE_PREFIX/bin/nginxctl.sh restart
		fi
		;;

	"restart-fpm" | "fpm-restart")
		if [ -x $ZCE_PREFIX/bin/php-fpm.sh ];then
                	$ZCE_PREFIX/bin/php-fpm.sh restart
		fi
		;;

	"restart-scd" | "scd-restart")
                if [ -x $ZCE_PREFIX/bin/scd.sh ];then
                    $ZCE_PREFIX/bin/scd.sh restart
                fi
		;;

	"restart-monitor" | "monitor-restart")
                if [ -x $ZCE_PREFIX/bin/monitor-node.sh ];then
                    $ZCE_PREFIX/bin/monitor-node.sh restart
                fi
		;;

	"restart-jobqueue" | "jobqueue-restart")
                if [ -x $ZCE_PREFIX/bin/jqd.sh ];then
                    $ZCE_PREFIX/bin/jqd.sh restart
                fi
		;;

	"restart-deployment" | "deployment-restart")
                if [ -x $ZCE_PREFIX/bin/zdd.sh ];then
                    $ZCE_PREFIX/bin/zdd.sh restart
                fi
		;;

	"restart-zsd" | "zsd-restart")
                if [ -x $ZCE_PREFIX/bin/zsd.sh ];then
                    $ZCE_PREFIX/bin/zsd.sh restart
                fi
		;;

	"restart-jb" | "jb-restart")
                if [ -x $ZCE_PREFIX/bin/java_bridge.sh ];then
                    $ZCE_PREFIX/bin/java_bridge.sh restart
		fi
		;;

	"setup-jb" | "jb-setup")
                if [ -x $ZCE_PREFIX/bin/setup_jb.sh ];then
                    $ZCE_PREFIX/bin/setup_jb.sh
                else
                    echo "Java bridge is not installed, please install the java-bridge-zend-$DIST package."
                fi
		;;

	"restart-apache" | "apache-restart")
		$0 stop-apache
		sleep 2
		$0 start-apache
		;;

	"restart")
		$0 stop
		sleep 2 
		$0 start
		;;

	"status")
                for SCRIPT in $ZCE_PREFIX/etc/rc.d/S*;do
		    $SCRIPT status
                done
		;;


        "version")
                $ECHO_CMD "$PRODUCT_NAME version: $PRODUCT_VERSION"
                ;;

	*)	
                usage
                exit 1
		;;
esac
