#!/bin/bash
#Script to remove Application from macOS Login Items list
###Shaquir Tannis on 7/5/20
#github.com/shaquir/

#App to remove from User's login items
appToRemove="Skype for Business"

#Determine current log in user
currentUser=$(ls -l /dev/console | awk '{print $3}')

#List login items | Remove space after the comma
loginItems=$( sudo -u $currentUser /usr/bin/osascript -e 'tell application "System Events" to get the name of every login item' | sed -e 's/, /,/g' )

IFS=","

#Initial check to determine if array contains appToRemove
if [[ " ${loginItems[*]} " == *"$appToRemove"* ]]; then
	
	#Loop through to delete appToRemove where found (Takes care of multiple instances of the same app)
	for item in $loginItems
		do
			if [ "$item" == "$appToRemove" ]; then
				echo "$appToRemove was found in "$currentUser"'s login items"
				
				#Remove $appToRemove from login items
				sudo -u $currentUser /usr/bin/osascript <<-EOD
					tell application "System Events" to delete login item "$appToRemove"
					EOD
				
				echo "$appToRemove has been removed."
			fi
	done
else
	echo "$appToRemove was NOT found in "$currentUser"'s login items."
fi

#List updated login items
echo "Updated login items:"
sudo -u $currentUser /usr/bin/osascript -e 'tell application "System Events" to get the name of every login item'
