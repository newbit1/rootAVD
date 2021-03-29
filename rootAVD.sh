#!/usr/bin/env bash
##########################################################################################
#
# Magisk Boot Image Patcher - original created by topjohnwu and modded by shakalaca's
# modded by NewBit XDA for Android Studio AVD
# Successfully tested on Android API:
# [Dec. 2019] - 29 Google Apis Play Store x86_64 Production Build
# [Jan. 2021] - 30 Google Apis Play Store x86_64 Production Build
# [Mar. 2021] - 30 Google Apis Play Store x86_64 Production Build (S)
#
##########################################################################################

###################
# Helper Functions
###################

# Copied 1 to 1 from topjohnwu
getdir() {
  case "$1" in
    */*) dir=${1%/*}; [ -z $dir ] && echo "/" || echo $dir ;;
    *) echo "." ;;
  esac
}

get_flags() {
	echo "[-] Get Flags"
	
	if [ -f /system/init -o -L /system/init ]; then
    	SYSTEM_ROOT=true
  	else
    	SYSTEM_ROOT=false
    	grep ' / ' /proc/mounts | grep -qv 'rootfs' || grep -q ' /system_root ' /proc/mounts && SYSTEM_ROOT=true
  	fi

	if [ -z $KEEPVERITY ]; then		
		if $SYSTEM_ROOT; then
			KEEPVERITY=true
			echo "[*] System-as-root, keep dm/avb-verity"
		else
			KEEPVERITY=false
		fi
	fi

	ISENCRYPTED=false
	grep ' /data ' /proc/mounts | grep -q 'dm-' && ISENCRYPTED=true
	[ "$(getprop ro.crypto.state)" = "encrypted" ] && ISENCRYPTED=true
	
	if [ -z $KEEPFORCEENCRYPT ]; then
		# No data access means unable to decrypt in recovery
		if $ISENCRYPTED || ! $DATA; then
			KEEPFORCEENCRYPT=true
			echo "[-] Encrypted data, keep forceencrypt"
		else
			KEEPFORCEENCRYPT=false
		fi
	fi
	
	export RECOVERYMODE=false
	export KEEPVERITY
	export KEEPFORCEENCRYPT
	echo "[*] RECOVERYMODE=$RECOVERYMODE"
	echo "[-] KEEPVERITY=$KEEPVERITY"
	echo "[*] KEEPFORCEENCRYPT=$KEEPFORCEENCRYPT"
}

api_level_arch_detect() {
	echo "[-] Api Level Arch Detect"
	# Detect version and architecture
	# To select the right files for the patching
	API=$(getprop ro.build.version.sdk)
	ABI=$(getprop ro.product.cpu.abi)
	ABI2=$(getprop ro.product.cpu.abi2)
	ABILONG=$(getprop ro.product.cpu.abi)
	FIRSTAPI=$(getprop ro.product.first_api_level)
	ARCH=arm
	ARCH32=arm
	IS64BIT=false
	if [ "$ABI" = "x86" ]; then ARCH=x86; ARCH32=x86; fi;
	if [ "$ABI2" = "x86" ]; then ARCH=x86; ARCH32=x86; fi;
	if [ "$ABILONG" = "arm64-v8a" ]; then ARCH=arm64; ARCH32=arm; IS64BIT=true; fi;
	if [ "$ABILONG" = "x86_64" ]; then ARCH=x64; ARCH32=x86; IS64BIT=true; fi;	

	echo "[-] Device Platform: $ARCH"
	echo "[-] Device SDK API: $API"
	echo "[-] ARCH32 $ARCH32"
	echo "[-] First API Level: $FIRSTAPI"
	
	# There is only a x86 or arm DIR with binaries
	BINDIR=$BASEDIR/lib/$ARCH32

	[ ! -d "$BINDIR" ] && BINDIR=$BASEDIR/lib/armeabi-v7a
	cd $BINDIR
	for file in lib*.so; do mv "$file" "${file:3:${#file}-6}"; done
	cd $BASEDIR
	
	echo "[*] copy all files from $BINDIR to $BASEDIR"
	cp $BINDIR/* $BASEDIR
	
	chmod -R 755 $BASEDIR

	[ -d /system/lib64 ] && IS64BIT=true || IS64BIT=false
}

abort_script(){
	echo "[!] aborting the script"
	exit
}

detect_ramdisk_compression_method()
{
	echo "[*] Detecting ramdisk.img compression"
	RDF=$BASEDIR/ramdisk.img
	CPIO=$BASEDIR/ramdisk.cpio
	
	local FIRSTFILEBYTES
	local METHOD_LZ4="02214c18"
	local METHOD_GZ="1f8b0800"
	FIRSTFILEBYTES=$(xxd -p -c8 -l8 "$RDF")
	FIRSTFILEBYTES="${FIRSTFILEBYTES:0:8}"
	RAMDISK_LZ4=false
	RAMDISK_GZ=false
	ENDG=""
	METHOD=""

	if [ "$FIRSTFILEBYTES" == "$METHOD_LZ4" ]; then
		ENDG=".lz4"
		METHOD="lz4_legacy"
		RAMDISK_LZ4=true	
		mv $RDF $RDF$ENDG
		RDF=$RDF$ENDG
	elif [ "$FIRSTFILEBYTES" == "$METHOD_GZ" ]; then
		ENDG=".gz"
		METHOD="gzip"
		RAMDISK_GZ=true
		mv $RDF $RDF$ENDG	
	fi
	
	if [ "$ENDG" == "" ]; then
		echo "[!] Ramdisk.img uses UNKNOWN compression $FIRSTFILEBYTES"		
		abort_script
	fi
	
	echo "[!] Ramdisk.img uses $METHOD compression"	
}

# requires additional setup
# EnvFixTask
construct_environment() {
	echo "[-] Constructing environment - PAY ATTENTION to AVDs Screen"
	ROOT=`su -c "id -u"` 2>/dev/null
	
	if [[ $ROOT -eq 0 ]]; then
		echo "[!] we are root"		
		local BBBIN=$BB
		local COMMONDIR=$BASEDIR/assets	
		local NVBASE=/data/adb
		local MAGISKBIN=$NVBASE/magisk

		`su -c "rm -rf $MAGISKBIN/* 2>/dev/null && \
				mkdir -p $MAGISKBIN 2>/dev/null && \
				cp -af $BINDIR/. $COMMONDIR/. $BBBIN $MAGISKBIN && \
				chown root.root -R $MAGISKBIN && \
				chmod -R 755 $MAGISKBIN && \
				rm -rf $BASEDIR 2>/dev/null && \
				reboot \
				"`
	fi

	echo "[!] not root yet"
	echo "[!] Couldn't construct environment"
	echo "[!] Double Check Root Access"
	echo "[!] Re-Run Script with clean ramdisk.img and try again"
	abort_script
}

checkfile() {
	if [ -r "$1" ]; then 
		#echo "File exists and is readable"
		if [ -s "$1" ]; then 
			#echo "and has a size greater than zero"
			if [ -w "$1" ]; then 
				#echo "and is writable"
				if [ -f "$1" ]; then 
					#echo "and is a regular file."
					return 1			
				fi
			fi
		fi
	fi
	return 0
}

# If all is done well so far, you can install some APK's to the AVD
# every APK file in the Apps DIR will be (re)installed
# Like magisk.apk etc.
installapps() {
  	APPS="Apps/*"
	echo "[-] Install all APKs placed in the Apps folder"
	FILES=$APPS
	FILENAME=
	for f in $FILES
	do
		echo "[*] Trying to install $f"
		adb install -r -d "$f"
	done
}

CopyMagiskToAVD() {
	echo "[-] Test if ADB SHELL is working"
	ADBWORKS=$(adb shell 'echo true' 2>/dev/null)

	if [ -z "$ADBWORKS" ]; then
		echo "no ADB connection possible"
		exit
	fi
	
	# The Folder where the script was called from
	ROOTAVD="`getdir "${BASH_SOURCE:-$0}"`"
	MAGISKZIP=$ROOTAVD/Magisk.zip

	echo "[-] In any AVD via ADB, you can execute code without root in /data/data/com.android.shell"
	ADBWORKDIR=/data/data/com.android.shell
	ADBBASEDIR=$ADBWORKDIR/Magisk
	
	# change to ROOTAVD directory
	cd $ROOTAVD

	# Download the Magisk apk/zip file -> Magisk-v22.0
	MAGISKZIPDL=https://github.com/topjohnwu/Magisk/releases/download/v22.0/Magisk-v22.0.apk
	# If Magisk.zip file already exist, don't download it again
	if ( checkfile $MAGISKZIP -eq 0 ); then	
		echo "[*] Downloading Magisk installer Zip"
		wget $MAGISKZIPDL -O $MAGISKZIP > /dev/null 2>&1
	else
		echo "[-] Magisk installer Zip exists already"
	fi
	
	echo "[*] Cleaning up the ADB working space"
	adb shell rm -rf $ADBBASEDIR
	
	echo "[*] Creating the ADB working space"
	adb shell mkdir $ADBBASEDIR
	
	echo "[-] Copy Magisk installer Zip"
	ADBPUSHECHO=$(adb push $MAGISKZIP $ADBBASEDIR 2>/dev/null) 
	echo "[*] $ADBPUSHECHO"
	# Proceed with ramdisk
	if "$RAMDISKIMG"; then
		# Set Folders and FileNames		
		echo "[*] Set Directorys"
		PATHWITHFILE="$1"
		PATHTOFILE=${PATHWITHFILE%/*}
		FILE=${PATHWITHFILE##*/}
		BACKUPFILE=$FILE".backup"
		# Is it a ramdisk named file?
		if [ $FILE != "ramdisk.img" ]; then
			echo "[!] please give a path to a ramdisk file"    
			exit
		fi
		
		# If no backup file exist, create one
		if ( checkfile $PATHTOFILE/$BACKUPFILE -eq 0 ); then
			echo "[*] create Backup File"
			cp $PATHWITHFILE $PATHTOFILE/$BACKUPFILE
		else
			echo "[-] Backup exists already"
		fi

		echo "[-] Copy the original AVD ramdisk.img into Magisk DIR"
		ADBPUSHECHO=$(adb push $PATHWITHFILE $ADBBASEDIR 2>/dev/null) 
		echo "[*] $ADBPUSHECHO"	
	fi
	
	echo "[-] Copy rootAVD Script into Magisk DIR"
	ADBPUSHECHO=$(adb push rootAVD.sh $ADBBASEDIR 2>/dev/null) 
	echo "[*] $ADBPUSHECHO"

	echo "[-] Convert Script to Unix Ending"
	adb -e shell "dos2unix $ADBBASEDIR/rootAVD.sh"
	
	echo "[-] run the actually Boot/Ramdisk/Kernel Image Patch Script"
	echo "[*] from Magisk by topjohnwu and modded by NewBit XDA"
	
	adb shell sh $ADBBASEDIR/rootAVD.sh $@

	if [ "$?" == "1" ]; then	
		# In Debug-Mode we can skip parts of the script
		if ( ! "$DEBUG" && "$RAMDISKIMG" ); then

			echo "[-] After the ramdisk.img file is patched and compressed,"
			echo "[*] pull it back in the Magisk DIR"
			ADBPUSHECHO=$(adb pull $ADBBASEDIR/ramdiskpatched4AVD.img 2>/dev/null) 
			echo "[*] $ADBPUSHECHO"
		
			echo "[-] pull Magisk.apk to Apps/"
			ADBPUSHECHO=$(adb pull $ADBBASEDIR/Magisk.apk Apps/ 2>/dev/null) 
			echo "[*] $ADBPUSHECHO"
		
			echo "[-] pull Magisk.zip to Apps/"
			ADBPUSHECHO=$(adb pull $ADBBASEDIR/Magisk.zip 2>/dev/null)
			echo "[*] $ADBPUSHECHO"
		
			echo "[-] Clean up the ADB working space"
			adb shell rm -rf $ADBBASEDIR
		
			echo "[*] Move and rename the patched ramdisk.img to the original AVD DIR"
			mv ramdiskpatched4AVD.img $PATHWITHFILE
		
			installapps

			echo "[-] Shut-Down & Reboot the AVD and see if it worked"
			echo "[-] Root and Su with Magisk for Android Studio AVDs"
			echo "[-] Modded by NewBit XDA - Jan. 2021"
			echo "[!] Huge Credits and big Thanks to topjohnwu and shakalaca"
		fi
	fi
}

