#!/bin/sh
#
# $Header: AgentInstall.sh 
#
# AgentInstall.sh
#
# Copyright (c) 2011, 2015, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      AgentInstall.sh - Downloads and Deploys lama/gateway agents on EMSaaS
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#   MODIFIED
#
#   03/14/2017  MEHMKHAN  EMCPALCM-2006: Enhance cURL TLS check.
#   11/17/2016  MEHMKHAN  EMCPALCM-1209: Remove swap.space file
#   12/09/2017  jsoule    EMCPALCM-1656: Pass passwords in expected order to AgentDeployment.sh.
#   11/15/2016  MEHMKHAN  EMCPALCM-1139: Support for APM mobile iOS and Android agents.
#   10/27/2016  jsoule    EMCAGNT-979: check for missing https support in curl
#   10/12/2016  MEHMKHAN  EMCPALCM-1424: Support for APM Ruby and PHP agents.
#   09/21/2016  MEHMKHAN  EMCPALCM-1372: Pre-Req check to validate if "host" is present.
#   08/24/2016  MEHMKHAN  EMCPALCM-1367: "host `hostname`" is used to fetch the fully qualified domain name. 
#   07/27/2016  MEHMKHAN  EMCPALCM-1290: Added version check for curl version to support TLS 1.2 - disabled by default
#
initialize()
{
#Paths
GATEWAY_HEADER="-H X-Gateway-MetaProtocolVersion:REVISION_1"
CURL_PATH=/usr/bin/curl
CURL_DEFAULT_ARGS="-s --insecure -w %{http_code} --retry 3 --retry-delay 5 --retry-max-time 30 $GATEWAY_HEADER"
CURL_ARGS=""
UNZIP_PATH=/usr/bin/unzip
UNZIP_ARGS=-o

#TemplateVariables
#TemplateVariables
cksum="1862595258"
alcEndPoint="https://a456007.itom.management.us2.oraclecloud.com/static/agentlifecycle"
apmCollectorRoot="https://a456007.itom2.management.us2.oraclecloud.com"
ohEndPoint="https://a456007.itom.management.us2.oraclecloud.com/registry"
#The OHS end point - https://host:port/
UploadRoot="https://a456007.itom.management.us2.oraclecloud.com/"
tenantId=a456007

#Constants
ABSENT="ABSENT"
certificateEndPoint="certificate"
lamaEndPoint="lama"
gatewayEndPoint="gateway"
apmEndPoint="apm"
apmDotNetType="apm_dotnet_agent"
apmNodeJsType="apm_nodejs_agent"
apmRubyType="apm_ruby_agent"
apmPhpType="apm_php_agent"
apmIOSType="apm_ios_agent"
apmAndroidType="apm_android_agent"
agentInstallShEndPoint="agentinstallscript"
AgentLifeCycleService="AgentLifeCycle"
PROTOCOL="https"
downloadFromEdge="false"
secureAgent=true
securityArtifact="securitytoken"
retryExitCode=5
ohEndPointIndex=`echo $ohEndPoint|grep OH_END_POINT|wc -l`
if [ $ohEndPointIndex -eq 1 ] 
then
	echo "Error: This script does not have a registry URL."
	exit 1
else
	serviceUrl=$ohEndPoint
fi
alcEndPointIndex=`echo $alcEndPoint|grep ALC_END_POINT|wc -l`
if [ $alcEndPointIndex -eq 1 ] 
then
	echo "Error: This script does not have the endpoint to the agent lifecycle."
	exit 1
fi

tenantIdIndex=`echo $tenantId|grep TENANT_ID|wc -l`
if [ $tenantIdIndex -eq 1 ] 
then
    tenantId=$ABSENT
fi

agentInstallScript=AgentInstall
agentInstallScriptWithExt=${agentInstallScript}.sh
timeStamp=`date +%m%d%y%H%M%S`
agentImageProperties="agentimage.properties"
emSaaSPropertiesFile="emaas.properties"
validationCode=0
TRUE="true"
stageCertLoc="stage/sysman/config/server"
sysAdminDir="sysman/admin/"
gatewayCert="$stageCertLoc/importCert"
gatewayKey="$stageCertLoc/importCertPrivateKey"
stageTrustedCerts="$stageCertLoc/trustedcerts"
trustCertEdge="$stageTrustedCerts/trustCertEdge"
trustCertGateway="$stageTrustedCerts/trustCertGateway"
apmCert="emcs.cer"
apmGatewayCertName="trustCertGateway.cer"
apmAuthToken="cwallet.sso"

#Inputs
agentType=$ABSENT;
agentBaseDir=$ABSENT;
agentRegistrationPassword=$ABSENT;
gatewayHost=$ABSENT;
gatewayPort=$ABSENT;
agentName=$ABSENT;
agentHome=$ABSENT;
harvesterUser=$ABSENT;
harvesterPswd=$ABSENT;
omrPswd=$ABSENT;
omrUser=$ABSENT;
omrHost=$ABSENT;
omrPort=$ABSENT;
omrSid=$ABSENT;
omrService=$ABSENT;
omrHostUser=$ABSENT;
omrHostUserPwd=$ABSENT;
omrHostUserKey=$ABSENT;
omrUserRole=$ABSENT;
omrStageDir=$ABSENT;
omrConnectString=$ABSENT;
additionalParameters=$ABSENT;
stageLocation=$ABSENT;
downloadOnly=$ABSENT;
checkForUpdates=$ABSENT;
ignorePrereqFlag=false;
ignoreHarvesterPrereqs=$ABSENT;
ignoreUlimitCheck=$ABSENT;
ignoreFQDNCheck=$ABSENT;
hostname=$ABSENT;
staged=$ABSENT;
agentPort=$ABSENT;
showhelp=$ABSENT;
agentInstDir=$ABSENT;
installFromStageLocation=$ABSENT;
namespace=$ABSENT;
stdInput=$ABSENT;
additionalGateways=$ABSENT;
agentProperties=$ABSENT;
responseFile=$ABSENT;

# derived values
gatewayRoot=$ABSENT
uploadRoots=$ABSENT
gatewayUrls=$ABSENT
}

executeCommand()
{
  cmd="$*"
  printCmd=`echo $cmd | sed 's/PASSWORD=\(.*\)\s/PASSWORD=\* /'`	
  printCmd=`echo $printCmd | sed 's/REGISTRATION_KEY=\(.*\)\s/REGISTRATION_KEY=\* /'`
  echo "Execution Command $printCmd" >>$LogFile 2>>$LogFile
  if [ "$stdInput" = "$ABSENT" ]
  then
  	$cmd >>$LogFile 2>>$LogFile
  else 
	 echo $ECHO_ARGS $stdInput|$cmd >>$LogFile 2>>$LogFile
  fi
   
  ret_status=$?
  if [ $ret_status -ne 0 ]
  then
	echo "Error: Execution of command $printCmd failed" |tee -a $LogFile
        echo "Check log file $LogFile for more information."
        exit 1
 else
	echo "Execution of command $printCmd succeeded" >>$LogFile
  fi
  stdInput=$ABSENT
}

createDir()
{
    dirName=$1
    mkdir -p $dirName
    ret_status=$?
    if [ $ret_status -ne 0 ]
    then
	 echo "Creation of directory $dirName failed. Ensure you have privileges to create this directory."
	 exit 1
    fi
}

isDirEmpty()
{
dirToCheck=$1
fileList=`ls -A $dirToCheck 2>>/dev/null|grep -v "ADATMP*" |grep -v logs|grep -v "lama.zip"|grep -v "gateway.zip"|grep -v "apm.zip"|grep -v "AgentInstall*"|tr '\n' ' '`
if [ "X" != "X$fileList" ]
then
     echo "Error: Directory $dirToCheck is not empty and has the following files [$fileList] in it. Ensure it is empty"
     exit 1
fi
}

isDirWritable()
{
file=$1
dirCreated=false
dirWritable=true
if [ ! -d $file ]
then
  createDir $file
  dirCreated=true
fi

if [ ! -w $file ] 
then 
	dirWritable=false
fi

if [ "$dirCreated" = "true" ]
then
	rmdir $file
fi
if [ "$dirWritable" = "false" ]
then
       echo "Error: $file is not writable. Ensure it is writable"
       exit 1
fi
}

isFileExecutable()
{
file=$1
if [ ! -x $file ] 
then 
       echo "Error: $file does not have execute permission. Ensure it has execute permission"
       exit 1
fi
}

isFilePresent()
{
file=$1
fileProp=$2
if [ ! -f $file ] 
then 
       echo "Error: $file [$fileProp] does not exist. Ensure it is present."
       exit 1
fi
}

#Adding space check for jira issue emcplcm-43
#Checking for 1 GB of free space basically for holding active and passive home
diskSpaceCheck()
{
if [ "$ignorePrereqFlag" = "false" ]
then
directoryToCheck=$1
        plat=`uname -s`
        if [ $plat = "HP-UX" ] 
        then
       		set `df -k $directoryToCheck|grep -i free|tr -s ' '|cut -d " " -f2` 1>>$LogFile 2>>$LogFile
        elif [ $plat = "AIX" ] ; then
        	set `df -k $directoryToCheck| tr -s ' '|tail -1|cut -d " " -f3` 1>>$LogFile 2>>$LogFile
        else
                set `df -k $directoryToCheck| tr -s ' '|tail -1|cut -d " " -f4` 1>>$LogFile 2>>$LogFile
        fi

        space=`echo $1 / 1024 | bc`
        echo "Space Available : $space" >>$LogFile 
        if [ $space -lt 1024 ] ; then
                echo  "Error: The $directoryToCheck Directory has less than 1 GB of space available. Ensure that the agent base directory has more than 1 GB of space." | tee -a $LogFile
                exit 1
        fi
        echo "Disk space check completed successfully" >>$LogFile
else
      echo "Skipping Diskspack check" >>$LogFile
fi
}

