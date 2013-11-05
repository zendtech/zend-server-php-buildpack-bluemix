#!/bin/sh
. /app/etc/zce.rc*
if [ -d "$ZEND_DATA_TMPDIR" ];then
        OUTFILE="$ZEND_DATA_TMPDIR/Zmanifest_$$.lst"
else
        OUTFILE="/tmp/Zmanifest_$$.lst"
fi
echo "$ZCE_PREFIX/lib/ZendExtensionManager.so:" > $OUTFILE
$ZCE_PREFIX/bin/ZManifest -vi $ZCE_PREFIX/lib/ZendExtensionManager.so >>$OUTFILE
for i in $ZCE_PREFIX/lib/*/*.*.x;do echo $i:; $ZCE_PREFIX/bin/ZManifest -vi  $i/*.so;done >> $OUTFILE
cat $OUTFILE
echo "Output saved to $OUTFILE"
