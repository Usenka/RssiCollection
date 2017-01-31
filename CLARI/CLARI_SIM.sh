#!/bin/bash

thisuser=`id -u`
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
# This is required to make midnight commanders editor highlight syntax correctly: "

CLARI_isCLARISim=1

if [ "$CLARISIMCONFIG" != "" ]
then
	source "$CLARISIMCONFIG"
else
	if [ -f "$CLARISIMCONFIG" ]
	then
		source clarisim_config.sh
	else
		if [ -f "$CLARICONFIG" ]
		then
			echo "Using CLARICONFIG instead of CLARISIMCONFIG.."
			CLARISIMCONFIG="$CLARICONFIG"
			source $CLARICONFIG
		else
			echo "No config found."
			exit 1
		fi
	fi
fi

trap 'kill $(jobs -p)' EXIT

__CLARI_gotoApplicationPath(){
  local path=""
  for item in ${TinyOSCustomApps[@]}
  do
    if [ -d $item/$1 ]
    then
      path=$item/$1
      break
    fi
  done
	
  if [ "" == "$path" ]
  then
    for item in ${tinyOSAppSubPaths[@]}
    do
      if [ -d $TinyOSAppPath/$item/$1 ]
      then
				path=$TinyOSAppPath/$item/$1
				break
      fi
    done
  fi
	
  if [ "" == "$path" ]
  then
    if [ -d $ConfigPath/tinyosApps/$1 ]
    then
      path=$ConfigPath/tinyosApps/$1
    fi
  fi

  if [ "" != "$path" ]
  then
    cd $path
    return 0
  fi
  if [ -d "$1" ]
  then
  	cd "$1"
  	return 0
  fi
  return 1
}

# Statt
copyToAllRemoteHosts(){
  filename=$1
  echo "Requested copy of $1"
  rm "/tmp/clarisim.$thisuser.tmp.apps" -fr
  mkdir -p "/tmp/clarisim.$thisuser.tmp.apps"
  echo "cp -r $filename /tmp/clarisim.$thisuser.tmp.apps -r"
  cp "$filename" "/tmp/clarisim.$thisuser.tmp.apps/application" -r
  return $?
}

CLARI_executeCommandOnAllHosts(){
	echo "This command does not exists for a local simulation."
	return 1
}



