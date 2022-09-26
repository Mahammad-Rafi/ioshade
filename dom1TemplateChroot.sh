#!/bin/sh
#
# $Header: oak/src/pkg/src/dom1TemplateChroot.sh /main/51 2014/08/21 12:36:56 jchheda Exp $
#
# dom1TemplateChroot.sh
#
# Copyright (c) 2012, 2014, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      dom1TemplateChroot.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    jchheda     08/21/14 - Bug 19456979. Change OAKDRUN mode to "non-cluster
#    jchheda     07/21/14 - Bug 19244484. Add ORA_OAK_HOME to bash_profile
#    sripadal    07/10/14 - 19168821 fix
#    jchheda     06/30/14 - Fix Bug18920270. mkinitrd issue
#    sripadal    06/24/14 - 18767256 fix
#    jchheda     06/15/14 - Fixed new Dom1 time issue. Bug 18751236
#    jchheda     06/04/14 - Bug 18896566. Set net.ipv4.conf.all.rp_filter
#    jchheda     05/21/14 - Bug18767765. Disable rpcidmapd.
#    sdhabre     04/30/14 - added panic_on_oops = 1.
#    sdhabre     04/23/14 - service smartd off
#    jchheda     03/18/14 - XbranchMerge jchheda_bug-18393279 from
#                           st_oak_2.10.0.0.0
#    jchheda     03/05/14 - XbranchMerge jchheda_bug-18341996 from
#                           st_oak_2.10.0.0.0
#    jchheda     03/17/14 - Bug 18393279. Setting kernel.pid_max
#    jchheda     03/04/14 - Fixed Bug 18341996
#    sdhabre     02/21/14 - removed hwmgmt service 18248999.
#    jchheda     01/15/14 - Fixed 18007822. Fixed Dom0 timezone as well.
#    jchheda     01/10/14 - Fixed 18054988. Disable icmp redirects
#    sdhabre     12/09/13 - bug 12965665
#    jchheda     12/04/13 - Bug 14312972 Comment the alsactl commands in
#                           /etc/rc.d/init.d/halt
#    jchheda     11/25/13 - Bug17607638 Setting VM.MIN_FREE_KBYTES=512000
#    sdhabre     10/16/13 - added ipv6.disable=1
#    sdhabre     10/15/13 - .bug 17213125 fixed disabled services in dom1
#    sdhabre     10/15/13 - bug 17210990 fixed.
#    sdhabre     10/03/13 - setting java 1.7 as default java using alternatives
#                           cmd.
#    sdhabre     10/01/13 - setting number of nfsd to 128, bug 17484816.
#    sdhabre     09/10/13 - creating private.net, bug 17231310.
#    ssingla     09/06/13 - nfs service
#    sdhabre     09/01/13 - bug 17336977 fixed.
#    ssingla     08/02/13 - remove public yum repo
#    ssingla     08/01/13 - disable yum-updatesd
#    sdhabre     07/15/13 - disabling transparent huge pages bug 17166372
#    sdhabre     07/04/13 - increasing baud rate ,
#    sdhabre     06/18/13 - removed MPT2SAS.MSIX_DISBABLE=1 from grub.conf, creating multipath.conf
# 			    with only blacklist section
#    sdhabre     06/13/13 - Adding pci=noaer in grub.conf for dom1
#    ssingla     06/10/13 - disable ctrl alt del
#    sdhabre     06/04/13 - Enabling fishwrap logs.
#    sdhabre     05/31/13 - replaced osw302 by oswbb601
#    ssingla     03/18/13 - network params v2
#    ssingla     03/11/13 - mpt2sas param
#    ssingla     01/11/13 - password complexity function
#    ssingla     01/09/13 - irq balance service off
#    ssingla     01/02/13 - clock file
#    ssingla     01/02/13 - setup osw
#    ssingla     01/02/13 - copy mib files
#    ssingla     12/21/12 - dom1 boot options
#    ssingla     12/18/12 - remove yum repo file
#    ssingla     12/10/12 - turn off bluetooth
#    ssingla     11/09/12 - turning on kudzu service
#    ssingla     11/07/12 - add missing changes from setupoak.sh to dom1
#                           template
#    ssingla     10/25/12 - change the grub params for serial console
#    ssingla     10/23/12 - change to uek kernel
#    ssingla     10/18/12 - build initrd with multipath
#    ssingla     10/18/12 - add swiotlb parameter to boot line
#    ssingla     09/19/12 - add swap
#    ssingla     08/10/12 - delete oracle user
#    ssingla     08/07/12 - unpack end user bundle
#    ssingla     08/03/12 - turn off iptables
#    ssingla     07/31/12 - template chroot script
#    ssingla     07/31/12 - Creation
#

