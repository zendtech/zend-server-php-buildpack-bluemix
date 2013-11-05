#!/bin/bash  
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
WD_INI=${ZCE_PREFIX}/etc/watchdog-monitor.ini
WATCHDOG="${ZCE_PREFIX}/bin/watchdog -c $WD_INI"
BINARY=monitor
NAME="$PRODUCT_NAME Monitor node"
umask 002 

start()
{
    launch
}

stop()
{
    _kill
}
status()
{
    $WATCHDOG -i $BINARY
}
case "$1" in
	start)
		start
		sleep 1
                status
		;;
	stop)
		stop

		# Clean monitor SHM files (JIRA issue ZSRV-965)
		for DIR in $ZCE_PREFIX/tmp /tmp; do
			rm -f $DIR/zshm_CollectorUptimeSHM_*
			rm -f $DIR/zshm_MonitorDumpHash_*
			rm -f $DIR/zshm_monitor_ZMRequestsStatContainerSHM_*
		done

		rm -f ${ZCE_PREFIX}/tmp/monitor.{app,wd}
		;;
	restart)
		stop

		# Clean monitor SHM files (JIRA issue ZSRV-965)
		for DIR in $ZCE_PREFIX/tmp /tmp; do
			rm -f $DIR/zshm_CollectorUptimeSHM_*
			rm -f $DIR/zshm_MonitorDumpHash_*
			rm -f $DIR/zshm_monitor_ZMRequestsStatContainerSHM_*
		done

		rm -f ${ZCE_PREFIX}/tmp/monitor.{app,wd}
		sleep 1
		start
		;;
	status)
		status
		;;
	*)
		usage
                exit 1
esac

exit $?
