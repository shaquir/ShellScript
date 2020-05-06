#!/bin/bash

<<ABOUT_THIS_SCRIPT
-----------------------------------------------------------------------
Forked from https://github.com/talkingmoose/Jamf-Scripts/blob/master/Computer%20Information.bash
	Written by:William Smith
	Professional Services Engineer
	Jamf
	bill@talkingmoose.net
	https://github.com/talkingmoose/Jamf-Scripts
	
	Originally posted: August 13, 2018
	Updated: April 7, 2019

	Purpose: Display a dialog to end users with computer information when
	run from within Jamf Pro Self Service. Useful for Help Desks to
	ask end users to run when troubleshooting.

	Except where otherwise noted, this work is licensed under
	http://creativecommons.org/licenses/by/4.0/

	
Edited 10-22-19 by Shaquir Tannis:
Point to Company Logo
Check if connected to Company Network
Display CPU Usage
Display Open Apps
Prompts User for a description of the issue
	
-----------------------------------------------------------------------
ABOUT_THIS_SCRIPT



## General section #####


#Company Logo
currentUser=$( stat -f "%Su" /dev/console )
if [ -f "/Users/$currentUser/Library/Application Support/com.jamfsoftware.selfservice.mac/Documents/Images/brandingimage.png" ];then
	companyLogo="/Users/$currentUser/Library/Application Support/com.jamfsoftware.selfservice.mac/Documents/Images/brandingimage.png"
	else
	companyLogo="/System/Library/CoreServices/Finder.app/Contents/Resources/Finder.icns"
	fi

# Display computer name
runCommand=$( /usr/sbin/scutil --get ComputerName )
computerName="Computer Name: $runCommand"


# Display serial number
runCommand=$( /usr/sbin/system_profiler SPHardwareDataType | /usr/bin/grep "Serial Number" | /usr/bin/awk -F ": " '{ print $2 }' )
serialNumber="Serial Number: $runCommand"


# Display uptime
runCommand=$( /usr/bin/uptime | /usr/bin/awk -F "(up |, [0-9] users)" '{ print $2 }' )
if [[ "$runCommand" = *day* ]] || [[ "$runCommand" = *sec* ]] || [[ "$runCommand" = *min* ]] ; then
	upTime="Uptime: $runCommand"
else
	upTime="Uptime: $runCommand hrs/min"
fi



## Network section #####


# Display active network services and IP Addresses

networkServices=$( /usr/sbin/networksetup -listallnetworkservices | /usr/bin/grep -v asterisk )

while IFS= read aService
do
	activePort=$( /usr/sbin/networksetup -getinfo "$aService" | /usr/bin/grep "IP address" | /usr/bin/grep -v "IPv6" )
	if [ "$activePort" != "" ] && [ "$activeServices" != "" ]; then
		activeServices="$activeServices\n$aService $activePort"
	elif [ "$activePort" != "" ] && [ "$activeServices" = "" ]; then
		activeServices="$aService $activePort"
	fi
done <<< "$networkServices"

activeServices=$( echo "$activeServices" | /usr/bin/sed '/^$/d')


# Display Wi-Fi SSID
model=$( /usr/sbin/system_profiler SPHardwareDataType | /usr/bin/grep 'Model Name' )

if [[ "$model" = *Book* ]]; then
	runCommand=$( /usr/sbin/networksetup -getairportnetwork en0 | /usr/bin/awk -F ": " '{ print $2 }' )
else
	runCommand=$( /usr/sbin/networksetup -getairportnetwork en1 | /usr/bin/awk -F ": " '{ print $2 }' )
fi

SSID="SSID: $runCommand"


# Display SSH status
runCommand=$( /usr/sbin/systemsetup -getremotelogin | /usr/bin/awk -F ": " '{ print $2 }' ) 
SSH="SSH: $runCommand"


#Check if it can succefully connect to Company's Internal Network
if [ "$runCommand" = af.lan ]; then
	AD="Bound to Active Directory: Yes"
else
	AD="Bound to Active Directory: No"	
