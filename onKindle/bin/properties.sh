#
# Copyright (c) 2012 Uli Fuchs <ufuchs@gmx.com>
# Released under the terms of the GNU GPL v2.0.
#

KEY_NOT_FOUND=100

PROPERTIES='properties'
KEYSET='keyset'

#declare -a PROPERTIES
#declare -a KEYSET

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
# checks if a list of keys contains a particular key
# @param $1	list of keys
# @param $2	key in question
# @return	true if list contains the key in question
#
containsKey () {
  
  local keys="$1"
  local keyInQuestion="$2"
  local found=0

  local i=0
  local count=$(echo $(eval echo \$$keys${i}))
                                     # fetch the number of lines
  i=1
  while [ $i -le $count ]; do

    [ "$keyInQuestion" = "$(eval echo \$$keys${i})" ] && {
      found=1
      break
    }

    i=$((i+1))

  done

  echo "$found"

}

#
# Gets the value of a property by a given key
# @param $1	key name of the property
# @return	value of the property
getPropertyValue () 
{

  local i=0
  local count=$(eval echo \$$PROPERTIES${i})
                                     # fetch the number of lines
  local property
  i=1
  while [ $i -le $count ]; do

    property=$(eval echo \$$PROPERTIES${i})

    [ "$1" = "$(getKey "$property")" ] && {
      echo "$(getValue "$property")"
      break
    }

    i=$((i+1))

  done

}

# 
# Loads the content from PROPERTY_FILENAME into an array named 'PROPERTIES'.
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

  # populate the KEYSET
  i=0
  local count=$(eval echo \$$PROPERTIES${i})
                                     # fetch the number of lines
  local property
  i=1
  while [ $i -le $count ]; do

    property=$(eval echo \$$PROPERTIES${i})

    eval ${KEYSET}${i}="'$(getKey "$property")'"

    i=$((i+1))

  done
  eval ${KEYSET}0="'$((i - 1))'"
                                     # write the number of lines

}
