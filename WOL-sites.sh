#!/bin/bash

# Bash script to loop through hostnames, and send WOL to them

# Requires source CSV of the computers to wake:
#   Hostname/url, Broadcast ip address, MAC address
# Example:
#   google.com,   1.2.3.4,  11:22:33:44:55:66
#

SiteList=SiteList.csv

while IFS=, read Hostname Broadcast MAC
do 
  echo "Do something with ${Hostname} ${Broadcast} and ${MAC}"
  printf "\n${Hostname}"
  ping -c 1 -W 1 ${Hostname} > /dev/null 2>&1 && { printf "   Online" ; continue ; }
  
  #MAC=
  #Broadcast=
  PortNumber=9
  echo -e $(echo $(printf 'f%.0s' {1..12}; printf "$(echo $MAC | sed 's/://g')%.0s" {1..16}) | sed -e 's/../\\x&/g') | socat - UDP-DATAGRAM:${Broadcast}:${PortNumber},broadcast
  
  
done < ${SiteList}