###################################################
# Method to extract specified field data from json
# Globals: None
# Arguments: 2
#   ${1} - value of field to fetch from json
#   ${2} - Optional, nth number of value from extracted values, by default shows all.
# Input: file | here string | pipe
#   _json_value "Arguments" < file
#   _json_value "Arguments <<< "${varibale}"
#   echo something | _json_value "Arguments"
# Result: print extracted value
###################################################
json_value() {
    $BB grep -o "\"""${1}""\"\:.*" | $BB sed -e "s/.*\"""${1}""\": //" -e 's/[",]*$//' -e 's/["]*$//' -e 's/[,]*$//' -e "s/\"//" -n -e "${2}"p
}

CheckAVDIsOnline() {
	echo "[-] Checking AVDs Internet connection..."
	AVDIsOnline=false
	$BB timeout 3 $BB wget -q --spider --no-check-certificate http://github.com > /dev/null 2>&1
	if [ $? -eq 0 ]; then
    		AVDIsOnline=true
	fi
	$AVDIsOnline && echo "[!] AVD is online" || echo "[!] AVD is offline"
	export AVDIsOnline
}

GetPrettyVer() {
		if echo $1 | $BB grep -q '\.'; then
			PRETTY_VER=$1
		else
			PRETTY_VER="$1($2)"
		fi
		echo "$PRETTY_VER"
}

