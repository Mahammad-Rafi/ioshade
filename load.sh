#!/bin/bash

export LANG=C

#TODAY="at $(date '+%H:%M on %d.%b.%y')"
TODAY="$(date '+%b %d, %Y %r %Z')"
OutputFilename=$(date +"%b_%d_%Y".html)

#
#Remove old HTML file
#

if [ -f /tmp/${OutputFilename} ]; then
	rm -f /tmp/${OutputFilename}
fi

#
#Create HTML File with Table
#
(
SAR=`sar -u 1 1|tail -n1`

#perfdata

PERFDATA=`echo ${SAR} | awk '{{printf("%.0f "), $3+$4+$5+$6+$7;};  {printf("%.2f%% "), $3+$4+$5+$6+$7}; {printf("%.2f%% "), $8}; {printf("%.2f%% "), $3}; {printf("%.2f%% "), $4}; {printf("%.2f%% "), $5}; {printf("%.2f%% "), $6}; {printf("%.2f%% "), $7}}'`

PERCENT=`echo $PERFDATA|awk '{print $1}'`
USED=`echo $PERFDATA|awk '{print $2}'`
ID=`echo $PERFDATA|awk '{print $3}'`
US=`echo $PERFDATA|awk '{print $4}'`
NI=`echo $PERFDATA|awk '{print $5}'`
SY=`echo $PERFDATA|awk '{print $6}'`
IW=`echo $PERFDATA|awk '{print $7}'`
ST=`echo $PERFDATA|awk '{print $8}'`

#
#Verify if disk usage is greater equal to, than set threshold limit - 90%
#

if [[ ${PERCENT} -ge 80 ]];
 then
	COLOR=#db3236
	CRITICALALERT="Yes,Notify"
	SEVR=Critical
	SC=Red

#
#If the disk space used is greater than 70% and less than 80% set alert color as orange
#
elif [ ${PERCENT} -ge 70 ] && [ ${PERCENT} -le 80 ];
then
	COLOR=#f4c20d
	CRITICALALERT="No"
	SEVR=Warning
	SC=Gold
#
#Other usage percentage set color as green
#
else
	COLOR=#3cba54
	CRITICALALERT="NA"
	SEVR=Normal
	SC=Green
fi

echo '<HTML><HEAD><TITLE>CPU Usage Statistics</TITLE></HEAD>'
echo '<BODY>'
#echo '<H3><b>CPU Usage Alert for Host=</b>'$(uname -n)' ('$(hostname -i)')</H3>'
echo '<P>Host=<b>'$(uname -n)' ('$(hostname -i)')</b><br>Reported Time=<b>'${TODAY}'</b></br><br>Severity=<b><font color='${SC}'>'${SEVR}'</font></b></br></P>'
echo '<TABLE BORDER=3 CELLSPACING=2 CELLPADDING=0>'
#echo '<TR BGCOLOR="#4885ed"> <TH>Used</TH> <TH>SY</TH> <TH>US</TH> <TH>NI</TH> <TH>ID</TH> <TH>IW</TH> <TH>ST</TH> <TH>Total CPU Use%</TH> <TH>Critical Alert</TH></TR>'
echo '<TR style="color: white; background-color: #001b4d"> <TH>System</TH> <TH>User</TH> <TH>Nice</TH> <TH>Idle</TH> <TH>I/O</TH> <TH>Steal</TH> <TH>Total CPU Use%</TH> <TH>Critical Alert</TH></TR>'
#
#Create Table Columns
#
#echo '<TR><TD ALIGN=RIGHT>'$USED'</TD><TD ALIGN=RIGHT>'$SY'</TD>'
echo '<TD ALIGN=RIGHT>'$SY'</TD>'
echo '<TD ALIGN=RIGHT>'$US'</TD><TD ALIGN=RIGHT>'$NI'</TD>'
echo '<TD ALIGN=RIGHT>'$ID'</TD><TD ALIGN=RIGHT>'$IW'</TD><TD ALIGN=RIGHT>'$ST'</TD>'
echo '<TD><TABLE BORDER=0 CELLSPACING=3 CELLPADDING=0>'
echo '<TR><TD WIDTH='$((2 * $PERCENT))' BGCOLOR='"$COLOR"'></TD>'
echo '<TD WIDTH='$((2 * (100 - $PERCENT)))' BGCOLOR="gray"></TD>'
echo '<TD><FONT FONT-WEIGHT="bold" SIZE=-1 COLOR='"$COLOR"'>'$USED'</FONT></TD>'
echo '<TD><FONT font-weight="bold"><TR></TABLE></TD><TD>'$CRITICALALERT'</TD></FONT></TR>'
#echo '</TABLE><P><FONT font-weight="bold">By Ashtech Team</P></BODY></HTML>'
echo '</TABLE>'
echo '<pre><font color="Black">'
#top -b -n 1 -c |head -n 20 
echo "Top 15 CPU consuming processes"
echo "%CPU %MEM   PID  PPID   UID CPU  NI S     TIME COMMAND"
ps -e -o pcpu,pmem,pid,ppid,uid,cpu,nice,state,cputime,args --sort pcpu | sed '/^ 0.0 /d'|pr -TW150|grep -v ^'%CPU'|tail -n 15|sort -nr
echo '</font></pre>'
echo '<b><P>~Team Ashtech</P></b>') | tee ${0##*/}.html

#
#Send E-Mail Notification - Snippet
#
(
echo From:jitendra_more@ashinfo.com
echo To:vmanageit@pathinfotech.com
echo Cc:hasan@polycab.com,ashish.anekar@polycab.com,ashish_chawan@ashinfo.com,vinod_menon@ashinfo.com,mahammad_rafi@ashinfo.com
#echo To:jitendra_more@ashinfo.com
#echo Cc:jitendramore3@gmail.com
echo "Content-Type:text/html;"
echo Subject: CPU Usage Alert for server `hostname`
echo 
cat ${0##*/}.html
)|sendmail -t
