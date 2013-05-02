#!/bin/sh

#
# Copyright (c) 2013 Uli Fuchs <ufuchs@gmx.com>
# Released under the terms of the MIT License
#

cd "$(dirname "$0")"

BASE="$(pwd)"

BIN_DIR="$BASE/bin"
TMP_DIR="/tmp"

WEATHER_FILE_DIR="$TMP_DIR/weather"
WEATHER_FILE_NAME="weather.png"
WEATHER_FILE="$WEATHER_FILE_DIR/$WEATHER_FILE_NAME"
WEATHER_FILE_DOWNLOADED="$TMP_DIR/$WEATHER_FILE_NAME"

DIAGS_ACTIVE="$TMP_DIR/diags_active"

FLIGHTMODE_ON=1
WLAN_UNAVAILABLE=2
SERVICE_UNAVAILABLE=8
WEATHER_OUTDATED=16

FLIGHTMODE_ON_PNG="$BASE/img/flightmode-on.png"
WLAN_UNAVAILABLE_PNG="$BASE/img/wlan-unavailable.png"
SERVICE_UNAVAILABLE_PNG="$BASE/img/service-unavailable.png"
WEATHER_OUTDATED_PNG="$BASE/img/weather-outdated.png"

. "$BIN_DIR/weatherProperties.sh"
. "$BIN_DIR/platform.sh"

#
# @param1 weather file name
#
getFileAge () {

    fileName="$1"
    [ -e "$fileName" ] && echo "$(stat -c %Y $fileName)" || echo "0"

}

#
#
#
isWeatherFileOutDated () {

    local fileAge=$(getFileAge "$WEATHER_FILE")

    local to=$(getTodaysDayEnd)

    local from=$(($to - 86399))

    # 00:00:00 <= fileage <= 23:59:59 ? false : true
    ([ $from -le $fileAge ] && [ $fileAge -le $to ]) && echo 0 || echo 1

}

#
# calculate the next possible update interval to be at time at 00:10 o'clock
#
# @return int - time in seconds upto the next possible sync point
calcUpdateIntervall () {

    local to=$(getTodaysDayEnd)   #  last second of the current day in epoch
    
    local from=$(($to - 86399))   #  one day is equal to 86400 seconds.
                                  #  our day ends at 23.59:59
    
    local nextDayPlus600=$((to + 601))
                                  #  at 00:10:00 we would like to see the 
                                  #+ weather of the current day.

    local now=$(date +%s)         #  current timestamp in epoche
    local last=$nextDayPlus600
    while [ $((last - UPDATE_INTERVAL)) -gt $now ]; do
        last=$(($last - $UPDATE_INTERVAL))
                                  #  get the last possible update time before
                                  #+ now  
    done

    res=$(($now - $last))

    [ $res -le 0 ] && {
        # 22:20 > 21:20 
        res=$(($res * -1))
    } || {
        # 21:20 <= 18:10 
        res=$(($UPDATE_INTERVAL - $res))        
    }

    echo $res

}

# checks the availability of a weather file on server.
# this function doesn't provide any information if this weather file is 
# outdated or not!  
#
# @param1 string url  download url to the weatherfile
# @return integer   1, a weather file is available on server
#                   0, the weather file doesn't exist  
#
isServiceAvailable () {

    local CURL_ARGS="-s -I $URL"
    curl $CURL_ARGS | head -n1 | grep -i 200 >/dev/null 2>&1
    echo $?

}

#
#
#
getWeatherfile () {

    local CURL_ARGS="-s -o $WEATHER_FILE_DOWNLOADED $URL"

    curl $CURL_ARGS # >/dev/null 2>&1

    local res=$?

    ([ $res -eq 0 ] && [ -s "$WEATHER_FILE_DOWNLOADED" ]) && {

        cp "$WEATHER_FILE_DOWNLOADED" "$WEATHER_FILE"

    }

    echo $res

}

#
#
#
checkPrerequests () {

    local res=0

    [ $(isAeroplaneModeOn) -eq 1 ] && {
        res=$FLIGHTMODE_ON
    }

    [  $(isWlanAvailable) -eq 0 ] && {
        res=$WLAN_UNAVAILABLE
    }

    [ $(isServiceAvailable "$URL") -ne 0 ] && {
        res=$SERVICE_UNAVAILABLE
    }

    echo $res

}

#
# @param1 integer errorCode
# @return string - filename of info image
#
errCodeToImgFilename () {

    case "$1" in

        $FLIGHTMODE_ON )
            echo "$FLIGHTMODE_ON_PNG"
            ;;
        $WLAN_UNAVAILABLE )
            echo "$WLAN_UNAVAILABLE_PNG"
            ;;
        $SERVICE_UNAVAILABLE )
            echo "$SERVICE_UNAVAILABLE_PNG"
            ;;
        $WEATHER_OUTDATED )
            echo "$WEATHER_OUTDATED_PNG"
            ;;
    esac

}

#
#
#
printInfoScreen () {
    local imgFilename="$(errCodeToImgFilename $1)"
    printScreen "$imgFilename"   # print the info PNG
}

#
#
#
init () {

    weatherProperties_init "$BASE/weather.conf"

    # Location aus conf-File wandeln
    URL="http://$DOWNLOAD_IP"

    mkdir -p "$WEATHER_FILE_DIR" > /dev/null

}

################################################################################
# entry
################################################################################

set -x

START=0
CHECK_PRE=3
CHECK_OUTDATED=4
FAILED=6
DOWNLOAD=9
PRINTSCREEN=12
WAIT=15

STATE=$START

while :; do

    case $STATE in

        # read env
        $START )

            init

            STATE=$CHECK_PRE
            ;;

        # check network connectivity
        $CHECK_PRE )

            res=$(checkPrerequests)

            [ $res -eq 0 ] && {
                STATE=$DOWNLOAD
            } || {

                # at least one pre request failed.
                [ ! -e "$DIAGS_ACTIVE" ] && {
                    STATE=$CHECK_OUTDATED            
                } || {
                    # run once in 'diag' mode
                    printInfoScreen $res
                    STATE=$WAIT
                }

            }

          ;;

        # check the expire date of weather file
        $CHECK_OUTDATED )

            [ $(isWeatherFileOutDated) -eq 0 ] && {
                STATE=$PRINTSCREEN           # weather file still valid
            } || {
                printInfoScreen $WEATHER_OUTDATED
                sec=$(calcUpdateIntervall)
                STATE=$WAIT
            }
            ;;

        # download the weather file
        $DOWNLOAD )

            [ $(getWeatherfile) -eq 0 ] && {
                STATE=$PRINTSCREEN
            } || {
                STATE=$CHECK_OUTDATED
            }  
            ;;

        # draw the weather file
        $PRINTSCREEN )
            printScreen "$WEATHER_FILE"
            sec=$(calcUpdateIntervall)
            [ "$INDICATORS" -gt 0 ] && {
                printBatteryIndicator
                printAdjustedUpdateInterval "$sec"
            }
            STATE=$WAIT
            ;;

        # take a nape
        $WAIT )

            $WAITSTRATEGY $sec

            STATE=$CHECK_PRE
            ;;

    esac

done
