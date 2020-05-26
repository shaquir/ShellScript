Background: As many of you may be aware, the Screen Recording option can only be enable by a physical user on a Mac.  To work around this limitation set by Apple, I have created this workflow to prompt users to enable the Screen Recording option for the required App (Currently set to Slack, but can be easily modified).  You can check out how I similarly addressed the Camera and Microphone issue here: https://www.jamf.com/jamf-nation/discussions/35301/automatically-reset-teams-camera-and-microphone-for-user

Solution: I created this Script to check if an Application's Screen Recording permission has been set to enabled in the TCC Security and Privacy.  If the TCC option is disabled, it will open System Preferences > Security & Privacy > Screen Recording and prompt the user to enable the App

Jamf Workflow

Extension Attribute
Name: Disabled System TCC Values

Script:
Run this Extension Attribute to report all the disabled System TCC values:


Smart Group:
Name: AppName ScreenSharing Disabled

Criteria:

Disabled Disabled System TCC Values is not <Leave Blank>
And
Disabled System TCC Values like kTCCServiceScreenCapture|com.tinyspeck.slackmacgap

Policy:

Name: Prompt User to enable AppName ScreenSharing

Frequency: Once every day

Trigger: Check-in

Scope: AppName ScreenSharing Disabled

Script: 
