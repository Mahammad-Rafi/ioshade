#!/bin/sh
#
# $Header: oak/pkgrepos/orapkgs/OEL/5.10/Base/Extras/asrEntries.sh /main/1 2014/03/05 07:36:30 jchheda Exp $
#
# asrEntries.sh
#
# Copyright (c) 2011, 2014, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      asrEntries.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    ssingla     07/28/11 - registering the asr entries with SASM
#    ssingla     07/28/11 - Creation
#

SASM_HOME="/opt/SUNWsasm" 
SWASR_HOME="/opt/SUNWswasr"

# if SASM is not running, start the instance
SASM_INSTANCE=`$SASM_HOME/bin/sasm start-instance`
if [ $? -ne 1 ]; then
        $SASM_HOME/bin/sasm install file://$SWASR_HOME/lib/com.sun.svc.ServiceActivation.jar >/dev/null 2>&1
        $SASM_HOME/bin/sasm install file://$SWASR_HOME/lib/com.sun.svc.asr.sw.jar >/dev/null 2>&1
        $SASM_HOME/bin/sasm install file://$SWASR_HOME/lib/com.sun.svc.asr.sw-frag.jar >/dev/null 2>&1
        $SASM_HOME/bin/sasm install file://$SWASR_HOME/lib/com.sun.svc.asr.sw-rulesdefinitions.jar >/dev/null 2>&1
        
        $SASM_HOME/bin/sasm start com.sun.svc.ServiceActivation >/dev/null 2>&1
        $SASM_HOME/bin/sasm refresh com.sun.svc.asr.sw-rulesdefinitions >/dev/null 2>&1
        $SASM_HOME/bin/sasm refresh com.sun.svc.asr.sw-frag >/dev/null 2>&1
        $SASM_HOME/bin/sasm start com.sun.svc.asr.sw >/dev/null 2>&1

        # check if SASM is registered or not
        REG_STATUS=`$SASM_HOME/bin/sasm transport -s`
        if [ $? -eq 0 ]; then
                ip=`ifconfig -a | grep "inet" | grep -v "127.0.0.1" | awk '{print $2;}'`
                $SASM_HOME/bin/sasm send_asr_reg >/dev/null 2>&1
        fi
else
        echo "SASM instance is not running."
        echo "Please make sure SASM is running before adding SUNWswasr package"
        exit 1
fi

