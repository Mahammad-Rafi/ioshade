#!/bin/bash
# Copyright (c) 2009, 2015, Oracle and/or its affiliates. All rights reserved.
# ODA Sundiag Script version 2.1
# Global Variable list
isV1=0
isV2=0
isV3=0
isV4=0
isV4_IB=0
numOfEbod=0
numOfJbod=0
counter=24 
OAK_HOME=/opt/oracle/oak/bin

#decide hardware type

hdwrType()
{
  cat /proc/cmdline | grep -qi "TYPE=V1"
  if [ $? -eq 0 ]; then
     isV1=1
  fi
  cat /proc/cmdline | grep -qi "TYPE=V2"
  if [ $? -eq 0 ]; then
     isV2=1
  fi
  cat /proc/cmdline | grep -qi "TYPE=V3"
  if [ $? -eq 0 ]; then
     isV3=1
  fi
  cat /proc/cmdline | grep -qi "TYPE=V4"
  if [ $? -eq 0 ]; then
     isV4=1
     /sbin/lspci | grep -qi  "Mellanox"
      if [ $? -eq 0 ]; then
         isV4_IB=1
      fi
  fi

  #if we are not able to decide based on cmdline  
  if [ "$isV1" = "0" ] && [ "$isV2" = "0" ]  && [ "$isV3" = "0" ] && [ "$isV4" = "0" ]; then
     dmidecode | grep -q 'X4370 M2'
     if [ $? -eq 0 ]; then
        isV1=1
     fi

     dmidecode | grep -q 'X4170 M3'
     if [ $? -eq 0 ]; then
        isV2=1
     fi

     dmidecode | grep -q 'SUN SERVER X4-2'
     if [ $? -eq 0 ]; then
        isV3=1
     fi

     dmidecode | grep -q 'ORACLE SERVER X5-2'
     if [ $? -eq 0 ]; then
        isV4=1
        /sbin/lspci | grep -qi  "Mellanox"
        if [ $? -eq 0 ]; then
           isV4_IB=1
        fi
     fi
  fi
}

check_for_ebod_number()
{
  numOfEbod=`lsscsi | grep enclosu | wc -l`
  if [ $numOfEbod -eq 1 ]; then
     echo "$numOfEbod EBOD found on the system (less than 2 EBODS with 1 JBOD)"
  fi
  if [ $numOfEbod -eq 3 ]; then
     echo "$numOfEbod EBOD found on the system (less than 4 EBODS with 2 JBODS)"
  fi
  if [ $numOfEbod -eq 2 ]; then
     numOfJbod=1
  fi
  if [ $numOfEbod -eq 4 ]; then
     numOfJbod=2
  fi
}
# Get IB related data for X5-2 system
get_IB_data()
{
  /opt/MegaRAID/MegaCli/MegaCli64 -AdpAllInfo -aALL -nolog > `hostname -s`_megacli64-AdpAllInfo_$datestamp.out 
  /opt/MegaRAID/MegaCli/MegaCli64 -AdpEventLog -GetEvents -f `hostname -s`_megacli64-GetEvents-all_$datestamp.out -aALL -nolog > /dev/null 2>&1 
  /opt/MegaRAID/MegaCli/MegaCli64 -fwtermlog -dsply -aALL -nolog > `hostname -s`_megacli64-FwTermLog_$datestamp.out
  /opt/MegaRAID/MegaCli/MegaCli64 -cfgdsply -aALL -nolog > `hostname -s`_megacli64-CfgDsply_$datestamp.out
  /opt/MegaRAID/MegaCli/MegaCli64 -adpbbucmd -aALL -nolog >  `hostname -s`_megacli64-BbuCmd_$datestamp.out
  /opt/MegaRAID/MegaCli/MegaCli64 -LdPdInfo -aALL  -nolog > `hostname -s`_megacli64-LdPdInfo_$datestamp.out
  /opt/MegaRAID/MegaCli/MegaCli64 -PDList -aALL -nolog > `hostname -s`_megacli64-PdList_long_$datestamp.out
  /opt/MegaRAID/MegaCli/MegaCli64 -LDInfo -LALL -aALL -nolog > `hostname -s`_megacli64-LdInfo_$datestamp.out

  $OAK_HOME/oakcli show ib > `hostname -s`_show_ib_$datestamp.out
  ibstatus >  `hostname -s`_ibstatus_$datestamp.out 
}