ulimitCheck()
{
if [ "$ignoreUlimitCheck" != "$ABSENT" ]; then
        echo "Ignoring Ulimit check" >>$LogFile
else
if [ ! "$ulimitValue" = "unlimited" ] ; then
if [ $ulimitValue -lt 4000 ] ; then
        echo  "ERROR: Ulimit value for max user processes $ulimitValue is less than expected value of 4000. We require an absolute minimum of 4000 for a successful deployment, but we recommend you to set the ulimit to 100000 for an uninterrupted service of the agent."
        exit 1
fi
fi
fi
}

usage()
{
echo $ECHO_ARGS "Usage:"
echo $ECHO_ARGS  "\tAgentInstall.sh"
echo $ECHO_ARGS  "\tAGENT_TYPE='Type of the agent to be installed or downloaded. The supported agent types are : cloud_agent, gateway, data_collector, apm_java_as_agent, apm_dotnet_agent and apm_nodejs_agent'"
echo $ECHO_ARGS  "\tAGENT_BASE_DIR='Agent installation directory'"
echo $ECHO_ARGS  "\tTENANT_ID='TenantID'"
echo $ECHO_ARGS  "\tAGENT_REGISTRATION_KEY='Agent registration key'"
echo $ECHO_ARGS  "\t[AGENT_PORT='Agent Port']"
echo $ECHO_ARGS  "\t[AGENT_INSTANCE_HOME='Agent instance directory']"
echo $ECHO_ARGS  "\t[GATEWAY_HOST='Gateway Host']"
echo $ECHO_ARGS  "\t[GATEWAY_PORT='Gateway Port']"
echo $ECHO_ARGS  "\t[EM_AGENT_NAME='Enterprise Manager Agent Name'|EM_AGENT_HOME='Enterprise Manager Agent Oracle Home']"
echo $ECHO_ARGS  "\t[OMR_HOSTNAME='Oracle Management Repository Host Name']"
echo $ECHO_ARGS  "\t[OMR_PORT='Oracle Management Repository Port']"
echo $ECHO_ARGS  "\t[OMR_USERNAME='Oracle Management Repository User Name']"
echo $ECHO_ARGS  "\t[OMR_USER_PASSWORD='Oracle Management Repository Password']"
echo $ECHO_ARGS  "\t[OMR_USER_ROLE='Oracle Management Repository User Role']"
echo $ECHO_ARGS  "\t[OMR_SID='Oracle Management Repository SID'|OMR_SERVICE_NAME='Oracle Management Repository Service Name']"
echo $ECHO_ARGS  "\t[OMR_CONNECT_STRING='Oracle Management Repository Connect String']"
echo $ECHO_ARGS  "\t[OMR_HOST_USERNAME='Oracle Management Repository (Install) User Name ']"
echo $ECHO_ARGS  "\t[OMR_HOST_USER_PASSWORD='Oracle Management Repository User Password'|OMR_HOST_USER_SSH_KEY='Oracle Management Repository install userprivate ssh key']"
echo $ECHO_ARGS  "\t[OMR_STAGE_DIR='Oracle Management Repository Staging Directory for data_collector to dump the data']"
echo $ECHO_ARGS  "\t[HARVESTER_USERNAME='Harvester User Name']"
echo $ECHO_ARGS  "\t[HARVESTER_USER_PASSWORD='Harvester User Password']"
echo $ECHO_ARGS  "\t[STAGE_LOCATION='Stage Location']"
echo $ECHO_ARGS  "\t[ADDITIONAL_PARAMETERS='Additional Parameters']"
echo $ECHO_ARGS  "\t[ADDITIONAL_GATEWAYS='Additional Gateways']"
echo $ECHO_ARGS  "\t[AGENT_PROPERTIES='Agent Properties']"
echo $ECHO_ARGS  "\t[CURL_PATH='Curl Path']"
echo $ECHO_ARGS  "\t[UNZIP_PATH='Unzip Path']"
echo $ECHO_ARGS  "\t[NAMESPACE='Namespace to uniquely identify the harvested targets in Oracle Data Store']"
echo $ECHO_ARGS  "\t[-download_only='Download only the agent software']"
echo $ECHO_ARGS  "\t[-secureAgent='Secures the agent and enables agent communication using HTTPS protocol']"
echo $ECHO_ARGS  "\t[-staged='Deploy the agent using the (staged) software.']"
echo $ECHO_ARGS  "\t[-ignoreHarvesterPrereqs='Ignore Oracle Management Repository's credential checks']"
echo $ECHO_ARGS  "\t[-ignoreUlimitCheck='Ignore ulimit check']"
echo $ECHO_ARGS  "\t[-ignoreFQDNCheck='Ignore FQDN check']"
echo $ECHO_ARGS  "\t[-help='Usage of the AgentInstall.sh script']\n"
echo $ECHO_ARGS  "Description:"
echo $ECHO_ARGS  "\tThis script is used to deploy Gateway, Harvester and Cloud agents\n"
echo $ECHO_ARGS  "Options:"
echo $ECHO_ARGS  "\tAGENT_TYPE"
echo $ECHO_ARGS  "\t\tType of agent to be installed or downloaded. The supported agent types are : cloud_agent, gateway, data_collector, apm_java_as_agent, apm_dotnet_agent and apm_nodejs_agent"
echo $ECHO_ARGS  "\tAGENT_BASE_DIR"
echo $ECHO_ARGS  "\t\tLocation where the agent must be installed."
echo $ECHO_ARGS  "\tTENANT_ID"
echo $ECHO_ARGS  "\t\tThe Tenant ID"
echo $ECHO_ARGS  "\tAGENT_REGISTRATION_KEY"
echo $ECHO_ARGS  "\t\tThe Agent Registration Key"
echo $ECHO_ARGS  "\tAGENT_PORT"
echo $ECHO_ARGS  "\t\tThe agent port"
echo $ECHO_ARGS  "\tAGENT_INSTANCE_HOME"
echo $ECHO_ARGS  "\t\tThe agent instance's home directory"
echo $ECHO_ARGS  "\tORACLE_HOSTNAME"
echo $ECHO_ARGS  "\t\tOverrides the target hostname on which agent gateway agent is deployed"
echo $ECHO_ARGS  "\tGATEWAY_HOST"
echo $ECHO_ARGS  "\t\tThe gateway host through which the cloud agent and data_collector communicate with Enterprise Manager Saas"
echo $ECHO_ARGS  "\tGATEWAY_PORT"
echo $ECHO_ARGS  "\t\tGateway port"
echo $ECHO_ARGS  "\tEM_AGENT_NAME"
echo $ECHO_ARGS  "\t\tThe name of the Enterprise Manager agent. The name format should be hostname:port."
echo $ECHO_ARGS  "\tEM_AGENT_HOME"
echo $ECHO_ARGS  "\t\tEnterprise Manager agent Oracle home."
echo $ECHO_ARGS  "\tOMR_HOSTNAME"
echo $ECHO_ARGS  "\t\tThe Oracle Management Repository host name."
echo $ECHO_ARGS  "\tOMR_PORT"
echo $ECHO_ARGS  "\t\tThe Oracle Management Repository port."
echo $ECHO_ARGS  "\tOMR_USERNAME"
echo $ECHO_ARGS  "\t\tThe Oracle Management Repository user name"
echo $ECHO_ARGS  "\tOMR_USER_PASSWORD"
echo $ECHO_ARGS  "\t\tThe Oracle Management Repository password"
echo $ECHO_ARGS  "\tHARVESTER_USERNAME"
echo $ECHO_ARGS  "\t\tThe Harvester username"
echo $ECHO_ARGS  "\tHARVESTER_USER_PASSWORD"
echo $ECHO_ARGS  "\t\tThe Harvester password"
echo $ECHO_ARGS  "\tNAMESPACE"
echo $ECHO_ARGS  "\t\tNamespace to uniquely identify the harvested targets in Oracle Data Store"
echo $ECHO_ARGS  "\tSTAGE_LOCATION"
echo $ECHO_ARGS  "\t\tThe location where the agent software must be staged"
echo $ECHO_ARGS  "\tADDITIONAL_PARAMETERS"
echo $ECHO_ARGS  "\t\tAdditional parameters"
echo $ECHO_ARGS  "\tADDITIONAL_GATEWAYS"
echo $ECHO_ARGS  "\t\tComma separated list of gateway URLs. A valid gateway URL is in this format: https://host:port"
echo $ECHO_ARGS  "\tAGENT_PROPERTIES"
echo $ECHO_ARGS  "\t\tComma separated list of agent properties. For example: property1:value1, property2:value2"
echo $ECHO_ARGS  "\tCURL_PATH"
echo $ECHO_ARGS  "\t\tThe location of the CURL binary files"
echo $ECHO_ARGS  "\tUNZIP_PATH"
echo $ECHO_ARGS  "\t\tThe location of the Unzip binary files"
echo $ECHO_ARGS  "\t-download_only"
echo $ECHO_ARGS  "\t\tDownloads and stages the software without installing it."
echo $ECHO_ARGS  "\t-staged"
echo $ECHO_ARGS  "\t\tUse the staged software for deploying the agent"
echo $ECHO_ARGS  "\t-help"
echo $ECHO_ARGS  "\t\tUsage of the AgentInstall.sh script\n"
echo $ECHO_ARGS  "Examples:"
echo $ECHO_ARGS  "\t/scratch/AgentInstall.sh AGENT_TYPE=gateway AGENT_BASE_DIR=/scratch/gateway_agent TENANT_ID=TestTenant1 AGENT_REGISTRATION_KEY=YlXrf2h0RNtVLZKeGf6q9mcDL AGENT_PORT=1830"
echo $ECHO_ARGS  "\t  Deploys a gateway agent using the specified inputs\n"
echo $ECHO_ARGS  "\t/scratch/AgentInstall.sh AGENT_TYPE=cloud_agent AGENT_BASE_DIR=/scratch/cloud_agent TENANT_ID=TestTenant1 GATEWAY_HOST=example.com GATEWAY_PORT=1831"
echo $ECHO_ARGS  "\tAGENT_REGISTRATION_KEY=YlXrf2h0RNtVLZKeGf6q9mcDL EM_AGENT_NAME=example1.com:3872 AGENT_PORT=1831"
echo $ECHO_ARGS  "\t  Deploys a cloud agent using the specified inputs\n"
echo $ECHO_ARGS  "\t/scratch/AgentInstall.sh AGENT_TYPE=data_collector AGENT_BASE_DIR=/scratch/data_collector_agent TENANT_ID=TestTenant1 GATEWAY_HOST=example.com GATEWAY_PORT=1830"
echo $ECHO_ARGS  "\tAGENT_REGISTRATION_KEY=YlXrf2h0RNtVLZKeGf6q9mcDL EM_AGENT_NAME=example1.com:3872 HARVESTER_USERNAME=EM_SAAS HARVESTER_USER_PASSWORD=welcome1 OMR_USER_PASSWORD=manager"
echo $ECHO_ARGS  "\tOMR_USERNAME=system OMR_HOSTNAME=example2.com OMR_PORT=1521 OMR_SID=orcl NAMESPACE=myOMR AGENT_PORT=1832"
echo $ECHO_ARGS  "\t  Deploys a data_collector agent using the specified inputs\n"
echo $ECHO_ARGS  "\t/scratch/AgentInstall.sh AGENT_TYPE=apm_java_as_agent STAGE_LOCATION=/scratch/apm_software -download_only AGENT_REGISTRATION_KEY=YlXrf2h0RNtVLZKeGf6q9mcDL"
echo $ECHO_ARGS  "\t  Downloads the APM Java agent installer\n"
echo $ECHO_ARGS  "\t/scratch/AgentInstall.sh AGENT_TYPE=apm_dotnet_agent STAGE_LOCATION=/scratch/apm_dotnet_software-download_only AGENT_REGISTRATION_KEY=YlXrf2h0RNtVLZKeGf6q9mcDL"
echo $ECHO_ARGS  "\t  Downloads the APM Dot Net agent installer\n"
echo $ECHO_ARGS  "\t/scratch/AgentInstall.sh AGENT_TYPE=apm_nodejs_agent STAGE_LOCATION=/scratch/apm_nodejs_software -download_only AGENT_REGISTRATION_KEY=YlXrf2h0RNtVLZKeGf6q9mcDL"
echo $ECHO_ARGS  "\t  Downloads the APM Node.js agent installer\n"
}