CheckAvailableMagisks() {
	if [ -z $MAGISKVERCHOOSEN ]; then
		
		UFSH=$BASEDIR/assets/util_functions.sh
		OF=$BASEDIR/download.tmp
		BS=1024
		CUTOFF=100
		
		MAGISK_LOCL_VER=$($BB grep $UFSH -e "MAGISK_VER" -w | sed 's/^.*=//')
		MAGISK_LOCL_VER_CODE=$($BB grep $UFSH -e "MAGISK_VER_CODE" -w | sed 's/^.*=//')
		MAGISK_LOCL_VER=$(GetPrettyVer $MAGISK_LOCL_VER $MAGISK_LOCL_VER_CODE)
		
		CheckAVDIsOnline
		if ("$AVDIsOnline"); then
			echo "[!] Checking available Magisk Versions"		
			URL="https://raw.githubusercontent.com/topjohnwu/magisk-files/master/"
			CANJSON="canary.json"
			STABLJSON="stable.json"
			rm $CANJSON $STABLJSON > /dev/null 2>&1
			
			$BB wget -q --no-check-certificate $URL$CANJSON
			$BB wget -q --no-check-certificate $URL$STABLJSON
			
			MAGISK_CAN_VER=$(json_value "version" < $CANJSON)
			MAGISK_CAN_VER_CODE=$(json_value "versionCode" 1 < $CANJSON)
			MAGISK_CAN_DL=$(json_value "link" 1 < $CANJSON)
			
			MAGISK_CAN_VER=$(GetPrettyVer $MAGISK_CAN_VER $MAGISK_CAN_VER_CODE)
			
			MAGISK_STABL_VER=$(json_value "version" < $STABLJSON)
			MAGISK_STABL_VER_CODE=$(json_value "versionCode" 1 < $STABLJSON)
			MAGISK_STABL_DL=$(json_value "link" 1 < $STABLJSON)
			
			MAGISK_STABL_VER=$(GetPrettyVer $MAGISK_STABL_VER $MAGISK_STABL_VER_CODE)
		
			MAGISK_V1="[1] Local $MAGISK_LOCL_VER (ENTER)"
			MAGISK_V2="[2] Canary $MAGISK_CAN_VER"
			MAGISK_V3="[3] Stable $MAGISK_STABL_VER"

			while :
			do
				echo "[?] Choose a Magisk Version to install and make it local"
				echo $MAGISK_V1
				echo $MAGISK_V2
				echo $MAGISK_V3
				read choice
				case $choice in
					"1"|"")
						MAGISK_VER=$MAGISK_LOCL_VER
						echo "[1] You choose Magisk Local Version $MAGISK_VER"
						MAGISKVERCHOOSEN=false
						break
						;;
					"2")
						MAGISK_VER=$MAGISK_CAN_VER
						MAGISK_DL=$MAGISK_CAN_DL
						echo "[$choice] You choose Magisk Canary Version $MAGISK_CAN_VER"
						break
						;;
					"3")
						MAGISK_VER=$MAGISK_STABL_VER
						MAGISK_DL=$MAGISK_STABL_DL
						echo "[$choice] You choose Magisk Stable Version $MAGISK_STABL_VER"
						break
						;;		
					*) echo "invalid option $choice";;
				esac
			done
		else
			MAGISK_VER=$MAGISK_LOCL_VER
			MAGISKVERCHOOSEN=false
		fi
		
		if [ -z $MAGISKVERCHOOSEN ]; then
			echo "[*] Deleting local Magisk $MAGISK_LOCL_VER"
			rm -rf $MZ
			echo "[*] Downloading Magisk $MAGISK_VER"	
			$BB wget -q -O $MZ --no-check-certificate $MAGISK_DL
			RESULT="$?"
			while [ $RESULT != "0" ]
			do				
				echo "[!] Error while downloading Magisk $MAGISK_VER"
				echo "[-] patching it together"
				FSIZE=$(./busybox stat $MZ -c %s)
				if [ $FSIZE -gt $BS ]; then
					COUNT=$(( FSIZE/BS ))
					if [ $COUNT -gt $CUTOFF ]; then
						COUNT=$(( COUNT - $CUTOFF ))
					fi
				fi
				$BB dd if=$MZ count=$COUNT bs=$BS of=$OF > /dev/null 2>&1
				mv -f $OF $MZ
				$BB wget -q -O $MZ --no-check-certificate $MAGISK_DL -c
				RESULT="$?"
			done
			echo "[!] Downloading Magisk $MAGISK_VER complete!"
			MAGISKVERCHOOSEN=true
			PrepBusyBoxAndMagisk
		fi
	fi
	export MAGISK_VER
	export MAGISKVERCHOOSEN
}

