#!/bin/sh
WHOAMI=`/usr/bin/whoami`
ID=/usr/bin/id
USER=`/usr/bin/id -u root`
CURRID=`/usr/bin/id -u`

if [ "X$USER" != "X$CURRID" ]; then
  echo "This should be run as root ($USER) but is being run by $WHOAMI - $CURRID" 
  exit 1 
fi
/bin/mkdir -p /opt/oracle/oak/onecmd/tmp; /bin/chmod 777 /opt/oracle/oak/onecmd/tmp
