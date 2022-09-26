#!/bin/sh

######################################################################
# PWC unix interrogation script nextgen
# Written by: anindya, rcrum 
#
#        
# $Id: secng.sh,v 2.1 2006-05-08 15:23:40 jbausch Exp $
# $Author: jbausch $
# $Date: 2006-05-08 15:23:40 $
######################################################################
# Complete list of functions:
######################################################################
#
# usage () {
# print_version () {
# dump_global_opts () {
# print_separator () {
# print_flag_header () {
# get_file () {
# check_os () {
# do_intro () {
# do_outro () {
# do_setup_output_files () {
# do_chmod () {
# do_file_cleanup () {
# do_tar () {
# do_xchecks () {
# do_ftpchecks () {
# do_sendmailchecks () {
# do_nfschecks () {
# do_bindchecks () {
# do_sshchecks () {
# do_net_checks () {
# do_uname () {
# do_accts_no_pass () {
# do_uid_zero () {
# do_fs_checks () {
# do_cron_checks () {
# do_log_checks () {
# do_users_files_check () {
# do_dmesg () {
# do_general_checks () {
# do_nis_check () {
# do_nisplus_check () {
# do_key_dirs_listing () {
# do_finds () {
# do_os_modules () {
# do_custom_dir () {
#
######################################################################
#
# function definitions
#
######################################################################
# function to print usage
######################################################################
usage () {
   ${ECHO} ""
   ${ECHO} "Usage: $0 [options]"
   ${ECHO} ""
   ${ECHO} "[-debug|-nodebug] Toggle DEBUG                   [default=off]"
   ${ECHO} "[-conftar|-noconftar] Toggle DO_CONFIGTAR        [default=off]"
   ${ECHO} "[-tar|-notar] Toggle DO_TAR                      [default=on]"
   ${ECHO} "[-users|-nousers] Toggle DO_SEARCH_USERS         [default=on]"
   ${ECHO} "[-nis|-nonis] Toggle DO_NIS                      [default=on]"
   ${ECHO} "[-nisusers] Toggle DO_NIS_SEARCH_USERS           [default=off]"
   ${ECHO} "[-nisplus|-nonisplus] Toggle DO_NISPLUS          [default=on]"
   ${ECHO} "[-nisplususers] Toggle DO_NISPLUS_SEARCH_USERS   [default=off]"
   ${ECHO} "[-finds|-nofinds] Toggle DO_ALLFINDS             [default=on]"
   ${ECHO} "[-keydirs|-nokeydirs] Toggle DO_KEY_DIRS_LISTING [default=on]"
   ${ECHO} "[-osmods|-noosmods] Toggle DO_OS_MODULES         [default=on]"
   ${ECHO} "[-noshadow] Turn OFF DO_GET_SHADOWFILE           [default=on]"
   ${ECHO} "[-bind] Turn ON DO_BIND                          [default=off]"
   ${ECHO} "[-custom] Turn ON Custom Dir Checks              [default=off]" 
   ${ECHO} "[-v|-version] Print $0 version and exit"
   ${ECHO} "[-h|-help] Print this usage message"
   ${ECHO} ""
   ${ECHO} "Example: $0 -debug -tar -nonis -nonisplus -nofinds"
   ${ECHO} "" 
   ${ECHO} "This command turns on debugging, creates an output tarball"
   ${ECHO} "turns off the nis and nis+ checks"
   ${ECHO} "and turns off the setuid/setgid/ww find comands"
   ${ECHO} "" 
   ${ECHO} "Also see etc/global.rc for detailed info on flags"
}
######################################################################
# function to print version 
######################################################################
print_version () {
   VERSION=`${GREP} Id $0 |${GREP} "^#"|${AWK} '{print $4}'`
   ${ECHO} "$0 version ${VERSION}"
}

######################################################################
# function to dump all global variables called from main
######################################################################
dump_global_opts () {

   ${ECHO} "Dumping global variables to output file" >>${OUTFILE}
   ${ECHO} "<DEBUGGLOBALOPTS>" >>${TAGS_OUT}
   print_separator outfile 
   # export all variables
   for i in ${GLOBALOPTS}
   do
   export $i
   done

   case "${OS}" in

     'Linux'|'AIX'|'FreeBSD'|'OpenBSD'|'NetBSD'|'OSF1'|'HP-UX'|'SCO_SV')
                ${AWK} ' BEGIN { for (env in ENVIRON) print env "=" ENVIRON[env] }'|${SORT} |${TEE} ${TAGS_OUT} >>${OUTFILE}
		;;
     'Solaris') 
                ${NAWK} ' BEGIN { for (env in ENVIRON) print env "=" ENVIRON[env] }'|${SORT} |${TEE} ${TAGS_OUT}  >>${OUTFILE}
		;;
       'Sol9')
                ${NAWK} ' BEGIN { for (env in ENVIRON) print env "=" ENVIRON[env] }'|${SORT} |${TEE} ${TAGS_OUT} >>${OUTFILE}
                ;;
       'Sol10')
                ${NAWK} ' BEGIN { for (env in ENVIRON) print env "=" ENVIRON[env] }'|${SORT} |${TEE} ${TAGS_OUT} >>${OUTFILE}
                ;;
	*)
                ${AWK} ' BEGIN { for (env in ENVIRON) print env "=" ENVIRON[env] }' |${SORT} |${TEE} ${TAGS_OUT} >>${OUTFILE}
                ${NAWK} ' BEGIN { for (env in ENVIRON) print env "=" ENVIRON[env] }' |${SORT} |${TEE} ${TAGS_OUT} >>${OUTFILE}
		;;
   esac 
   print_separator outfile 
   ${ECHO} "Script VERSION is:" |${TEE} ${TAGS_OUT} >>${OUTFILE}
   print_version |${TEE} ${TAGS_OUT} >>${OUTFILE}
   print_separator outfile 
   ${ECHO} "</DEBUG-GLOBALOPTS>" >>${TAGS_OUT}
}
######################################################################
# function to print out a nice line to separate output, called from many func 
######################################################################
print_separator () {
   case "$1" in
   'stdout') 
          ${ECHO} '===================================================='
	  ;;
   'outfile')
         case "$2" in
           
         'userfiles') 
		${ECHO} '====================================================' >>${USER_FILE_OUT}
		;;
         'logs')
		${ECHO} '====================================================' >>${LOG_FILE_OUT}
		;;
         'keydirs') 
		${ECHO} '====================================================' >>${KEYDIRS_OUT}
		;;
         'mods') 
		${ECHO} '====================================================' >>${MODS_OUT}
		;;
         'custdirs')
                ${ECHO} '====================================================' >>${CUSTDIRS_OUT}
                ;;
	'tagsout')
		${ECHO} '**************************' >>${TAGS_OUT}
		;;
          *)
         	${ECHO} '====================================================' >>${OUTFILE}
	 	;;
	 esac
	;;
      *)
	 ${ECHO} "Argument must be stdout or outfile."
	 ;;
    esac
}
####################################################################
# print_flag_header
# $1 must be stdout or outfile
# $2 must be userfiles/logs/keydirs/mods/custdir or main 
# $3 is either BEGIN or END
# $4 is the text to be printed, a flag such 
# as DO_ACCTNOPASS or module name
####################################################################
print_flag_header () {

   case "$1" in
   'stdout') 
     print_separator stdout 
     ${ECHO} "DEBUG: $2 $3 $4 $5"
     print_separator stdout 
     ;;
   'outfile')
      case "$2" in

         'userfiles')
                print_separator outfile userfiles
                ${ECHO} "USERFILES_$3: $4">>${USER_FILE_OUT}
                print_separator outfile userfiles
                ;;
         'logs')
                print_separator outfile logs
                ${ECHO} "LOGS_$3: $4">>${LOG_FILE_OUT}
                print_separator outfile logs
                ;;
         'keydirs')
                print_separator outfile keydirs
                ${ECHO} "KEYDIRS_$3: $4">>${KEYDIRS_OUT}
                print_separator outfile keydirs
                ;;
         'mods')
                print_separator outfile mods
                ${ECHO} "MODULE_$3: $4">>${MODS_OUT}
                print_separator outfile mods
                ;;
         'main')
                print_separator outfile
                ${ECHO} "CHECK_$3: $4">>${OUTFILE}
                print_separator outfile
		#added for TAG support, not used yet
		#${ECHO} "<CHECK_$3: $4" >>${TAGS_OUT}
                ;;
         'custdirs')
                print_separator outfile custdirs
                ${ECHO} "CUSTDIRS_$3: $4">>${CUSTDIRS_OUT}
                print_separator outfile custdirs
                ;;
             *)
                ${ECHO} "Arguments: [userfiles|logs|keydirs|mods|main|custdirs]"
                ;;
         esac
        ;;
      *)
         ${ECHO} "Argument must be stdout or outfile."
         ;;
    esac
}
####################################################################
####################################################################
# function to check for existence of a file , then cat it to outfile
# takes filename as an argument, called from many diff functions
####################################################################
get_file () {

   # check to make sure we were passed some args
   if [ $# = 0 ]; then
      ${ECHO} "get_file(): no file specified."
      ${ECHO} "get_file(): no file specified." >>${ERRFILE}
      return
   fi

   target=$1;
   name="";
   
   case "$2" in
   'userfiles')
		OUT=${USER_FILE_OUT}
		;;
   'mods')
		OUT=${MODS_OUT}
		;;
   *)
		OUT=${OUTFILE}
		;;
   esac

   if ( ${TEST} -f ${target} ) then

      print_separator outfile $2
      name=`${BASENAME} ${target}|${TR} '[a-z]' '[A-Z]'`
      ${ECHO} "[FILE]: ${name}" >>${OUT}
      
      ${ECHO} "<FILE TAG=\"${name}\"" >>${TAGS_OUT} 
      
      #only perform ls -l once
      DO_LS_ONCE=`${LS} -l ${target}`
      
      ${ECHO} "${DO_LS_ONCE}" >>${OUT} 2>>${ERRFILE}
      
      ${ECHO} "LS=\"${DO_LS_ONCE}\">" >>${TAGS_OUT}
       
      # if the file is a symlink to another file,
      # dereference the link also.
      if ( ${TEST} -L ${target} ) then
         ${LS} -lL ${target} >>${OUT} 2>>${ERRFILE} >>${TAGS_OUT}
      fi
      print_separator outfile $2

      if [ "${DO_CONFIGTAR}" = "0" ]; then

         [ "${DEBUG}" != "0" ] && { 
            ${ECHO} "DEBUG: Grabbing ${target}"
         }
         ${CAT} ${target} >> ${OUT} 2>>${ERRFILE}
	
	 # Added line to capture in TAGS file 
         ${CAT} ${target} >>${TAGS_OUT} 2>>${ERRFILE}

         print_separator outfile $2
	 ${ECHO} "</FILE>" >>${TAGS_OUT}
         ${ECHO} '' >> ${OUT}

      elif ( [ "${DO_CONFIGTAR}" = "1" ]  && [ -d "${SYSDIR}" ] ); then

         # get path to duplicate under SYSDIR
         pathtotarget=`${DIRNAME} ${target}`

         [ "${DEBUG}" != "0" ] && {
            ${ECHO} "DEBUG: Copying ${target}"
         }
       
         # if file is /etc/rc2.d/S99sendmail it creates SYSDIR/etc/rc2.d
         ${MKDIR} -p ${SYSDIR}/${pathtotarget} 2>>${ERRFILE}
         # copy the file over
         ${CP} -p ${target} ${SYSDIR}/${pathtotarget} 2>>${ERRFILE}

      else 

         ${MKDIR} -p ${SYSDIR} 2>${ERRFILE}
         # get path to duplicate under SYSDIR
         pathtotarget=`${DIRNAME} ${target}`

         [ "${DEBUG}" != "0" ] && {
            ${ECHO} "DEBUG: Copying ${target}"
         }
       
         # if file is /etc/rc2.d/S99sendmail it creates SYSDIR/etc/rc2.d
         ${MKDIR} -p ${SYSDIR}/${pathtotarget} 2>>${ERRFILE}
         # copy the file over
         ${CP} -p ${target} ${SYSDIR}/${pathtotarget} 2>>${ERRFILE}

      fi
   else
      name=`${BASENAME} ${target}|${TR} '[a-z]' '[A-Z]'`
      print_separator outfile $2
      ${ECHO} "[FILE]: ${name} <NOT FOUND>" >> ${OUT}
      ${ECHO} "<FILE TAG=\"${name}\"> NOT FOUND </FILE>" >>${TAGS_OUT}
      print_separator outfile $2
   fi
}
######################################################################
# function check_os, called from main
# Determine OS first to get binary paths
# Ignore errors here
#
######################################################################
check_os () {
   # get operating system name
   OS=`/usr/bin/uname -s 2>>/dev/null`
   [ "x${OS}" = "x" ] && {
      OS=`/bin/uname -s 2>>/dev/null`
   }	
   # get operating system release version
   OS_RELEASE=`/usr/bin/uname -r 2>>/dev/null`
   [ "x${OS_RELEASE}" = "x" ] && {
      OS_RELEASE=`/bin/uname -r 2>>/dev/null`
   }	

   # export these values for use elsewhere
   export OS OS_RELEASE

   case "${OS}" in  
     'Linux')  
	       	OS_CONF=${LINUX_CONF}
		MODULES=${LINUX_MODS}
	       ;;
     'SunOS') 
	 	RELEASE=`/bin/uname -r | /usr/bin/cut -c1` 
	 	if ( /usr/bin/test "${RELEASE}" = "5" ) then
            	      # added for sol9
			SUBRELEASE=`/bin/uname -r | /usr/bin/cut -c3-4 `
                        if ( /usr/bin/test "${SUBRELEASE}" = "9" ) then 
			     OS="Sol9"
	    		     #echo "System type is Solaris9"
	    		     OS_CONF=${SOL9_CONF}		
		             MODULES=${SOL9_MODS}
		      # added for sol10
			elif ( /usr/bin/test "${SUBRELEASE}" = "10" ) then
			     OS="Sol10"
                             #echo "System type is Solaris10"
	    		     OS_CONF=${SOL10_CONF}		
		             MODULES=${SOL10_MODS}
			else
			     OS="Solaris"
                             #echo "System type is Solaris6-8"
                             OS_CONF=${SOLARIS_CONF}
                             MODULES=${SOLARIS_MODS}	
			     fi
		else
	    		#echo "System type is SunOS"
	    		OS_CONF=${SUNOS_CONF}		
		        MODULES=${SUNOS_MODS}
            		fi
	    	;;
     'BSD/OS')
	 	#echo "System type is BSD"
        # im afraid this will not work for now
	 	OS_CONF=${BSD_CONF}		
		MODULES=${BSD_MODS}
	 	;;
     'FreeBSD'|'OpenBSD'|'NetBSD')
	 	#echo "System type is BSD"
	 	OS_CONF=${BSD_CONF}		
		MODULES=${BSD_MODS}
	 	;;
     'AIX')
	 	#echo "System type is AIX"
	 	OS_CONF=${AIX_CONF}		
		MODULES=${AIX_MODS}
	 	;;
     'HP-UX')
	 	echo "System type is HP-UX"
	 	OS_CONF=${HPUX_CONF}		
		MODULES=${HPUX_MODS}
	 	;;
     'SCO_SV')
	 	#echo "System type is SCO"
	 	OS_CONF=${SCO_CONF}		
		MODULES=${SCO_MODS}
	 	;;
     'OSF1'|'osf1')
	 	#echo "System type is DEC OSF1"
	 	OS_CONF=${OSF1_CONF}		
		MODULES=${OSF1_MODS}
	 	;;
     *)
        echo "WARNING!!! Unknown OS.  Absolute pathnames will NOT be used."
        echo "Press Ctrl-C to exit or wait 15 seconds to continue."
        echo ""
        sleep 15
	 	OS_CONF=${GENERIC_CONF}
	 	;;
     esac

    # source the appropriate config file
    if [ "${DEBUG}" != 0 ]; then
    	echo "DEBUG: Using OS configuration file: ${OS_CONF}"
    fi

    if [ -f ${OS_CONF} ]; then
 	  . ${OS_CONF}
    else 
	  echo "${OS_CONF} not found! Quitting."
          exit 1;
    fi
    return;

} # end check_os
####################################################################
# function to print out start banner and copyright, called from main
####################################################################
do_intro () {
   print_separator stdout
   ${ECHO} "${COPYRIGHT}"
   print_separator stdout
   print_version
   print_separator stdout
   ${ECHO} "Beginning Security Profile on ${HOSTNAME}"
   ${ECHO} "  Start time - `date`"
   print_separator stdout

   # write the start to the logfile
   print_separator outfile 
   # print the script version at the top
   print_version >>${OUTFILE}
   print_separator outfile 
   ${ECHO} "Beginning Security Profile on ${HOSTNAME}" >>${OUTFILE}
   ${ECHO} "  Start time - `date`" >>${OUTFILE}
   print_separator outfile 

   # write the start of the logfile in fancy support
   ${ECHO} "<SECNG_VERSION>" >>${TAGS_OUT}
   	${ECHO} "${VERSION}" >>${TAGS_OUT} 
   ${ECHO} "</SECNG_VERSION>" >>${TAGS_OUT}
   
   ${ECHO} "<HOSTNAME>" >>${TAGS_OUT}
	${ECHO} "${HOSTNAME}" >>${TAGS_OUT}
   ${ECHO} "</HOSTNAME>" >>${TAGS_OUT}
   
   ${ECHO} "<STARTTIME>" >>${TAGS_OUT}
	${ECHO} "`date`" >>${TAGS_OUT}
   ${ECHO} "</STARTTIME>" >>${TAGS_OUT}

} 

