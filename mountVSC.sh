#!/bin/bash

# script to mount image and volume shadow copies on SIFT workstation


if test "$1" = "-h"
then
	echo "help"
	echo "Syntax: mountV.sh <option> [arg2] [arg3] [arg4]"
	echo "Options:"
	echo "-h print help"
	echo "-m mount image and VSC; arg2 - source image path, arg3 - destination mountpoint path, arg4 - suffix for /mnt/vss_arg4 and /mnt/vsc_arg4 directories"
	echo "-u unmount image and VSC; arg2 - path to mountpoint, arg3 - path to directory where ewf is mounted, arg4 - suffix for /mnt/vss_arg4 and /mnt/vsc_arg4 directories to unmount"
	exit 0

elif test "$1" = "-m"
then
	src=${2:?Error command line argument - source image path - not passed}
	dst=${3:?Error command line argument - destination mountpoint path - not passed}
	
	name=${4}
	myDat=$(date -u | tr -d ":" | tr -d [:space:] )

	test -n name && myPath=$name || myPath=$myDat
	echo "Path suffix is $myPath"
	imageMounter.py $src $dst  > tmp

	ewfMount=$(grep "at /mnt/ewf" tmp | cut -d " " -f 6)
	rm tmp

	echo "Note the location (path to directory) of mounted EWF: $ewfMount"

	#vypisat a manualne zadat offset
	#output=$(mmls $ewfMount)
	#echo $output
	mmls $ewfMount

	echo "\nEnter partition offset to look for VSC...\n"
	read offset
	if test $offset -le 0 
	then
		echo "Zero offset set, quitting... "
		exit 0
	fi

	
	
	if (mkdir /mnt/vss_$myPath)
	then
		echo "Directory /mnt/vss_$myPath created" 
	else
		echo "Directory /mnt/vss_$myPath could not be created, quitting..."
		exit 1
	fi 

	echo "Getting info about volume shadow copies... "
	vshadowinfo -o $((512*$offset)) $ewfMount
	
	echo "Press "m" to continue..."
	read m

	if test "$m" = "m" 
	then
		vshadowmount -o $((512*$offset)) $ewfMount /mnt/vss_$myPath
		cd /mnt/vss_$myPath
		if (mkdir /mnt/vsc_$myPath)
		then
			echo "Directory /mnt/vsc_$myPath created" 
		else
			echo "Directory /mnt/vsc_$myPath could not be created, quitting..."
			exit 1
		fi 
		# TODO test dir created?
		for i in *; do mkdir /mnt/vsc_$myPath/$i; done
		for i in *; do mount -o ro,loop,show_sys_files,stream_interface=windows $i /mnt/vsc_$myPath/$i; done
		echo "Volume shadow copies mounted in /mnt/vsc_$myPath/ directory. Now updating database..."
		updatedb
		echo "Database updated. Bye!"
	else	
		echo "Quitting... "
		exit 0
	fi
	




elif test "$1" = "-u"
then
# upratanie
	toUmount=${2:?Error command line argument - mount path to clear - not passed}
	myEwf=${3:?Error command line argument - path to ewf - not passed}
	myVSC=${4:?Error command line argument - suffix of VSS/VSC directory - not passed}

	umount $toUmount/0
	umount $toUmount/1

	cd /mnt/vss_$myVSC
	# umount jednotlive VSC
	for i in *; do umount /mnt/vsc_$myVSC/$i; done
	cd ..
	# umount namountovane VSS z EWFka 
	umount /mnt/vss_$myVSC
	
	

	# zmazat adresare/mountpointy
	rm -rf /mnt/vss_$myVSC && rm -rf /mnt/vsc_$myVSC

	# umount EWF 
	umount $myEwf
	rm -rf $myEwf

	

else
	echo "If you don't know how to use this, try -h first..."	
	exit 1
fi