PrepBusyBoxAndMagisk() {

	echo "[-] Switch to the location of the script file"
	BASEDIR="`getdir "${BASH_SOURCE:-$0}"`"
	TMPDIR=$BASEDIR/tmp
	BB=$BASEDIR/busybox
	MZ=$BASEDIR/Magisk.zip
	cd $BASEDIR
	echo "[*] Extracting busybox and Magisk.zip ..."
	unzip $MZ -oq
	chmod -R 755 $BASEDIR/lib
	mv -f $BASEDIR/lib/x86/libbusybox.so $BB
	$BB >/dev/null 2>&1 || mv -f $BASEDIR/lib/armeabi-v7a/libbusybox.so $BB
	chmod -R 755 $BASEDIR
		
	export BASEDIR
	export TMPDIR
	export BB
	export MZ

	CheckAvailableMagisks
}

ExecBusyBoxAsh() {	
	echo "[*] Re-Run rootAVD in Magisk Busybox STANDALONE (D)ASH"
	export PREPBBMAGISK=1
	export ASH_STANDALONE=1
	exec $BB sh $0 $@
}

decompress_ramdisk(){
	echo "[-] taken from shakalaca's MagiskOnEmulator/process.sh"
	echo "[*] executing ramdisk splitting / extraction / repacking"
	# extract and check ramdisk
	if [ $API -ge 30 ]; then
		$RAMDISK_GZ && gzip -fdk $RDF$ENDG
		echo "[-] API level greater then 30"
		echo "[*] Check if we need to repack ramdisk before patching .."
		COUNT=`strings -t d $RDF | grep TRAILER\!\!\! | wc -l`
	  if [[ $COUNT -gt 1 ]]; then
		echo "[-] Multiple cpio archives detected"
		REPACKRAMDISK=1
	  fi
	fi

	if [[ -n "$REPACKRAMDISK" ]]; then
		$RAMDISK_GZ && rm $RDF$ENDG
	  	echo "[*] Unpacking ramdisk .."
	  	mkdir -p $TMPDIR/ramdisk
	  	LASTINDEX=0
	  	IBS=1
	  	OBS=4096
	  	OF=$TMPDIR/temp$ENDG
		
	  	RAMDISKS=`strings -t d $RDF | grep TRAILER`

	  	for OFFSET in $RAMDISKS
	  	do
			# calculate offset to next archive			
			if [ `echo "$OFFSET" | grep TRAILER` ]; then
				# find position of end of TRAILER!!! string in image

				if $RAMDISK_GZ; then
					LEN=${#OFFSET}
					START=$((LASTINDEX+LEN))			
					# find first occurance of string in image, that will be start of cpio archive
					dd if=$RDF skip=$START count=$OBS ibs=$IBS obs=$OBS of=$OF > /dev/null 2>&1
					HEAD=`strings -t d $OF | head -1`
					# vola
					for i in $HEAD;do
						HEAD=$i
						break
					done					
					LASTINDEX=$((START+HEAD))	  	
				fi
				if $RAMDISK_LZ4; then
					START=$LASTINDEX	
				fi
		  		continue
			fi

			# number of blocks we'll extract
			$RAMDISK_GZ && BLOCKS=$(((OFFSET+128)/IBS))
			$RAMDISK_LZ4 && BLOCKS=$(((OFFSET+19)/IBS))

			# extract and dump
			echo "[-] Dumping from $LASTINDEX to $BLOCKS .."
			dd if=$RDF skip=$LASTINDEX count=$BLOCKS ibs=$IBS obs=$OBS of=$OF > /dev/null 2>&1
			cd $TMPDIR/ramdisk > /dev/null
				$RAMDISK_GZ && cat $OF | $BASEDIR/busybox cpio -i > /dev/null 2>&1
				if $RAMDISK_LZ4; then
					$BASEDIR/magiskboot decompress $OF $OF.cpio
					$BASEDIR/busybox cpio -F $OF.cpio -i > /dev/null 2>&1
				fi
			cd - > /dev/null
			$RAMDISK_GZ && LASTINDEX=$OFFSET
			$RAMDISK_LZ4 && LASTINDEX=$BLOCKS
	  	done
		echo "[*] Repacking ramdisk .."
		cd $TMPDIR/ramdisk > /dev/null
		`find . | cpio -H newc -o > $CPIO`
		cd - > /dev/null
	else
		echo "[*] After decompressing ramdisk.img, magiskboot will work"
		$RAMDISK_GZ && RDF=$RDF$ENDG
		./magiskboot decompress $RDF $CPIO
	fi
}

test_ramdisk_patch_status(){
	echo "[-] Test patch status and do restore"
	echo "[-] Checking ramdisk status"

	if [ -e ramdisk.cpio ]; then
		./magiskboot cpio ramdisk.cpio test 2>/dev/null
		STATUS=$?
		echo "[-] STATUS=$STATUS"
	else
		echo "[-] Stock A only system-as-root"
		STATUS=0
	fi

	case $((STATUS & 3)) in
	  0 )  # Stock boot
		echo "[-] Stock boot image detected"
		SHA1=`./magiskboot sha1 ramdisk.cpio 2>/dev/null`
		cp -af ramdisk.cpio ramdisk.cpio.orig 2>/dev/null
		;;

	  1 )  # Magisk patched
		echo "[-] Magisk patched boot image detected"
		construct_environment
		abort_script
		;;
	  2 )  # Unsupported
		echo "[!] Boot image patched by unsupported programs"
		echo "[!] Please restore back to stock boot image"
		abort_script
		;;
	esac

	if [ $((STATUS & 8)) -ne 0 ]; then
	  echo "[!] TWOSTAGE INIT image detected - Possibly using 2SI, export env var"
	  export TWOSTAGEINIT=true
	fi
}