accessUrl()
{
url=$1
error=$2
echo $url >>$LogFile 2>>$LogFile

httpCode=`$CURL_PATH ${CURL_ARGS} ${CURL_DEFAULT_ARGS}  -H X-USER-IDENTITY-DOMAIN-NAME:$tenantId -H X-USER-REGISTRATION_KEY:$agentRegistrationPassword  -o /dev/null -i $url`

#curl on solaris and aix do not return non 200 status code.
if [ "$httpCode" = "" ]
then
        echo $error
        exit $retryExitCode
fi

if [ $httpCode -ne 200 ]
then
	echo $error
	exit $retryExitCode
fi
}

downloadFile()
{
    type=$1
    source=$2
    destinationFile=$3
    certHostName=$4
    #checkTrailing=`echo "${alcEndPoint: -1}"`
    checkTrailing=`echo "$alcEndPoint"|awk '{ for(i=length;i!=0;i--)x=x substr($0,i,1);}END{print x}'|cut -c1 |awk '{ for(i=length;i!=0;i--)x=x substr($0,i,1);}END{print x}'`
    curlOutputStream=""
    if [ "$checkTrailing" = "/" ]; then
       alcSwEndPoint=${alcEndPoint}softwaredispatcher/artifact
    else
       alcSwEndPoint=${alcEndPoint}/softwaredispatcher/artifact
    fi

    if [ "$destinationFile" = "" ]
    then
	destFileArg=""
    else
        destFileArg="-o $destinationFile"
    fi
    
    if [ "$certHostName" = "" ]
    then
	 hostnameParam=""
    else
	hostnameParam="&hostname=$certHostName"
    fi
    
    if [ "$platformId" = "" ]
    then
        platformIdParam=""
    else
        platformIdParam="&platformId=$platformId"
    fi
        curlCommand="$CURL_PATH ${CURL_ARGS} ${CURL_DEFAULT_ARGS}  -H X-USER-IDENTITY-DOMAIN-NAME:$tenantId -H X-USER-REGISTRATION_KEY:$agentRegistrationPassword $alcSwEndPoint?type=$type&name=$source$hostnameParam$platformIdParam $destFileArg"

    curlPrintCommand="$CURL_PATH ${CURL_ARGS} ${CURL_DEFAULT_ARGS} -H X-USER-IDENTITY-DOMAIN-NAME:$tenantId $alcSwEndPoint?type=$type&name=$source$hostnameParam$platformIdParam $destFileArg"   
    echo $curlPrintCommand >>$LogFile
    curlOutput=`$curlCommand`
    charCount=`echo $curlOutput|wc -c`
    c1=`expr $charCount - 3`
    c2=`expr $charCount - 4`
         
    httpCode=`echo $curlOutput|cut -c$c1-`
    if [ $c2 -gt 0 ]
	then
          curlOutputStream=`echo $curlOutput|cut -c-$c2`
    fi
 
    if [ $httpCode -ne 200 ] 
    then
        if [ -f "$destinationFile" ]
        then
        	cat $destinationFile
 		echo $ECHO_ARGS "\n"
        else
		echo "Unable to download artifact $source $curlOutputStream"
        fi
	exit 1
    fi
}

validateFile()
{
zipFileToValidate=$1
$UNZIP_PATH -l $zipFileToValidate >>$LogFile 2>>$LogFile
status=$?
if [ $status -ne 0 ] 
then
 cat $zipFileToValidate
 echo $ECHO_ARGS "\n"
 rm $zipFileToValidate
 exit 1
fi
}

# Generate emaas.properties
generateSaaSProperties()
{
tId=$1
fileToGenerate=$workDir/$emSaaSPropertiesFile
echo "tenantID=$tId" >$fileToGenerate
if [ "$agentType" = "gateway" -o "$gatewayHost" = "$ABSENT" ]
then
	echo "serviceUrls=$serviceUrl" >>$fileToGenerate
fi
if [ "$gatewayHost" = "$ABSENT" ]
then # the agent is not uploading through a gateway, so set the UploadRoot
  echo "UploadRoot=$UploadRoot" >>$fileToGenerate
fi
}

generateAPMProperties()
{
fileToGenerate=$1
echo "Tenant_ID=$tenantId" >$fileToGenerate
echo "UploadRoot=$uploadRoots" >>$fileToGenerate
echo "ApmCollectorRoot=$apmCollectorRoot" >>$fileToGenerate
echo "RegistryService_URL=$serviceUrl" >>$fileToGenerate
echo "AgentAuthToken=$authToken" >>$fileToGenerate
echo "RegistrationKey=$encrAgentRegistrationPassword" >>$fileToGenerate
}

generateAPMDotNetProperties()
{
fileToGenerate=$1
echo [OMC]>$fileToGenerate
echo oracle.apmaas.agent.registryServiceUrl=$serviceUrl>>$fileToGenerate
echo oracle.apmaas.agent.tenant=$tenantId>>$fileToGenerate
echo oracle.apmaas.agent.uploadRoot=$uploadRoots>>$fileToGenerate
echo oracle.apmaas.agent.collectorRoot=$apmCollectorRoot>>$fileToGenerate
echo oracle.apmaas.agent.registrationKey=$encrAgentRegistrationPassword>>$fileToGenerate
echo oracle.apmaas.agent.omcAuthToken=$authToken>>$fileToGenerate
echo # the following are optional - only if proxy will be required by agent>>!fileToGenerate!
echo oracle.apmaas.agent.proxyHost=>>$fileToGenerate
echo oracle.apmaas.agent.proxyPort=>>$fileToGenerate
echo oracle.apmaas.agent.proxyAuthUser=>>$fileToGenerate
echo oracle.apmaas.agent.proxyAuthPassword=>>$fileToGenerate
echo oracle.apmaas.agent.proxyAuthDomain=>>$fileToGenerate
}

generateAPMNodeJsProperties()
{
fileToGenerate=$1
cat <<EOF >$fileToGenerate
{
  "registryServiceUrl":"$serviceUrl",
  "tenant": "$tenantId",
  "uploadRoot":"$uploadRoots",
  "collectorRoot":"$apmCollectorRoot",
  "registrationKey": "$encrAgentRegistrationPassword",
  "pathToCertificate":"${workDir}/${apmCert}",
  "auth":"$authToken",
  "MCAccessRateSeconds": "60",
  "MEIDCheckRateSeconds": "60"
}
EOF
}

