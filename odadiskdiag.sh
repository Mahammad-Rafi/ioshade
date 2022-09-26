#!/bin/bash
# Copyright (c) 2009, 2011, Oracle and/or its affiliates. All rights reserved.
# ODA disks diagnostics Script version 1.2
#
# by Ruggero Citton
#
#
# Usage:
#	ODADiskDiag.sh
#	ODADiskDiag.sh <Date format YYYYMMDD>
#   
#   i.e.: 
#		ODADiskDiag.sh 20120928     # it will collect oswiostat above that day
# ----------------------------------------------------------------------------
if [ $# -eq 1 ]; then
    STARTDATE=$1;
	CENT1=`echo $STARTDATE | cut -c1,2`
	YR1=`echo $STARTDATE | cut -c3,4`
	MO1=`echo $STARTDATE | cut -c5,6`
	DD1=`echo $STARTDATE | cut -c7,8`

	case "$CENT1" in
	    19 | 20 ) ;;
	    * ) echo "Invalid Century, please re-enter entire date. \n"
            exit 1 
	esac

	case "$MO1" in
	    01|02|03|04|05|06|07|08|09|10|11|12 ) ;;
	    * ) echo "Invalid Month, please re-enter entire date. \n" 
            exit 1
	esac

	case "$DD1" in
		01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|29|21|22|23|24|25|26|27|28|29|30|31 ) ;;
		* ) echo "Invalid day, please re-enter entire date. \n"
		exit 1
	esac
fi

# ----------------------------------------------------------------------------
datestamp="`date +%Y_%m_%d_%H_%M`"
hostname=`hostname -s`
mkdir -p /tmp/ODADiskDiag_${hostname}_$datestamp
cd /tmp/ODADiskDiag_${hostname}_$datestamp
# ----------------------------------------------------------------------------
#
echo
echo "...collecting OS messages files"
cp /var/log/messages* .
/bin/dmesg > ${hostname}_dmesg_$datestamp.out

/opt/oracle/oak/bin/oakcli show version -detail > ${hostname}_show-version_$datestamp.out
/usr/sbin/dmidecode -s system-serial-number  > ${hostname}_system-serial_$datestamp.out

# ----------------------------------------------------------------------------
#
echo "...collecting OAK disks details"
/opt/oracle/oak/bin/oakcli show storage > ${hostname}_show-storage_$datestamp.out
/opt/oracle/oak/bin/oakcli show disk > ${hostname}_show-disk_$datestamp.out
/opt/oracle/oak/bin/oakcli show diskgroup > ${hostname}_show-diskgroup_$datestamp.out

for i in $(seq -w 0 23); do
    /opt/oracle/oak/bin/oakcli show disk pd_$i >> ${hostname}_show-disk_detail_$datestamp.out;
done

# ----------------------------------------------------------------------------
#
echo "...collecting colateral disks details"
/opt/oracle/oak/bin/oakcli show expander 0 > ${hostname}_show-expander_0_$datestamp.out
/opt/oracle/oak/bin/oakcli show expander 1 > ${hostname}_show-expander_1_$datestamp.out
/usr/sbin/fwupdate list disk >  ${hostname}_fwupdate-listDisk_$datestamp.out
/sbin/multipath -ll > ${hostname}_multipath_$datestamp.out
/sbin/fdisk -l > ${hostname}_fdisk_$datestamp.out 2>&1



# ----------------------------------------------------------------------------
#
echo "...collecting S.M.A.R.T. details"
/opt/oracle/oak/bin/oakcli show storage|grep dev| awk '{print $1}'| while read line; do echo -n "Smart Heath check on: "; echo $line; smartctl -a $line; echo "============================="; echo ""; done > ${hostname}_show-smartcheck_$datestamp.out


# ----------------------------------------------------------------------------
#
echo "...collecting ASM disks details"
asm1=`ps -ef|grep smon_+ASM1|wc -l`
asm2=`ps -ef|grep smon_+ASM2|wc -l`
if [ $asm1 == '2' ]; then {
    su -c 'export ORACLE_SID=+ASM1;asmcmd lsdsk -p' - grid > ${hostname}_asm-disk-status_$datestamp.out
}    
elif [ $asm2 == '2' ]; then {
     su -c 'export ORACLE_SID=+ASM2;asmcmd lsdsk -p' - grid > ${hostname}_asm-disk-status_$datestamp.out
}
fi


