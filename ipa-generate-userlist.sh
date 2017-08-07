#!/bin/bash

######################################
#        ipa-generate-userlist       #
######################################
# Import local accounts into FreeIPA #
# https://github.com/JoeWalters      #
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
PASSWORD=/tmp/passwd

# Shadow file to read. This must at least have read permissions (default shadow does not)
SHADOW=/tmp/shadow

# FreeIPA administrative account
#IPAADMIN=admin

# Exclude these users
EXC=('nfsnobody')

## Works starts here

# Check system for ipa server packages. IPA server package is named freeipa-server on Fedora 25.
#if [ ! rpm -q ipa-server ]; then
#echo "This server doesn't even have ipa-server installed"
#exit 1
#fi

# Become IPA admin so we can add users
#kinit $IPAADMIN

SORTED=$(awk -F: '{if ($3 >= 1000) print}' < $PASSWORD)
IFS=$'\n'

for line in $SORTED
  do

  USER=$(echo $line | cut -d: -f1)
  # Skip this iteration of the loop if this user was excluded
  for i in "${EXC[@]}"; do
  if [[ $line == "$i"* ]]; then
    CONT=1
  else
    CONT=0
  fi
  done
  if [[ $CONT -eq 1 ]]; then
    continue
  fi

  UUID=$(echo $line | cut -d: -f3)

  GID=$(echo $line | cut -d: -f4)

  FIRST=$(echo $line | cut -d: -f5 | awk {'print $1'})
  if [ -z "$FIRST" ]; then
    FIRST=$USER
  fi

    if echo $line | grep -q ")\|]"; then # If there are details in parenthesis or brackets, cut them out
      LAST=$(echo $line | cut -f1 -d"(" | cut -f1 -d"[" | awk {'print $NF'})
    else
      LAST=$(echo $line | cut -d: -f5 | awk {'print $NF'})
    if [ -z "$LAST" ]; then
    LAST=$USER
    fi
  fi

  FULL="$(echo $line | cut -d: -f5)"
  if [ -z "$FULL" ]; then
    FULL="$FIRST $LAST"
  fi

  CRYPT="$(grep $USER $SHADOW | cut -d: -f2)"

##This was for testing the variables
  echo "ipa user-add $USER --first=$FIRST --last=$LAST --cn=\"$FULL\" --displayname="$FULL" --uid=$UUID --gidnumber=$GID --setattr userpassword='{crypt}$CRYPT'"

  #ipa user-add $USER --first=$FIRST --last=$LAST --cn="$FULL" --displayname="$FULL" --uid=$UUID --gidnumber=$GID --setattr userpassword='{crypt}$CRYPT'

  echo "----------------------------------------------------
"
done
