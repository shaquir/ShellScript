#!/bin/bash
#Shaquir Tannis 3-19-2020
#This script is created to report and reset disabled Camera or Microphone TCC Security and Privacy access for Skype for Business within a logged in user's TCC preferences.  If the Camera or Microphone option is disabled it will reset the TCC value to allow a reprompt for a user's Camera or microphone access
#### Please be aware that for machines running Mojave and below resetting a single Application's TCC bundle ids does not work properly so the entire microphone or camera TCC settings will be reset.  If you have multiple apps that require TCC, please consider the neccessity of this script.  Use at your own risk####

# This script can only succesfully reset the camera or microphone's TCC value with a logged in User
# Get current logged in user
loggedInUser=$(/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }')

# Get current logged in user's home directory
[[ "$loggedInUser" ]] && loggedInUser_home="$(/usr/bin/dscl /Local/Default read /Users/"$loggedInUser" NFSHomeDirectory | /usr/bin/awk '{print $2}')"

APPNAME="Skype for Business"

#You can only reset single app bundle id's starting with Catalina. All TCC Camera and Microphone approval values will need to be reset for OS's below Catalina
bundleID="com.microsoft.SkypeForBusiness"

#Check Os Version if Catalina - Add bundle id for app
versionCheck="$( sw_vers -productVersion | cut -d . -f 2 )"

if [[ "$versionCheck" -ge "15" ]];
then
	echo "macOS version is 10.$versionCheck so bundleID will be set"
function resetMicrophone(){
		su - $(stat -f%Su /dev/console) -c "/usr/bin/tccutil reset Microphone $bundleID"
}
function resetCamera(){
		su - $(stat -f%Su /dev/console) -c "/usr/bin/tccutil reset Camera $bundleID"
}
else
	echo "macOS version is 10.$versionCheck so all TCC Microphone or Camera values will be reset"
function resetMicrophone(){
		su - $(stat -f%Su /dev/console) -c "/usr/bin/tccutil reset Microphone"
}
function resetCamera(){
		su - $(stat -f%Su /dev/console) -c "/usr/bin/tccutil reset Camera"
}
fi

# Tests whether the app to be updated is closed - returns 1 if closed, or 0 if running
# If App is opened run command to prompt User to close
function is_app_running()
{
	#If app is running call on AppleScript
	/usr/bin/pgrep -q "$APPNAME"
	if [[ "$?" == "0" ]]; then
		echo "$APPNAME is running. Will prompt user for permission to close"
        show_update_alert
		wasOpen="Yes"
	fi
}

# AppleScript to alert the user that the app needs to close
#Will Autoclose after 10 Minutes (900)
function show_update_alert()
{
	/usr/bin/osascript <<-EOD
	tell application "Finder"
		activate
		set DialogTitle to "$APPNAME"
		set DialogText to "Skype needs to close to repair your $disabledMessgae permission.  Please select ***Allow*** when prompted to grant Skype for Business Access to your $disabledMessgae"
		set DialogButton to "Fix Now"
		set DialogIcon to "Applications:Skype for Business.app:Contents:Resources:AppIcon.icns"
		display dialog DialogText buttons {DialogButton} with title DialogTitle with icon file DialogIcon giving up after 900
	end tell
	EOD
	echo "Prompt has completed"
	forcibly_close_app
}

# Send the app a signal to forcibly close the process
function forcibly_close_app()
{
	echo "Closing $APPNAME"
	/usr/bin/pkill -HUP "$APPNAME"
}

function open_app()
{
if [ "$wasOpen" == "Yes" ];
then
	echo "Re-opening $APPNAME"
	sudo -u $(ls -l /dev/console | awk '{print $3}') open "/Applications/$APPNAME.app"
else
	exit
fi
}

if [[ -z "$loggedInUser" ]]; then
	echo "No Logged in User.  Exiting Script"
	exit
elif [ "${loggedInUser}" != "itadmin" ] || [ "${loggedInUser}" != "root" ] || [ "${loggedInUser}" != "" ]; then
	#Report 
	disabledValues=$(/usr/bin/sqlite3 "$loggedInUser_home/Library/Application Support/com.apple.TCC/TCC.db" 'SELECT service, client FROM access WHERE allowed = '0'' | grep "com.microsoft")
	IFS=" "
	#echo "<result>$disabledValues</result>"
	
	#Check if both Mic and Camera are disabled
	if [[ "$disabledValues" == *"kTCCServiceMicrophone|com.microsoft.SkypeForBusiness"* ]]&&[[ "$disabledValues" == *"kTCCServiceCamera|com.microsoft.SkypeForBusiness"* ]]; then
		disabledMessgae="Camera and Microphone"

	 	#Close Skype and reset permission
		is_app_running

		#Reset TCC
		resetMicrophone
		resetCamera
        echo "$disabledMessgae permission reset" 

		#Reopen App if it was previously open
		open_app
	
	#Check if Mic is disabled
	elif [[ "$disabledValues" == *"kTCCServiceMicrophone|com.microsoft.SkypeForBusiness"* ]];
	then
		disabledMessgae="Microphone"
		
			#Close Skype and reset permission
			is_app_running

			#Reset TCC Microphone
			resetMicrophone
            echo "$disabledMessgae permission reset" 
			#Reopen App if it was previously open
			open_app
	
	#Check if Camera is disabled
	elif [[ "$disabledValues" == *"kTCCServiceCamera|com.microsoft.SkypeForBusiness"* ]];
	then
		disabledMessgae="Camera"	
			#Close Skype and reset permission
			is_app_running

			#Reset TCC Camera
			resetCamera
			echo "$disabledMessgae permission reset" 

			#Reopen App if it was previously open
			open_app
	else
		echo "Permisions Okay"
		exit
	fi
	
fi