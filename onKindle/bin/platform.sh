#!/bin/sh

#
# Copyright (c) 2013 Uli Fuchs <ufuchs@gmx.com>
# Released under the terms of the GNU GPL v2.0.
#

#
# Some kind of strategy pattern to handle the variations 
# of the development platform and the KINDLE device
# 

#
# determines the platform we are running on
#
[ $(hostname) = "kindle" ] && {
	PLATFORM="onKindle" 
} || {
	PLATFORM="onHost"
}

################################################################################
# platform depending functions
################################################################################

#
#
#
getTodaysDayEnd_onHost () {

	local todaysDate=$(date +%Y-%m-%d)
	local end=$(date -d "$todaysDate 23:59:59 +0100" +%s)
	echo $end
}

#
#
#
getTodaysDayEnd_onKindle () {

	local todaysDate=$(date +%Y-%m-%d)
	local end=$(date -D %Y-%m-%dT%H%M%S -d "$todaysDate"T235959 +%s)
	echo $end
}

#
#
#
isAeroplaneModeOn_onHost () {
	echo 0    # on host platform always switched off
}

#
#
#
isAeroplaneModeOn_onKindle () {

 	[ ! -d "/sys/class/net/wlan0" ] && {
 		echo 1  # 'wlan0' directory doesn't exist in 'Aeroplane mode'
	} || {
		echo 0
	}
	
}

#
#
#
isWlanAvailable_onHost () {
	echo 1    # on host platform always switched on
}

check_wireless_connected()
{
	for i in `seq 3` ; do
		if [ -n "$(lipc-get-prop com.lab126.wifid cmState | grep CONNECTED)" ] ; then
			return 0
		fi
		sleep 10
	done
	ltp_print INFO "wifi is not connected"
	stoptest
	return 1
}

#
#
#
isWlanAvailable_onKindle () {

	# /home/ufuchs/workspace/OFFICIAL-H2-Yoshi/kindle-backup/mmcblk0p1/test/unit_tests/common.sh

	# lipc-get-prop com.lab126.wifid profileCount
	# echo "{index = (0)}" | lipc-hash-prop com.lab126.wifid profileData

	# lipc-get-prop com.lab126.powerd isCharging
	# lipc-set-prop -i com.lab126.powerd preventScreenSaver 1
	# lipc-get-prop com.lab126.powerd state

	# echo "{index = (0)}" | lipc-hash-prop -n com.lab126.wifid currentEssid
	# lipc-get-prop com.lab126.wifid cmState

    # lipc-get-prop com.lab126.cmd activeInterface

	[  "$(cat /sys/class/net/wlan0/operstate)" == "up" ] && {
		echo 1  # operstate == up
	} || {
		echo 0  # operstate == down
	}

}

#
#
#
printScreen_onHost () {
	echo
#	eog "$1"  >/dev/null 2>&1 &
}

#
#
#
printScreen_onKindle () {
	eips -c
	eips -f -g "$1"
}

#
#
#
printBatteryIndicator_onHost () {
	echo "Batt: 100"
}

#
# left lower corner
#
printBatteryIndicator_onKindle () {

	#  path to battery properties
	local battery="/sys/devices/system/yoshi_battery/yoshi_battery0"

	# capacity in procent
	# lipc-get-prop com.lab126.powerd battLevel
	local capacity=$(cat "$battery"/battery_capacity) 
	# line=$(echo $line | sed -e 's/^[ 	]*//g' -e 's/#.*//' -e 's/[ 	]*$//g')

	#  remove trailing percent sign.
	#  this percent sign causes an interruption in the output and cut off the remaining string.
	capacity=${capacity%%\%*}

	local curr=$(cat "$battery"/battery_current)
	eips 1 39 "Batt:          "
	eips 1 39 "Batt: $capacity/$curr"mA

}

#
#
#
printWlanIndicator_onHost () {
	echo "Wlan: aus"
}

#
# rigth lower corner
#
printWlanIndicator_onKindle () {

	local state="aus"

	#  TODO : Rename 'isWlanAvailable' to 'isWlanOperstateUp' 
	#  'Aeroplane Mode' is switched off &&
	#  'wlan0/operstate' is 'up'
	([ $(isAeroplaneModeOn) -eq 0 ] && [ $(isWlanAvailable) -eq 1 ]) && {
		state="ein"
	}

	eips 40 39 "Wlan:    "
	eips 40 39 "Wlan: $state"	

}

#
#
#
printAdjustedUpdateInterval_onHost () {
	echo "Wait: $1"
}

#
# rigth lower corner
#
printAdjustedUpdateInterval_onKindle () {
	eips 38 39 "Wait:      "
	eips 38 39 "Wait: $1"	
}

#
#
#
waitBySuspend_onHost () {
	sleep "$1"
}

#
#
#
isAR6003Loaded () {
	grep -i ar6003 -q /proc/modules
	echo $?
}

#
#
#
waitBySuspend_onKindle () {

	# lipc-set-prop com.lab126.powerd rtcWakeup $suspend_length_left

    echo -n "$1" > /sys/devices/platform/mxc_rtc.0/wakeup_enable
    sleep 5
	echo mem > /sys/power/state

	###
	# post wait
	###
	sleep 10

	local i=0
	# /usr/sbin/updatewait
    #if /usr/sbin/setdate $(date -u -D "%d %b %Y %T %Z" +%s -d "${_WEBDATE}"); then

	while [ $(isAR6003Loaded) -ne 0 ]; do
		sleep 1
		i=$(($i + 1))
	done;

}

#
#
#
waitBySleep_onHost () {
	sleep "$1"
}

#
#
#
waitBySleep_onKindle () {
	lipc-set-prop com.lab126.wifid enable 0
	sleep "$1"
	lipc-set-prop com.lab126.wifid enable 1
	sleep 10
}

###############################################################################
# public functions
###############################################################################

# checks the state of 'Aeroplane mode' on Kindle
#  
# @return integer   1, if 'Aeroplane mode' is on or
#                   0, if 'Aeroplane mode' is off 
#
isAeroplaneModeOn () {
	isAeroplaneModeOn_"$PLATFORM"
}

# checks the state of the wlan module on Kindle.
# this means, the wlan is switched on but is there any connection to a wlan 
# router? 
#
# @return integer   1, the Kindle has a connection to a wlan
#                   0, the Kindle has not a connection to a wlan 
isWlanAvailable () {
	isWlanAvailable_"$PLATFORM"
}

# checks the availability of a weather file on server.
# this function doesn't provide any information if this weather file is 
# outdated or not!  
#
# @param1 string url  download url to the weatherfile
# @return integer   1, a weather file is available on server
#                   0, the weather file doesn't exist  
#
#isServiceAvailable () {
#	isServiceAvailable_"$PLATFORM" "$1"
#}

#
#
#
getTodaysDayEnd () {
	getTodaysDayEnd_"$PLATFORM"
}

# prints a PNG file onto the screen
#
# @param1 string PNG file name
#
printScreen () {
	printScreen_"$PLATFORM" "$1"
}

#
#
#
printBatteryIndicator () {
	printBatteryIndicator_"$PLATFORM"
}	

#
#
#
printWlanIndicator () {
	printWlanIndicator_"$PLATFORM"	
}

#
#
#
printAdjustedUpdateInterval () {
	printAdjustedUpdateInterval_"$PLATFORM" "$1"
}

#
#
#
waitBySuspend () {
	waitBySuspend_"$PLATFORM" "$1"
}

#
#
#
waitBySleep () {
	waitBySleep_"$PLATFORM" "$1"
}


