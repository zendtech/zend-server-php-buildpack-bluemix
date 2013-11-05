#!/bin/bash

if [ -f /app/etc/zce.rc ];then
	source /app/etc/zce.rc
else
	echo "/app/etc/zce.rc doesn't exist!"
	exit 1;
fi

PATH=$PATH:$ZCE_PREFIX/bin

if [ ! -d "$TMPDIR" ]; then 
	TMPDIR="/tmp"
fi

STAMP=`date +%F-%H%M%S`
ZEND_DATA_DIR=zend-support-tool_${STAMP}
ZEND_DATA_TMPDIR=${TMPDIR}/${ZEND_DATA_DIR}
ZEND_ERROR_LOG=${ZEND_DATA_TMPDIR}/support_tool_error.log
ZEND_COMPRESSED_REPORT=zend-support-tool_${PRODUCT_VERSION}_${STAMP}.tar.gz
ZSST_ACTION="none"

export ZCE_PREFIX
export ZEND_DATA_DIR
export ZEND_DATA_TMPDIR
export ZEND_ERROR_LOG
export WEB_USER


if [ ! -w /etc/passwd ]; then
	echo "WARNING: Some functionality may be disabled."
	echo "Switch to superuser for full functionality."
	export NONSU=1
	echo  "--- Non-superuser execution" >> $ZEND_ERROR_LOG
#	exit 1
fi


# ZSST parse command line
source $ZCE_PREFIX/share/support_tool/options.sh


# ZSST actions start
if [ "$ZSST_ACTION" != "none" ]; then
	export "$( grep -m1 'ZSST_PLUGIN_NAME=' $ZCE_PREFIX/share/support_tool/actions/$ZSST_ACTION)"
	echo " $ZSST_PLUGIN_NAME"
	$ZCE_PREFIX/share/support_tool/actions/$ZSST_ACTION $@
	exit 0
fi
# ZSST actions end



mkdir -p $ZEND_DATA_TMPDIR
cd $ZEND_DATA_TMPDIR

# ZSST plugins start
echo "Plugins :"

ZSST_PLUGINS=$(find $ZCE_PREFIX/share/support_tool/plugins -type f -name "*.sh" -print)

while read PLUGIN; do
	export "$( grep -m1 'ZSST_PLUGIN_NAME=' $PLUGIN)"
	$PLUGIN
	echo " $ZSST_PLUGIN_NAME"

done <<EOI
$ZSST_PLUGINS
EOI
# ZSST plugins end


cat <<EOF

The information was collected successfully.
Use free text to describe the issue in your own words.
To submit the information press CONTROL-D

EOF
cat > $ZEND_DATA_TMPDIR/free_problem_desc
cd $TMPDIR
tar czf ${ZEND_COMPRESSED_REPORT} ${ZEND_DATA_DIR}
if [ $? -eq 0 ];then
    rm -rf $ZEND_DATA_TMPDIR
    echo "Archive created at $TMPDIR/${ZEND_COMPRESSED_REPORT}"
else
    echo "Could not create the archive, leaving $ZEND_DATA_TMPDIR behind for you to archive manually."
fi