fi

if ping -q -c 1 -W 1 AXFarm.af.lan &>/dev/null; then
	connectedToCompany="Connected to Company Network"
else
	connectedToCompany="Not Connected to Company Network!"	
fi



# Display date, time and time zone
runCommand=$( /bin/date )
timeInfo="Date and Time: $runCommand"


# Display network time server
runCommand=$( /usr/sbin/systemsetup -getnetworktimeserver )
timeServer="$runCommand"



## Active Directory section #####


# Display Active Directory binding
runCommand=$( /usr/sbin/dsconfigad -show | /usr/bin/grep "Directory Domain" | /usr/bin/awk -F "= " '{ print $2 }' )

if [ "$runCommand" = af.lan ]; then
	AD="Bound to Active Directory: Yes"
else
	AD="Bound to Active Directory: No"	
fi



## Hardware/Software section #####


# Display free space
FreeSpace=$( /usr/sbin/diskutil info "Macintosh HD" | /usr/bin/grep  -E 'Free Space|Available Space' | /usr/bin/awk -F ":\s*" '{ print $2 }' | awk -F "(" '{ print $1 }' | xargs )
FreePercentage=$( /usr/sbin/diskutil info "Macintosh HD" | /usr/bin/grep -E 'Free Space|Available Space' | /usr/bin/awk -F "(\\\(|\\\))" '{ print $6 }' )
diskSpace="Disk Space: $FreeSpace free ($FreePercentage available)"


# Display operating system
runCommand=$( /usr/bin/sw_vers -productVersion)
operatingSystem="Operating System: $runCommand"


# Display battery cycle count
runCommand=$( /usr/sbin/ioreg -r -c "AppleSmartBattery" | /usr/bin/grep '"CycleCount" = ' | /usr/bin/awk '{ print $3 }' | /usr/bin/sed s/\"//g )
batteryCycleCount="Battery Cycle Count: $runCommand"

# Gets the current CPU usage
runCommand=$(top -l 1 | grep CPU | grep -v %CPU | awk '{print $3}')
cpuUsage="CPU Usage: $runCommand"

#List of Open Apps
runCommand=$(osascript -e 'tell application "System Events" to get name of (processes where background only is false)')
openAPPS="Open Apps: $runCommand"


## Format information #####


displayInfo="
----------------------------------------------
GENERAL

$computerName
$serialNumber
$upTime
----------------------------------------------
NETWORK

$activeServices
$SSID
$SSH
$timeInfo
$timeServer

$connectedToCompany
$AD
----------------------------------------------
HARDWARE/SOFTWARE

$diskSpace
$operatingSystem
$batteryCycleCount
$cpuUsage

$openAPPS
----------------------------------------------"



## Display information to end user #####


runCommand="button returned of (display dialog \"$displayInfo\" with title \"Computer Information\" with icon file posix file \"$companyLogo\" buttons {\"Submit a Ticket\", \"OK\"} default button {\"OK\"})"

clickedButton=$( /usr/bin/osascript -e "$runCommand" )



## Run additional commands #####


if [ "$clickedButton" = "Submit a Ticket" ]; then
	
	
	#Added option for users to add aditional texts to Company Ticket
results=$( /usr/bin/osascript -e "display dialog \"Please add a short description of the problem\" with icon file POSIX file \"$companyLogo\" default answer \"\" buttons {\"Cancel\",\"OK\"} default button {\"OK\"}" )



theButton=$( echo "$results" | /usr/bin/awk -F "button returned:|," '{print $2}' )
theText=$( echo "$results" | /usr/bin/awk -F "text returned:" '{print $2}' )


if [ "$theButton" != "OK" ];
then
echo "exiting"
fi
	
	# Open Outlook and email computer information to help desk
	currentUser=$( stat -f "%Su" /dev/console )
	sudo -u "$currentUser" /usr/bin/open -b com.microsoft.outlook "mailto:ticket@company.com?subject=Computer Information ($serialNumber)&body=$theText$displayInfo"   

fi


exit 0
