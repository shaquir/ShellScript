#!/bin/bash

#This script is part of a workflow to ensure an Application's Screen Recording permission has been set to enabled in the TCC Security and Privacy.  If the TCC option is disabled it will prompt the user to enable it
#Shaquir Tannis 5-26-2020
#https://github.com/shaquir/

#Select the TCC value pair from the system's TCC.db
#To get a list of all the system TCC values on your machine, you can run the command:
#/usr/bin/sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" 'SELECT * FROM access;'
tccSearchPair="kTCCServiceScreenCapture|com.tinyspeck.slackmacgap"
#Variables for dialog
appName="Slack"
#App icon location
appImage="/Applications/Slack.app/Contents/Resources/electron.icns"
#Dialog to send user
initialMessage="To properly support your machine, we need you to allow the Screen Recording option for $appName"
#Second message screen for user to allow
secondMessage="In the Security and Privacy window, please allow $appName by adding a checkmark to the left of it"


function promptUser()
{
initialPrompt=$( /usr/bin/osascript -e "display dialog \"$initialMessage\" with title \"$appName Screen Sharing\" with icon file POSIX file \"$appImage\"  buttons {\"OK\"} default button {\"OK\"} giving up after 900" )

theButton=$( echo "$initialPrompt" | /usr/bin/awk -F "button returned:|," '{print $2}' )


if [ "$theButton" == "OK" ];
then
	echo "Opening Screen Recording Privacy"
	#Open System Preferences > Security & Privacy > Screen Recording
	open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
	sleep 1
	#Prompt User with second dialog instructing them to enable app
	secondPrompt=$( /usr/bin/osascript -e "display dialog \"$secondMessage\" with title \"$appName Screen Sharing\" with icon file POSIX file \"$appImage\"  buttons {\"OK\"} default button {\"OK\"} giving up after 30" )
else
	echo "Button OK not selected.  Exiting..."
	exit
fi

#Wait 60 seconds and report if screen recording has been enabled
sleep 60
secondCheck=$(/usr/bin/sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" 'SELECT service, client FROM access WHERE allowed = '0'')
if [[ "$secondCheck" != *"$tccSearchPair"* ]]; then
	echo "User successfully enabled $appName"
else
	echo "$appName is still disabled.  Exiting..."
	exit
fi
}

#Check for disabled System TCC values
disabledValues=$(/usr/bin/sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" 'SELECT service, client FROM access WHERE allowed = '0'')

#Check if tccSearchPair matches a disabled TCC value on the user's machine
if [[ "$disabledValues" == *"$tccSearchPair"* ]]; then
	#Run function to prompt user to enable
	promptUser
else
	echo "$appName permission has already been enabled.  Exiting Script."
	exit
fi
