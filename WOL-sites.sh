#!/bin/bash

# Bash script to loop through hostnames, and send WOL to them

# Requires source CSV of the computers to wake:
#   Hostname/url, Broadcast ip address, MAC address
# Example:
#   google.com,   1.2.3.4,  11:22:33:44:55:66
#

# Curentlly uses socat, but will have option to alternativly use nc (aka netcat)


SiteListDefault=SiteList.csv
PortNumberDefault=9

###------------------------------------------------------------------------------------

## Functions
HelpEcho ()
{
		echo "
		WOL tool for (Old) Linux, Written by Stripy42 aka Andrew, 2022/11/29
		command:
		WOL-sites.sh [hf] 
		Dependency:
		socat
		SWITCHES
		-f F <File path and name>	Site list CSV file
		-s S <hostname>				Specify a single site in the csv site list
		-v V 						Verbose
		-h H						Help (this option)
		Error levels: 0 = OK, 1 = Not OK 
		"
}

## Choice
while getopts "hHf:F:s:S:" c
do
	case $c
	in
	V|v) verbose="-v"; verbose2="";;
	f|F)
		SiteListNew="${OPTARG}"
	;;
	s|S)
		Site="${OPTARG}"
	;;
	p|P)
		PortNumberNew="${OPTARG}"
	;;
	h|H) #Help
		HelpEcho
		exit 1
	;;
	?|*) #Help
		echo "
		Invalid option: -${OPTARG}
		" >&2
		HelpEcho
		exit 1
	;;
	'')
		HelpEcho
		exit 1
	;;
	esac
done
shift $((OPTIND - 1))

narg=${#@}
n=0

testids="${@}"

###------------------------------------------------------------------------------------

SiteList="${SiteListNew:-${SiteListDefault}}"
PortNumber="${PortNumberNew:-${PortNumberDefault}}"

if [ ! -s ${SiteList} ]; then echo "no csv file"; exit 1 ; fi

# Check dependicy
if [[ $(which socat) ]]; then BroadcastTool="Socat"
elif [[ $(which nc) ]]; then BroadcastTool="NC"
elif [[ $(which netcat) ]]; then BroadcastTool="Netcat"
else
	echo install socat, nc, or netcat from your prefered supplier of zeros and ones
	exit 1
fi

CheckandWOL() {

	Hostname=$(echo ${HostnamePre} | tr -d '[:space:]')
	MAC=$(echo ${MACPre} | tr -d '[:space:]')
	Broadcast=$(echo ${BroadcastPre} | tr -d '[:space:]')
	
	if [[ ${BroadcastTool} -eq "Socat" ]]; then
		echo -e $(echo $(printf 'f%.0s' {1..12}; printf "$(echo $MAC | sed 's/://g')%.0s" {1..16}) | sed -e 's/../\\x&/g') | socat - UDP-DATAGRAM:${Broadcast}:${PortNumber},broadcast
	elif [[ ${BroadcastTool} -eq "NC" ]]; then
		echo -e $(echo $(printf 'f%.0s' {1..12}; printf "$(echo $MAC | sed 's/://g')%.0s" {1..16}) | sed -e 's/../\\x&/g') | nc
	elif [[ ${BroadcastTool} -eq "Netcat" ]]; then
		echo -e $(echo $(printf 'f%.0s' {1..12}; printf "$(echo $MAC | sed 's/://g')%.0s" {1..16}) | sed -e 's/../\\x&/g') | netcat
	else
		echo "how did you get here?"
	fi
}

LoopWholeSiteList() {
	while IFS=, read HostnamePre BroadcastPre MACPre
	do 
		echo "Do something with ${HostnamePre} ${BroadcastPre} and ${MACPre}"
		printf "\n${HostnamePre}"
		ping -c 1 -W 1 ${HostnamePre} > /dev/null 2>&1 && { printf "   Online" ; continue ; }
		CheckandWOL
	done < ${SiteList}
}

WakeOneSite() {	
	IFS=,
	read HostnamePre BroadcastPre MACPre <<<"$(grep "${Site}" "${SiteList}" 2>/dev/null)"
	CheckandWOL
}


if [[ -z "${Site}" ]]; then
	LoopWholeSiteList
else
	WakeOneSite
fi


exit 0

####################################

#Notes on other requirements.

# All require root
if [[ $EUID -ne 0 ]]; then echo -e "This script must be run as root\n"; exit 1; fi


# Identify if WOL enabled



# Enable WOL
## Get WOL info for all (real) ethernet devices 
for NET in $(/sbin/ifconfig -a | sed 's/[ \t].*//;/^\(lo\|\)$/d');do ethtool $NET | grep 'Settings\|Wake'; done


####################################

# Create list of required IP addresses and MAC from hostnames

## Two part method
### Part 1
thedestination=/your/prefered/destination

for TestCell in <your list of urls>;do
	ssh ${TestCell} "/sbin/ifconfig" > "$thedestination"/${TestCell}.ifconfig.txt
done

### Part 2
for TestCell in <your list of urls>;do
	FileName="${TestCell}.ifconfig.txt"
	if [ ! -s ${FileName} ]; then continue ; fi

	for NET in $(cat ${FileName} | sed 's/[ \t].*//;/^\(lo\|\)$/d');do 
		theMAC=$(grep "${NET} " ${FileName} | sed -n -e 's/^.*HWaddr //p')
		theIP=$(sed -n "/${NET} /{n;p}" ${FileName} | grep -o -P '(?<=addr:).*(?=Bcast)')

		#This filters down to only ip addresses starting with 19, it's a Ford thing you might not need this
		if [ $(echo ${theIP} | grep -c "^19\.") -eq 1 ]; then
			printf "\n${TestCell}, ${theIP}, ${theMAC}"
		fi
	done
done > YourSiteList.csv

#OR one hit method

for TestCell in <your list of urls>;do

	ping -c 1 -w 1 ${TestCell} > /dev/null 2>&1 ||  { echo offline; continue; }
	theIfconfig=$(ssh ${TestCell} "/sbin/ifconfig")
	
	if [ -z ${theIfconfig} ]; then continue ; fi

	for NET in $(echo ${theIfconfig} | sed 's/[ \t].*//;/^\(lo\|\)$/d');do 
		theMAC=$(echo ${theIfconfig} | grep "${NET} " | sed -n -e 's/^.*HWaddr //p')
		theIP=$(echo ${theIfconfig} | sed -n "/${NET} /{n;p}" | grep -o -P '(?<=addr:).*(?=Bcast)')

		#This filters down to only ip addresses starting with 19, it's a Ford thing you might not need this
		if [ $(echo ${theIP} | grep -c "^19\.") -eq 1 ]; then
			printf "\n${TestCell}, ${theIP}, ${theMAC}"
		fi
	done
done > YourSiteList.csv