# ----------------------------------------------------------------------------
#
echo "...building disks details"
processLine(){
    line="$@";

    F1=$(echo $line | awk -F ":" '{ print $1 }');
    F2=$(echo $line | awk '{ print $2 }');
    F3=$(echo $line | awk '{ print $3 }');

    if [ $F1 == 'Disk' ]; then {
        echo "" >> ${hostname}_show-disk_detail_tab_$datestamp.out;
        echo -n $F2 "    " >> ${hostname}_show-disk_detail_tab_$datestamp.out;
    }
    elif [ $F1 == 'ActivePath' ]; then {
        echo -n $F3 "    " >> ${hostname}_show-disk_detail_tab_$datestamp.out;
    }
    elif [ $F1 == 'DiskType' ]; then {
        echo -n $F3 "    " >> ${hostname}_show-disk_detail_tab_$datestamp.out;
    }
    elif [ $F1 == 'MultiPathList' ]; then {
        echo -n $F3 "    " >> ${hostname}_show-disk_detail_tab_$datestamp.out;
    }
    elif [ $F1 == 'State' ]; then {
        echo -n $F3 "     " >> ${hostname}_show-disk_detail_tab_$datestamp.out;
    }
    elif [ $F1 == 'StateDetails' ]; then {
        echo -n $F3 "      " >> ${hostname}_show-disk_detail_tab_$datestamp.out;
    }
    elif [ $F1 == 'UsrDevName' ]; then {
        echo -n $F3 "    " >> ${hostname}_show-disk_detail_tab_$datestamp.out;
    }
   fi
}

echo "" >> ${hostname}_show-disk_detail_tab_$datestamp.out;
echo "Disk      ActivePath    Type    MultiPathList             State       Details    UsrDevName" >> ${hostname}_show-disk_detail_tab_$datestamp.out;
echo "-----------------------------------------------------------------------------------------------------" >> ${hostname}_show-disk_detail_tab_$datestamp.out;

while read -r line
do
    processLine $line;
done < ${hostname}_show-disk_detail_$datestamp.out

echo " " >> ${hostname}_show-disk_detail_tab_$datestamp.out;
echo "=====================================================================================================" >> ${hostname}_show-disk_detail_tab_$datestamp.out;


# ----------------------------------------------------------------------------
#
echo "...collecting local disks details"
/opt/oracle/oak/bin/oakcli show disk -local > ${hostname}_show-local_disk_$datestamp.out

#
# ----------------------------------------------------------------------------
echo "...collecting oakd log"
cp /opt/oracle/oak/log/${hostname}/oak/oakd.log .


# ----------------------------------------------------------------------------
#
echo "...collecting ASM alert.log"
if [ -f /u01/app/grid/diag/asm/+asm/+ASM1/trace/alert_+ASM1.log ]; then
    cp /u01/app/grid/diag/asm/+asm/+ASM1/trace/alert_+ASM1.log .
elif [ -f /u01/app/grid/diag/asm/+asm/+ASM2/trace/alert_+ASM2.log ]; then
    cp /u01/app/grid/diag/asm/+asm/+ASM2/trace/alert_+ASM2.log .
fi

# ----------------------------------------------------------------------------
#
echo "...collecting OSW IOStats"
tar cvfz osw_iostat.tar.gz --after-date=${STARTDATE} /opt/oracle/oak/osw/archive/oswiostat/*  > ${hostname}_oswiostat_filelist_$datestamp.out 2>&1


# ----------------------------------------------------------------------------
#
cd /tmp
tar -pzcvf /tmp/ODADiskDiag_${hostname}_$datestamp.tar.gz ODADiskDiag_${hostname}_$datestamp >/dev/null
echo "=============================================================================="
echo "ODA disks diagnostics Script version 1.1"
echo "Done the report files are in gzip compressed /tmp/ODADiskDiag_${hostname}_$datestamp.tar.gz"
echo "=============================================================================="
/bin/rm -rf ODADiskDiag_$datestamp
exit 0

# ----------------------------------------------------------------------------
# EndOfFile
# ----------------------------------------------------------------------------
