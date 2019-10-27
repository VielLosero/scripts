#!/bin/bash
#Copyright (c) 2019 Viel Losero
#All rights reserved.
#
#MIT License.
#Begin license text.
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"),
#to deal in the Software without restriction, including without limitation the rights to use,
#copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
#and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all copies
#or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
#INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
#IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
#DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
#ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#End license text.
#https://opensource.org/licenses/MIT


########################################
# Script configuration parameters
########################################

## Backup dir
## That dir will have a profile firefox backup of your user, the downloaded addons and the downloaded user.js files.
backup_dir=${HOME}/.mozilla/firefox_backup

## Run as user
## if user = null then firefox will run with the user u launch the script.
## if user != null then create and delete a new user, dir and run firefox as that user. If u run the script again it will stop firefox and delete all files and dirs from that user and will delete the user. Hard clean.
user=null

## Addons installation
## addons to install
addons=(https://addons.mozilla.org/firefox/downloads/file/3412681/ublock_origin-1.22.4-an+fx.xpi\
	https://addons.mozilla.org/firefox/downloads/file/3423038/decentraleyes-2.0.13-an+fx.xpi\
	)
## Addons install dir
## https://extensionworkshop.com/documentation/publish/distribute-sideloading/#standard-extension-folders
## for user only installation change addons_install_dir to default user dir: /home/$user/.mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/
## for all users installation change addons_install_dir to defautl firefox lib dir: /usr/lib/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/
#addons_install_dir=/home/$user/.mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}
addons_install_dir=/usr/lib/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/

## base user.js
user_js=https://raw.githubusercontent.com/pyllyukko/user.js/master/user.js

########################################
# control file to test if we run as user 
########################################
control() {
# Control file to test if diferent user are running
if [ -f /home/$user/control-file-00 ] 
then
	return 1
else
	return 0
fi
}

########################################
# Stop firefox from isolated user
########################################
stop_user() {
	pkill -u $user && echo "[ok] Process of user $user stoped" # stoping process for user 
	#pgrep -u $user -l
	sleep 1
	userdel -r $user 2>/dev/null && echo "[ok] Home folder of user $user deleted" # deleting user
	while [ -d /home/$user ] # if cant delete because process running, sleep and try again
	do
		sleep 2
		pkill -u $user && echo "[ok] Force process of user $user to stop" # stoping process for user 
		#pgrep -u $user -l
		userdel -r $user 2>/dev/null && echo "[ok] Force deletion of user $user home folder " # deleting user
	done
}