patching_ramdisk(){
	##########################################################################################
	# Ramdisk patches
	##########################################################################################

	echo "[-] Patching ramdisk"

	echo "KEEPVERITY=$KEEPVERITY" > config
	echo "KEEPFORCEENCRYPT=$KEEPFORCEENCRYPT" >> config
	echo "RECOVERYMODE=$RECOVERYMODE" >> config

	# actually here is the SHA of the bootimage generated
	# we only have one file, so it could make sense
	[ ! -z $SHA1 ] && echo "SHA1=$SHA1" >> config

	# Compress to save precious ramdisk space
	./magiskboot compress=xz magisk32 magisk32.xz
	./magiskboot compress=xz magisk64 magisk64.xz
	$IS64BIT && SKIP64="" || SKIP64="#"
	
	# Here gets the ramdisk.img patched with the magisk su files and stuff

	# Set PATCHFSTAB=true if you want the RAMDISK merge your modded fstab.ranchu before Magisk Mirror gets mounted

	PATCHFSTAB=false
	#PATCHFSTAB=true
	
	# cp the read-only fstab.ranchu from vendor partition and add usb:auto for SD devices
	# kernel musst have Mass-Storage + SCSI Support enabled to create /dev/block/sd* nodes

	echo "[!] PATCHFSTAB=$PATCHFSTAB"
	if ("$PATCHFSTAB"); then
		echo "[-] pulling fstab.ranchu from AVD"
		cp /system/vendor/etc/fstab.ranchu $(pwd)
		echo "[-] adding usb:auto to fstab.ranchu"
		#echo "/devices/*/block/sd* auto auto defaults voldmanaged=usb:auto" >> fstab.ranchu
		#echo "/devices/*/block/loop7 auto auto defaults voldmanaged=sdcard:auto" >> fstab.ranchu
		echo "/devices/1-* auto auto defaults voldmanaged=usb:auto" >> fstab.ranchu
		# cat fstab.ranchu
		#/system/vendor/etc/fstab.f2fs.hi3650
		echo "[-] adding overlay.d folder to ramdisk"
		./magiskboot cpio ramdisk.cpio \
		"mkdir 750 overlay.d" \
		"mkdir 755 overlay.d/vendor" \
		"mkdir 755 overlay.d/vendor/etc" \
		"add 644 overlay.d/vendor/etc/fstab.ranchu fstab.ranchu"
		echo "[-] overlay adding complete"
		echo "[-] jumping back to patching ramdisk for magisk init"
	else
		echo "[!] Skipping fstab.ranchu patch with /dev/block/sda"
		echo "[?] If you want fstab.ranchu patched, set PATCHFSTAB=true"
	fi

	$PATCHFSTAB && SKIPOVERLAYD="#" || SKIPOVERLAYD=""

	echo "[!] patching the ramdisk with Magisk Init"
	./magiskboot cpio ramdisk.cpio \
	"add 0750 init magiskinit" \
	"$SKIPOVERLAYD mkdir 0750 overlay.d" \
	"mkdir 0750 overlay.d/sbin" \
	"add 0644 overlay.d/sbin/magisk32.xz magisk32.xz" \
	"$SKIP64 add 0644 overlay.d/sbin/magisk64.xz magisk64.xz" \
	"patch" \
	"backup ramdisk.cpio.orig" \
	"mkdir 000 .backup" \
	"add 000 .backup/.magisk config"
}