generateAPMRubyProperties()
{
  fileToGenerate=$1
  echo "registry_service_url: $serviceUrl" > $fileToGenerate
  echo "tenant: $tenantId" >> $fileToGenerate
  echo "uploadRoot: $uploadRoots" >> $fileToGenerate
  echo "collectorRoot: $apmCollectorRoot" >> $fileToGenerate
  echo "registration_key: $encrAgentRegistrationPassword" >> $fileToGenerate
  echo "omc_auth_token: $authToken" >> $fileToGenerate
  echo "# the following are optional - only if proxy will be required by agent" >> $fileToGenerate
  echo "proxy_host:" >> $fileToGenerate
  echo "proxy_port:" >> $fileToGenerate
  echo "proxy_auth_user:" >> $fileToGenerate
  echo "proxy_auth_password:" >> $fileToGenerate
}

generateAPMPhpProperties()
{
  fileToGenerate=$1
  echo "Tenant_ID=$tenantId" > $fileToGenerate
  echo "UploadRoot=$uploadRoots" >>$fileToGenerate
  echo "ApmCollectorRoot=$apmCollectorRoot" >>$fileToGenerate
  echo "RegistryService_URL=$serviceUrl" >> $fileToGenerate
  echo "AgentAuthToken=$authToken" >> $fileToGenerate
  echo "RegistrationKey=$encrAgentRegistrationPassword" >> $fileToGenerate
  echo "# the following are optional - only if proxy will be required by agent" >> $fileToGenerate
  echo "proxy_host:" >> $fileToGenerate
  echo "proxy_port:" >> $fileToGenerate
  echo "proxy_auth_user:" >> $fileToGenerate
  echo "proxy_auth_password:" >> $fileToGenerate
}

generateAPMMobileProperties()
{
  fileToGenerate=$1
  echo "Tenant_ID=$tenantId" > $fileToGenerate
  echo "ApmClientCollector_URL=$apmCollectorRoot" >> $fileToGenerate
  echo "MobileApp_ID=" >> $fileToGenerate
  echo "MobileAgentMEID=" >> $fileToGenerate
}

checkFQDNValidity()
{
  parameterName=$1
  parameterValue=$2
  if [ "$parameterValue" != "" ]
  then
    echo "Resolving hostname $parameterValue" >>$LogFile
    #this method will compute the name in calculated_hostname variable
    calcHostName $unameOutput $parameterValue
    echo "checkFQDNValidity resolved the hostname to ($calculated_hostname)" >>$LogFile
    if [ "$calculated_hostname" = "" ]
    then
      echo "Error: Unable to resolve the $parameterName:$parameterValue."
      exit 1
    fi
  fi
}

checkFQDN()
{
parameterName=$1
parameterValue=$2
if [ "$parameterValue" != "" ]
then
     shortName=`echo $parameterValue|cut -d '.' -f1`
     if [ "$shortName" = "$parameterValue" ]
     then
        echo "Error: The $parameterName:$parameterValue is not in the Fully Qualified Domain Name format"
        exit 1
     fi
fi
}

checkMandatoryParameter()
{
parameterName=$1
parameterValue=$2
isPassword=$3
variableName=$4

if [ "$parameterValue" = "$ABSENT" ]
then
    if [ "X$isPassword" = "X" ]
    then
	    echo "Error: Mandatory argument $parameterName missing in command line"
	    validationCode=1
    else
		echo "Enter $parameterName:"
                stty -echo
                read $READ_ARGS stdInValue
                stty echo      	
                eval ${variableName}="${stdInValue}";
                if [ "X$stdInValue" = "X" ]
                then
		    echo "Error: Mandatory argument $parameterName missing in command line and stdin"
	   	    validationCode=1
               fi
    fi
fi
}


checkMandatoryTwoParameters()
{
parameter1Name=$1
parameter1Value=$2
parameter2Name=$3
parameter2Value=$4

if [ "$parameter1Value" = "$ABSENT" -a "$parameter2Value" = "ABSENT" ] ; then
   echo "Error: You have to specify either $parameter1Name or $parameter2Name."
   validationCode=1
fi

if [ "$parameter1Value" != "$ABSENT" -a "$parameter2Value" != "ABSENT" ] ; then
   echo "Error: You can specify either $parameter1Name or $parameter2Name, but not both."
   validationCode=1
fi
}

checkMandatoryHarvesterParams()
{
checkMandatoryParameter "HARVESTER_USERNAME" $harvesterUser
checkMandatoryParameter "OMR_STAGE_DIR" $omrStageDir
checkMandatoryParameter "OMR_HOST_USERNAME" $omrHostUser
checkMandatoryParameter "OMR_USERNAME" $omrUser

if [ "$omrHostUser" != "$ABSENT" -a "$omrHostUserKey" = "$ABSENT" ] ; then
        checkMandatoryParameter "OMR_HOST_USER_PASSWORD" $omrHostUserPwd "$TRUE" "omrHostUserPwd"
fi

if [ "$omrHostUserPwd" != "" ] ; then
        checkMandatoryTwoParameters "OMR_HOST_USER_PASSWORD" $omrHostUserPwd "OMR_HOST_USER_SSH_KEY" $omrHostUserKey
fi


if [ "$omrHost" = "$ABSENT" -a "$omrPort" = "$ABSENT" -a "$omrSid" = "$ABSENT" -a "$omrService" = "$ABSENT" ] ; then
	checkMandatoryParameter "OMR_CONNECT_STRING" $omrConnectString
else
	checkMandatoryParameter "OMR_HOSTNAME" $omrHost
	checkMandatoryParameter "OMR_PORT" $omrPort
	checkMandatoryTwoParameters "OMR_SID" $omrSid "OMR_SERVICE_NAME" $omrService
fi
}

validateDownloadOnlyParams()
{
     checkMandatoryParameter "STAGE_LOCATION" $stageLocation
     logDir=$stageLocation
     workDir=$stageLocation
     LogFile=$logDir/${agentInstallScript}_${timeStamp}.log

     #if [ "$downloadFromEdge" = "false" -a $agentType != "gateway" ]  
     #then	     
	     #checkMandatoryParameter "GATEWAY_HOST" $gatewayHost
	     #checkMandatoryParameter "GATEWAY_PORT" $gatewayPort
     #fi

     if [ $validationCode -ne 0 ]
     then
           exit 1
     else
        checkMandatoryParameter "AGENT_REGISTRATION_KEY" $agentRegistrationPassword $TRUE "agentRegistrationPassword"
        if [ $validationCode -ne 0 ]
        then
           exit 1
        fi
     fi 

     isDirWritable $stageLocation
     isDirEmpty $stageLocation
}

getEmdNameFromEmAgentHome()
{
propertyName=EMD_URL

if [ ! -f $agentHome/bin/emctl ]
then
    echo "Error: $agentHome is not a valid EM Agent Home."
    exit 1
fi

#If omcli doesn't exist, use emctl
if [ ! -f $agentHome/bin/omcli ]
then
	command="$agentHome/bin/emctl getproperty agent -name $propertyName"
else
	command="$agentHome/bin/omcli getproperty agent -name $propertyName"
fi

outStream=`$command`
if [ $? -gt 0 ]
then
    echo "Error: Unable to retrieve the EMD_URL from the EM_AGENT_HOME $agentHome"
    exit 1
fi

echo $outStream >>$LogFile
if [ "$outStream" = "" ]
then
    echo "Error: Unable to retrieve the EMD_URL from the EM_AGENT_HOME $agentHome"
    exit 1
fi

for NAME in `echo "$outStream"`
do
        propertyFound=`echo $NAME|grep $propertyName=|wc -l`
        if [ $propertyFound -gt 0 ]
        then
              agentName=`echo $NAME|cut -d= -f2|sed 's|\/\/|\/|g'|cut -f2 -d /`
	      echo "Agent Name derived from agentHome $agentHome is :$agentName" >>$LogFile
              break
        fi
done
if [ "$agentName" = "" ]
then
    echo "Error: Unable retrieve the EMD_URL from the EM_AGENT_HOME $agentHome"
   exit 1
fi
}

computeAndValidateHostNames()
{
  echo "Host name $hostname" >>$LogFile
  echo "Oracle Host name $oraclehostname" >>$LogFile
  if [ "$oraclehostname" != "" ]
  then
    if [ "$ignorePrereqFlag" = "false" ]
    then
      checkFQDN "ORACLE_HOSTNAME" $oraclehostname
      checkFQDNValidity "ORACLE_HOSTNAME" $oraclehostname
    fi
    hostname=$oraclehostname
    echo "Resolved ORACLE_HOSTNAME=$hostname" >>$LogFile
  else
    if [ "$hostname" = "" ]
    then
      echo "Error : Unable to determine the Fully Qualified Domain Name of this host."
      exit 
    fi
    if [ "$ignorePrereqFlag" = "false" ]
    then
      checkFQDN "computed hostname " $hostname
      checkFQDNValidity "computed hostname " $hostname
    fi
  fi
}