hdwrType
check_for_ebod_number
datestamp="`date +%Y_%m_%d_%H_%M`"
mkdir -p /tmp/diskdiag_$datestamp
cd /tmp/diskdiag_$datestamp

cp /var/log/messages* .

/bin/dmesg > `hostname -s`_dmesg_$datestamp.out


/sbin/lspci > `hostname -s`_lspci_$datestamp.out

/sbin/lspci -xxxx > `hostname -s`_lspci-xxxx_$datestamp.out

/usr/bin/lsscsi > `hostname -s`_lsscsi_$datestamp.out


/usr/bin/lsscsi > `hostname -s`_lsscsi_$datestamp.out

/sbin/fdisk -l > `hostname -s`_fdisk-l_$datestamp.out 2>&1

/usr/bin/ipmitool sel elist > `hostname -s`_sel-list_$datestamp.out


/opt/oracle/oak/bin/oakcli show storage > `hostname -s`_show-storage_$datestamp.out

/opt/oracle/oak/bin/oakcli show disk > `hostname -s`_show-disk_$datestamp.out
/opt/oracle/oak/bin/oakcli show diskgroup > `hostname -s`_show-diskgroup_$datestamp.out
/opt/oracle/oak/bin/oakcli show expander 0 > `hostname -s`_show-expander_0_$datestamp.out
/opt/oracle/oak/bin/oakcli show expander 1 > `hostname -s`_show-expander_1_$datestamp.out
/opt/oracle/oak/bin/oakcli show version -detail > `hostname -s`_show-version_$datestamp.out
i=0
if [ "$isV1" == 1 ]; then
   while [  $i -lt $counter ]; do
      if [ $i -lt 10 ]; then 
         $OAK_HOME/oakcli show disk pd_0$i >> `hostname -s`_show-disk_detail_$datestamp.out
      else
         $OAK_HOME/oakcli show disk pd_$i >> `hostname -s`_show-disk_detail_$datestamp.out
      fi 
      let i=i+1
   done
else
   while [  $i -lt $counter ]; do
         if [ $i -lt 10 ]; then
            $OAK_HOME/oakcli show disk e0_pd_0$i >> `hostname -s`_show-disk_detail_$datestamp.out
            else
            $OAK_HOME/oakcli show disk e0_pd_$i >> `hostname -s`_show-disk_detail_$datestamp.out
         fi
         let i=i+1
   done
fi

# For two jbod system on V2 and above dump oakcli show disk output after 1st get printed
i=0
if [ $isV1 -eq 0 ] && [ $numOfJbod -eq 2 ]; then
   while [  $i -lt $counter ]; do
      if [ $i -lt 10 ]; then
         $OAK_HOME/oakcli show disk e1_pd_0$i >> `hostname -s`_show-disk_detail_$datestamp.out
      else
         $OAK_HOME/oakcli show disk e1_pd_$i >> `hostname -s`_show-disk_detail_$datestamp.out
      fi
      let i=i+1
   done
fi

/opt/oracle/oak/bin/oakcli show disk -local > `hostname -s`_show-local_disk_$datestamp.out

/usr/sbin/dmidecode -s system-serial-number  > `hostname -s`_system-serial_$datestamp.out

cp /opt/oracle/oak/log/`hostname -a`/oak/oakd.log .

# X5-2 system with IB cards
if [ $isV4 -eq 1 ] && [ $isV4_IB -eq 1 ]; then
   get_IB_data
fi

cd /tmp
tar -pjcvf /tmp/diskdiag_$datestamp.tar.bz2 diskdiag_$datestamp
echo "=============================================================================="
echo "ODA sundiag Script Version 2.1"
echo "The report files are in bzip2 compressed /tmp/diskdiag_$datestamp.tar.bz2"
echo "=============================================================================="
/bin/rm -rf diskdiag_$datestamp
exit 0