mount -t proc /proc /proc 
mount -t sysfs /sys /sys

cat > /etc/fstab <<EOF
LABEL=rootfs             /                      ext3    defaults        1 1
LABEL=bootfs             /boot                  ext3    defaults        1 2
LABEL=u01fs               /u01                   ext3    defaults        0 0
LABEL=swapfs              swap                   swap    defaults        0 0
tmpfs                   /dev/shm                tmpfs   defaults        0 0
devpts                  /dev/pts                devpts  gid=5,mode=620  0 0
sysfs                   /sys                    sysfs   defaults        0 0
proc                    /proc                   proc    defaults        0 0
EOF

cat > multipath.conf <<EOF
blacklist {
  devnode "^asm/*"
  devnode "ofsctl"
  devnode "xvd*"
}
EOF
mv multipath.conf /etc/multipath.conf

kernelversion=`rpm -q --qf '%{VERSION}-%{RELEASE}\n' kernel-uek`
initrd=/boot/initrd-${kernelversion}.img

if [ -e "$initrd" ]
then
  rm -f $initrd
fi

/sbin/mkinitrd --with=dm-multipath --with=xen-blkfront --with=xen-netfront  --builtin=ehci-hcd --builtin=ohci-hcd  --builtin=uhci-hcd $initrd ${kernelversion}

#for pvops kernel need to set iommu=force and for xen kernel swiotlb=force
cat >/boot/grub/grub.conf <<EOF
default=0
timeout=5
splashimage=(hd0,0)/grub/splash.xpm.gz
#hiddenmenu
serial --unit=0 --speed=115200  --word=8 --parity=no --stop=1
terminal --timeout=5 serial console
title Oracle Linux Server (${kernelversion})
        root (hd0,0)
        kernel /vmlinuz-${kernelversion} ro root=LABEL=rootfs tsc=reliable nohpet nopmtimer hda=noprobe hdb=noprobe ide0=noprobe numa=off pci=noaer console=tty console=ttyS0,115200n8 selinux=0 nohz=off crashkernel=256M@64M loglevel=7 panic=60 ipv6.disable=1 
        initrd /initrd-${kernelversion}.img
EOF

cat >/boot/grub/device.map <<EOF
(hd0)   /dev/xvda
EOF

cat >/etc/sysconfig/network <<EOF
NETWORKING=yes
HOSTNAME=test
NOZEROCONF=yes
EOF


/usr/sbin/pwconv
/root/rootpasswd.sh

#services related action
/sbin/chkconfig firstboot off
/sbin/chkconfig iptables off
/sbin/chkconfig avahi-daemon off
#turning off kudzu service caused problem with vnc
#/sbin/chkconfig kudzu off
/sbin/chkconfig cpuspeed off
/sbin/chkconfig kdump on
/sbin/chkconfig snmptrapd on
/sbin/chkconfig snmpd on
/sbin/chkconfig multipathd on
/sbin/chkconfig ntpd on
/sbin/chkconfig bluetooth off
/sbin/chkconfig irqbalance off
/sbin/chkconfig yum-updatesd off
/sbin/chkconfig nfs on

