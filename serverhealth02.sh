#!/bin/bash

#Author: Jitendra More
#Created Date: 22.07.2015
#Purpoes: Server Health Check up.
#Last Modified:
#export LANG=C
function sysstat {
echo -e "
--------------------------------------------------------------
Server Health Report 
Date Created: $(date +%c)
--------------------------------------------------------------
Host Name	   : $(hostname)
Running Kernel     : $(uname -r)
Uptime		   : $(uptime|sed 's/.*up \([^,]*\), .*/\1/')
Last Reboot Time   : $(who -b|awk '{print $3,$4,$5}')

---------------------------------------------------------------
CPU Load
---------------------------------------------------------------
"
#cpus=$(lscpu | grep -e "^CPU(s):" | cut -f2 -d: | awk '{print $1}')
#cpus=$(lscpu | grep -e "^CPU(s):" | cut -f2 -d: | awk '{print $1}')
#cpus=$(cat /proc/cpuinfo |grep proce|tail -n 1|awk '{print $3}')

#i=0
#while [ $i -gt $cpus ]
#do
#        echo "CPU$i : `mpstat -P ALL | awk -v var=$i '{ if ($2 == var ) print $4+$5+$6+$7+$8+$9+$10 }' `"
#        let i=$i+1
#done
echo -e "
Load Average:$(uptime |awk -F'load average:' '{print $2}'|cut -f1 -d,)
Heath Status :$(uptime | awk -F'load average:' '{ print $2 }' | cut -f1 -d, | awk '{if ($1 > 16) print "\033[1;31mCRITICAL\033[0m"; else if ($1 > 10) print "\033[1;33mWARNING\033[0m"; else print "\033[1;32mOK\033[0m"}')


---------------------------------------------------------------
Memory Utilization
---------------------------------------------------------------
"
UsedBuffers=`free | awk '/Mem/{printf("Used Buffers=%.2f%"), $6/$2*100}'`
UsedCache=`free | awk '/Mem/{printf("Used Cache=%.2f%"), $7/$2*100}'`
UsedMem=`free | awk '/buffers\/cache/{printf("Actual UsedMem=%.2f%"),$3/($3+$4)*100}'`
FreeMem=`free | awk '/buffers\/cache/{printf("Actual FreeMem=%.2f%"),$4/($3+$4)*100}'`
TotalFree=`free|awk '/Mem/{printf("Total MemFree=%.2f%"), $4/$2*100}'`

TOTALMEM=$(free -m|grep Mem|awk '{print $2}') 
USEDMEM=$(free -m|grep Mem|awk '{print $3}') 
FREEMEM=$(free -m|grep Mem|awk '{print $4}') 
BUFFERS=$(free -m|grep Mem|awk '{print $6}') 
CACHE=$(free -m|grep Mem|awk '{print $7}') 

REALMEMU=$(free -m|grep buffers|tail -1|awk '{print $3}')
REALMEMF=$(free -m|grep buffers|tail -1|awk '{print $4}')

UsedMemSTS=$(free | awk '/buffers\/cache/{printf("%.2f"),$3/($3+$4)*100}'|cut -f1 -d.)

if [ $UsedMemSTS -ge 80 ];
then
	MSTATUS="[1;31mCRITICAL[0m"
elif [ $UsedMemSTS -ge 70 ];
then
	MSTATUS="[1;33mWARNING[0m"
else
	MSTATUS="[1;32mOK[0m"
fi



echo "Memory Utilization"
echo "------------------"
echo -e Total Memory - "$TOTALMEM"M
echo ""
echo -e $UsedBuffers - "$BUFFERS"M
echo -e $UsedCache   - "$CACHE"M
echo -e $TotalFree   - "$FREEMEM"M
echo ""
echo -e $UsedMem     - "$REALMEMU"M
echo -e $FreeMem     - "$REALMEMF"M
echo ""
echo Health Status: $MSTATUS
echo ""

#SWAP Utilization


TotalSwap=`free -m|grep Swap|awk '{print $2}'`
TotalSwapUsed=`free|awk '/Swap/{printf("Used=%.2f%"), $3/$2*100}'`
TotalSwapFree=`free|awk '/Swap/{printf("Free=%.2f%"), $4/$2*100}'`
SwapUsedSTS=`free|awk '/Swap/{printf("%.2f"), $3/$2*100}'|cut -f1 -d.`

if [ $SwapUsedSTS -ge 80 ];
then
	SSTATUS="[1;31mCRITICAL[0m"
elif [ $SwapUsedSTS -ge 70 ];
then
	SSTATUS="[1;33mWARNING[0m"
else
	SSTATUS="[1;32mOK[0m"
fi



SWAPU=$(free -m|grep Swap|awk '{print $3}')
SWAPF=$(free -m|grep Swap|awk '{print $4}')
echo "Swap Utilization"
echo "----------------"
echo Total Swap - "$TotalSwap"M
echo ""
echo $TotalSwapUsed - "$SWAPU"M
echo $TotalSwapFree - "$SWAPF"M
echo ""
echo Health Status: $SSTATUS
# Disk Utilization
echo -e "
---------------------------------------------------------------
Disk Utilization
---------------------------------------------------------------
"

df -PhT |grep -v Filesystem > /tmp/df.status

#while read DF
#do
#    #echo -e $DF|awk '{print "Allocated: "$2"\t","Used: "$3"\t","Avail: "$4"\t",$6"\t", $1}'
#    echo -e $DF|awk '{print $2"\t",$3"\t",$4"\t",$5"\t",$6"\t",$7"\t"}'
#
#done < /tmp/df.status
#echo
echo -e "TYPE SIZE USED AVAIL %USE MOUNTED_ON STATUS" > /tmp/dfh.status
#echo -e "---- ---- ---- ----- ---- ---------- ------" >> /tmp/dfh.status
while read DF
do
    USAGE=`echo $DF | awk '{print $6}'|cut -f1 -d%`
    if [ $USAGE -ge 90 ]
    then
	#STATUS="[1;31mCRITICAL[0m"
	STATUS="\033[1;31mCRITICAL\033[0m"
	elif	[ $USAGE -ge 80 ]
	then
	STATUS="[1;33mWARNING[0m"
	else
	STATUS="[1;32mOK[0m"
    fi
LINE=`echo -e $DF|awk '{print $2"\t",$3"\t",$4"\t",$5"\t",$6"\t",$7"\t"}'`

	echo -e $LINE"\t" $STATUS >> /tmp/dfh.status

done < /tmp/df.status
cat /tmp/dfh.status|column -t
rm -f /tmp/df.status
rm -f /tmp/dfh.status
echo ""

}
sysstat
