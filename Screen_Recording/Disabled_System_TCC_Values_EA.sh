#!/bin/bash
#Extension Attribute reports disabled system level TCC values
#Shaquir Tannis 5-26-2020

#Report Machine's disabled TCC values (Note, this does not include user level TCC results, i.e. Camera and Microphone)
disabledValues=$(/usr/bin/sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" 'SELECT service, client FROM access WHERE allowed = '0'')
echo "<result>$disabledValues</result>"