validateDownloadAndInstallParams()
{
     if [ "$staged" != "$ABSENT" ] 
     then
	     installFromStageLocation="true"
     fi

     checkMandatoryParameter "AGENT_BASE_DIR" $agentBaseDir
     logDir=$agentBaseDir/logs
     LogFile=$logDir/${agentInstallScript}_${timeStamp}.log
     workDir=$agentBaseDir/ADATMP_$timeStamp
     configCommand="$workDir/AgentDeployment.sh -configOnly TENANT_ID=$tenantId"

     if [  "$agentType" != "gateway" ]
     then
	        #checkMandatoryParameter "GATEWAY_HOST" $gatewayHost
		if [ "$ignorePrereqFlag" = "false" -a "$gatewayHost" != "$ABSENT" ] ; then
		checkFQDN "GATEWAY_HOST" $gatewayHost
		fi
                #checkMandatoryParameter "GATEWAY_PORT" $gatewayPort
		#checkMandatoryTwoParameters "EM_AGENT_NAME" $agentName "EM_AGENT_HOME" $agentHome
		if [ "$gatewayHost" != "$ABSENT" -a "$gatewayPort" != "$ABSENT" ] ; then
     		configCommand="$configCommand GATEWAY_HOST=$gatewayHost GATEWAY_PORT=$gatewayPort"
		fi
			
       		if [ "$agentHome" != "$ABSENT" ]; then
                    echo "Validating EM_AGENT_HOME $agentHome" >> $LogFile
		    getEmdNameFromEmAgentHome
                fi
                
                if [ "$agentName" != "$ABSENT" ]; then
	            configCommand="$configCommand  AGENT_NAME=$agentName"
                fi

     		if [ "$agentType" = "harvester" ] ; then
			checkMandatoryHarvesterParams 
               	        configCommand="$configCommand AGENT_TYPE=harvester HARVESTER_USERNAME=$harvesterUser OMR_USERNAME=$omrUser"
			if [ "$omrConnectString" = "$ABSENT" ] ; then
				configCommand="$configCommand OMR_HOSTNAME=$omrHost OMR_PORT=$omrPort"
			else
				configCommand="$configCommand OMR_CONNECT_STRING=\"$omrConnectString\""
			fi
 
			if [ "$omrService" = "$ABSENT" ] ; then	
				configCommand="$configCommand OMR_SID=$omrSid"
			else
				configCommand="$configCommand OMR_SERVICE_NAME=$omrService"	
			fi

			if [ "$omrUserRole" != "$ABSENT" ] ; then
				configCommand="$configCommand OMR_USER_ROLE=$omrUserRole"
			fi	
	
			if [ "$omrHostUser" != "$ABSENT" ] ; then
				configCommand="$configCommand OMR_HOST_USERNAME=$omrHostUser OMR_STAGE_DIR=$omrStageDir"
				if [ ! "$omrHostUserPwd" = "$ABSENT" ] ; then
					omrHostPswd=$omrHostUserPwd
				fi
			fi
				
			if [ "$omrHostUserKey" != "$ABSENT" ] ; then
                                configCommand="$configCommand OMR_HOST_USER_SSH_KEY=$omrHostUserKey"
                        fi
	
			#Fix for jira issue emaas-2465
			if [ "$namespace" != "$ABSENT" ]; then
				configCommand="$configCommand NAMESPACE=$namespace"
			fi

  			if [ $validationCode -ne 0 ]
		        then
			        exit 1
   		        else
       			 	checkMandatoryParameter "HARVESTER_USER_PASSWORD" $harvesterPswd $TRUE "harvesterPswd"
		        	checkMandatoryParameter "OMR_USER_PASSWORD" $omrPswd $TRUE "omrPswd"
               		 fi
		else 
         		 configCommand="$configCommand AGENT_TYPE=lama"
		fi
      else
		configCommand="$configCommand AGENT_TYPE=gateway"
    fi

  if [ $validationCode -ne 0 ]
  then
        exit 1
  else
        checkMandatoryParameter "AGENT_REGISTRATION_KEY" $agentRegistrationPassword $TRUE "agentRegistrationPassword"
        if [ $validationCode -ne 0 ]
        then
           exit 1
        fi
  fi
  if [ "$platformId" = "23" ]
  then
      if [ "$ignorePrereqFlag" = "false" ]
      then
          isDirWritable "/var/tmp"
      fi
  fi
  isDirWritable $agentBaseDir
  isDirEmpty $agentBaseDir
  isFilePresent $UNZIP_PATH UNZIP_PATH

  if [ "$agentInstDir" != "$ABSENT" ]
  then	
  	if [ "$agentInstDir" = "$agentBaseDir" ]
        then	
		  echo "Error: The location for the AGENT_BASE_DIR and the AGENT_INSTANCE_HOME cannot be the same directory."
		  exit 1
        fi
  	isDirWritable $agentInstDir
        isDirEmpty $agentInstDir
  fi
}

#
# This function downloads necessary certificates for additional gateways
# and sets the derived variables
# $gatewayUrls (cloud agent->gateway only)
# $uploadRoots (APM agents only)
# It does not modify any properties files.
#
generateAdditionalGatewaysProps()
{
  gateways=$gatewayRoot
  echo "Downloading additional Gateway certificates..."
  for url in `echo "$additionalGateways"|sed 's/,/ /g'`
        do
          addGatewayHostname=`echo "$url"|cut -f2 -d:|sed 's/\///g'`
          # APM Agents needed the cert names to end with extn .cer, cloud agents don't care
          if [ "$apmType" = "true" ]; then
            certPath="${workDir}/trustCert_${addGatewayHostname}.cer"
          else
            certPath="$agentBaseDir/$core_version/${stageTrustedCerts}/trustCert_${addGatewayHostname}"
          fi
          # TODO:downloadFile using THIS gateway
          downloadFile "$securityArtifact" "agentCert" $certPath $addGatewayHostname
          # TODO:add only on success
          gateways="$gateways,$url"
        done
  if [ "$apmType" = "true" ]; then
    uploadRoots=$gateways
  else
    gatewayUrls=$gateways
  fi
}

generateAgentProperties()
{
        if [ -f $agentProperties ]
        then
              echo "$agentProperties  file exists"  >>$LogFile
              cat $agentProperties >>$agentPropertiesFile
        else
           for line in `echo "$agentProperties"|sed 's/,/ /g'`
           do
   	       echo "$line"|sed 's/:/=/1' >>$agentPropertiesFile
           done
        fi
}

removeFileOrDir()
{
	fileToRemove=$1
	rm -rf $fileToRemove
}

validateGatewayAndLCMUrl() 
{
  alcEndPoint="${gatewayRoot}/emd/gateway/AgentLifeCycle"
  gatewayUrl="${gatewayRoot}/emd/main"

         if [ "$ignorePrereqFlag" = "false" ] 
         then	
         accessUrl "$gatewayUrl" "Error : Unable to connect to the gateway url $gatewayUrl. Ensure the value of GATEWAY_HOST($gatewayHost),GATEWAY_PORT($gatewayPort) are correct and the gateway is up and running."

         accessUrl "$alcEndPoint/softwaredispatcher/testSvc" "Error : Unable to connect to Agent LCM service through GATEWAY_HOST($gatewayHost),GATEWAY_PORT($gatewayPort).Ensure the Agent Life Cycle service is running."
         fi
}

validateBrownFieldTargets()
{
         if [ "$ignorePrereqFlag" = "false" ] 
         then	
             if [ "$agentName" != "$ABSENT" ]; then
                      emAgentHostName=`echo $agentName|cut -f1 -d :`
                      hostip=`host $hostname|awk '{ for(i=length;i!=0;i--)x=x substr($0,i,1);}END{print x}'|cut -f1 -d ' '|cut -f1 |awk '{ for(i=length;i!=0;i--)x=x substr($0,i,1);}END{print x}'`
                      hostIndex=`echo $hostname|grep $emAgentHostName|wc -l`
                      hostIpIndex=`echo $hostip|grep $emAgentHostName|wc -l`
                       if [ $hostIndex -eq 0 -a $hostIpIndex -eq 0 ]
                       then
                           echo "Error: The EM_AGENT_NAME $agentName does not match the hostname[$hostname]/IP address[$hostip] on which this agent is being be deployed."
                           exit 1
                       fi
              accessUrl "$alcEndPoint/softwaredispatcher/validateRegKey" "Error: The registration key validation failed. Ensure the registration key is valid."
# sdhamdhe 7/21/2016 Following checks are getting disabled for EMCPALCM-1347 - FOR NOW. I will find out what new types are & if changes are needed in a-lcm svc. 
# Brownfield target type data is not returned by ODS any longer - so these calls will return error all the time
# LA & other consumers now rely on Agent to Host assoc done after install - so we do no need these checks
              #accessUrl "$alcEndPoint/softwaredispatcher/validateEmAgentTarget?emAgentName=$agentName" "Error : Agent target(oracle_emd) $agentName does not exist in Oracle Management Cloud."
              #accessUrl "$alcEndPoint/softwaredispatcher/validateHostTarget?hostname=$emAgentHostName" "Error : Host target $emAgentHostName does not exist in Oracle Management Cloud."
              #accessUrl "$alcEndPoint/softwaredispatcher/validateMonitoredByAssoc?emAgentName=$agentName&hostname=$emAgentHostName" "Error : There is no monitored_by association between the host target $emAgentHostName and agent target(oracle_emd) $agentName"
              #accessUrl "$alcEndPoint/softwaredispatcher/validate?emAgentName=$agentName&agentType=$agentType" "Error : EM Agent $agentName is already associated with a cloud agent."
             fi
         fi
}

getArgs()
{
        args=`echo $1|grep "="|wc -l`
        if [ $args -gt 0 ] ; then
        name=`echo $1| cut -d '=' -f 1`
        value=`echo $1|cut -d '=' -f 2-`
        if [ "X$value" = "X" ]
          then
              echo "Error: Value not specified for argument $name"
              exit 1
        fi
          value=`echo $value|sed s/\"//g`

        else
        name=$1;
        fi
}

