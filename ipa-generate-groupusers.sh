#!/bin/bash

######################################
#        ipa-generate-userlist       #
######################################
# Import local accounts into FreeIPA #
# https://shellonearth.net           #
# Creation date: 20150917            #
# Last modified: 20161129            #
######################################
# Resources
# http://www.server-world.info/en/note?os=Fedora_18&p=ipa
# http://stackoverflow.com/questions/1521462/looping-through-the-content-of-a-file-in-bash
# http://stackoverflow.com/questions/4168371/how-can-i-remove-all-text-after-a-character-in-bash
# https://shellonearth.net/import-local-accounts-in-freeipa-rhelcentos/



## Variables
# Password file to read
PASSWORD=/root/passwd.oldhost

# Shadow file to read. This must at least have read permissions (default shadow does not)
SHADOW=/root/shadow.oldhost

# Group file to read.
GROUP=/root/group.oldhost

# FreeIPA administrative account
IPAADMIN=admin

# Exclude these users
EXCUSERS=('nfsnobody','nobody')

# Include these groups even if they have no members
INCPVTGPS=('wheel') # For RHEL systems where root's primary group is root but wheel exists with no members

# Lowest non-system account uid
LOWERBOUND=1000

create_users() {
  IFS=$'\n'

  for line in $SORTED ; do

    USER=$(echo $line | cut -d: -f1)
    # Skip this iteration of the loop if this user was excluded
    for i in "${EXCUSERS[@]}" ; do
      if [[ $line == "$i"* ]] ; then
        CONT=1
      else
        CONT=0
      fi
    done
    if [[ $CONT -eq 1 ]] ; then
      continue
    fi

    UUID=$(echo $line | cut -d: -f3)

    GID=$(echo $line | cut -d: -f4)

# Special code for a special circumstance
#    [[ $UUID =~ 00$ ]] && GIDOPT=--noprivate || GIDOPT=""

    FIRST=$(echo $line | cut -d: -f5 | awk {'print $1'})
    if [ -z "$FIRST" ] ; then
      FIRST=$USER
    fi

      if echo $line | grep -q ")\|]" ; then # If there are details in parenthesis or brackets, cut them out
        LAST=$(echo $line | cut -f1 -d"(" | cut -f1 -d"[" | awk 'NF > 1 {print $NF}')
      else
        LAST=$(echo $line | cut -d: -f5 | awk 'NF > 1 {print $NF}')
      if [ -z "$LAST" ] ; then
      LAST=.
      fi
    fi

    FULL="$(echo $line | cut -d: -f5)"
    if [ -z "$FULL" ] ; then
      FULL="$FIRST $LAST"
    fi

    CRYPT="$(grep ^${USER}: $SHADOW | cut -d: -f2)"

  ##This was for testing the variables
    echo "ipa user-add $USER --first=\"$FIRST\" --last=\"$LAST\" --cn=\"$FULL\" --displayname=\"$FULL\" --uid=$UUID --gidnumber=$GID $GIDOPT --setattr userpassword='{crypt}$CRYPT'"

    #ipa user-add $USER --first="$FIRST" --last="$LAST" --cn="$FULL" --displayname="$FULL" --uid=$UUID --gidnumber=$GID --setattr userpassword='{crypt}$CRYPT'

    echo -e "----------------------------------------------------\n"
  done
}

create_groups() {
  IFS=$'\n'

  for line in $GROUPSORT ; do
    GROUP=$(cut -d: -f1 <<< $line)
    GID=$(cut -d: -f3 <<< $line)
    CONT=0
    for f in $PVTGROUPS ; do
        USER=$(echo $line | cut -d: -f1)
    # Skip this iteration of the loop if this user was excluded
        for i in "${INCPVTGPS[@]}" ; do
            [[ $GROUP == "$i"* ]]
            CONT=$?
        done
        if [[ $CONT -eq 1 ]] ; then
            continue
        fi
    done
    [[ CONT -eq 1 ]] && continue
    #ipa group-add $GROUP --gid=$GID --desc=$GROUP
    echo ipa group-add $GROUP --gid=$GID --desc=$GROUP
  done
}

add_users_to_groups() {
  for line in $GROUPSORT ; do
    GROUP=$(cut -d: -f1 <<< $line)
    USERS=$(cut -d: -f4 <<< $line)
    for user in ${USERS/,/ } ; do
      CONT=0
      for f in $EXCUSERS ; do
        [[ $USER = $f ]] && CONT=1
      done
      [[ $CONT -eq 1 ]] && continue
      #ipa group-add-member $GROUP --users={$USERS}
      echo ipa group-add-member $GROUP --users={$USERS}
    done
  done
}

## Works starts here

# Check system for ipa server packages. IPA server package is named freeipa-server on Fedora 25.
if ! which ipa > /dev/null ; then
  echo "This server doesn't even have ipa-server installed"
  exit 1
fi

# Become IPA admin so we can add users
#kinit $IPAADMIN
echo kinit $IPAADMIN
#ipa config-mod --enable-migration=true
echo ipa config-mod --enable-migration=true

SORTED=$(grep -v '^#' $PASSWORD | awk -F: -v LOWERBOUND=$LOWERBOUND '$3 > LOWERBOUND {print}')
GROUPSORT=$(grep -v '^#' $GROUP | awk -F: -v LOWERBOUND=$LOWERBOUND '$3 > LOWERBOUND {print}')
PVTGROUPS=$(grep -v '^#' $GROUP | awk -F: '$4 ~ /^$/ {print $3}')
#echo $PVTGROUPS;exit

create_groups
create_users
add_users_to_groups

#ipa config-mod --enable-migration=false
echo ipa config-mod --enable-migration=false
