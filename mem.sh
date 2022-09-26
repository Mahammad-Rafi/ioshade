#!/bin/bash

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
#
#Collect Memory Usage Info
#
MEM=`free | awk '/buffers\/cache/{printf("%.0f "),$3/($3+$4)*100}'`
MEMORY=`free -m|sed -ne '2,3p'|tr -s  '\n' ' '`

USED_MEMP=`echo ${MEMORY}|awk '{{printf("%.2f%% "), $10/$2*100}}'`
MVAL=`echo ${MEMORY}|awk '{{printf("%.2f "), $10/$2*100}}'`
FREE_MEMP=`echo ${MEMORY}|awk '{{printf("%.2f%% "), $11/$2*100}}'`
BUFFERSP=`echo ${MEMORY}|awk '{{printf("%.2f%% "), $6/$2*100}}'`
CACHEP=`echo ${MEMORY}|awk '{{printf("%.2f%% "), $7/$2*100}}'`

USED_MEM=`echo ${MEMORY}|awk '{{printf  $10"M"}}'`
FREE_MEM=`echo ${MEMORY}|awk '{{printf  $11"M"}}'`
BUFFERS=`echo ${MEMORY}|awk '{{printf $6"M"}}'`
CACHE=`echo ${MEMORY}|awk '{{printf  $7"M"}}'`



PERCENT="${MEM}"

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

echo '<HTML><HEAD><TITLE>Memory Usage Statistics</TITLE></HEAD>'
echo '<BODY>'
#echo '<H3><b>Memory Usage Alert for Host=</b>'$(uname -n)' ('$(hostname -i)')</H3>'
echo '<P>Host=<b>'$(uname -n)'</b><br>Target type=<b>Host</b><br>Target name=<b>'$(uname -n)'</b><br>Categories=<b>Capacity</b><br>Message=<b>Memory Utilization is '$USED_MEMP', crossed warning(70) or critical(80) threshold.</b><br>Severity=<b><blink><font color='${SC}'>'${SEVR}'</font></b></blink><br>Reported Time=<b>'${TODAY}'</b><br>Operating System=<b>'$(uname -o)'</b><br>Platform=<b>'$(uname -i)'</b><br>Event type=<b>Metric Alert</b><br>Event name<b>=RAM:MemoryUtil</b><br>Metric=<b>Memory Utilization(%)</b></b><br>Metric value=<b>'$MVAL'</b></b></br></P>'
echo '<TABLE BORDER=3 CELLSPACING=2 CELLPADDING=0>'
echo '<TR style="color: white; background-color: #001b4d"> <TH>Used Mem</TH> <TH>Cache</TH> <TH>Buffers</TH> <TH>Free Mem</TH> <TH>Use%</TH> <TH>Critical Alert</TH></TR>'


#
#Create Table Columns
#
echo '<TD ALIGN=RIGHT>'$USED_MEM' ('$USED_MEMP')</TD><TD ALIGN=RIGHT>'$CACHE' ('$CACHEP')</TD>'
echo '<TD ALIGN=RIGHT>'$BUFFERS' ('$BUFFERSP')</TD><TD ALIGN=RIGHT>'$FREE_MEM' ('$FREE_MEMP')</TD>'
echo '<TD><TABLE BORDER=0 CELLSPACING=3 CELLPADDING=0>'
echo '<TR><TD WIDTH='$((2 * $PERCENT))' BGCOLOR='"$COLOR"'></TD>'
echo '<TD WIDTH='$((2 * (100 - $PERCENT)))' BGCOLOR="gray"></TD>'
echo '<TD><FONT FONT-WEIGHT="bold" SIZE=-1 COLOR='"$COLOR"'>'$USED_MEMP'</FONT></TD>'
echo '<TD><FONT font-weight="bold"><TR></TABLE></TD><TD>'$CRITICALALERT'</TD></FONT></TR>'
#echo '</TABLE><P><FONT font-weight="bold">By Ashtech Team</P></BODY></HTML>')| tee ${0##*/}.html
echo '</TABLE>'
echo '<pre><b><font color='"Black"'>'
#top -b -n 1 -c |head -n 20
echo "Top 15 Memory utilization processes..."
echo "%MEM %CPU   PID  PPID   UID CPU  NI S     TIME COMMAND"
#ps -e -o pmem,pcpu,pid,ppid,uid,cpu,nice,state,cputime,args --sort pmem | sed '/^ 0.0 /d'|pr -TW150|grep -v ^'%Memory'|tail -n 15|sort -nr
ps -e -o pmem,pcpu,pid,ppid,uid,cpu,nice,state,cputime,args --sort pmem | sed '/^ 0.0 /d'|pr -TW150|grep -v ^'%MEM'|tail -n 15|sort -nr
echo '</b></font></pre>'
echo '<b><P>~Ashtech Team</P></b>') | tee ${0##*/}.html


#
#Send E-Mail Notification - Snippet
#
(
#echo From:me
echo To:jitendra_more@ashinfo.com
echo Cc:jitendra_more@ashinfo.com
echo "Content-Type:text/html;"
echo Subject:"Alert from `uname -n` - Memory Utilization is crossed warning(70) or critical(80) threshold."
echo 
cat ${0##*/}.html
)|/usr/sbin/sendmail -t