####################################################################
# function to print out end banner, called from main
####################################################################
do_outro () {
   print_separator stdout
   ${ECHO} "Finished Security Profile on ${HOSTNAME}"
   ${ECHO} "End time - `date`" 
   print_separator stdout

   print_separator outfile
   ${ECHO} "<ENDTIME>" >> ${TAGS_OUT}
   ${ECHO} "Finished Security Profile on ${HOSTNAME}" >>${OUTFILE}
   ${ECHO} "End time - `date`" |${TEE} ${TAGS_OUT} >> ${OUTFILE}
   ${ECHO} "</ENDTIME>" >> ${TAGS_OUT}
   print_separator outfile 
   ${ECHO} '' >> ${OUTFILE}

   
}
######################################################################
# function to name output files, called from main
######################################################################
do_setup_output_files () {

   HOSTNAME=`${HOST_CMD}`
   if (${TEST} x${HOSTNAME} = x) then
      HOSTNAME="unknown"
   fi

   # filename definitions
   OUTFILE="${OUTDIR}/${HOSTNAME}.`date +%Y%m%d`"
   TARFILE="${OUTFILE}.tar"
   ERRFILE="${OUTFILE}.errors"
   SETUID_OUT=${OUTFILE}.setUID
   SETGID_OUT=${OUTFILE}.setGID
   WW_OUT=${OUTFILE}.ww
   USER_FILE_OUT=${OUTFILE}.userfiles
   LOG_FILE_OUT=${OUTFILE}.logs
   KEYDIRS_OUT=${OUTFILE}.keydirs
   MODS_OUT=${OUTFILE}.osmodules
   SYSDIR=${OUTFILE}.configs
   CUSTDIRS_OUT=${OUTFILE}.custom
   TAGS_OUT=${OUTFILE}.tags

   if [ "${DEBUG}" != 0 ]; then
      ${ECHO} ''
      ${ECHO} "DEBUG: OUTFILE is ${OUTFILE}"
      ${ECHO} "DEBUG: TARFILE is ${TARFILE}"
      ${ECHO} "DEBUG: ERRFILE is ${ERRFILE}"
      ${ECHO} "DEBUG: SETUID_OUT is ${SETUID_OUT}"
      ${ECHO} "DEBUG: SETGID_OUT is ${SETGID_OUT}"
      ${ECHO} "DEBUG: WW_OUT is ${WW_OUT}"
      ${ECHO} "DEBUG: USER_FILE_OUT is ${USER_FILE_OUT}"
      ${ECHO} "DEBUG: LOG_FILE_OUT is ${LOG_FILE_OUT}"
      ${ECHO} "DEBUG: KEYDIRS_OUT is ${KEYDIRS_OUT}"
      ${ECHO} "DEBUG: MODS_OUT is ${MODS_OUT}"
      ${ECHO} "DEBUG: SYSDIR is ${SYSDIR}"
      ${ECHO} "DEBUG: CUSTDIRS_OUT is ${CUSTDIRS_OUT}"
      ${ECHO} "DEBUG: TAGS_OUT is ${TAGS_OUT}"	
      ${ECHO} ''
   fi

   return;
}
####################################################################
# function to do housekeeping, remove old output files
# if they exist. Give operator an opportunity to abort., called from main
####################################################################
do_file_cleanup () {

   if ([ -f ${OUTFILE} ] || [ -f ${TARFILE} ] || [ -f ${TARFILE}.gz ]) then  
    ${ECHO} ""
    print_separator stdout 
    ${ECHO} ""
   	${ECHO} "WARNING!!! WARNING!!! WARNING!!! WARNING!!! WARNING!!!"
    ${ECHO} ""
    ${ECHO} "${OUTFILE} (or a tarred version) already exists."
    ${ECHO} "Press Ctrl-C to exit or wait to delete the existing files."
    ${ECHO} ""
   	${ECHO} "WARNING!!! WARNING!!! WARNING!!! WARNING!!! WARNING!!!"
    ${ECHO} ""
    print_separator stdout 
        sleep 5
    for i in ${OUTFILE} ${TARFILE} ${TARFILE}.gz ${ERRFILE} ${SETUID_OUT} ${SETGID_OUT} ${WW_OUT} ${USER_FILE_OUT} ${LOG_FILE_OUT} ${KEYDIRS_OUT} ${MODS_OUT} $CUSTDIRS_OUT} ${TAGS_OUT}
        do
        if [ "${DEBUG}" != "0" ] ; then
		   echo "DEBUG: Removing $i"
        fi
        /bin/rm -f $i
	done
    if [ "${DEBUG}" != "0" ] ; then
	   echo "DEBUG: Removing ${SYSDIR}"
    fi
    rm -rf ${SYSDIR}
  fi
  
   # create output files make sure its writable
   [ \! -d ${OUTDIR} ]  && {
      [ "${DEBUG}" != "0" ] && {
         ${ECHO} "DEBUG: ${OUTDIR} doesn't exist. Creating."
      }
      ${MKDIR} ${OUTDIR}
   }
   ${TOUCH} ${OUTFILE}
   ${TOUCH} ${ERRFILE}
   	[ \! -w ${OUTFILE} ] && {
       ${ECHO} "Error creating output file."
       ${ECHO} "Program is terminating."
       exit
    }

}
####################################################################
# function to change output file permissions, just in
# case the default UMASK is set insecure, called from main
# This check does a chmod 700 output/servname.*
# Added 8/2005
####################################################################
do_chmod () {
 if [ -f "${CHMOD}" ]; then
    # Change Permission on Output files, just in case
    [ "${DEBUG}" != "0" ] && {
         ${ECHO} "DEBUG: Changing secng output files to 700"
      }
    for i in ${OUTFILE} ${ERRFILE} ${SETUID_OUT} ${SETGID_OUT} ${WW_OUT} ${USER_FILE_OUT} ${LOG_FILE_OUT} ${KEYDIRS_OUT} ${MODS_OUT} ${CUSTDIRS_OUT} ${TAGS_OUT}
      do
      [ "${DEBUG}" != "0" ] && {
          ${ECHO} "DEBUG: Changing permissions on file $i"
        }
        chmod -f 600 $i
      done
 else
      ${ECHO} "${CHMOD} not found. Please correct path to tar in .rc file."
      exit 1
   fi
}