#disabling services in dom1 bug 17213125
/sbin/chkconfig anacron  off
/sbin/chkconfig autofs off         
/sbin/chkconfig hidd off     
/sbin/chkconfig ip6tables off
/sbin/chkconfig iscsi off          
/sbin/chkconfig iscsid off       
/sbin/chkconfig mcstrans off       
/sbin/chkconfig o2cb off      
/sbin/chkconfig ocfs2 off      
/sbin/chkconfig oraclevalidated off
/sbin/chkconfig pcscd off 
/sbin/chkconfig rawdevices off  
/sbin/chkconfig restorecond off  
/sbin/chkconfig rhnsd off  
/sbin/chkconfig smartd off
##
## Bug18767765. Disable rpcidmapd.
/sbin/chkconfig rpcidmapd off

rm -f /etc/yum.repos.d/public-yum-el5.repo

#setup swapiness to 100
echo 'vm.swappiness=100' >> /etc/sysctl.conf
echo 'kernel.panic_on_oops = 1' >> /etc/sysctl.conf

#enabling cores 
echo 'fs.suid_dumpable=1' >> /etc/sysctl.conf
echo 'kernel.core_pattern=core.%e.%p' >> /etc/sysctl.conf
sed  -i 's/ulimit -S -c 0/ulimit -S -c unlimited/' /etc/profile

#network params
echo 'net.ipv4.conf.all.arp_announce=2' >> /etc/sysctl.conf
echo 'net.ipv4.conf.all.arp_ignore=1' >> /etc/sysctl.conf
echo 'net.ipv4.conf.all.arp_filter=1' >>  /etc/sysctl.conf

#sysctl modifications
sed -i 's/memlock.*/memlock\t72000000/' /etc/security/limits.conf
sed -i 's/net.core.wmem_max.*/net.core.wmem_max=2097152/' /etc/sysctl.conf

for param in 'net.core.rmem_max' 'net.core.wmem_max' 'net.ipv4.tcp_rmem' 'net.ipv4.tcp_wmem' 'net.core.netdev_max_backlog' 'net.ipv4.tcp_moderate_rcvbuf'
  do
    echo $param
    grep -v $param /etc/sysctl.conf > /etc/sysctl.conf.tmp
    mv -f /etc/sysctl.conf.tmp /etc/sysctl.conf
  done
echo 'net.core.rmem_max=134217728' >> /etc/sysctl.conf
echo 'net.core.wmem_max=134217728' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_rmem=4096 87380 134217728' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_wmem=4096 65536 134217728' >> /etc/sysctl.conf
echo 'net.core.netdev_max_backlog=300000' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_moderate_rcvbuf=1' >> /etc/sysctl.conf


cat >> /etc/security/limits.conf <<EOF
grid   soft   nofile    131072
grid   hard   nofile    131072
grid   soft   nproc    131072
grid   hard   nproc    131072
grid   soft   core    unlimited
grid   hard   core    unlimited
grid   soft   memlock   72000000
grid   hard   memlock   72000000
EOF

#set the syslog params for the fsync 
/usr/bin/perl -pi -e 's/\s\/var/-\/var/' /etc/syslog.conf

#remove information from resolv.conf
echo 'search localdomain' > /etc/resolv.conf

#setup snmptrapd.conf file
echo 'disableAuthorization yes' > /etc/snmp/snmptrapd.conf

#asm syslog logging
echo 'local0.info   /var/log/asmaudit.log' >> /etc/syslog.conf
/usr/bin/perl -pi -e 's/mail.none/local0.none;mail.none/' /etc/syslog.conf

#password algorithm
/usr/sbin/authconfig --passalgo=md5 --update


cat >>/etc/logrotate.d/asmaudit <<EOF
/var/log/asmaudit.log {
  weekly
  rotate 4
  compress
  copytruncate
  delaycompress
  notifempty
}
EOF

#Add pam_limits.so entry
echo "session     required      pam_limits.so" >> /etc/pam.d/login
#export ORA_OAK_HOME='/opt/oracle/oak'
#for file in `ls /opt/OAKEndUserBundle*zip`
#do
#  echo "Unpacking $file"
#  /opt/oracle/oak/bin/oakcli unpack -package $file
#done