repacking_ramdisk(){
	if [ $((STATUS & 4)) -ne 0 ]; then
		echo "[!] Compressing ramdisk before repacking it"
	  ./magiskboot cpio ramdisk.cpio compress
	fi

	echo "[*] repacking back to ramdisk.img format"
	# Rename and compress ramdisk.cpio back to ramdiskpatched4AVD.img
	./magiskboot compress=$METHOD "ramdisk.cpio" "ramdiskpatched4AVD.img"
	
	if ("$MAGISKVERCHOOSEN"); then
		echo "[!] Copy Magisk.zip to Magisk.apk"
		cp Magisk.zip Magisk.apk
	else
		echo "[!] Rename Magisk.zip to Magisk.apk"
		mv Magisk.zip Magisk.apk
	fi	
}	

InstallMagiskToAVD() {
	if [ -z $PREPBBMAGISK ]; then
		PrepBusyBoxAndMagisk
		ExecBusyBoxAsh $@
	fi
	
	echo "[-] We are now in Magisk Busybox STANDALONE (D)ASH"
	# Don't use $BB from now on

	echo "[*] rootAVD with Magisk $MAGISK_VER Installer"
	
	get_flags
	api_level_arch_detect

	if [[ $1 == "EnvFixTask" ]]; then
		construct_environment
	fi

	if $RANCHU; then
		detect_ramdisk_compression_method
		decompress_ramdisk
		test_ramdisk_patch_status
		patching_ramdisk
		repacking_ramdisk
	fi
}

