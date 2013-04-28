#!/bin/sh

#
# Copyright (c) 2013 Uli Fuchs <ufuchs@gmx.com>
# Released under the terms of the MIT License
#

set -x

# prevents an instantaneous re-run after pressing the center of the 5way keypad 
WEATHER_ACTIVE=/tmp/WEATHER_ACTIVE

cd "$(dirname "$0")"

#
# determines the platform we are running on
#
[ $(hostname) = "kindle" ] && {
	PLATFORM="onKindle" 
} || {
	PLATFORM="onHost"
}

#
#
# @see http://stackoverflow.com/questions/392022/best-way-to-kill-all-child-processes
#
killtree () {

    local _pid=$1

    local _sig=${2-TERM}	#  default is SIGTERM

    kill -stop ${_pid}		#  needed to stop quickly forking parent from 
    						#+ producing child between child killing and 
    						#+ parent killing

    for _child in $(ps -o pid --no-headers --ppid ${_pid}); do

        killtree ${_child} ${_sig}

    done

    kill -${_sig} ${_pid}
}

#
#
#
launch_onHost () {

	./weather.sh &

	wpid=$(pgrep weather.sh)

	echo "Hit any key $wpid :"
	read x

	killtree "$wpid" "KILL"

}

#
#
#
launch_onKindle () {
	
	[ -f $WEATHER_ACTIVE ] && {
		# skip over to prevent an instantaneous re-run
		exit	
	}

	###
	# prepare
	###

	touch $WEATHER_ACTIVE

	local activeInterface=`lipc-get-prop com.lab126.cmd activeInterface` 

	lipc-set-prop -i com.lab126.powerd preventScreenSaver 1

	killall -STOP cvm

	###
	# run weather
	###

	./weather.sh &

	wpid=$(pgrep weather.sh)

	waitforkey

	###
	# resume
	###

	killtree "$wpid" "KILL"
	
	killall -CONT cvm
	
	[ "$activeInterface" == "wifi" ] && {

		local cmState=`lipc-get-prop com.lab126.wifid cmState`

		[ "$cmState" == "NA" ] && {
			lipc-set-prop com.lab126.wifid enable 1
		}	
		
	}

	lipc-set-prop -i com.lab126.powerd preventScreenSaver 0

	# pressing the 'Home' button
	echo "send 101" > /proc/keypad

	# fade away any pressing of the center of the 5way keypad 
	sleep 3

	rm $WEATHER_ACTIVE

}

###############################################################################
# public functions
###############################################################################

launch_"$PLATFORM"