#remove yum repos 
/usr/bin/yum clean all
rm -f /etc/yum.repos.d/oda.repo

#copy mib files
mkdir -p /usr/share/snmp/mibs/
cp /root/Extras/*mib /usr/share/snmp/mibs/

#setup osw
if [ -f "/root/Extras/oswbb601.tar" ]; then
  mkdir -p /opt/oracle/oak/oswbb
  mkdir -p /opt/oracle/oak/oswbb/archive
  cp /root/Extras/oswbb601.tar /opt/oracle/oak/
  cd /opt/oracle/oak/
  tar -oxvf oswbb601.tar
  rm -f /opt/oracle/oak/oswbb601.tar
  
  touch /opt/oracle/oak/oswbb/private.net
  chmod 755 /opt/oracle/oak/oswbb/private.net
  echo 'echo `date`' >> /opt/oracle/oak/oswbb/private.net
  echo "traceroute -r -F 192.168.16.27" >> /opt/oracle/oak/oswbb/private.net
  echo "traceroute -r -F 192.168.16.28" >> /opt/oracle/oak/oswbb/private.net
  echo "rm locks/lock.file" >> /opt/oracle/oak/oswbb/private.net

  # Start at boot, run as root and interval is 10 seconds, for 21 days
  echo "runuser root -c \"/opt/oracle/oak/oswbb/startOSWbb.sh 10 504 gzip /opt/oracle/oak/oswbb/archive \"" >> /etc/rc.d/rc.local
  
fi

##fishwarp log enabled for ovm
sed -i 's|FWRP_LOG_LEVEL = .|FWRP_LOG_LEVEL = 5|' /etc/sun-ssm/oracle_hmp.conf
mkdir -p  /opt/oracle/oak/log/fishwrap
echo FWRP_LOG_FILE = /opt/oracle/oak/log/fishwrap/fishwrap.log >> /etc/sun-ssm/oracle_hmp.conf
#/opt/oracle/oak/install/init.oak restart

##
#clock file
cat >/etc/sysconfig/clock <<EOF
ZONE="America/Los_Angeles"
UTC=true
ARC=false
EOF
#setting nfsd cound to 128
sed -i 's/\#RPCNFSDCOUNT=8/RPCNFSDCOUNT=128/' /etc/sysconfig/nfs
##
##making java 1.7 as default java
alternatives  --auto java
alternatives --install /usr/bin/java java /usr/java/jdk1.7.0_25/jre/bin/java 17025
#

# Disabling transparent huge pages. Bug 17336977 fixed by commenting out below lines of code
#echo "if test -f /sys/kernel/mm/transparent_hugepage/enabled; then" >> /etc/rc.d/rc.local
#echo "    echo never > /sys/kernel/mm/transparent_hugepage/enabled"  >> /etc/rc.d/rc.local
#echo "fi" >> /etc/rc.d/rc.local
#echo "if test -f /sys/kernel/mm/transparent_hugepage/defrag; then" >> /etc/rc.d/rc.local
#echo "    echo never > /sys/kernel/mm/transparent_hugepage/defrag" >> /etc/rc.d/rc.local
#echo "fi" >> /etc/rc.d/rc.local

#removing old file for *2.6.18*
rm -f /boot/*2.6.18-308*
rm -f /boot/*2.6.18-348*

##remove oracle user and group
userdel oracle
groupdel oinstall
groupdel dba

#disable ctrlaltdel
sed -i 's/^ca/#ca/' /etc/inittab

#umount /proc
umount /sys


#Bug17607638 Setting VM.MIN_FREE_KBYTES=512000
#Bug18341996 Setting VM.MIN_FREE_KBYTES=524288

VALUE=`grep -i 'vm.min_free_kbytes' /etc/sysctl.conf | grep -v ^\# | awk -F \= '/vm.min_free/{print $2}' | sed -e 's/^ *//g;s/ *$//g'`
if [ -z "$VALUE" ];
then
echo "vm.min_free_kbytes=524288" >> /etc/sysctl.conf;
else
 if [ "$VALUE" -le 524288 ]; then
 sed -i 's/^vm.min_free_kbytes.*$/vm.min_free_kbytes = 524288/' /etc/sysctl.conf;
 sed -i 's/vm.min_free_kbytes is 512000/vm.min_free_kbytes is 524288/' /etc/sysctl.conf;
 sed -i 's/vm.min_free_kbytes is 51200/vm.min_free_kbytes is 524288/' /etc/sysctl.conf;
 fi
