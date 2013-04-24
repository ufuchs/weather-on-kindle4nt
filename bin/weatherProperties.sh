#!/bin/sh

#
# Copyright (c) 2012 Uli Fuchs <ufuchs@gmx.com>
# Released under the terms of the MIT License
#

#
# used properties
#
KEY_DOWNLOAD_IP="downloadIP"
KEY_UPDATE_INTERVAL="updateInterval"
KEY_INDICATORS="indicators"
KEY_WAITSTRATEGY="waitStrategy"

# server IP for download the weatherfile
DOWNLOAD_IP=

# update interval in seconds
UPDATE_INTERVAL=

#  debug flag  0, no debug output
#              1, prints battery capacity and current into the
#                 left upper edge of the screen
#                 and
#                 prints wlan state into the
#                 right lower edge of the screen
INDICATORS=

WAITSTRATEGY=

. "$BIN_DIR/properties.sh"

#
# @param1 - time range, e.g. '06:00'
#
weatherProperties_getUpdateIntervalInSec_local () {

	local min=${1#*:}		# separate the minutes
	min=${min#0*}			# remove leading zero from min

	local hour=${1%%:*}		# separate the hours
	hour=${hour#0*}			# remove leading zero from hour

	local secByHour=$(($hour * 3600))
	local secByMin=$(($min * 60))

	echo $((secByHour + secByMin))

}

#
# @param1 - property file name
#
weatherProperties_init () {

	loadProperties "$1"

	DOWNLOAD_IP=$(getPropertyValue "$KEY_DOWNLOAD_IP")

	local updateInterval=$(getPropertyValue "$KEY_UPDATE_INTERVAL")
	UPDATE_INTERVAL="$(weatherProperties_getUpdateIntervalInSec_local "$updateInterval")"

	INDICATORS=$(getPropertyValue "$KEY_INDICATORS")
	[ -z $INDICATORS ] && { 
		INDICATORS=0
	}

	WAITSTRATEGY=$(getPropertyValue "$KEY_WAITSTRATEGY")

}