processResponseFile()
{
responseArgs=""
while read responseLine
do
responseNvp=`echo $responseLine|grep -v "^#"`
responseArgs="$responseArgs $responseNvp"
done <$responseFile
shellargs="$responseArgs $shellargs"
}

# param uname_type : output of uname
# param hostname_resolve : hostname to resolve
# returns: calculated_hostname variable
calcHostName()
{
  uname_type=$1
  hostname_resolve=$2

  if [ "$uname_type" = "" ]; then
    echo "os type not available to calculate hostname";
    exit 1;
  fi

  if [ "$hostname_resolve" = "" ]; then
    echo "no hostname provided";
    exit 1;
  fi

  resolver_cmd=""
  if [ "$uname_type" = "AIX" ]; then
         resolver_cmd="/usr/bin/host"
         isFilePresent $resolver_cmd "host command"
         # EMCPALCM-1367, EMCAGNT-958: Changed the way hostname is evaluated. Combination of domainname and hostname 
         # are not valid methodology across platform to evaluate FQDN, hence, using this approach.
         calculated_hostname=`$resolver_cmd $hostname_resolve | awk '{print $1}'`

  elif [ "$uname_type" = "Linux" -o "$uname_type" = "SunOS" ]; then
         resolver_cmd="/usr/bin/getent"
         isFilePresent $resolver_cmd "getent command"
         # EMCPALCM-1367, EMCAGNT-958: Changed the way hostname is evaluated. Combination of domainname and hostname 
         # are not valid methodology across platform to evaluate FQDN, hence, using this approach.
         calculated_hostname=`$resolver_cmd hosts $hostname_resolve | head -1 | awk '{print $2}'`

  else
         calculated_hostname="";
         echo "Cannot resolve hostname: unexpected OS: $uname_type";
         exit 1;
  fi
}

processPlatform()
{
unameOutput=`uname`

if [ "$unameOutput" = "" ]
then
     echo "Error : uname execution failed. Unable to detect the platform"
     exit 1
fi

case $unameOutput in
        AIX)platformName=$unameOutput
             platformId=212
             ulimitValue=`ulimit -u`
             ECHO_ARGS=""
             READ_ARGS=""
             GREP_RE_ARGS="-e"
             ;;
       Linux)platformName=$unameOutput
             platformId=226
             ulimitValue=`/bin/sh -c "ulimit -u"`
             ECHO_ARGS="-e"
             READ_ARGS="-t 60"
             GREP_RE_ARGS="-e"
             ;;
       SunOS)platformName=$unameOutput
             platformId=23
             ulimitValue=`/bin/sh -c "/usr/sbin/sysdef | grep v_maxup|tr -s ' '"|awk '{print $1}'`
             #TODO reserve 500 MB for Solaris
             ECHO_ARGS=""
             READ_ARGS=""
             GREP_RE_ARGS=""
             ;;
        *) echo "Error : Deployment of cloud agent is not supported on this platform: $unameOutput. Supported platforms are Linux, AIX and Solaris" 
             exit 1;
             ;;
esac

  hostname_sys=`hostname`;
  #This method will return the hostname in calculated_hostname
  calcHostName $unameOutput $hostname_sys;
  hostname=$calculated_hostname;
}

# EMCAGNT-979
validateCurlHttps()
{
  # best effort check for missing https support in cURL
  https="true"
  sslFeature=`${CURL_PATH} --version | grep ${GREP_RE_ARGS} '^Features:.*SSL.*'`
  if [ $? -ne 0 ] ; then
    https="false"
  else
    httpsProtocol=`${CURL_PATH} --version | grep ${GREP_RE_ARGS} '^Protocols:.*https.*'`
    if [ $? -ne 0 ] ; then
      https="false"
    fi
  fi
  if [ "$https" = "false" ] ; then
    echo "**WARNING** curl may be missing full https support"
  fi
}

# Fix for EMCPALCM-1290
validateCurlVersion()
{ 
  reqVer=
  case `uname` in
    AIX)    reqVer='7.47.1'
            AWK=/usr/bin/awk;;
    Linux)  reqVer='7.49.1'
            AWK=/bin/awk;;
    SunOS)  reqVer='7.49.1'
            AWK=/usr/xpg4/bin/awk;;
    *)      echo "Error : Deployment of cloud agent is not supported on this platform: $unameOutput. Supported platforms are Linux, AIX and Solaris" 
            exit 1;
            ;;
  esac
  currVer=`${CURL_PATH} --version | grep curl | grep -v '^#' | cut -d " " -f2`
  
  if [ "$reqVer" = "$currVer" ] ; then
    echo "The current cURL version '${currVer}' matches the required cURL version '${reqVer}'."
    return
  fi
  
  ret=`echo "${currVer}" | ${AWK} -v rVer="${reqVer}" '
    {
      cCount = split($0, cArr, ".");
      rCount = split(rVer, rArr, ".");
      
      if ( cCount < rCount )
        {
          count = cCount;
          while ( count < rCount)
            {
              cArr[++count] = 0;
            }
        }
      else if ( rCount < cCount )
        {
          count = rCount;
          while ( count < cCount )
            {
              rArr[++count] = 0;
            }
        }
      
      for ( idx = 1; idx <= rCount; idx++ )
        {
          if ( cArr[idx] < rArr[idx] )
          {
            print "-1";
            exit;
          }
          if ( cArr[idx] > rArr[idx] )
          {
            print "1";
            exit;
          }
        }
      print "1";
    }'`
  
  if [ ${ret} -eq "-1" ]; then
    echo "WARNING: The current cURL version ${currVer} does not support TLS1.2 protocol; the downloader script will attempt to continue but may not work. Please install ${reqVer} or later versions of cURL for error-free execution."
    return;
  else
    echo "The current cURL version ${currVer} is greater than the required cURL version ${reqVer}. Proceed further."
    return;
  fi
}

# EMCPALCM-2006
testTlsConnectivity()
{
  testUrl=${1}
  curlArgs=${2}
  
  printCurlCmd="${CURL_PATH} ${curlArgs} -H X-USER-IDENTITY-DOMAIN-NAME:$tenantId -H X-USER-REGISTRATION_KEY:XXXXXX -o /dev/null -i ${testUrl}"
  echo ${printCurlCmd} >> ${LogFile}
  curlCmd="${CURL_PATH} ${curlArgs} -H X-USER-IDENTITY-DOMAIN-NAME:$tenantId -H X-USER-REGISTRATION_KEY:$agentRegistrationPassword -o /dev/null -i ${testUrl}"
  $curlCmd > ${httpOut} 2>> ${LogFile}
  statusCode=$?
  httpCode=`cat ${httpOut}`
  echo "HTTP Response code is '${httpCode}' and status code is '${statusCode}'" >> ${LogFile}
  
  if [ $statusCode = 2 ]; then
    echo "Execution of cURL command failed with status code '${statusCode}'" >> ${LogFile}
    statusError=true
    return
  fi
  
  if [ "$httpCode" = "" ]; then
    echo "${connectTo} connection failed" >> ${LogFile}
    accessError=true
    return
  fi

  if [ $httpCode -ne 200 ]; then
    echo "${connectTo} connection failed" >> ${LogFile}
    accessError=true
    return
  fi

  if [ $statusCode != 0 ]; then
    echo "Execution of cURL command failed with status code '${statusCode}'" >> ${LogFile}
    statusError=true
    return
  fi
}

processTlsConnectivity()
{
  tlsVersion=$1
  
  if [ "${gatewayRoot}" != "$ABSENT" ]; then
    connectTo="Gateway"
    echo "Try connection to ${connectTo}." >> ${LogFile}
    testTlsConnectivity "${gatewayRoot}/emd/main" "${tlsVersion} ${CURL_ARGS} --insecure -w %{http_code} --retry 3 --retry-delay 5 --retry-max-time 30 $GATEWAY_HEADER"
    
    if [ $accessError = "true" -o $statusError = "true" ]; then
      echo "Connection to ${connectTo} failed." >> ${LogFile}
      return
    else
      echo "Connection to ${connectTo} was successful." >> ${LogFile}
    fi
    connectTo="Cloud via Gateway"
  else
    connectTo="Cloud"
  fi
  
  echo "Try connection to ${connectTo}." >> ${LogFile}
  if [ "${gatewayRoot}" != "$ABSENT" ]; then
    testTlsConnectivity "${gatewayRoot}/emd/gateway/AgentLifeCycle/softwaredispatcher/testSvc" "${tlsVersion} ${CURL_ARGS} --insecure -w %{http_code} --retry 3 --retry-delay 5 --retry-max-time 30 $GATEWAY_HEADER"
  else 
    testTlsConnectivity "${alcEndPoint}/softwaredispatcher/testSvc" "${tlsVersion} ${CURL_ARGS} --insecure -w %{http_code} --retry 3 --retry-delay 5 --retry-max-time 30 $GATEWAY_HEADER"
  fi
  
  if [ $accessError = "true" -o $statusError = "true" ]; then
    echo "Connection to ${connectTo} failed." >> ${LogFile}
  else
    echo "Connection to ${connectTo} was successful." >> ${LogFile}
  fi
}