########################################
# Start firefox from isolated user
########################################
start_user() {
	if [ -d /home/$user ] # testing if user exist and exit
	then 
		echo "[!] User exist: Delete user (userdel -r user) if u know what are u doing." && echo "[*] Exiting!!" && exit
	fi
	useradd -m $user && echo "[ok] User $user created successfully" # create user, cp files, and launch firefox
	touch /home/$user/control-file-00

	/bin/bash -c "sudo -u $user -H firefox" & # fisrt launch for create folders, then kill
	sleep 1
	pkill -u $user
	# configuring files
	rm /home/$user/.mozilla/firefox/*.default/prefs.js
	#rm /home/test/.mozilla/firefox/*.default/search.json.mozlz4
	cd  /home/$user/.mozilla/firefox/*.default/
	cp $backup_dir/user.js user.js && echo "[*] User.js copied to user $user firefox profile folder"
	install_user_addons
	echo "[*] Start firefox as $user" && /bin/bash -c "sudo -u $user -H TZ=UTC firefox " & 
	exit
}


########################################
# Make backup user profiles 
########################################
backup() {
# creating backup dir
if [ -d $backup_dir ]
then 
	echo "[ok] Backup dir exist"
else
	mkdir -p $backup_dir && echo "[*] Bachup dir created" || exit 1
fi

# backup user firefox profiles
IFS=":" # if profile have spaces ...
profiles=$(sed -n -e 's/Path=//p' ${HOME}/.mozilla/firefox/profiles.ini | awk '{printf "%s:",$0}')
for profile in ${profiles[@]}
do
	if [ -d $backup_dir/$profile ]
	then
		echo "[ok] Backup \"$profile\" profile exist"
	else
		cp -r ${HOME}/.mozilla/firefox/$profile $backup_dir/$profile  && echo "[*] Firefox \"$profile\" profile Backup done" 
	fi
done
}

########################################
# Download addons and user.js if needed
########################################
download() {
IFS=""
# download addons if not exist
if [ -d $backup_dir/addons ]
then 
	echo "[ok] Addons dir exist"
else
	mkdir $backup_dir/addons && echo "[*] Addons dir created" || exit 1
fi

cd $backup_dir/addons

for addon_url in ${addons[@]}
do
	addon=$(echo $addon_url | awk -v FS=/ '{print $8}')
	if [ -f $addon ]
	then 
		echo "[ok] Addon $addon bakup exist"
	else
		wget -q $addon_url && echo "[*] Downloaded $addon" || exit 1
	fi
done

# download user.js if not exist
cd $backup_dir
if [ -f user.js ]
then 
	echo "[ok] User.js backup exist"
else
	wget -q $user_js && echo "[*] Downloaded user.js" || exit 1
fi

}

########################################
# Installing addons loop
########################################
install_addons() {
cd $backup_dir/addons
for addon in $backup_dir/addons/* 
do 
	# Test if addon exist
	xpi=$(unzip -c $addon manifest.json | grep '"id"' | awk '{print $2}'| sed 's/[",]//g').xpi
	if [ -f $addons_install_dir/$xpi ]
	then
		echo "[ok] Addon $xpi installed"
	else
		echo "[*] Copied addon - id $(unzip -c $addon manifest.json | grep '"id"' | awk '{print $2}'| sed 's/[",]//g') to $addons_install_dir"
		cp $addon $addons_install_dir/$xpi
	fi
done

}

########################################
# Installing addons only for one user
########################################
install_user_addons(){	
if [ $addons_install_dir == /home/$user/.mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384} ]
then
	if [ ! $user == null  ]
	then
		#changing dir install to .mozilla/firefox/profile/extensions
		profile=$(sed -n -e 's/Path=//p' /home/$user/.mozilla/firefox/profiles.ini)
		mkdir /home/$user/.mozilla/firefox/$profile/extensions
		addons_install_dir=/home/$user/.mozilla/firefox/$profile/extensions
		install_addons
		chown -R -f $user:$user /home/$user/.mozilla/firefox/$profile/extensions
	else
		#changing dir install to .mozilla/firefox/profile/extensions
		profile=$(cat  ${HOME}/.mozilla/firefox/profiles.ini | grep Default=1 -B1 | sed -n -e 's/Path=//p')
		if [ ! -d ${HOME}/.mozilla/firefox/$profile/extensions ]
		then	
			mkdir ${HOME}/.mozilla/firefox/$profile/extensions
		fi
		addons_install_dir=${HOME}/.mozilla/firefox/$profile/extensions
		install_addons
	fi
fi
}

########################################
# Restoring user preferences
########################################
restoring_user_prefs() {
profile=$(sed -n -e 's/^.*Path=//p' ${HOME}/.mozilla/firefox/profiles.ini | head -n 1)

if [ -f ${HOME}/.mozilla/firefox/$profile/prefs.js ] 
then
	rm ${HOME}/.mozilla/firefox/$profile/prefs.js && echo "[ok] Prefs.js removed"
else
	echo "[ok] Prefs.js not present"
fi

if [ -f ${HOME}/.mozilla/firefox/$profile/user.js ]
then
	if ! diff -q $backup_dir/user.js ${HOME}/.mozilla/firefox/$profile/user.js &>/dev/null
	then
		>&2 echo "[!] User.js is different !!"	
	else
		echo "[ok] user.js is ok"
	fi
else
	cp $backup_dir/user.js ${HOME}/.mozilla/firefox/$profile/user.js && echo "[*] User.js prefs restored" 
fi
}

########################################
# Delete hiden addons 
########################################
delete_hidden() {
if [ -d /usr/lib/firefox-esr/browser/features ] # mv hidden addons
then
	mv  /usr/lib/firefox-esr/browser/features /usr/lib/firefox-esr/browser/features.bkp
	echo "[*] Moved hidden addons to /usr/lib/firefox-esr/browser/features.bkp"
else
	echo "[ok] Hidden addons not present "
fi
}

########################################
# Show usage info
########################################
usage() {
echo "**This script run whitout arguments.**"
echo "To run the script use: ./script or add it to /usr/bin/"
echo "This script make a backup of u firefox profile, install addons and user.js file to reduce firefox fingerprint."
echo "This script can start firefox as other user creating it and stop and delete user and files running the script again."
echo "For more info visit https://viellosero.github.io"
echo "You can change config options and have detailed run info inside the script."
echo "Require sudo, unzip, diff, wget, sed, awk"
}

########################################
# Test if programs we need are present
########################################
require(){
programs=(sudo unzip diff wget sed awk)
for program in "${programs[@]}"
do
	if command -v $program >/dev/null 
	then
		echo "[ok] $program present"
	else
		echo "[!] Needed $program to run the script" && exit 0
	fi
done
}

########################################
# Initial Loop
########################################

while :;
do

# check if run with args and display usage.
if [[ ! $# -le 0 ]] 
then 
	usage
	exit 0
fi 

# print runing as user
echo "[*] Runing as $USER"
# testing requerimetns
require
# make backup if necessary
backup
# download files if necessary
download
# install addons if necessary
if [ $addons_install_dir == /usr/lib/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/ ]
then
	install_addons
fi
# deleting hidden addons
delete_hidden

# Control if we will run as diferent user
if [ ! $user == null ] 
then
	#if we run as diferent user test if firefox are runing
	control
	if [ $? == 1 ] # is running
	then
		stop_user 
	else
		start_user
	fi
else
	# cp user prefs user.js
	restoring_user_prefs
	install_user_addons
	echo "[*] Start firefox as $USER " && TZ=UTC firefox &
fi

exit 0
done