CLARI_installApplicationOnAllRemoteHosts(){
	if [ "$#" != "2" ]
	then
	    echo "Please specify configuration file and cooja config file as a parameter." >&2
	    return 1
	fi
	
	echo "INFO:    Stopping all serial forwarders.." | tee -a "$log"
	CLARI_killallRemoteSerialForwardersPlease
	
	# Load cooja config file
	source "$2"
	
	echo "INFO:    Serial forwarders stopped.."
	
	echo "INFO:    Getting a global list of motes.."
#	CLARI_performGlobalMotelist > /dev/null
	
	
	megaApp=""
	idToApplicationFile=$1
	applications=($(cat $1 | awk '{print $2}' ))
	echo "Apps=$applications.."
	amIds=($(cat $1 | awk '{print $1}' ))
	echo "amIds=$amIds"
	megaApp=$(cat $idToApplicationFile | grep \* | awk '{print $2}')
	
	sorted_unique_ids=$(echo "${applications[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
	
	
	lastapp=""
	for application in ${sorted_unique_ids[@]}
	do
		if [ "$application" != "Null" ]
		then
			if [ "$application" != "$lastapp" ]
			then
				if [ "$lastapp" == "" ]
				then
					firstpath=`pwd`
					lastapp="$application"
					echo "Application is $application"
					__CLARI_gotoApplicationPath $application
					if [ $? -eq 0 ] 
					then
						echo "copying application $application to all remoteHosts"
						#TODO copy application just on the pies that require it
						appname=`basename $application`
						echo "Dirname $(pwd)"
						copyToAllRemoteHosts ../$appname
						# Goto directory:
						cd "/tmp/clarisim.$thisuser.tmp.apps/application" > /dev/null
						# Create "fresh" binary:
						make telosb
					else 
						echo "FAIL:    Application $application not found. Aborting.."
						return 1
					fi
					cd "$firstpath" > /dev/null
				else
					echo "More than one application specified. This is currently not possible."
					return 1
				fi
			fi
		fi
	done 
	
	echo -n "" > "/tmp/clarisim.$thisuser.nodelist"
	# Liste der Knoten aufbauen:
	if [ "$CLARISIM_nodeSubset" != "" ]
	then
		# Write list of managed motes based on the nodeSubset to be used for this experiment (DTM variable)
		for mote in $nodeSubset
		do
			echo "$mote" >> "/tmp/clarisim.$thisuser.nodelist"
		done
	else
		# Write list of managed motes:
		cat $managedMotes/* | awk '{print $2}' >> "/tmp/clarisim.$thisuser.nodelist"
	fi
	
	# Timeout is given in seconds. We need to recalc that:
	if [ "$simTimeout" != "" ]
	then
		simTimeout=$((1000000 * $simTimeout))
		simtimeoutinfo=" -simTimeout $simTimeout"
	else
		simtimeoutinfo=""
		echo "COOJACONF: No simulation timeout."
	fi
	
	if [ "$randomSeed" != "" ]
	then
		randomseedinfo=" -randomseed $randomSeed"
	else
		randomseedinfo=""
		echo "COOJACONF: No random seed."
	fi
	
	if [ "$moteDelay" != "" ]
	then
		motedelayinfo=" -motedelay $moteDelay"
	else
		motedelayinfo=""
		echo "COOJACONF: No moteDelay."
	fi
	
	# These parameters must be included in cooja config:
	echo "java -jar \"$coojaConfigBuilderJar\" -inputTemplate \"$CLARISIM_coojaTemplate\" -radioModel \"$CLARISIM_coojaRadioModel\"$simtimeoutinfo$randomseedinfo$motedelayinfo -firmwarefile \"/tmp/clarisim.tmp.apps/application/build/telosb/main.exe\" -nodelist \"/tmp/clarisim.$thisuser.nodelist\" > \"/tmp/clarisim.$thisuser.coojaconfig\""
	java -jar "$coojaConfigBuilderJar" -inputTemplate "$CLARISIM_coojaTemplate" -radioModel "$CLARISIM_coojaRadioModel"$simtimeoutinfo$randomseedinfo$motedelayinfo -firmwarefile "/tmp/clarisim.tmp.apps/application/build/telosb/main.exe" -nodelist "/tmp/clarisim.$thisuser.nodelist" > "/tmp/clarisim.$thisuser.coojaconfig"
	echo "COOJA simulation config file has been written to /tmp/clarisim.$thisuser.coojaconfig"
}


CLARI_startAllLocalSerialForwarderJava(){
	
	# Kill all local serial forwarders (kill screen..)
	CLARI_killallLocalSerialForwardersPlease
	
	CLARI_getAllRemoteForwarderList | while read id
	do
		echo "id found: $id"
		host=`CLARI_getHostFromID $id`
		remoteport=`CLARI_getPortFromID $id`
	
      localport=$((9000 + id))
      echo "Starting SF to $id on localhost using $port, local port $port."
			
			screen -dmS "localmotesf-$id" java -cp $pathToTinyOSJar net.tinyos.sf.SerialForwarder -comm sf@$host:$remoteport -no-gui -port $localport
	done
}



CLARI_startAllRemoteSerialForwarders(){
	
	# Stop all remote sf first:
	CLARI_killallRemoteSerialForwardersPlease > /dev/null 2>&1
	
	# Start COOJA here.
	echo "java -jar $coojaJar -nogui=\"/tmp/clarisim.$thisuser.coojaconfig\" &"
	#
	java -jar $coojaJar -nogui="/tmp/clarisim.$thisuser.coojaconfig" &
	ret=$?
	
	# Echo the PID to this file. We need to do this since STDOUT is clobbered by bash's output of the startet PID..
	echo "$!" > "/tmp/clarisim.$thisuser.coojapid"
	
	# We have to give cooja some time until motes are connected.
	sleep 10
	
	return $ret
}

CLARI_killallJavaSerialForwarder(){
 CLARI_executeCommandOnAllHosts "killall java"
 CLARI_executeCommandOnAllHosts "screen -wipe"
}

CLARI_killallRemoteSerialForwardersPlease(){ 
	# This will kill all C serial forwarders on the PIs. Screen exits and quits sessions automatically when they exit.
	#CLARI_executeCommandOnAllHosts "/usr/bin/screen -ls | grep motesf | cut -d. -f1 | awk '{print \$1}' | xargs kill || true"
	
	# Find local cooja instance and kill it.
	echo "To be implemented."
	return 0
}

CLARI_killallLocalSerialForwardersPlease() {
	# List all screen sessions, grep the ones that contain "mote-", get the process IDs and run kill on them.
	screen -ls | grep "localmotesf" | cut -d. -f1 | awk '{print $1}' | xargs kill
}





CLARI_getAllRemoteSerialForwarderStatus(){
	cat $managedMotes/* | awk '{print $2}' | tr -dc "[:alnum:] \n" | while read id
	do
#		id=`tr -dc "[:alnum:] "`
		if [ "$id" != "" ]
		then
#			echo "id $id"
			port=`CLARI_getPortFromID $id`
			running=`netstat -anp 2>/dev/null | grep "$port" | grep "java"`
			if [ "$running" == "" ]
			then
				echo "STOPPED: CLARISIM is stopped for $id."
			else
				echo "RUNNING: CLARISIM is running for $id."
			fi
		fi
	done
	
	return 0
}

CLARI_getAllRemoteSerialForwarderList() {
	cat $managedMotes/* | awk '{print $2}' | tr -dc "[:alnum:] \n" | while read id
	do
#		id=`tr -dc "[:alnum:] "`
		if [ "$id" != "" ]
		then
#			echo "id $id"
			port=`CLARI_getPortFromID $id`
			running=`netstat -anp 2>/dev/null | grep "$port" | grep "java"`
			if [ "$running" != "" ]
			then
				echo "$id"
			fi
		fi
	done
	
	return 0
	
}

CLARI_performGlobalMotelist() {
	cat $managedMotes/* | awk '{print $2}' | tr -dc "[:alnum:] \n" | while read id
	do
		host=`CLARI_getIPFromID $id`
		port=`CLARI_getPortFromID $id`
		echo "$host SIMID$id /dev/null" | tee -a /tmp/clarisim.$thisuser.motelist
	done
	
	return $res
}

CLARI_getPIList() {
	echo "CLARISIM does not have PIs."
    return 1
}

CLARI_resetAllMotes() {
	echo "CLARISIM cannot reset motes."
	return 1
}

CLARI_resetAllPIs() {
	echo "Since CLARISIM does not have any PIs there is no use in resetting them." >&2
	return 1
}

__CLARI_checkForForeignProgramsOnPI() {
	echo "Since CLARISIM does not have any PIs we cannot check for foreign programs." >&2
	return 1
}

CLARI_getNewLock() {
	# We are always running exclusively.
	return 0
}

CLARI_isLocked() {
	return 0
}

# Check testbed locking state: 0=We have a lock, 1=Lock could not be checked, 2=Somebody else has locked the testbed, 3=Nobody has locked the testbed.
CLARI_hasLock() {
	return 0
}

CLARI_releaseLock() {
	return 0
}

CLARI_releaseAllLocks() {
	return 0
}

CLARI_lockRequestAccess() {
	return 0
}

CLARI_validateManagedMotes() {
	echo "Cannot validate virtual motes."
	return 1
}

CLARI_startExperiments() {
	return 0
}

CLARI_stopExperiments() {
	return 0
}

CLARI_getIPFromID() {
	# We are running experiments always locally..
	echo "127.0.0.1"
	return 0
}

CLARI_getHostFromID() {
	CLARI_getIPFromID $1
}

CLARI_getPortFromID() {
    port=$((6000 + $1))
    echo "$port"
    return 0
}

CLARI_getIDList() {
    cat $managedMotesFiles | awk '{print $2}' | tr -dc "[:alnum:] \n" | while read -r moteid
    do
		echo -n "$moteid "
    done
    echo ""
    return 0
}