validateTlsVersion()
{
  tlsCount=0
  connectTo="Cloud"
  accessError="false"
  statusError="false"
  
  if [ "X${CURL_ARGS}" != "X" ]; then
    echo "CURL_ARGS passed in as parameters and the value is '${CURL_ARGS}'" >> ${LogFile}
    tlsCount=`echo ${CURL_ARGS} | grep tls | wc -l`
  fi
  
  currVer=`${CURL_PATH} --version | grep curl | grep -v '^#' | cut -d " " -f2`
  accessErrMess="The cURL version '${currVer}' deployed on this host is not configured to support TLS protocol required to communicate with ${connectTo}. The agent installation will encounter issues. You should update cURL to a higher version which supports TLS1.2 protocol to proceed with installation."
  statusErrMess="The CURL_ARGS provided as part of the installation parameters are not valid. Please verify the values passed in CURL_ARGS and retry without '${CURL_ARGS}'."
  
  httpOut=${logDir}/http.out
  
  if [ $tlsCount -gt 0 ]; then
    echo "TLS protocol to be used for connection with Cloud is passed in CURL_ARGS, using the same to check connectivity." >> ${LogFile}
    
    processTlsConnectivity ""
    
    if [ $statusError = "true" ]; then
      echo "${statusErrMess}" | tee -a ${LogFile}
      exit $retryExitCode
    fi
    
    if [ $accessError = "true" ]; then
      echo "${accessErrMess} Please retry installation without explicitly passing tls version in CURL_ARGS parameter as '${CURL_ARGS}'." | tee -a ${LogFile}
      exit $retryExitCode
    fi
    
    echo "Connection to ${connectTo} was succesful with ${CURL_ARGS}." >> ${LogFile}
  else
    echo "Determine TLS protocol to be used for connection with Cloud, same will be used for later connectivity." >> ${LogFile}
    curltlsvar="--tlsv1.2 --tlsv1.1 --tlsv1.0 --tlsv1"
    tlsVersion=$ABSENT
    for token in $curltlsvar
    do
      echo "Testing connectivity with ${token}." >> ${LogFile}
      accessError="false"
      statusError="false"
      processTlsConnectivity ${token}

      if [ $statusError = "true" ]; then
        echo "${connectTo} connection failed with $token." >> ${LogFile}
        continue
      fi
    
      if [ $accessError = "true" ]; then
        echo "${connectTo} connection failed with $token." >> ${LogFile}
      else
        echo "Connection to ${connectTo} was succesful with ${token}." >> ${LogFile}
        tlsVersion=${token}
        break
      fi
    done
    
    if [ $statusError = "true" ]; then
      echo ${statusErrMess} | tee -a ${LogFile}
      exit $retryExitCode
    fi

    if [ $accessError = "true" ]; then
      echo ${accessErrMess} | tee -a ${LogFile}
      exit $retryExitCode
    fi
    
    if [ $tlsVersion != $ABSENT ]; then
      echo "Including '${tlsVersion}' in CURL_ARGS to communicate with ${connectTo}." >> $LogFile
      CURL_ARGS="$tlsVersion ${CURL_ARGS}"
    fi
  fi
  
  if [ -f ${httpOut} ]; then
    rm -f ${httpOut}
  fi
}

#Program Starts Here
startTime=`date +"%F %T %Z"`
initialize
shellargs="$*"

processPlatform
for token in $shellargs
do
     getArgs "$token"
     case $name in 
	RESPONSE_FILE) responseFile=$value;;
     esac
done

if [ "$responseFile" != "$ABSENT" ]
then
      isFilePresent $responseFile "RESPONSE_FILE"
      processResponseFile $reponseFile
fi

for token in $shellargs
do
     getArgs "$token"
     case $name in
        AGENT_TYPE) agentType=$value
		    if [ "$agentType" = "apm_java_as_agent" ]
		    then
			agentType="apm"
		    fi
		    if [ "$agentType" = "cloud_agent" ]
		    then
			agentType="lama"
		    fi	
		    if [ "$agentType" = "data_collector" ]
		    then
			agentType="harvester"
		    fi	
		    ;;			
        AGENT_BASE_DIR) agentBaseDir=$value;;
        AGENT_INSTANCE_HOME) agentInstDir=$value;;
        TENANT_ID) tenantId=$value;;
        AGENT_REGISTRATION_PASSWORD) agentRegistrationPassword=$value;;
        AGENT_REGISTRATION_KEY) agentRegistrationPassword=$value;;
        GATEWAY_HOST)   gatewayHost=$value;;
        GATEWAY_PORT)   gatewayPort=$value;;
        EM_AGENT_NAME)  agentName=$value;;
        EM_AGENT_HOME)  agentHome=$value;;
        AGENT_PORT)     agentPort=$value;;
	HARVESTER_USERNAME) harvesterUser=$value;;
        HARVESTER_USER_PASSWORD)harvesterPswd=$value;;
        OMR_USER_PASSWORD)          omrPswd=$value;;
        OMR_USERNAME)       omrUser=$value;;
        OMR_HOSTNAME)       omrHost=$value;;
        OMR_PORT)           omrPort=$value;;
        OMR_SID)            omrSid=$value;;
	OMR_SERVICE_NAME)   omrService=$value;;
	OMR_HOST_USERNAME)  omrHostUser=$value;;
	OMR_HOST_USER_PASSWORD) omrHostUserPwd=$value;;
	OMR_HOST_USER_SSH_KEY)	omrHostUserKey=$value;;
	OMR_USER_ROLE)		omrUserRole=$value;;
	OMR_STAGE_DIR)		omrStageDir=$value;;
	OMR_CONNECT_STRING)	omrConnectString=$value;;
	ADDITIONAL_PARAMETERS)   additionalParameters=$value;;
	ADDITIONAL_GATEWAYS)   additionalGateways=$value;;
	AGENT_PROPERTIES)   agentProperties=$value;;
	STAGE_LOCATION)   stageLocation=$value;;
	ORACLE_HOSTNAME) oraclehostname=$value;;
	CURL_PATH) CURL_PATH=$value;;
	CURL_ARGS) CURL_ARGS=$value;;
	UNZIP_PATH) UNZIP_PATH=$value;;
	NAMESPACE)  namespace=$value;;
	-ignorePrereqs) ignorePrereqFlag=true;;
	-checkForUpdates) checkForUpdates=true;;
        -download_only) downloadOnly=true;;
        -download_from_edge) downloadFromEdge=true;;
        -secureAgent) secureAgent=true;;
        -staged) staged=true;;
	-ignoreHarvesterPrereqs) ignoreHarvesterPrereqs=true;;
	-ignoreUlimitCheck)      ignoreUlimitCheck=true;;
	-ignoreFQDNCheck)	 ignoreFQDNCheck=true;;
        -help) usage
	       exit 0;;
        *) echo "Error: Invalid argument $name passed. Run '$0 -help' for the usage of this script."
           exit 1;;
        esac
done

# EMCAGNT-979
validateCurlHttps

# establish gatewayRoot based on gatewayHost & gatewayPort
if [ "$gatewayHost" != "$ABSENT" -a "$gatewayPort" != "$ABSENT" ]; then
  gatewayRoot="$PROTOCOL://$gatewayHost:$gatewayPort"
fi
 
# additionalGateways makes sense only when there is a gateway
# i.e., clear additionalGateways when not uploading to a gateway
if [ "$additionalGateways" != "$ABSENT" -a "$gatewayRoot" = "$ABSENT" ]
then
  additionalGateways=$ABSENT
fi

#Fix EMCPALCM-1290
isFilePresent $CURL_PATH CURL_PATH
#validateCurlVersion

baseDir=`dirname $0`
if [ -f $baseDir/registration_key ] 
then
       agentRegistrationPassword=`cat $baseDir/registration_key`	
fi

if [ "$gatewayHost" = "$ABSENT" ]
then
	downloadFromEdge=true
fi


checkMandatoryParameter "AGENT_TYPE" $agentType
if [ $validationCode -ne 0 ]
then
	echo "Run '$0 -help' for the usage of this script.".
        exit 1
fi

case $agentType in
        lama) pullendPoint=$lamaEndPoint;;
        gateway) pullendPoint=$gatewayEndPoint;;
        harvester) pullendPoint=$lamaEndPoint;;
        apm)pullendPoint=$apmEndPoint
	    downloadOnly=true
            platformId=226
            functionToGeneratePropFile=generateAPMProperties
            propFileName=ApmAgentBundle.properties
            downloadWallet=true
            apmType=true;;
       $apmDotNetType)pullendPoint=$apmDotNetType
	    downloadOnly=true
            downloadFromEdge=true
            platformId=233
            functionToGeneratePropFile=generateAPMDotNetProperties 
            propFileName=OMC.ini
            downloadWallet=false
            apmType=true;;
       $apmNodeJsType)pullendPoint=$apmNodeJsType
	    downloadOnly=true
            downloadFromEdge=true
            platformId=226
            functionToGeneratePropFile=generateAPMNodeJsProperties
            propFileName=oracle-apm-config.json
            downloadWallet=false
            apmType=true;;
  $apmRubyType)   pullendPoint=$apmRubyType
                  downloadOnly=true
                  downloadFromEdge=true
                  platformId=226
                  functionToGeneratePropFile=generateAPMRubyProperties
                  propFileName=omc.yml
                  downloadWallet=false
                  apmType=true;;
  $apmPhpType)    pullendPoint=$apmPhpType
                  downloadOnly=true
                  downloadFromEdge=true
                  platformId=226
                  functionToGeneratePropFile=generateAPMPhpProperties
                  propFileName=ApmAgentBundle.properties
                  downloadWallet=false
                  apmType=true;;
  $apmIOSType)   pullendPoint=$apmIOSType
                  downloadOnly=true
                  downloadFromEdge=true
                  platformId=512
                  functionToGeneratePropFile=generateAPMMobileProperties
                  propFileName=ApmMobileAgent.properties
                  downloadWallet=false
                  apmType=true;;
  $apmAndroidType)  pullendPoint=$apmAndroidType
                  downloadOnly=true
                  downloadFromEdge=true
                  platformId=513
                  functionToGeneratePropFile=generateAPMMobileProperties
                  propFileName=ApmMobileAgent.properties
                  downloadWallet=false
                  apmType=true;;
        *) echo "Error: $agentType is not a valid agent type. It should be one of cloud_agent, gateway, harvester, apm_java_as_agent, $apmDotNetType, $apmNodeJsType"
           exit 1;;
        esac