# Script Entry Point
# Checking in which shell we are
RANCHU=false
SHELL=$(getprop ro.kernel.androidboot.hardware 2>/dev/null)
if [[ $SHELL == "ranchu" ]]; then
	echo "[!] We are in an emulator shell"
	RANCHU=true
fi
export RANCHU

if $RANCHU; then
	InstallMagiskToAVD $@
	return 1
fi

# While debugging and developing you can turn this flag on
DEBUG=false
#DEBUG=true

# Shows whatever line get executed...
if ("$DEBUG"); then
	#set -x
	echo "[!] We are in Debug Mode"
fi

ENVFIXTASK=false
RAMDISKIMG=false

case $1 in
  "EnvFixTask" )  # AVD requires additional setup
		ENVFIXTASK=true
	;;

  * )  # If there is no file to work with, abort the script	
		if (checkfile "$1" -eq 0); then
			echo "[!] rootAVD needs either a path with file to an AVD ramdisk"
			echo "[!] or the EnvFixTask argument for Android 12 (S)"			
  			echo "[!] rootAVD will backup your ramdisk.img and replace it when finished"
  			echo "[*][*] possible commands are... [L]inux / [M]ac/Darwin"
  			echo "[L][M] ./rootAVD.sh EnvFixTask (fix Requires Additional Setup / construct environment)"
  			echo "[L][|] ./rootAVD.sh ~/Android/Sdk/system-images/android-30/google_apis_playstore/x86_64/ramdisk.img"
  			echo "[L][|] ./rootAVD.sh ~/Android/Sdk/system-images/android-S/google_apis_playstore/x86_64/ramdisk.img"
  			echo "[|][M] ./rootAVD.sh ~/Library/Android/sdk/system-images/android-30/google_apis_playstore/x86_64/ramdisk.img"
			echo "[|][M] ./rootAVD.sh ~/Library/Android/sdk/system-images/android-S/google_apis_playstore/x86_64/ramdisk.img"
			exit
		fi
		RAMDISKIMG=true
	;;
esac

echo "[!] and we are NOT in an emulator shell"
export ENVFIXTASK
export RAMDISKIMG

CopyMagiskToAVD $1

exit
