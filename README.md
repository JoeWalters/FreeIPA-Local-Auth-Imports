# FreeIPA-Local-Auth-Imports
Import local users/groups/passwords using passwd/shadow/group

One of the biggest problems when trying to upgrade existing infrastructure to central authentication is importing the users in order to minimize interruption. The following is a BASH script to import users and their corresponding password into FreeIPA.

This script is intended to be run on the FreeIPA server. This script was tested on RHEL 6.7 and Fedora 25. Run at your own risk. I recommend running the troubleshooting script first to make sure the right users are being detected and that the script appears to be working for you.

Expected passwd file format:
user1:x:1001:1001:User one:/home/user1:/bin/bash
The script is expecting the 5th field (GECOS) to contain FIRSTNAME LASTNAME. If this information isn’t populated, it’s going to make the first name, last name, and full name the user name.

Script prep:
1. Download or copy script from below to your FreeIPA server.
2. Copy the /etc/passwd and /etc/shadow with existing users to the FreeIPA server and ensure they have a minimum of read permissions.
3. Set the PASSWORD/SHADOW location variables in the script.
4. Set/Verify IPAADMIN variable in the script (FreeIPA administrative account).
5. Set/Verify EXC variable in the script. This is an array of the users that should NOT be imported. This is formatted in the following way: EXC=('nfsnobody' 'user1' 'user2')
6. Make script executable: chmod 750 ipa-import-local.txt
7. Migration mode must be enabled to import passwords from the shadow file: ipa config-mod –enable-migration=true

Warnings:
1. The script will create users and set the same password as was set in the /etc/shadow file.
2. All accounts with a 1000 or greater will be imported.
3. The only user prompt is for the IPA admin’s password (This user is defined in script prep).