fi

# Bug 14312972 Comment the alsactl commands in /etc/rc.d/init.d/halt
sed -i '/Save mixer/,+4 s/^/# /'  /etc/rc.d/init.d/halt

#bug 12965665 fixed, removing invalid links
for module in /lib/modules/*
do
if [ -L $module/build ]
then
 rm -f $module/build
fi
if [ -L $module/source ]
then
 rm -f $module/source
fi
done


#Bug 18054988. Disable icmp redirects

VALUE1=`grep -i 'net.ipv4.conf.all.accept_redirects' /etc/sysctl.conf | grep -v ^\# | awk -F \= '/net.ipv4.conf.all.accept_redirects/{print $2}' | sed -e 's/^ *//g;s/ *$//g'`
if [ -z "$VALUE1" ];
then
echo "net.ipv4.conf.all.accept_redirects = 0" >> /etc/sysctl.conf;
else
 sed -i 's/^net.ipv4.conf.all.accept_redirects.*$/net.ipv4.conf.all.accept_redirects = 0/' /etc/sysctl.conf;
fi

#Fixed 18007822. Fixed Dom1 timezone issue.

mv /etc/localtime /tmp/localtime.bkp
ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
touch /root/.tzfirst
echo "" >> /etc/rc.local
echo "" >> /etc/rc.local
echo "if [ -f /root/.tzfirst ]; then" >> /etc/rc.local
echo "/sbin/hwclock -s --utc" >> /etc/rc.local
echo "/sbin/hwclock -w --utc" >> /etc/rc.local
echo "rm -f /root/.tzfirst" >> /etc/rc.local
echo "fi " >> /etc/rc.local


# Bug 18393279. Setting kernel.pid_max

PID_VALUE=`grep -i 'kernel.pid_max' /etc/sysctl.conf | grep -v ^\# | awk -F \= '/kernel.pid_max/{print $2}' | sed -e 's/^ *//g;s/ *$//g'`
if [ -z "$PID_VALUE" ];
then
echo "kernel.pid_max = 99999" >> /etc/sysctl.conf;
 echo "Setting kernel.pid_max "
else
 if [ "$PID_VALUE" -gt 99999 ]; then
 sed -i 's/^kernel.pid_max.*$/kernel.pid_max = 99999/' /etc/sysctl.conf;
 echo "Updating kernel.pid_max.  OLD_VALUE: $PID_VALUE"
 fi
fi


#Bug 18896566. Set net.ipv4.conf.all.rp_filter.

VALUE2=`grep -i 'net.ipv4.conf.all.rp_filter' /etc/sysctl.conf | grep -v ^\# | awk -F \= '/net.ipv4.conf.all.rp_filter/{print $2}' | sed -e 's/^ *//g;s/ *$//g'`
if [ -z "$VALUE2" ];
then
echo "net.ipv4.conf.all.rp_filter = 2" >> /etc/sysctl.conf;
else
 sed -i 's/^net.ipv4.conf.all.rp_filter.*$/net.ipv4.conf.all.rp_filter = 2/' /etc/sysctl.conf;
fi


#Bug 19244484. Add ORA_OAK_HOME and PATH environment settings to /root/.bash_profile.

echo 'export ORA_OAK_HOME=/opt/oracle/oak' >> /root/.bash_profile
echo 'export PATH=$ORA_OAK_HOME/bin:$PATH' >> /root/.bash_profile

#Bug 19456979.  Change OAKDRUN mode to "non-cluster".
echo "non-cluster" > /opt/oracle/oak/install/oakdrun