####################################################################
# function to tar up output files, called from main
####################################################################
do_tar () {
   if [ -f "${TAR}" ]; then
      # add all the output files to the tarball
      [ "${DEBUG}" != "0" ] && { 
         ${ECHO} "DEBUG: Adding all output files to ${TARFILE}"
      }
      if [ -f "${TARFILE}" ]; then 
	 # tarfile exists, so use TAROPT1
         ${TAR} ${TAROPT1} ${TARFILE} ${OUTDIR}/* 2>>${ERRFILE}
	 # secure tar file from bad UMASK perms
	 ${CHMOD} -f 600 ${TARFILE} 2>>${ERRFILE}
      else 
	 # tarfile doesnt exist, create using TAROPT
         ${TAR} ${TAROPT} ${TARFILE} ${OUTDIR}/* 2>>${ERRFILE}
	 # secure tar file from bad UMASK perms
         ${CHMOD} -f 600 ${TARFILE} 2>>${ERRFILE}
      fi

      [ "${DEBUG}" != "0" ] && { 
         ${ECHO} "DEBUG: Removing original output files."
      }

      for i in ${OUTFILE} ${ERRFILE} ${SETUID_OUT} ${SETGID_OUT} ${WW_OUT} ${USER_FILE_OUT} ${LOG_FILE_OUT} ${KEYDIRS_OUT} ${MODS_OUT} ${CUSTDIRS_OUT} ${TAGS_OUT}
      do
        [ "${DEBUG}" != "0" ] && { 
          ${ECHO} "DEBUG: Removing file $i"
        }
        rm -f $i
      done
      [ "${DEBUG}" != "0" ] && { 
          ${ECHO} "DEBUG: Removing dir ${SYSDIR}"
      }
      rm -rf ${SYSDIR}
      if [ "${HAVE_GZIP}" != "0" ]; then
         [ "${DEBUG}" != "0" ] && { 
            ${ECHO} "DEBUG: Compressing ${TARFILE} with ${GZIPBIN}"
         }
         ${GZIPBIN} ${TARFILE}
      fi 
   else 
      ${ECHO} "${TAR} not found. Please correct path to tar in .rc file."
      exit 1
   fi
}
###################################################################
# function to do x windows check,
# called from do_net_checks 
###################################################################
do_xchecks () {
   ${ECHO} "Checking X settings..."
   ${ECHO} "<XCHECK>" >>${TAGS_OUT}
   print_separator outfile 
   ${ECHO} "Checking X settings..."  >> ${OUTFILE}
   ${ECHO} "Command: ${XHOST}" >> ${OUTFILE}
   print_separator outfile 

   ${ECHO} '' >> ${OUTFILE}
   ${XHOST} |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
   ${ECHO} "</XCHECK>" >>${TAGS_OUT}
   for i in ${X_FILES}
     do	
      get_file $i
   done
   ${ECHO} '' >> ${OUTFILE}
} 
###################################################################
# function to do ftp checks, called from do_net_checks
###################################################################
do_ftpchecks () {
   # FTP Checks
   ${ECHO} "Checking ftp settings..."
   ${ECHO} '' >> ${OUTFILE}
   ${ECHO} "<FTP_SERVER>" >>${TAGS_OUT} 

# Get the ~ftp directory
   DIRS="`${AWK} -F: '($1 == "ftp") {print $6}' /etc/passwd`"
   if (${TEST} x${DIRS} = x) then
      ${ECHO} "No ftp user found.\n" |${TEE} ${TAGS_OUT} >> ${OUTFILE}
      # ftp files to search
      LIST="${FTP_FILES}"
   else
      ${LS} -lLd ${DIRS} |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
      ${ECHO} '' >> ${OUTFILE}
      ${ECHO} "${DIRS}:" >> ${OUTFILE}
      ${LS} -la ${DIRS} |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
      ${ECHO} '' >> ${OUTFILE}
      ${LS} -lR ${DIRS}/bin ${DIRS}/usr/bin ${DIRS}/sbin |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
      ${ECHO} '' >> ${OUTFILE}
      # ftp files to search
      LIST="${DIRS}/etc/passwd ${DIRS}/etc/group ${FTP_FILES}"
   fi

   # grab FTP-related files regardless of whether ftp user
   # exists or not 
   for FILE in ${LIST}
    do
     get_file ${FILE}
   done
   ${ECHO} "</FTP_SERVER>" >>${TAGS_OUT}
}

###################################################################
# function to do sendmail checks, called from do_net_checks
###################################################################
do_sendmailchecks () {
   # Sendmail Checks
   ${ECHO} "Checking sendmail settings..."
   ${ECHO} "<SENDMAIL>" >>${TAGS_OUT}
   ${ECHO} '' >> ${OUTFILE}
      ${ECHO} '' >> ${OUTFILE}
      # sendmail files to search
      LIST="${SENDMAIL_FILES}"
   # grab sendmail-related files 
   for FILE in ${LIST}
    do
     get_file ${FILE}
   done
   ${ECHO} "</SENDMAIL>" >>${TAGS_OUT}
}

###################################################################
# function to do nfs checks, pretty minimal for now, 
# called from do_net_checks
###################################################################
do_nfschecks () {

   ${ECHO} "Checking NFS exports..."
   ${ECHO} "Checking NFS exports..." >> ${OUTFILE}
   ${ECHO} "<NFS_EXPORTS>" >>${TAGS_OUT} 
   ${ECHO} "Command: ${SHOWMOUNT} -e"  >> ${OUTFILE}
   print_separator outfile
   ${ECHO} '' >> ${OUTFILE}
   ${SHOWMOUNT} -e  |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
   ${ECHO} >> ${OUTFILE}

   #Now get some NFS files
 
   ${ECHO} "Checking NFS files..."
   for i in ${NFS_FILES}
   do
      get_file $i
   done
   ${ECHO} "</NFS_EXPORTS>" >>${TAGS_OUT}
} 
###################################################################
# function to do bind checks, called from do_net_checks
###################################################################
do_bindchecks () {
   # named config checks
   ${ECHO} "Looking for bind configs..."
   ${ECHO} "Looking for bind configs..." >> ${OUTFILE}
   ${ECHO} "<BIND>" >>${TAGS_OUT}
   print_separator outfile
   [ -d ${BIND_CONF_DIR} ] && {
      case ${BIND_VERSION} in
         '4') 
		BIND_CONF=${BIND_CONF_DIR}/named.boot
		;;
	 '8')
		BIND_CONF=${BIND_CONF_DIR}/named.conf
		;;
	 '9')
		BIND_CONF=${BIND_CONF_DIR}/named.conf
		;;
	  *)
		${ECHO} "version must be 4, 8 or 9"
	        ;;
	  esac

      # grab the conf file
      get_file ${BIND_CONF}

      # grab named version header
      ${ECHO} "NAMED Version...."  >> ${OUTFILE}
      ${ECHO} "<BIND_VER>" >>${TAGS_OUT}
      ${NAMED_LOCATION} -v |${TEE} ${TAGS_OUT} >> ${OUTFILE}
      print_separator outfile
      ${ECHO} "</BIND_VER>" >>${TAGS_OUT}

      # now get zone files
      [ -d ${BIND_ZONEFILES_DIR} ] && {
	     for zone in `ls ${BIND_ZONEFILES_DIR}`
         do
            get_file ${BIND_ZONEFILES_DIR}/${zone}
         done
	  }

   }
   ${ECHO} "</BIND>" >>${TAGS_OUT}
} 
###################################################################
# function to do ssh checks, called from do_net_checks
###################################################################
do_sshchecks () {
   # ssh config checks
   ${ECHO} "Looking for global ssh configs..."
   ${ECHO} "<SSHVERSION>" >>${TAGS_OUT}
   print_separator outfile
   ${ECHO} "Looking for global ssh configs..." >> ${OUTFILE}
   ${ECHO} "Checking ssh version..."
   ${SSHBIN} -V |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${OUTFILE}
   print_separator outfile
   ${ECHO} "</SSHVERSION>" >>${TAGS_OUT}
   ${ECHO} '' >> ${OUTFILE}
   if [ -d ${SSHDIR} ]; then
      case ${SSH_VERSION} in
         '1') LIST=${GLOBAL_SSH_FILES_V1}
            ;;
         '2') LIST=${GLOBAL_SSH_FILES_V2}
            ;;
          *) 
			${ECHO} 'No ssh version specified' >> ${ERRFILE}
			;;
      esac

    for conf in ${LIST}
    do
    if ( ${TEST} -f ${conf} ) then
	   get_file ${conf}
    fi 
    done
  else 
    ${ECHO} "${SSHDIR} does not exist. Please edit ${GLOBALCONF}." 
    ${ECHO} "${SSHDIR} does not exist. Please edit ${GLOBALCONF}." >> ${OUTFILE}
  fi
}
###################################################################
# function to do all networking checks, called from main script
#
# also checks several flags:
# 1) DO_IFCONFIG
# 2) DO_NETSTAT_NR
# 3) DO_ARP
# 4) DO_NETSTAT_A
# 5) DO_RPCINFO
# 6) DO_GET_NET_CONFIGS
# 7) DO_XCHECKS
# 8) DO_FTP
# 9) DO_NFS
# 10) DO_BIND
# 11) DO_SSH
# 12) DO_SENDMAIL
###################################################################
do_net_checks () {
   # Network configuration
   ${ECHO} "Checking network configuration settings..."
   ${ECHO} "<NETCHECKS>" >>${TAGS_OUT}
   print_separator stdout

### Ifconfig checks #####
   ${ECHO} "<IFCONFIG>" >>${TAGS_OUT}
   if [ "${DO_IFCONFIG}" != "0" ]; then 
 
      print_flag_header outfile main BEGIN DO_IFCONFIG
      case "${OS}" in
 
         'HP-UX')
            ${ECHO} '' >> ${OUTFILE}
            ${ECHO} "Running LANSCAN then IFCONFIG on each int"  >> ${OUTFILE} 
            for i in `${LANSCAN}|${GREP} lan|${AWK} '{print $5}'`
            do
              ${IFCONFIG} $i |${TEE} ${TAGS_OUT} >>${OUTFILE}
            done
            ;;
          *)
             ${ECHO} '' >> ${OUTFILE}
             ${ECHO} "Using ${IFCONFIG} -a"  >> ${OUTFILE}
             ${ECHO} '' >> ${OUTFILE}
             ${IFCONFIG} -a |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
             ;;
      esac
      print_flag_header outfile main END DO_IFCONFIG
 
   elif [ "${DEBUG}" != "0" ]; then
      print_flag_header stdout SKIP DO_IFCONFIG
      ${ECHO} "skipped" >>${TAGS_OUT}
   fi
   ${ECHO} "</IFCONFIG>" >>${TAGS_OUT}

#### Routing Table and Interfaces #####

   ${ECHO} "<NETSTAT_NR>" >>${TAGS_OUT}
   if [ "${DO_NETSTAT_NR}" != "0" ]; then 
      print_flag_header outfile main BEGIN DO_NETSTAT_NR
      ${ECHO} '' >> ${OUTFILE}
      ${ECHO} "Command: ${NETSTAT} -rn" >> ${OUTFILE}
      ${ECHO} '' >> ${OUTFILE}
      ${NETSTAT} -rn |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
      ${ECHO} '' >> ${OUTFILE}
      print_flag_header outfile main END DO_NETSTAT_NR
   elif [ "${DEBUG}" != "0" ]; then
      print_flag_header stdout SKIP DO_NETSTAT_NR
      ${ECHO} "skipped" >>${TAGS_OUT}
   fi
   ${ECHO} "</NETSTAT_NR>" >>${TAGS_OUT}

   #ARP Table
   ${ECHO} "<ARP_TABLE>" >>${TAGS_OUT}
   if [ "${DO_ARP}" != "0" ]; then 
      ${ECHO} "Listing arp Table..."
      print_flag_header outfile main BEGIN DO_ARP
      ${ECHO} '' >> ${OUTFILE}
      ${ECHO} "Command: ${ARP} -a" >> ${OUTFILE}
      ${ECHO} '' >> ${OUTFILE}
      ${ARP} -a |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
      ${ECHO} '' >> ${OUTFILE}
      print_flag_header outfile main END DO_ARP
   elif [ "${DEBUG}" != "0" ]; then
      print_flag_header stdout SKIP DO_ARP
      ${ECHO} "skipped" >>${TAGS_OUT}
   fi
   ${ECHO} "</ARP_TABLE>" >>${TAGS_OUT}

   # Active Services
   ${ECHO} "<NETSTAT_A>" >>${TAGS_OUT}
   if [ "${DO_NETSTAT_A}" != "0" ]; then 
      ${ECHO} "Determining active services..."
      print_flag_header outfile main BEGIN DO_NETSTAT_A
      ${ECHO} '' >> ${OUTFILE}
      ${ECHO} "Command: ${NETSTAT} -a | ${GREP} LISTEN" >> ${OUTFILE}
      ${ECHO} '' >> ${OUTFILE}
      ${NETSTAT} -a | ${GREP} LISTEN |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
      ${ECHO} '' >> ${OUTFILE}
      print_flag_header outfile main END DO_NETSTAT_A
   elif [ "${DEBUG}" != "0" ]; then
      print_flag_header stdout SKIP DO_NETSTAT_A
      ${ECHO} "skipped" >>${TAGS_OUT}
   fi 
   ${ECHO} "</NETSTAT_A>" >>${TAGS_OUT}

   #rpcinfo
   ${ECHO} "<RPCINFO>" >>${TAGS_OUT}
   if [ "${DO_RPCINFO}" != "0" ]; then 
      ${ECHO} "Listing rpcinfo..."
      print_flag_header outfile main BEGIN DO_RPCINFO
      ${ECHO} '' >> ${OUTFILE}
      ${ECHO} "Command: ${RPCINFO} -p" >> ${OUTFILE}
      ${ECHO} '' >> ${OUTFILE}
      ${RPCINFO} -p |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
      ${ECHO} '' >> ${OUTFILE}
      print_flag_header outfile main END DO_RPCINFO
   elif [ "${DEBUG}" != "0" ]; then
      print_flag_header stdout SKIP DO_RPCINFO
      ${ECHO} "skipped" >>${TAGS_OUT}
   fi
   ${ECHO} "</RPCINFO>" >>${TAGS_OUT}
   
   # Get Basic Files
   if [ "${DO_GET_NET_CONFIGS}" != "0" ]; then 
      print_flag_header outfile main BEGIN DO_GET_NET_CONFIGS
      ${ECHO} "Getting basic networking files.."
      ${ECHO} "Getting basic networking files.." >>${OUTFILE}
      print_separator outfile
      # get the rest
      for i in ${NET_CONFIGS}
      do
         get_file $i
      done
      print_flag_header outfile main END DO_GET_NET_CONFIGS
   elif [ "${DEBUG}" != "0" ]; then
      print_flag_header stdout SKIP DO_GET_NET_CONFIGS
   fi

   # Do XCHECKS
   if [ "${DO_XCHECKS}" != "0" ]; then
      print_flag_header outfile main BEGIN DO_XCHECKS
      do_xchecks
      print_flag_header outfile main END DO_XCHECKS
   elif [ "${DEBUG}" != "0" ]; then
      print_flag_header stdout SKIP DO_XCHECKS
   fi

   # DO FTP 
   if [ "${DO_FTP}" != "0" ]; then
      print_flag_header outfile main BEGIN DO_FTP
      do_ftpchecks
      print_flag_header outfile main END DO_FTP
   elif [ "${DEBUG}" != "0" ]; then
      print_flag_header stdout SKIP DO_FTP
      ${ECHO} "skipped" >>${TAGS_OUT}
   fi

   # DO NFS CHECKS
   if [ "${DO_NFS}" != "0" ]; then
      print_flag_header outfile main BEGIN DO_NFS
      do_nfschecks
      print_flag_header outfile main END DO_NFS
   elif [ "${DEBUG}" != "0" ]; then
      print_flag_header stdout SKIP DO_NFS
      ${ECHO} "skipped" >>${TAGS_OUT}
   fi

   # DO BIND CHECKS
   if [ "${DO_BIND}" != "0" ]; then
      print_flag_header outfile main BEGIN DO_BIND
      do_bindchecks
      print_flag_header outfile main END DO_BIND
   elif [ "${DEBUG}" != "0" ]; then
      print_flag_header stdout SKIP DO_BIND
      ${ECHO} "skipped" >>${TAGS_OUT}
   fi

   # DO_SSH
   if [ "${DO_SSH}" != "0" ]; then
      print_flag_header outfile main BEGIN DO_SSH
      do_sshchecks
      print_flag_header outfile main END DO_SSH
   elif [ "${DEBUG}" != "0" ]; then
      print_flag_header stdout SKIP DO_SSH
      ${ECHO} "skipped" >>${TAGS_OUT}
   fi

# DO Sendmail Checks
   if [ "${DO_SENDMAIL}" != "0" ]; then
      print_flag_header outfile main BEGIN DO_SENDMAIL
      do_sendmailchecks
      print_flag_header outfile main END DO_SENDMAIL
   elif [ "${DEBUG}" != "0" ]; then
      print_flag_header stdout SKIP DO_SENDMAIL
      ${ECHO} "skipped" >>${TAGS_OUT}
   fi
   print_separator stdout
   ${ECHO} "</NETCHECKS>" >>${TAGS_OUT}
}
###################################################################
# function to do uname -a, called from do_general_checks
###################################################################
do_uname () {
   # do generic ident of OS
   ${ECHO} "Identify vendor and version of OS..."
   print_separator stdout
   ${UNAME} -a
   print_separator stdout

   print_separator outfile 
   ${ECHO} "Identify vendor and version of OS..." >> ${OUTFILE}
   ${ECHO} "<UNAME>" >>${TAGS_OUT}
   ${ECHO} "Command: ${UNAME} -a" >> ${OUTFILE}
   print_separator outfile 
   ${UNAME} -a |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
   print_separator outfile 
   ${ECHO} "</UNAME>" >>${TAGS_OUT}
}
####################################################################
# function to check for accounts with no password, called from do_
# general_checks
####################################################################
do_accts_no_pass () {

   
   ${ECHO} "Checking for accounts with no password."

   ${ECHO} "<ACCTS_NO_PASS>" >> ${TAGS_OUT}

   if [ "${OS}" != "AIX" ]; then

      if ( ${TEST} -f ${SHADOWFILE} ) then
         ${AWK} -- 'BEGIN { FS = ":" } ($2 == "") {print}' ${SHADOWFILE} |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
      else
         ${AWK} -- 'BEGIN { FS = ":" } ($2 == "") {print}' /etc/passwd |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
      fi
   else
     # Added ver 2.0 for AIX check, Troy Frost contributed
     # TROY AIX
     ${ECHO} "This is AIX, running custom AIX check looking for blank passwords"
     ${AWK} -- '{ 
        if (/:/) {
	  act=substr($1,0,(length $1) -1);
	  getline;
	  if((!/password/) || (!$3)) { 
	    print act " has a blank password";
	  }
	}
      }' /etc/security/passwd |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}

   fi

   ${ECHO} '' >> ${OUTFILE}
   ${ECHO} "</ACCTS_NO_PASS>" >> ${TAGS_OUT}

}
###################################################################
# function to check for UID 0 accounts, called from do_general_checks
####################################################################
do_uid_zero () {
   ${ECHO} "Checking for UID 0 accounts..." 
   ${ECHO} "<UID0>" >> ${TAGS_OUT}

   if [ "${OS}" != "AIX" ]; then
      #Use awk to find users with third field in password file equal to 0
      ${AWK} -- 'BEGIN { FS = ":" } ($3 == 0) {print}' /etc/passwd |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
   else
    #Use awk on AIX to find users with third field in password file equal to 0
    ${AWK} -- 'BEGIN { FS = ":" } ($3 == 0) {print}' /etc/passwd |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}   
   fi
      #${ECHO} '' >> ${OUTFILE}
   ${ECHO} "</UID0>" >> ${TAGS_OUT}
}
###################################################################
# function to do basic filesystem checks, called from do_general_checks
####################################################################
do_fs_checks () {

   ${ECHO} "Gathering information on the filesystem..."
   #print_separator outfile 
   #${ECHO} "Gathering information on the filesystem..." >> ${OUTFILE}
   #print_separator outfile 
   ${ECHO} '' >> ${OUTFILE}
   ${ECHO} "Using '${DF}':" >> ${OUTFILE}
   ${ECHO} "<DF>" >> ${TAGS_OUT}
   ${DF} |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
   ${ECHO} "</DF>" >> ${TAGS_OUT}
   ${ECHO} '' >> ${OUTFILE}
   ${ECHO} "Using '${SHOWMOUNT} -a':" >> ${OUTFILE}
   ${ECHO} "<SHOWMOUNT>" >> ${TAGS_OUT}
   ${SHOWMOUNT} -a |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
   ${ECHO} '' >> ${OUTFILE}
   ${ECHO} "</SHOWMOUNT>" >> ${TAGS_OUT}
   ${ECHO} "Using '${MOUNT}':" >> ${OUTFILE}
   ${ECHO} "<MOUNT>" >> ${TAGS_OUT}
   ${MOUNT} |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
   ${ECHO} '' >> ${OUTFILE}
   ${ECHO} "</MOUNT>" >> ${TAGS_OUT}

}
###################################################################
# function to check crontabs, called from do_general_checks 
###################################################################
do_cron_checks () {

   #Check crontab files
   ${ECHO} "Checking crontab files..."
   ${ECHO} "<CRONTAB>" >> ${TAGS_OUT}

   # get the cron files 
   for i in ${CRON_FILES}
   do
      get_file $i
   done

   ${ECHO} '' >> ${OUTFILE}
   ${ECHO} "</CRONTAB>" >> ${TAGS_OUT}

   ${ECHO} "Checking permissions on ${CRONDIR}" >>${OUTFILE}
   ${ECHO} "<CRONPERMS>" >>${TAGS_OUT}
   [ -d ${CRONDIR} ] && {
        DIRS=${CRONDIR}
        for dname in ${DIRS}
        do
           ${LS} -lLd ${dname} |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
           ${ECHO} '' |${TEE} ${TAGS_OUT} >> ${OUTFILE}
           for fname in `${LS} ${dname}`
           do
           if ( ${TEST} -f ${dname}/${fname} ) then
              ${LS} -l ${dname}/${fname} |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
              ${ECHO} '' |${TEE} ${TAGS_OUT} >> ${OUTFILE}
	      get_file ${dname}/${fname}
              ${ECHO} '' |${TEE} ${TAGS_OUT} >> ${OUTFILE}
            fi      #End test
            done    #End for fname
         done #End for dname
   }
   ${ECHO} '' |${TEE} ${TAGS_OUT} >> ${OUTFILE}
   ${ECHO} "</CRONPERMS>" >>${TAGS_OUT}
}
###################################################################
# function to get last 50 lines in logfile, called from do_general_checks
###################################################################
do_log_checks () {

   # Log information
   ${ECHO} "Displaying log information..."
   ${ECHO} '' >> ${LOG_FILE_OUT}
   # grab log info
   for log in ${LOG_FILES}
   do
        if ( ${TEST} -f ${log} ) then
           [ "${DEBUG}" != "0" ] && {
 		      ${ECHO} "DEBUG: Checking ${log}"
           }
           print_separator outfile logs
           ${ECHO} "<LOG=\"${log}\" LS=\"" >> ${TAGS_OUT} 
           ${ECHO} "[FILE]: ${log}" >> ${LOG_FILE_OUT}
           ${LS} -l ${log} |${TEE} ${TAGS_OUT} >> ${LOG_FILE_OUT} 2>>${ERRFILE}
           ${ECHO} "\">" >> ${TAGS_OUT}
           # if its a symlink, deref the symlink too
           if ( ${TEST} -L ${log} ) then
              ${LS} -lL ${log} |${TEE} ${TAGS_OUT} >> ${LOG_FILE_OUT} 2>>${ERRFILE}
           fi
           print_separator outfile logs
           ${TAIL} -100 ${log} |${TEE} ${TAGS_OUT} >> ${LOG_FILE_OUT} 2>>${ERRFILE}
           print_separator outfile logs
           ${ECHO} "</LOG>" >> ${TAGS_OUT}
        fi
   done
   ${ECHO} '' >> ${LOG_FILE_OUT}

   # Review the last login time of each user
   ${ECHO} "Checking the last login time of each user..."
   print_separator outfile logs
   ${ECHO} "Checking the last login time of each user..." >> ${LOG_FILE_OUT}
   print_separator outfile logs
   ${ECHO} '' >> ${LOG_FILE_OUT}
   ${ECHO} "<LASTLOGIN>" >> ${TAGS_OUT}
   ${ECHO} "Using: ${CUT} -d: -f1 /etc/passwd | ${XARGS} ${FINGER} -m" >> ${LOG_FILE_OUT}
   print_flag_header outfile logs BEGIN DO_FINGER
   ${CUT} -d: -f1 /etc/passwd | ${XARGS} ${FINGER} -m |${TEE} ${TAGS_OUT} >> ${LOG_FILE_OUT} 2>>${ERRFILE}
   ${ECHO} "</LASTLOGIN>" >> ${TAGS_OUT}
   print_flag_header outfile logs END DO_FINGER
   ${ECHO} '' >> ${LOG_FILE_OUT}
   

   ${ECHO} "Displaying last 100 logins..." >> ${LOG_FILE_OUT}
   ${ECHO} '' >> ${LOG_FILE_OUT}
   ${ECHO} "<LAST100-LOGINS>" >> ${TAGS_OUT}
   ${ECHO} "Using: ${LAST} -100" >> ${LOG_FILE_OUT}
   print_flag_header outfile logs BEGIN DO_LAST
   if (${TEST} ${OS} = 'SCO_SV') then
     ${LAST} -n 100 |${TEE} ${TAGS_OUT} >> ${LOG_FILE_OUT} 2>>${ERRFILE}
   else
     ${LAST} -100 |${TEE} ${TAGS_OUT} >> ${LOG_FILE_OUT} 2>>${ERRFILE}
   fi
   print_flag_header outfile logs END DO_LAST
   ${ECHO} '' >> ${LOG_FILE_OUT}
   ${ECHO} "</LAST100-LOGINS>" >> ${TAGS_OUT}

}
###################################################################
# function to get files from user home directories
# such as .rhosts, .netrc, etc, called from do_general_checks
###################################################################
do_users_files_check () {

   #Find user's .netrc, .rhosts, .profile, and other configuration files
   print_separator stdout 
   ${ECHO} "Finding user configuration files such as .rhosts, .netrc, etc..."
   print_separator stdout 
   print_separator outfile userfiles
   ${ECHO} "Finding user configuration files such as .rhosts, .netrc, etc..." >> ${USER_FILE_OUT}
   ${ECHO} "Finding user configuration files such as .rhosts, .netrc, etc..." >> ${OUTFILE}
   ${ECHO} "Please see ${USER_FILE_OUT} for detailed output." >> ${OUTFILE}
   print_separator outfile userfiles
   ${ECHO} '' >> ${USER_FILE_OUT}
  
   # process ssh options, set up list of files to look at 
   if ( ${TEST} "${DO_SSH}" = "1" ) then
      if ( ${TEST} "${SSH_VERSION}" = "1" ) then
	 LIST="${USER_FILES} ${USER_SSH_FILES_V1}"
      elif ( ${TEST} "${SSH_VERSION}" = "2" ) then
	 LIST="${USER_FILES} ${USER_SSH_FILES_V2}"
      fi
   else
      LIST="${USER_FILES}"
   fi

   # figure out whether to search user directories  only
   # or just root directories

   if ( ${TEST} "${DO_SEARCH_ROOTONLY}" = "1" ) then
      DIRS="/ /root"
   else
      DIRS="`${AWK} -F\: '{print $6}' /etc/passwd|${SORT}|${UNIQ}`"
      # if NIS search users check is enabled, traverse all user directories
      # in NIS passwd map as well.
      if ( ( ${TEST} "${DO_NIS_SEARCH_USERS}" = "1" ) &&
         ( ${TEST} "${DO_NIS}" = "1" ) ) then
        NISDIRS="`${YPCAT} passwd|${AWK} -F\: '{print $6}' |${SORT}|${UNIQ}`"
        DIRS="${DIRS} ${NISDIRS}"
      # if NISPLUS search users check is enabled, traverse all user directories
      # in NISPLUS passwd map as well. Not sure if this works.
      elif ( ( ${TEST} "DO_NISPLUS_SEARCH_USERS" = "1" ) &&
             ( ${TEST} "DO_NISPLUS" = "1" ) ) then
        NISPLUSDIRS="`${NISCAT} passwd.org_dir|${AWK} -F\: '{print $6}' |${SORT}|${UNIQ}`"
        DIRS="${DIRS} ${NISPLUSDIRS}"
      fi
   fi

   [ "${DEBUG}" != "0" ] && {
      ${ECHO} "DEBUG: Searching these dirs:"
      ${ECHO} "DEBUG: ${DIRS}"
      ${ECHO} "DEBUG: Searching for these files:"
      ${ECHO} "DEBUG: ${LIST}"
   } 

   for dname in ${DIRS}
   do
      ${ECHO} '' >> ${USER_FILE_OUT}
      ${LS} -lLd ${dname} >> ${USER_FILE_OUT} 2>>${ERRFILE}
      for fname in ${LIST}
      do
        if [ -f "${dname}/${fname}" ]; then
           ${ECHO} '' >> ${USER_FILE_OUT}
	       get_file ${dname}/${fname} userfiles
           ${ECHO} '' >> ${USER_FILE_OUT}
        else
           ${ECHO} "${dname}/${fname} <NOT FOUND>" >>${USER_FILE_OUT}
        fi      #End test
       done    #End for fname
    done    #End for dname

}
###################################################################
# function to do dmesg, special check for DMESG_FILE
###################################################################
do_dmesg () {
      ${ECHO} "Displaying dmesg..."
      ${ECHO} "<DMESG>" >>${TAGS_OUT}
      #print_separator outfile 
      #${ECHO} "Displaying dmesg..." >> ${OUTFILE}
      #${ECHO} "Command: ${DMESG}" >> ${OUTFILE}
      #print_separator outfile 
      ${ECHO} '' >> ${OUTFILE}
      ${DMESG} |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
      ${ECHO} '' >> ${OUTFILE}

	  # now get DMESG_FILE if it exists, mostly bsd-ism
      if [ "x${DMESG_FILE}" != "x" ]; then 
            get_file ${DMESG_FILE}
	  fi
      ${ECHO} "</DMESG>" >>${TAGS_OUT}
}
###################################################################
# function do_general_checks, called from main script
#
# This function does many generic checks, it checks the
# flags for each of the options, and run the 
# appropriate routine , some have subflags
#
# 1) DO_GET_GEN_CONFIGS 
# 2) DO_ACCTSNOPASS
# 3) DO_UIDZERO
# 4) DO_UMASK
# 5) DO_UPTIME
# 6) DO_PS
# 7) DO_WHO
# 8) DO_FS_CHECKS
# 9) DO_CRON
# 10) DO_LOG
# 11) DO_DMESG
###################################################################
do_general_checks () {

   ${ECHO} "Running through general checks."
   print_separator stdout
   
   if [ "${DO_GET_GEN_CONFIGS}" != "0" ]; then
      ${ECHO} "Grabbing general configuration files..."

      print_flag_header outfile main BEGIN DO_GET_GEN_CONFIGS

      # if -noshadow on command line,
      # don't grab the shadow file
      if [ "${DO_GET_SHADOWFILE}" != "0" ]; then
         # first get shadowfile 
         get_file ${SHADOWFILE}
      elif [ "${DO_GET_SHADOWFILE}" = "0" ]; then
	 # Let us record if client disable shadow checks
         ${ECHO} "<SHADOW>Check was manually disabled</SHADOW>" >>${TAGS_OUT}
      elif [ "${DEBUG}" != "0" ]; then
         ${ECHO} "DEBUG: Skipping shadow file: ${SHADOWFILE}"
	 ${ECHO} "<SHADOW>Check was manually disabled</SHADOW>" >>${TAGS_OUT}
      fi

      # get the rest
      for i in ${GEN_CONFIGS}
      do
        get_file $i
      done
   elif [ "${DEBUG}" != "0" ]; then
     print_flag_header stdout SKIP DO_GET_GEN_CONFIGS
   fi # end do_get_gen_configs
   print_flag_header outfile main END DO_GET_GEN_CONFIGS

   # check for accounts with no password
   if [ "${DO_ACCTSNOPASS}" != "0" ]; then
      print_flag_header outfile main BEGIN DO_ACCTSNOPASS
      do_accts_no_pass
      print_flag_header outfile main END DO_ACCTSNOPASS
   elif [ "${DEBUG}" != "0" ]; then
     print_flag_header stdout SKIP DO_ACCTSNOPASS
   fi

   # check for uid zero accounts
   if [ "${DO_UIDZERO}" != "0" ]; then
      print_flag_header outfile main BEGIN DO_UIDZERO
      do_uid_zero
      print_flag_header outfile main END DO_UIDZERO
   elif [ "${DEBUG}" != "0" ]; then
     print_flag_header stdout SKIP DO_UIDZERO
   fi

   # umask information
   #umask is a built-in shell command so no path is required
   if [ "${DO_UMASK}" != "0" ]; then
      ${ECHO} "Root's umask information..."
      print_flag_header outfile main BEGIN DO_UMASK
      ${ECHO} "<UMASK>" >>${TAGS_OUT}
      umask |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
      ${ECHO} "</UMASK>" >>${TAGS_OUT}
      print_flag_header outfile main END DO_UMASK
   elif [ "${DEBUG}" != "0" ]; then
     print_flag_header stdout SKIP DO_UMASK
     ${ECHO} "<UMASK>Manually Disabled</UMASK>" >>${TAGS_OUT}
   fi

   # uptime
   if [ "${DO_UPTIME}" != "0" ]; then
      ${ECHO} "Getting uptime..."
      print_flag_header outfile main BEGIN DO_UPTIME
      ${ECHO} "<UPTIME>" >>${TAGS_OUT}
      ${UPTIME} |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
      ${ECHO} "</UPTIME>" >>${TAGS_OUT}
      print_flag_header outfile main END DO_UPTIME
   elif [ "${DEBUG}" != "0" ]; then
     print_flag_header stdout SKIP DO_UPTIME
     ${ECHO} "<UPTIME>Manually Disabled</UPTIME>" >>${TAGS_OUT}
   fi

 
   # display running processes
   if [ "${DO_PS}" != "0" ]; then
      ${ECHO} "Listing currently running processes..."
      print_flag_header outfile main BEGIN DO_PS
      ${ECHO} "<PS>" >>${TAGS_OUT}
      ${PS} |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
      ${ECHO} "</PS>" >>${TAGS_OUT}
      print_flag_header outfile main END DO_PS
   elif [ "${DEBUG}" != "0" ]; then
     print_flag_header stdout SKIP DO_PS
     ${ECHO} "<PS>Manually Disabled</PS>" >>${TAGS_OUT}
   fi

   # List users who are currently online
   if [ "${DO_WHO}" != "0" ]; then
      ${ECHO} "Listing users who are currently online..."
      print_flag_header outfile main BEGIN DO_WHO
      ${ECHO} "<WHO>" >>${TAGS_OUT}
      $W |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
      ${ECHO} '' |${TEE} ${TAGS_OUT} >> ${OUTFILE}
      ${WHO} |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
      ${ECHO} "</WHO>" >>${TAGS_OUT}
      print_flag_header outfile main END DO_WHO
   elif [ "${DEBUG}" != "0" ]; then
     print_flag_header stdout SKIP DO_WHO
     ${ECHO} "<WHO>Manually Disabled</WHO>" >>${TAGS_OUT}
    fi

   # do fs checks
   if [ "${DO_FS_CHECKS}" != "0" ]; then
      print_flag_header outfile main BEGIN DO_FS_CHECKS
      do_fs_checks
      print_flag_header outfile main END DO_FS_CHECKS
   elif [ "${DEBUG}" != "0" ]; then
     print_flag_header stdout SKIP DO_FS_CHECKS
     ${ECHO} "<FS_CHECKS>Manually Disabled</FS_CHECKS>" >>${TAGS_OUT}

   fi

   # do cron checks
   if [ "${DO_CRON}" != "0" ]; then
      print_flag_header outfile main BEGIN DO_CRON
      do_cron_checks
      print_flag_header outfile main END DO_CRON
   elif [ "${DEBUG}" != "0" ]; then
     print_flag_header stdout SKIP DO_CRON
     ${ECHO} "<CRON_CHECKS>Manually Disabled</CRON_CHECKS>" >>${TAGS_OUT}
   fi

   # do log checks
   if [ "${DO_LOG}" != "0" ]; then
      print_flag_header outfile logs BEGIN DO_LOG
      do_log_checks
      print_flag_header outfile logs END DO_LOG
   elif [ "${DEBUG}" != "0" ]; then
     print_flag_header stdout SKIP DO_LOG
     ${ECHO} "<DO_LOG>Manually Disabled</DO_LOG>" >>${TAGS_OUT}
   fi

   if [ "${DO_DMESG}" != "0" ]; then
      print_flag_header outfile main BEGIN DO_DMESG
      do_dmesg
      print_flag_header outfile main END DO_DMESG
   elif [ "${DEBUG}" != "0" ]; then
     print_flag_header stdout SKIP DO_DMESG
     ${ECHO} "<DMESG>Manually Disabled</DMESG>" >>${TAGS_OUT}
   fi

   print_separator stdout
}
###################################################################
# function to do basic nis checks, called from main script
###################################################################
do_nis_check () {

   print_separator stdout
   ${ECHO} "NIS Checks..."
   ${ECHO} "<NIS_CHECK>" >>${TAGS_OUT}
   print_separator stdout
   #${ECHO} "Command: ${YPWHICH} and others" >> ${OUTFILE}

   NISMASTER=`${YPWHICH} 2>>${ERRFILE}`
   if (${TEST} x${NISMASTER} = x) then
        # Not using NIS
        ${ECHO} "This host does not appear to be running NIS."
        print_separator stdout
        ${ECHO} "This host does not appear to be running NIS" |${TEE} ${TAGS_OUT} >> ${OUTFILE}
   else
        # Perform NIS tests
        print_separator outfile
        ${ECHO} "<NIS_MASTER>" >>${TAGS_OUT}
        ${ECHO} "NIS Master is ${NISMASTER}" |${TEE} ${TAGS_OUT} >> ${OUTFILE}
        ${ECHO} "</NIS_MASTER>" >>${TAGS_OUT}
        print_separator outfile
        ${ECHO} "<NIS_DOMAIN>" >>${TAGS_OUT}
        ${ECHO} "Checking NIS domainname" >> ${OUTFILE}
   	${ECHO} '' >> ${OUTFILE}
        ${DOMAINNAME} |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
        print_separator outfile
        ${ECHO} "</NIS_DOMAIN>" >>${TAGS_OUT}

        ${ECHO} "Executing ${YPCAT} on NIS passwd file."  >> ${OUTFILE}
        ${ECHO} '' >> ${OUTFILE}
        # We can't tar it out, so we have to put it in the output file
        # Sort it so we can look for duplicate UIDs
        ${ECHO} "<NIS_PASSWD>" >>${TAGS_OUT}
        ${YPCAT} ${NIS_PASSWD} | ${SORT} -n -t: +2 - |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
        ${ECHO} '' >> ${OUTFILE}
        ${ECHO} "</NIS_PASSWD>" >>${TAGS_OUT}
        ${ECHO} "Listing all NIS accounts with a possible empty password."  >> ${OUTFILE}
        print_separator outfile
        ${ECHO} '' >> ${OUTFILE}
        ${ECHO} "<NIS_PASSWD_NOPASS>" >>${TAGS_OUT}
        ${YPCAT} ${NIS_PASSWD} | ${AWK} -- 'BEGIN { FS = ":" } ($2 == "") {print}' |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
        ${ECHO} '' >> ${OUTFILE}
        ${ECHO} "</NIS_PASSWD_NOPASS>" >>${TAGS_OUT}
        ${ECHO} "Listing all NIS accounts with possible root access."  >> ${OUTFILE}
        print_separator outfile
        ${ECHO} '' >> ${OUTFILE}
        ${ECHO} "<NIS_PASSWD_UID0>" >>${TAGS_OUT}
        ${YPCAT} ${NIS_PASSWD} | ${AWK} -- 'BEGIN { FS = ":" } ($3 == 0) {print}' |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
        ${ECHO} '' >> ${OUTFILE}
        ${ECHO} "</NIS_PASSWD_UID0>" >>${TAGS_OUT}

	# get all possible map names
        ${ECHO} "<NIS_MAPS_NUM>" >>${TAGS_OUT}
	NIS_MAPS=`${YPWHICH} -m |${AWK} '{print $1}'|${SORT}|${UNIQ}`
	TOTAL_NIS_MAPS=`${YPWHICH} -m |${AWK} '{print $1}'|${SORT}|${UNIQ}|${WC} -l`

        print_separator outfile
	echo "Number of NIS maps found: ${TOTAL_NIS_MAPS}" |${TEE} ${TAGS_OUT} >>${OUTFILE} 2>>${ERRFILE}
        print_separator outfile
        ${ECHO} "</NIS_MAPS_NUM>" >>${TAGS_OUT}
	echo "Number of NIS maps found: ${TOTAL_NIS_MAPS}"
        print_separator stdout

        # grab all NIS maps
        for map in ${NIS_MAPS}
        do
           ${ECHO} "<NIS_MAP_${map}>" >>${TAGS_OUT}
           ${ECHO} "==> Executing ${YPCAT} on NIS map: ${map}"  >> ${OUTFILE}
           ${ECHO} "==> Grabbing NIS map: ${map}"
           ${ECHO} '' >> ${OUTFILE}
           ${YPCAT} ${map} |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
           ${ECHO} '' >> ${OUTFILE}
           ${ECHO} "</NIS_MAP_${map}>" >>${TAGS_OUT}
        done
    fi
    ${ECHO} '' >> ${OUTFILE}
   ${ECHO} "</NIS_CHECK>" >>${TAGS_OUT}
}
###################################################################
# functions to do nis plus checks, called from main script
###################################################################
do_nisplus_check () {

   print_separator stdout
   ${ECHO} "NIS+ Checks..."
   ${ECHO} "<NIS_PLUS_CHECK>" >>${TAGS_OUT}
   print_separator stdout 

   print_separator outfile 
   ${ECHO} "NIS+ Checks..." >> ${OUTFILE}
   ${ECHO} "Command: ${NISDEFAULTS} and others" >> ${OUTFILE}
   print_separator outfile 
   ${ECHO} '' >> ${OUTFILE}
   #TODO: Find better check - There is probably a better NIS+ check.
   NISDOMAIN=`${NISDEFAULTS} -d 2>>${ERRFILE}`
   if (${TEST} x${NISDOMAIN} = x) then
        # Not using NIS+
        ${ECHO} "This host does not appear to be running NIS+"
        print_separator stdout
        ${ECHO} "This host does not appear to be running NIS+" |${TEE} ${TAGS_OUT} >> ${OUTFILE}
   else
        # Perform NIS+ tests
        ${ECHO} "NIS+ Domain is ${NISDOMAIN}" |${TEE} ${TAGS_OUT} >> ${OUTFILE}
        ${ECHO} '' >> ${OUTFILE}
        ${ECHO} "Executing ${NISCAT} on NIS+ passwd file."  >> ${OUTFILE}
        ${ECHO} '' >> ${OUTFILE}

        # We can't tar it out, so we have to put it in the output file
   	# Sort it so we can look for duplicate UIDs

   	${NISCAT} passwd.org_dir | ${SORT} -n -t: +2 -  |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
   	${ECHO} '' >> ${OUTFILE}

   	#TODO: Put in password checks for NIS+

   	${ECHO} "Executing ${NISCAT} on NIS+ hosts file."  >> ${OUTFILE}
   	${ECHO} '' >> ${OUTFILE}
   	${NISCAT} hosts.org_dir |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
   	${ECHO} '' >> ${OUTFILE}

   	#TODO: Verfity if it is group or groups
   	${ECHO} "Executing ${NISCAT} on NIS+ group file."  >> ${OUTFILE}
   	${ECHO} '' >> ${OUTFILE}
   	${NISCAT} group.org_dir |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
   fi
	${ECHO} '' >> ${OUTFILE}
	${ECHO} "</NIS_PLUS_CHECK>" >>${TAGS_OUT}
} 
###################################################################
# function to do listing of permissions on key directories
###################################################################
do_key_dirs_listing () {

  #Find permissions on a bunch of directories 
  print_separator stdout
  ${ECHO} "Listing permissions on key directories..."
  print_separator stdout
  ${ECHO} "Listing permissions on key directories..." >> ${OUTFILE}
  ${ECHO} "Please see ${KEYDIRS_OUT} for detailed output." >> ${OUTFILE}
  ${ECHO} '' >> ${KEYDIRS_OUT}
  ${ECHO} "<KEYDIRS>" >>${TAGS_OUT}

  if [ "${DO_KEY_DIRS_ETCONLY}" = "0" ]; then

     [ "${DEBUG}" != "0" ] && {
        ${ECHO} "DEBUG: Directories to be examined are:"
        ${ECHO} "DEBUG: ${KEY_DIRS}"
     } 

     for dname in ${KEY_DIRS}
        do
           [ -d ${dname} ] && {
                print_separator outfile keydirs
                ${ECHO} "<KEYDIRS-${dname}>" >>${TAGS_OUT}
                ${ECHO} "${dname}:" |${TEE} ${TAGS_OUT} >> ${KEYDIRS_OUT}
                if (${TEST} ${dname} = "/etc") then
                   ${LS} -alR /etc |${TEE} ${TAGS_OUT} >> ${KEYDIRS_OUT} 2>>${ERRFILE}
                else
                   ${LS} -al ${dname} |${TEE} ${TAGS_OUT} >> ${KEYDIRS_OUT} 2>>${ERRFILE}
                   ${ECHO} '' >> ${KEYDIRS_OUT}
                fi
                ${ECHO} "</KEYDIRS-${dname}>" >>${TAGS_OUT}
           }
     done
  else

     [ "${DEBUG}" != "0" ] && {
        ${ECHO} "DEBUG: Directories to be examined are:"
        ${ECHO} "DEBUG: /etc"
     } 

     print_separator outfile keydirs
     ${ECHO} "/etc:" >> ${KEYDIRS_OUT}
     ${LS} -alR /etc >> ${KEYDIRS_OUT} 2>>${ERRFILE}
     ${ECHO} '' >> ${KEYDIRS_OUT}
     ${ECHO} "</KEYDIRS>" >>${TAGS_OUT}
  fi

}
####################################################################
# function to do finds for setuid, setgid, and ww
####################################################################
do_finds () {

   case "$1" in
        
   'setuid') 
	FINDOUTFILE=${SETUID_OUT}	
        FINDOPTS=${FINDOPTSUID}
        ;;
   'setgid')   	
	FINDOUTFILE=${SETGID_OUT}	
        FINDOPTS=${FINDOPTSGID}
        ;;
   'ww') 	
	FINDOUTFILE=${WW_OUT}	
        FINDOPTS=${FINDOPTSWW}
        ;;
   *)   
        ${ECHO} "supply an argument of setuid, setgid or www."
        exit 1;
        ;;
   esac

   # touch output file
   ${TOUCH} ${FINDOUTFILE}
   if [ "x${FINDOPTS}" = "x" ]; then
	${ECHO} "Critical Error. FINDOPTS is not defined for this OS."
 	${ECHO} "Please define FINDOPTSUID, FINDOPTSGID, and FINDOPTSWW"
	${ECHO} "in ${OS_CONF} and re-run the script."
	exit 1;
   fi

   ${ECHO} "Looking for $1 files... (Please be patient)"
   ${ECHO} "<FIND_$1>" >> ${TAGS_OUT}
   print_separator stdout
   ${ECHO} "Looking for $1 files..." >> ${OUTFILE}
   print_separator outfile

   # if FSTAB is defined, then lets parse it and loop
   # through the filesystems, makes our file easier. 
   if [ "x${FSTAB}" != "x" ]; then
      [ "${DEBUG}" != "0" ] && {
         ${ECHO} "FSTAB is defined: ${FSTAB}"
      }

	  # unfortunately for us, a few OS put the mount
      # point someplace other than $2, notably solaris.

      case "${OS}" in

       'Solaris')
           for fs in `${AWK} '! /(nfs|proc|swap)/ && ! /^#/ {print $3}' ${FSTAB}`
           do
              [ "${DEBUG}" != "0" ] && {
                 ${ECHO} "DEBUG: Running find command on ${fs}"
                 ${ECHO} "DEBUG: ${FINDOPTS} \\;"
              }
              ${FIND} ${fs} ${FINDOPTS} \; |${TEE} ${TAGS_OUT} >>${FINDOUTFILE} 2>>${ERRFILE}
           done
           ;;

       'Sol10')
           for fs in `${AWK} '! /(nfs|proc|swap)/ && ! /^#/ {print $3}' ${FSTAB}`
           do
              [ "${DEBUG}" != "0" ] && {
                 ${ECHO} "DEBUG: Running find command on ${fs}"
                 ${ECHO} "DEBUG: ${FINDOPTS} \\;"
              }
              ${FIND} ${fs} ${FINDOPTS} \; |${TEE} ${TAGS_OUT} >>${FINDOUTFILE} 2>>${ERRFILE}
           done
           ;;

       'Sol9')
           for fs in `${AWK} '! /(nfs|proc|swap)/ && ! /^#/ {print $3}' ${FSTAB}`
           do
              [ "${DEBUG}" != "0" ] && {
                 ${ECHO} "DEBUG: Running find command on ${fs}"
                 ${ECHO} "DEBUG: ${FINDOPTS} \\;"
              }
              ${FIND} ${fs} ${FINDOPTS} \; |${TEE} ${TAGS_OUT} >>${FINDOUTFILE} 2>>${ERRFILE}
           done
           ;;

       *)
           for fs in `${AWK} '! /(nfs|proc|swap)/ && ! /^#/ {print $2}' ${FSTAB}`
           do
              [ "${DEBUG}" != "0" ] && {
                 ${ECHO} "DEBUG: Running find command on ${fs}"
                 ${ECHO} "DEBUG: ${FINDOPTS} \\;"
              }
              ${FIND} ${fs} ${FINDOPTS} \; |${TEE} ${TAGS_OUT} >>${FINDOUTFILE} 2>>${ERRFILE}
           done
           ;;
     esac

   else

      # fstab is not defined, for AIX/SCO_SV we parse output
      # of df -k command to find the filesystems to do our finds
      # on. Otherwise we just do a brute force find on /.

      [ "${DEBUG}" != "0" ] && {
         ${ECHO} "DEBUG: FSTAB is NOT DEFINED for this OS."
         ${ECHO} "DEBUG: FSTAB is NOT DEFINED for this OS." >>${OUTFILE}
      }

      case "${OS}" in

       'AIX')
           for fs in `${DF} -k |${AWK} '! /(nfs|proc|swap)/ {print $7}'|${GREP} -v Mounted`
           do
              [ "${DEBUG}" != "0" ] && {
                 ${ECHO} "DEBUG: Running find command on ${fs}"
                 ${ECHO} "DEBUG: ${FINDOPTS} \\;"
              }
              ${FIND} ${fs} ${FINDOPTS} \; |${TEE} ${TAGS_OUT} >>${FINDOUTFILE} 2>>${ERRFILE}
           done
           ;;

       'SCO_SV')
           for fs in `${DF} -k |${AWK} '! /(nfs|proc|swap)/ {print $1}'`
           do
              [ "${DEBUG}" != "0" ] && {
                 ${ECHO} "DEBUG: Running find command on ${fs}"
                 ${ECHO} "DEBUG: ${FINDOPTS} \\;"
              }
              ${FIND} ${fs} ${FINDOPTS} \; |${TEE} ${TAGS_OUT} >>${FINDOUTFILE} 2>>${ERRFILE}
           done
           ;;

       *)
           # run the brute force find
           [ "${DEBUG}" != "0" ] && {
              ${ECHO} "DEBUG: FSTAB is NOT DEFINED for this OS."
              ${ECHO} "DEBUG: Output file: ${FINDOUTFILE}"
              ${ECHO} "DEBUG: Running find command with these arguments:"
              ${ECHO} "DEBUG: ${FINDOPTS} \\;"
           }
           ${FIND} / ${FINDOPTS} \; |${TEE} ${TAGS_OUT} >>${FINDOUTFILE} 2>>${ERRFILE}
       esac
   fi
   ${ECHO} "</FIND_$1>" >> ${TAGS_OUT}
   # get number of setuid/setgid/ww files, send to logfile
   ${ECHO} "<FIND_$1_NUM>" >> ${TAGS_OUT}
   ${ECHO} "`${WC} -l ${FINDOUTFILE} | ${AWK} '{print $1}'` $1 files found."  |${TEE} ${TAGS_OUT} >> ${OUTFILE} 2>>${ERRFILE}
   ${ECHO} "</FIND_$1_NUM>" >> ${TAGS_OUT}
   ${ECHO} "Please see ${FINDOUTFILE} for detailed output." >> ${OUTFILE}
   print_separator outfile

   return;
}
###################################################################
# function to do listing of permissions on custom defined directories
# really only used for those special occasions.
# Dirs are defined in /etc/global.rc (Look for CUSTOM_DIRS"
# Also, you will need to turn this on with the -custom switch
###################################################################
do_custom_dir () {

  #Find permissions on a bunch of directories
  print_separator stdout
  ${ECHO} "Listing permissions on custom directories..."
  ${ECHO} "<CUSTOM_DIRS>" >> ${TAGS_OUT}
  print_separator stdout
  ${ECHO} "Listing permissions on custom directories..." >> ${OUTFILE}
  ${ECHO} "Please see ${CUSTDIRS_OUT} for detailed output." >> ${OUTFILE}
  ${ECHO} '' >> ${CUSTDIRS_OUT}


     [ "${DEBUG}" != "0" ] && {
        ${ECHO} "DEBUG: Directories to be examined are:"
        ${ECHO} "DEBUG: ${CUSTOM_DIRS}"
     }

     print_separator outfile custdirs
     ${LS} -alR ${CUSTOM_DIRS} |${TEE} ${TAGS_OUT} >> ${CUSTDIRS_OUT} 2>>${ERRFILE}
     ${ECHO} '' >> ${CUSTDIRS_OUT}
  ${ECHO} "</CUSTOM_DIRS>" >> ${TAGS_OUT}
}


###################################################################
# function to do OS specific stuff, called from main script
###################################################################
do_os_modules () {

# get all the MODULES
print_separator stdout
${ECHO} "Running OS-specific checks for ${OS}"
${ECHO} "<OS_MODULES>" >> ${TAGS_OUT}
print_separator stdout

# find number of modules
NUMMODS=`${LS} ${MODULES} |${GREP} -v CVS|${WC} -l`

print_separator outfile
${ECHO} "${NUMMODS} registered modules for ${OS}" >>${OUTFILE}
print_separator outfile
${ECHO} "Please see ${MODS_OUT} for detailed output." >>${OUTFILE}

if [ -d ${MODULES} ]; then
   if [ "${NUMMODS}" != "0" ]; then
      for mod in `${LS} ${MODULES} |${GREP} -v CVS`
      do
         print_flag_header outfile mods BEGIN ${mod}
         . ${MODULES}/${mod}
         print_flag_header outfile mods END ${mod}
      done 
   else
      ${ECHO} "No modules registered for this OS! Skipping OS-specific checks."
      ${ECHO} "No modules registered for this OS! Skipping OS-specific checks." >>${MODS_OUT}
   fi
else
      ${ECHO} "${MODULES} directory not found. Skipping OS-specific checks."
      ${ECHO} "${MODULES} directory not found. Skipping OS-specific checks." >>${MODS_OUT}
fi
${ECHO} "</OS_MODULES>" >> ${TAGS_OUT}
}
###################################################################
#
# main script
#
####################################################################

# location of conf directory
CONFDIR=etc
GLOBALCONF=${CONFDIR}/global.rc

# read global configuration file
if [ -f ${GLOBALCONF} ]; then
   . ${GLOBALCONF}
else
   echo "Cannot find global config file ${GLOBALCONF}. Quitting." 
   exit 1
fi

# first get the OS version and source the appropriate config file
check_os

# process command line arguments
while ${TEST} $# != 0
do
   case "$1" in

   -debug)         DEBUG=1 ;;
   -nodebug)       DEBUG=0 ;;
   -tar)           DO_TAR=1 ;;
   -notar)         DO_TAR=0 ;;
   -bind)          DO_BIND=1 ;;
   -conftar)       DO_CONFIGTAR=1 ;;
   -noconftar)     DO_CONFIGTAR=0 ;;
   -noshadow)      DO_GET_SHADOWFILE=0 ;;
   -users)         DO_SEARCH_USERS=1 ;;
   -nousers)       DO_SEARCH_USERS=0 
                   DO_NIS_SEARCH_USERS=0
                   DO_NISPLUS_SEARCH_USERS=0
                   ;;
   -nis)           DO_NIS=1 ;;
   -nisusers)      DO_NIS_SEARCH_USERS=1 ;;
   -nonis)         DO_NIS=0 
                   DO_NIS_SEARCH_USERS=0
                   ;;
   -nisplus)       DO_NISPLUS=1 ;;
   -nisplususers)  DO_NISPLUS_SEARCH_USERS=1 ;;
   -nonisplus)     DO_NISPLUS=0
                   DO_NISPLUS_SEARCH_USERS=0
                   ;;
   -finds)         DO_ALLFINDS=1 ;;
   -nofinds)       DO_ALLFINDS=0 ;;
   -keydirs)       DO_KEY_DIRS_LISTING=1 ;;
   -nokeydirs)     DO_KEY_DIRS_LISTING=0 ;;
   -osmods)        DO_OS_MODULES=1 ;;
   -noosmods)      DO_OS_MODULES=0 ;;
   -custom)	   DO_CUSTOM_DIRS=1 ;;
   -v|-version)    print_version ; exit 1 ;;
   -h|-help)       usage ; exit 1 ;; 
   *)              usage ; exit 1 ;;

   esac
   shift
done

# setup the output filenames
do_setup_output_files
# do file cleanup if script has been run before on this host
do_file_cleanup
# begin
do_intro

# moved uname check here from do_gen_checks because it is
# mandatory
do_uname

if [ "${DEBUG}" != "0" ]; then
 dump_global_opts
fi

################################
# This is the generic section for all OSes 
# More flags are tested in do_general_checks 
# and do_net_checks 
################################
if [ "${DO_GEN_CHECKS}" != "0" ]; then
   print_flag_header outfile main BEGIN DO_GEN_CHECKS
   do_general_checks
   print_flag_header outfile main END DO_GEN_CHECKS
elif [ "${DEBUG}" != "0" ]; then
     print_flag_header stdout SKIP DO_GEN_CHECKS
fi

# do user files check, can be time consuming if you have a lot
# of users, esp automounted ones 
if [ "${DO_SEARCH_USERS}" != "0" ]; then
   print_flag_header outfile main BEGIN DO_SEARCH_USERS
   print_flag_header outfile userfiles BEGIN DO_SEARCH_USERS
   do_users_files_check
   print_flag_header outfile userfiles END DO_SEARCH_USERS
   print_flag_header outfile main END DO_SEARCH_USERS
elif [ "${DEBUG}" != "0" ]; then
   print_flag_header stdout SKIP DO_SEARCH_USERS
fi

# listing on key dirs
if [ "${DO_KEY_DIRS_LISTING}" != "0" ]; then
   print_flag_header outfile main BEGIN DO_KEY_DIRS_LISTING
   print_flag_header outfile keydirs BEGIN DO_KEY_DIRS_LISTING
   do_key_dirs_listing
   print_flag_header outfile keydirs END DO_KEY_DIRS_LISTING
   print_flag_header outfile main END DO_KEY_DIRS_LISTING
elif [ "${DEBUG}" != "0" ]; then
   print_flag_header stdout SKIP DO_KEY_DIRS_LISTING
fi

# do net checks
if [ "${DO_NET_CHECKS}" != "0" ]; then
   print_flag_header outfile main BEGIN DO_NET_CHECKS
   do_net_checks
   print_flag_header outfile main END DO_NET_CHECKS
elif [ "${DEBUG}" != "0" ]; then
   print_flag_header stdout SKIP DO_NET_CHECKS
fi

# do nis check
if [ "${DO_NIS}" != "0" ]; then
   print_flag_header outfile main BEGIN DO_NIS
   do_nis_check
   print_flag_header outfile main END DO_NIS
elif [ "${DEBUG}" != "0" ]; then
   print_flag_header stdout SKIP DO_NIS
fi

# do nis+ check 
if [ "${DO_NISPLUS}" != "0" ]; then
   print_flag_header outfile main BEGIN DO_NISPLUS
   do_nisplus_check
   print_flag_header outfile main END DO_NISPLUS
elif [ "${DEBUG}" != "0" ]; then
   print_flag_header stdout SKIP DO_NISPLUS
fi

# do finds, check flags
if [ "${DO_ALLFINDS}" != "0" ]; then
  if [ "${DO_SETUID}" != "0" ]; then
     do_finds setuid   
  fi
  if [ "${DO_SETGID}" != "0" ]; then
     do_finds setgid
  fi
  if [ "${DO_WW}" != "0" ]; then
     do_finds ww
  fi
elif [ "${DEBUG}" != "0" ]; then
   print_flag_header stdout SKIP DO_ALLFINDS
fi

# do custom dirs listings - not for the faint of heart
if [ "${DO_CUSTOM_DIRS}" != "0" ]; then
   print_flag_header outfile main BEGIN DO_CUSTOM_DIRS_LISTING
   print_flag_header outfile custdirs BEGIN DO_CUSTOM_DIRS
   do_custom_dir
   print_flag_header outfile custdirs END DO_CUST_DIRS
   print_flag_header outfile main END DO_CUSTOM_DIRS
elif [ "${DEBUG}" != "0" ]; then
   print_flag_header stdout SKIP DO_CUSTOM_DIRS
fi

# do os-specific checks 
if [ "${DO_OS_MODULES}" != "0" ]; then
   print_flag_header outfile main BEGIN DO_OS_MODULES
   do_os_modules
   print_flag_header outfile main END DO_OS_MODULES
elif [ "${DEBUG}" != "0" ]; then
   print_flag_header stdout SKIP DO_OS_MODULES
fi

# secure output files, just in case UMASK permissions are insecure
do_chmod

# wrap up
do_outro

# tar up all output files if they want 
if [ "${DO_TAR}" != "0" ]; then
   do_tar
fi

