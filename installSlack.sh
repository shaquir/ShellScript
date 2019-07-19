#!/bin/bash
##  Created by Shaquir Tannis on 6/12/19
##Inspiration of scripts from owen.pragel and anverhousseini from JamfNation
#### Edited 7/19/19 to address Slack releases.json removal

#To kill Slack, Input "kill" in Parameter 4 
killSlack="$4"

#Find latest Slack version / Pulls Version from Slack for Mac download page
currentSlackVersion=$(/usr/bin/curl -s 'https://slack.com/downloads/mac' | grep -o "Version [0-9]\.[0-9]\.[0-9]" | cut -d' ' -f2 )

#Install Slack function
install_slack() {
	
#Slack download variables
slackDownloadUrl=$(curl "https://slack.com/ssb/download-osx" -s -L -I -o /dev/null -w '%{url_effective}')
dmgName=$(printf "%s" "${slackDownloadUrl[@]}" | sed 's@.*/@@')
slackDmgPath="/tmp/$dmgName"

	
#Kills slack if "kill" in Parameter 4 
if [ "$killSlack" = "kill" ];
then
pkill Slack*
fi

#Begin Download

#Downloads latest version of Slack
curl -L -o "$slackDmgPath" "$slackDownloadUrl"

#Mounts the .dmg
hdiutil attach -nobrowse $slackDmgPath

#Checks if Slack is still running
if pgrep '[S]lack' && [ "$killSlack" != "kill" ]; then
	printf "Error: Slack is currently running!\n"
		
elif pgrep '[S]lack' && [ "$killSlack" = "kill" ]; then
	pkill Slack*
	sleep 10
	if pgrep '[S]lack' && [ "$killSlack" != "kill" ]; then
		printf "Error: Slack is still running!  Please try again later.\n"
		exit 409
	fi
fi
    
# Remove the existing Application
	rm -rf /Applications/Slack.app

#Copy the update app into applications folder
	sudo cp -R /Volumes/Slack*/Slack.app /Applications

#Unmount and eject dmg
	mountName=$(diskutil list | grep Slack | awk '{ print $3 }')
	umount -f /Volumes/Slack*/
	diskutil eject $mountName

#Clean up /tmp download
	rm -rf "$slackDmgPath"
}

#Fix Slack ownership function
assimilate_ownership() {
	echo "=> Assimilate ownership on '/Applications/Slack.app'"
	chown -R $(scutil <<< "show State:/Users/ConsoleUser" | awk -F': ' '/[[:space:]]+Name[[:space:]]:/ { if ( $2 != "loginwindow" ) { print $2 }}'):staff "/Applications/Slack.app"
}

#Check if Slack is installed
if [ ! -d "/Applications/Slack.app" ]; then
	echo "=> Slack.app is not installed"
	install_slack
	assimilate_ownership

#If Slack version is not current install set permissions
elif [ "$currentSlackVersion" != `defaults read "/Applications/Slack.app/Contents/Info.plist" "CFBundleShortVersionString"` ]; then
	install_slack
	assimilate_ownership
	
#If Slack is installed and up to date just adjust permissions
elif [ -d "/Applications/Slack.app" ]; then
		localSlackVersion=$(defaults read "/Applications/Slack.app/Contents/Info.plist" "CFBundleShortVersionString")
		if [ "$currentSlackVersion" = "$localSlackVersion" ]; then
			printf "Slack is already up-to-date. Version: %s" "$localSlackVersion"		
assimilate_ownership			
			exit 0
	fi
fi
