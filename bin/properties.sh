#
# Copyright (c) 2012 Uli Fuchs <ufuchs@gmx.com>
# Released under the terms of the GNU GPL v2.0.
#

PROPERTIES='properties'

#
# Gets the key name of a key/value pair
# @param $1	the key/value pair
# qreturn	the key name of the key/value pair
getKey () {
  echo ${1%%=*}
}

#
# Gets the value of a key/value pair
# @param $1	the key/value pair
# qreturn	the value of the key/value pair
getValue () {
  echo "${1#*=}"
}

#
# Gets the value of a property by a given key
# @param $1	key name of the property
# @return	value of the property
getPropertyValue () 
{

  local i=0
  local propCount=$(eval echo \$$PROPERTIES${i})
                                     #  fetch the number of lines.
                                     #  be aware to substitute 'i' with 0
  local property
  i = 0
  while [ $i -le $propCount ]; do

    property=$(eval echo \$$PROPERTIES${i})

    [ "$1" = "$(getKey "$property")" ] && {
      echo "$(getValue "$property")"
      break
    }

    i=$((i+1))

  done

}

# 
# Loads the content from a property file into an array named 'PROPERTIES'.
# An element in the array represents a single line from the property file.
# In the form 'KEY=VALUE
#
# @param $1	name of the property file
loadProperties () 
{

  #  add a trailing linefeed at the end of file if missing.
  #  background:
  #  if you forgot to press ENTER on the last line of the conf script
  #+ you will get an empty value later.
  #  sed -i -e '$a\' "$1"

  local is="$1"

  local i=1

  while read line; do

    # 1.remove all leading whitespaces
    # 2 remove all comments
    # 3.remove all trailing whitespaces
    line=$(echo $line | sed -e 's/^[ 	]*//g' -e 's/#.*//' -e 's/[ 	]*$//g')
    #                               ^
    #                               |  this is a space and a tab because the sed on 
    #                               |+ Mac OS 10.7 doesn't recognize a '\t'

    [ ${#line} -eq 0 ] && continue  # skip the now eventually empty lines

    eval ${PROPERTIES}${i}="'$line'"

    i=$((i + 1))

  done < "$is"                       # the input comes from here...

  eval ${PROPERTIES}0="'$((i - 1))'"
                                     # write the number of lines

}
