#!/bin/bash
# on OEL, /etc/issue states "Enterprise Linux Enterprise Linux Server"
SUPPORTED_OS='CentOS|Red Hat Enterprise Linux Server|Enterprise Linux Enterprise Linux Server|Fedora|SUSE|Debian GNU/Linux|Ubuntu|Oracle Linux Server'
PROD_NAME="Zend Server"

if ! egrep -q "$SUPPORTED_OS" /etc/issue ; then
cat <<EOF

Unable to install: Your distribution is not suitable for installation using
Zend's DEB/RPM repositories. You can install Zend Server Community Edition on
most Linux distributions using the generic tarball installer. For more 
information, see http://www.zend.com/en/community/zend-server-ce

EOF
    exit 1
fi

MYUID=`id -u 2> /dev/null`
if [ ! -z "$MYUID" ]; then
    if [ $MYUID != 0 ]; then
        echo "You need root privileges to run this script.";
        exit 1
    fi
else
    echo "Could not detect UID";
    exit 1
fi
cat <<EOF

Running this script will perform the following:
* Remove any installed $PROD_NAME packages. 

EOF

if [ "$1" = "--automatic" ]; then
	AUTOMATIC="-y"
else
	AUTOMATIC=""
fi

if [ -z "$AUTOMATIC" ]; then
cat <<EOF
Hit ENTER to remove $PROD_NAME, or Ctrl+C to abort now.
EOF
read 
fi

COMMAND=""
# first, lets figure if we're apt-get or yum
if which yum > /dev/null; then
	COMMAND="yum ${AUTOMATIC} remove '*zend*'"
elif which zypper > /dev/null; then
	COMMAND="zypper ${AUTOMATIC} remove '*zend*'"
elif which aptitude > /dev/null; then
	COMMAND="aptitude ${AUTOMATIC} remove '~nzend'"
elif which apt-get > /dev/null; then
	# Fallback if aptitude isn't present (can happen in Ubuntu)
        COMMAND="apt-get ${AUTOMATIC} remove `dpkg -l | grep zend | awk '{print $2}' | xargs echo`"
fi

if [ -n "$COMMAND" ]; then
        echo "Going to execute the following command: $COMMAND"
        eval $COMMAND
        if [ $? -eq 0 ]; then
            echo "$PROD_NAME was successfully removed."
        else
            echo "$PROD_NAME removal was not completed. See output above for detailed error information."
        fi
fi
