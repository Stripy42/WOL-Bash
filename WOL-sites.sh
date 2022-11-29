#!/bin/bash

#!/bin/bash

# Bash script to loop through hostnames, and send WOL to them

# Requires source CSV of the computers to wake:
# hostname/url, ip address, MAC address
# google.com, 1.2.3.4, 11:22:33:44:55:66

SiteList=SiteList.csv

while read Site; do
	echo "$Site"
	
	
	
	
	
	
	
	
	
done <${SiteList}




while IFS=, Hostname, IP, MAC
do 
  echo "Do something with $Hostname $IP and $MAC"
  
  
  
done < ${SiteList}