zipName=${pullendPoint}.zip
checkMandatoryParameter "TENANT_ID" $tenantId
#isFilePresent $CURL_PATH CURL_PATH

if [ "$downloadOnly" = "true" ]
then
	validateDownloadOnlyParams
else
	validateDownloadAndInstallParams
fi

createDir $workDir
createDir $logDir

echo "The execution of script started at '${startTime}'" >> ${LogFile}
# EMCPALCM-2006 Validate TLS connectivity
validateTlsVersion

if [ "$downloadOnly" != "true" ]
then
	computeAndValidateHostNames
	ulimitCheck
fi

if [ "$downloadFromEdge" = "false" -a "$agentType" != "gateway" ] 
then
       validateGatewayAndLCMUrl  
fi

if [ "$agentType" = "lama" ] 
then
       validateBrownFieldTargets
fi

echo "Download end point $alcEndPoint" >>$LogFile
echo "Detected Platform $unameOutput" >>$LogFile

agentZipFile=$workDir/$zipName

#Call diskSpaceCheck before deploying the agent
diskSpaceCheck $workDir

if [ "$installFromStageLocation" = "$ABSENT" ]
then
	echo "Downloading $agentType agent software ..."|tee -a  $LogFile
	downloadFile "agentimage" $pullendPoint $agentZipFile 
	validateFile $agentZipFile

	if [ "$downloadOnly" = "true" ]
	then
	      if [ "$apmType" = "true" ]
	      then
                if [ "$apmCollectorRoot" = "ABSENT" ]; then
                  # hard failure
                  echo "ApmCollectorRoot was not provided by OMC"
                  echo "Please contact OMC support"
                  exit 1
                fi
        	   checkMandatoryParameter "AGENT_REGISTRATION_KEY" $agentRegistrationPassword $TRUE "agentRegistrationPassword"
        	   downloadFile "$securityArtifact" "encryptRegKey"
	           encrAgentRegistrationPassword=$curlOutputStream
	     	   downloadFile "$securityArtifact" "agentAuthTokenEncrypted" 
		   authToken=$curlOutputStream
                   downloadFile "$securityArtifact" "edgeServiceCert" ${workDir}/${apmCert} $hostname
                   #Download gateway cert if gateway specified as a install parameter - SND
                   if [ "$gatewayHost" != "$ABSENT" ]; then
       	             downloadFile "$securityArtifact" "agentCert"  ${workDir}/${apmGatewayCertName} $gatewayHost
                   fi
                   if [ "$downloadWallet" = "true" ]
                   then
                   	downloadFile "$securityArtifact" "agentAuthWallet" ${workDir}/${apmAuthToken} $hostname
                   fi
 
                   # Prepare uploadRoots, either from within generateAdditionalGatewaysProps
                   # or afterwards.
                   if [ "$additionalGateways" != "$ABSENT" -a "$agentType" != "gateway" ]
                   then
       	             generateAdditionalGatewaysProps
                   else
                     if [ "$gatewayHost" = "$ABSENT" ]; then
                       # OMC upload root
                       uploadRoots=$UploadRoot
                     else
                       # single gateway root
                       uploadRoots=$gatewayRoot
                     fi
                   fi
		   $functionToGeneratePropFile ${workDir}/${propFileName}
                   executeCommand "$UNZIP_PATH $UNZIP_ARGS $agentZipFile -d $workDir"
                   removeFileOrDir $agentZipFile
	      else
	      	   echo "Downloading AgentInstall.sh ..."|tee -a  $LogFile
      	           downloadFile "script" $agentInstallShEndPoint $workDir/$agentInstallScriptWithExt
	           chmod 755 $workDir/$agentInstallScriptWithExt
	      fi
	      	    removeFileOrDir $LogFile
              exit 0
	fi
else
        scriptDir=`dirname $0`	
	agentZipFile=$scriptDir/$zipName
        isFilePresent $agentZipFile "Agent Software"
fi

downloadFile "$securityArtifact" "agentAuthTokenEncrypted"         
authToken=$curlOutputStream

echo "Generating emaas.properties ..."|tee -a  $LogFile
generateSaaSProperties $tenantId

echo "Extracting Agent Software ..."|tee -a  $LogFile
executeCommand "$UNZIP_PATH $UNZIP_ARGS  $agentZipFile -d $workDir"
versionDir=`cat $workDir/agentimage.properties | grep '^VERSION'|cut -d= -f2`
coreDir=`cat $workDir/agentimage.properties | grep '^TYPE'|cut -d= -f2`
core_version=$coreDir/$versionDir


echo "Installing the Agent ..."|tee -a  $LogFile
installCommand="$workDir/AgentDeployment.sh AGENT_BASE_DIR=$agentBaseDir -softwareOnly"
if [ "$agentPort" != "$ABSENT" ]; then
        installCommand="$installCommand AGENT_PORT=$agentPort"
fi

executeCommand $installCommand

echo "Registering the Agent ..."|tee -a  $LogFile
copySaasPropCommand="cp $workDir/$emSaaSPropertiesFile $agentBaseDir/$core_version/$sysAdminDir"
executeCommand $copySaasPropCommand

configCommand="$configCommand AGENT_BASE_DIR=$agentBaseDir -secureAgent"
echo "Downloading Certificates ..."

        createDir $agentBaseDir/$core_version/$stageTrustedCerts

        if [  "$agentType" != "gateway" ]
        then
		if [ "$gatewayHost" = "$ABSENT" ] ; then
		  downloadFile "$securityArtifact" "edgeServiceCert" $agentBaseDir/$core_version/$trustCertEdge $hostname
		  downloadFile "$securityArtifact" "agentCert" $agentBaseDir/$core_version/$trustCertGateway $hostname
		else
                  downloadFile "$securityArtifact" "agentCert" $agentBaseDir/$core_version/$trustCertGateway $gatewayHost
		fi
        else
                downloadFile "$securityArtifact" "edgeServiceCert" $agentBaseDir/$core_version/$trustCertEdge $hostname
                downloadFile "$securityArtifact" "agentCert" $agentBaseDir/$core_version/$gatewayCert $hostname
                downloadFile "$securityArtifact" "agentPrivateKey" $agentBaseDir/$core_version/$gatewayKey $hostname
        fi

if [ "$agentPort" != "$ABSENT" ]; then
        configCommand="$configCommand AGENT_PORT=$agentPort"
fi

if [ "$agentInstDir" != "$ABSENT" ]; then
        configCommand="$configCommand AGENT_INSTANCE_HOME=$agentInstDir"
fi

if [ "$hostname" != "$ABSENT" ]; then
        configCommand="$configCommand ORACLE_HOSTNAME=$hostname"
fi

if [ "$additionalParameters" != "$ABSENT" ]; then
        configCommand="$configCommand $additionalParameters"
fi

if [ "$ignoreHarvesterPrereqs" != "$ABSENT" ]; then
	configCommand="$configCommand -ignoreHarvesterPrereqs"
fi

if [ "$ignoreUlimitCheck" != "$ABSENT" ]; then
	configCommand="$configCommand -ignoreUlimitCheck"
fi

agentPropertiesFile=${logDir}/agent.properties
rm -f $agentPropertiesFile

if [ "$additionalGateways" != "$ABSENT" -a "$agentType" != "gateway" ]
then
	generateAdditionalGatewaysProps
  echo "gatewayUrls=$gatewayUrls" >>$agentPropertiesFile
fi

if [ "$agentProperties" != "$ABSENT" ]; 
then
	generateAgentProperties
fi

if [ -f $agentPropertiesFile ]
then
	configCommand="$configCommand PROPERTIES_FILE=$agentPropertiesFile"
fi 

echo "Configuring the Agent ..."|tee -a  $LogFile

#
# AgentDeployment.sh expects password parameters in the following manner
#  and sequence...
#
# AGENT_REGISTRATION_PASSWORD - always
stdInput="$agentRegistrationPassword"
# SAAS_AUTH_PASSWORD          - if this is a gateway
#                            OR there's no gateway we're sending to
if [ "$agentType" = "gateway" -o "$gatewayHost" = "$ABSENT" ]
then
  stdInput="$stdInput\n$authToken"
fi
#(HARVESTER_USER_PASSWORD
# OMR_USER_PASSWORD
# OMR_HOST_USER_PASSWORD)     - if this is a harvester
if [  "$agentType" = "harvester" ]
then
  stdInput="$stdInput\n$harvesterPswd\n$omrPswd"
  # this is one difference
  # AgentDeployment.sh demands an omrHostPswd while this script tolerates
  #  its absence.
  if [ ! "$omrHostPswd" = "" ] ; then
    stdInput="$stdInput\n$omrHostPswd"
  fi
fi

executeCommand $configCommand

echo "Cleanup temporary files ..."|tee -a $LogFile
removeFileOrDir $workDir

echo "The following configuration scripts need to be executed as the root user"|tee -a $LogFile
echo "#!/bin/sh"|tee -a $LogFile
echo "#Root script to run"|tee -a $LogFile
echo "$agentBaseDir/$core_version/root.sh"|tee -a $LogFile
exit 0
