#!/bin/sh
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
# pattern for our semid files
ZEND_SEMFILE_PATTERN=zsemfile*_semid

# pattern for our shm files
ZEND_SHM_PATTERN=zshm_*

# cycle through $ZCE_PREFIX/tmp /tmp $ZCE_PREFIX/gui/lighttpd/tmp in search of semid files
for DIR in $ZCE_PREFIX/tmp /tmp $ZCE_PREFIX/gui/lighttpd/tmp; do 
    # if found, concat to a list of sem IDs to kill
    if ls $DIR/$ZEND_SEMFILE_PATTERN > /dev/null 2>&1 ;then
                    # collect sem IDs from $ZEND_TMPDIR/zsemfile_*_semid and /tmp/zsemfile_*_semid:
                    SEMS=`for ZSEMFILE in $DIR/$ZEND_SEMFILE_PATTERN; do if [ -f $ZSEMFILE ]; then cat $ZSEMFILE; fi; done | xargs `
    fi        

    # if we actually found files matching the zsemfile_*_semid pattern and extracted IDs, remove with ipcrm:
    if [ -n "$SEMS" ];then
                    echo "`date`: Will now attempt ipcrm on $SEMS" >> $ZCE_PREFIX/var/log/clean_semaphores.log
                    for ID in $SEMS;do
                                    ipcrm -s $ID >> $ZCE_PREFIX/var/log/clean_semaphores.log 2>&1
                    done
                    rm -f $DIR/$ZEND_SEMFILE_PATTERN
                    unset SEMS
    fi
done

for DIR in $ZCE_PREFIX/tmp /tmp; do
   rm -f $DIR/${ZEND_SHM_PATTERN} 
done

if [ -n "$WEB_USER" ];then
	SEM_USERS="$WEB_USER|zend"
else
	SEM_USERS="zend"	
fi

# see #29971, this should be removed when the issue if fixed and a workaround is no longer needed.
for i in `ipcs -m |grep -E "$SEM_USERS"|awk -F " " '{print $2}'` ; do ipcrm -m $i ; done &>/dev/null
for i in `ipcs -s |grep -E "$SEM_USERS"|awk -F " " '{print $2}'` ; do ipcrm -s $i ; done &>/dev/null
