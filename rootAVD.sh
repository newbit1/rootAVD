#!/usr/bin/env bash
##########################################################################################
#
# Magisk Boot Image Patcher - original created by topjohnwu and modded by shakalaca's
# modded by NewBit XDA for Android Studio AVD
# Successfully tested on Android API:
# [Dec. 2019] - 29 Google Apis Play Store x86_64 Production Build
# [Jan. 2021] - 30 Google Apis Play Store x86_64 Production Build
# [Mar. 2021] - 30 Google Apis Play Store x86_64 Production Build (S)
# [Apr. 2021] - 30 Google Apis Play Store x86_64 Production Build (S) rev. 2
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

compression_method(){
	local FILE="$1"
	local FIRSTFILEBYTES
	local METHOD_LZ4="02214c18"
	local METHOD_GZ="1f8b0800"
	local ENDG=""
	FIRSTFILEBYTES=$(xxd -p -c8 -l8 "$FILE")
	FIRSTFILEBYTES="${FIRSTFILEBYTES:0:8}"

	if [ "$FIRSTFILEBYTES" == "$METHOD_LZ4" ]; then
		ENDG=".lz4"
	elif [ "$FIRSTFILEBYTES" == "$METHOD_GZ" ]; then
		ENDG=".gz"
	fi
	echo "$ENDG"
}

detect_ramdisk_compression_method(){
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
	ROOT=`su -c "id -u"` 2>/dev/null

	if [[ "$ROOT" == "" ]]; then
		ROOT=$(id -u)
	fi
	
	echo "[-] Constructing environment - PAY ATTENTION to the AVDs Screen"
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
	#echo "checkfile $1"
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
install_apps() {
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

create_backup() {
	local BACKUPFILE=""
	local FILE=""
	FILE="$1"
	BACKUPFILE="$FILE.backup"
	# If no backup file exist, create one
	if ( checkfile $AVDPATH/$BACKUPFILE -eq 0 ); then
		echo "[*] create Backup File of $FILE"
		cp $AVDPATH/$FILE $AVDPATH/$BACKUPFILE
	else
		echo "[-] $FILE Backup exists already"
	fi
}

pushtoAVD() {
	local SRC=""
	local ADBPUSHECHO=""
	SRC=${1##*/}
	echo "[*] Push $SRC into $ADBBASEDIR"
	ADBPUSHECHO=$(adb push $1 $ADBBASEDIR 2>/dev/null)
	echo "[-] $ADBPUSHECHO"
}

pullfromAVD() {
	local SRC=""
	local DST=""
	local ADBPULLECHO=""
	SRC=${1##*/}
	DST=${2##*/}
	ADBPULLECHO=$(adb pull $ADBBASEDIR/$SRC $2 2>/dev/null)
	if [[ ! "$ADBPULLECHO" == *"error"* ]]; then
		echo "[*] Pull $SRC into $DST"
  		echo "[-] $ADBPULLECHO"
	fi
}

restore_backups() {
	local BACKUPFILE=""
	local RESTOREFILE=""
	for f in $1/*.backup; do
    	BACKUPFILE="$f"
    	RESTOREFILE="${BACKUPFILE%.backup}"
    	echo "[!] Restoring ${BACKUPFILE##*/} to ${RESTOREFILE##*/}"
    	cp $BACKUPFILE $RESTOREFILE
	done
	echo "[*] Backups still remain in place"
	exit 0
}

TestADB() {
	local HOME=~/
	local ADB_DIR_M=Library/Android/sdk/platform-tools
	local ADB_DIR_L=Android/Sdk/platform-tools
	local ADB_DIR=""
	local ADB_EX=""

	echo "[-] Test if ADB SHELL is working"
	
	if [ -d "$HOME$ADB_DIR_M" ]; then
		ADB_DIR=$ADB_DIR_M
	elif [ -d "$HOME$ADB_DIR_L" ]; then
		ADB_DIR=$ADB_DIR_L
	else
		echo "[!] ADB not found, please install and add it to your \$PATH"
		exit
	fi
	cd $HOME > /dev/null
		for adb in $(find $ADB_DIR -type f -name adb); do
			ADB_EX="~/$adb"
		done
	cd - > /dev/null

	if [[ $ADB_EX == "" ]]; then
		echo "[!] ADB binary not found in ~/$ADB_DIR"
		exit
	fi

	ADBWORKS=$(which adb)
	if [ "$ADBWORKS" == *"not found"* ] || [ "$ADBWORKS" == "" ]; then
  		echo "[!] ADB is not in your Path, try to"
  		echo "export PATH=~/$ADB_DIR:\$PATH"
  		echo ""
  		exit
	fi

	ADBWORKS=$(adb shell 'echo true' 2>/dev/null)
	if [ -z "$ADBWORKS" ]; then
		echo "no ADB connection possible"
		exit
	fi
}

CopyMagiskToAVD() {
	# Set Folders and FileNames
	echo "[*] Set Directorys"
	AVDPATHWITHRDFFILE="$1"
	AVDPATH=${AVDPATHWITHRDFFILE%/*}
	RDFFILE=${AVDPATHWITHRDFFILE##*/}

	if ( "$restore" ); then
		restore_backups $AVDPATH
	fi

	TestADB

	# The Folder where the script was called from
	ROOTAVD="`getdir "${BASH_SOURCE:-$0}"`"
	MAGISKZIP=$ROOTAVD/Magisk.zip
	
	# change to ROOTAVD directory
	cd $ROOTAVD
	
	# Kernel Names
	BZFILE=$ROOTAVD/bzImage
	KRFILE=kernel-ranchu
	
	if ( "$InstallApps" ); then
		install_apps
		exit
	fi

	ADBWORKDIR=/data/data/com.android.shell
	ADBBASEDIR=$ADBWORKDIR/Magisk
	echo "[-] In any AVD via ADB, you can execute code without root in $ADBWORKDIR"

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

	pushtoAVD $MAGISKZIP
	# Proceed with ramdisk
	if "$RAMDISKIMG"; then
		# Is it a ramdisk named file?
		if [ $RDFFILE != "ramdisk.img" ]; then
			echo "[!] please give a path to a ramdisk file"
			exit
		fi

		create_backup $RDFFILE
		pushtoAVD $AVDPATHWITHRDFFILE

		if ( "$InstallKernelModules" ); then
			INITRAMFS=$ROOTAVD/initramfs.img
			if ( ! checkfile $INITRAMFS -eq 0 ); then
				pushtoAVD $INITRAMFS
			fi
		fi
	fi

	pushtoAVD "rootAVD.sh"

	echo "[-] Convert Script to Unix Ending"
	adb -e shell "dos2unix $ADBBASEDIR/rootAVD.sh"

	echo "[-] run the actually Boot/Ramdisk/Kernel Image Patch Script"
	echo "[*] from Magisk by topjohnwu and modded by NewBit XDA"
	adb shell sh $ADBBASEDIR/rootAVD.sh $@

	if [ "$?" == "1" ]; then
		# In Debug-Mode we can skip parts of the script
		if ( ! "$DEBUG" && "$RAMDISKIMG" ); then

			pullfromAVD "ramdiskpatched4AVD.img" $AVDPATHWITHRDFFILE
			pullfromAVD "Magisk.apk" "Apps/"
			pullfromAVD "Magisk.zip" $ROOTAVD

			if ( "$InstallPrebuiltKernelModules" ); then
				pullfromAVD $BZFILE $ROOTAVD
				InstallKernelModules=true
			fi

			if ( "$InstallKernelModules" ); then
				if ( ! checkfile $BZFILE -eq 0 ); then
					create_backup $KRFILE
					echo "[*] Copy $BZFILE (Kernel) into kernel-ranchu"
					cp $BZFILE $AVDPATH/$KRFILE
					if [ "$?" == "0" ]; then
						rm -f $BZFILE $INITRAMFS
					fi
				fi
			fi

			echo "[-] Clean up the ADB working space"
			adb shell rm -rf $ADBBASEDIR

			install_apps

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

DownLoadFile() {
	if ("$AVDIsOnline"); then
		local URL="$1"
		local SRC="$2"
		local DST="$3"

		OF=$BASEDIR/download.tmp
		rm -f $OF
		BS=1024
		CUTOFF=100

		if [ "$DST" == "" ]; then
			DST=$BASEDIR/$SRC
		else
			DST=$BASEDIR/$DST
		fi
		#echo "[*] Downloading File $SRC"
		$BB wget -q -O $DST --no-check-certificate $URL$SRC
		RESULT="$?"
		while [ $RESULT != "0" ]
		do
			echo "[!] Error while downloading File $SRC"
			echo "[-] patching it together"
			FSIZE=$(./busybox stat $DST -c %s)
			if [ $FSIZE -gt $BS ]; then
				COUNT=$(( FSIZE/BS ))
				if [ $COUNT -gt $CUTOFF ]; then
					COUNT=$(( COUNT - $CUTOFF ))
				fi
			fi
			$BB dd if=$DST count=$COUNT bs=$BS of=$OF > /dev/null 2>&1
			mv -f $OF $DST
			$BB wget -q -O $DST --no-check-certificate $URL$SRC -c
			RESULT="$?"
		done
		echo "[!] Downloading File $SRC complete!"
	fi
}

GetUSBHPmod() {
	USBHPZSDDL="/sdcard/Download/usbhostpermissons.zip"
	USBHPZ="https://github.com/newbit1/usbhostpermissons/releases/download/v1.0/usbhostpermissons.zip"
	if [ ! -e $USBHPZSDDL ]; then
		echo "[*] Downloading USB HOST Permissions Module Zip"
		$BB wget -q -O $USBHPZSDDL --no-check-certificate $USBHPZ
	else
		echo "[*] USB HOST Permissions Module Zip is already present"
	fi
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

		# Call rootAVD with GetUSBHPmodZ to download the usbhostpermissons module
		$GetUSBHPmodZ && $AVDIsOnline && GetUSBHPmod
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
	  	update_lib_modules
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

	# Call rootAVD with PATCHFSTAB if you want the RAMDISK merge your modded fstab.ranchu before Magisk Mirror gets mounted

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
		echo "[?] If you want fstab.ranchu patched, Call rootAVD with PATCHFSTAB"
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

	if ( "$MAGISKVERCHOOSEN" ); then
		echo "[!] Copy Magisk.zip to Magisk.apk"
		cp Magisk.zip Magisk.apk
	else
		echo "[!] Rename Magisk.zip to Magisk.apk"
		mv Magisk.zip Magisk.apk
	fi
}

strip_html_links() {
		sed -i -e 's/<a href=/\n<a href=/g;s/<\/a>/<\/a>\n/g' "$1"
		sed -i -n '/>Update kernel to builds/p' "$1"
}

update_lib_modules() {
	local INITRAMFS=initramfs.img
	if ("$AVDIsOnline"); then
		if ( "$InstallPrebuiltKernelModules" ); then
			local unameR=$(uname -r)
			local majmin=${unameR%.*}
			local installedbuild=${unameR##*ab}
			local URL="https://android.googlesource.com"
			local KERSRC="/kernel/prebuilts/$majmin/x86-64/+log/refs/heads/master"
			local MODSRC="/kernel/prebuilts/common-modules/virtual-device/$majmin/x86-64/+log/refs/heads/master"
			local KERPREMASHTML="kernelprebuiltsmaster.html"
			local KERDST="prebuiltkernel.tar.gz"
			local MODDST="prebuiltmodules.tar.gz"
			local MODPREMASHTML="moduleprebuiltsmaster.html"
			local TMPSTRIPFILE="tmpstripfile"
			local TMPREADFILE="tmpreadfile"
			local FILETOREAD=""
			local FILETOSTRIP=""

			local BUILDVERCHOOSEN=""
			local CHOOSENLINE=""
			local KERCOMMITID=""
			local MODCOMMITID=""

			local ker_line_cnt=""
			local mod_line_cnt=""
			local i=""

			DownLoadFile $URL $KERSRC $KERPREMASHTML
			DownLoadFile $URL $MODSRC $MODPREMASHTML

			strip_html_links $KERPREMASHTML
			strip_html_links $MODPREMASHTML

			ker_line_cnt=$(sed -n '$=' $KERPREMASHTML)
			mod_line_cnt=$(sed -n '$=' $MODPREMASHTML)

			if [ "$ker_line_cnt" -gt "$mod_line_cnt" ];then
				FILETOREAD="$KERPREMASHTML"
				FILETOSTRIP="$MODPREMASHTML"
			else
				FILETOREAD="$MODPREMASHTML"
				FILETOSTRIP="$KERPREMASHTML"
			fi

			touch $TMPSTRIPFILE
			touch $TMPREADFILE

			echo "[*] Find common Build Versions"
			while read line; do
					BUILDVER=$(echo $line | sed -e 's/<[^>]*>//g')
					grep -e ">$BUILDVER<" -F $FILETOSTRIP >> $TMPSTRIPFILE
					if [[ "$?" == "0" ]]; then
						echo $line >> $TMPREADFILE
					fi
			done < $FILETOREAD

			mv -f $TMPREADFILE $FILETOREAD
			mv -f $TMPSTRIPFILE $FILETOSTRIP

			while :
			do
				i=0
				echo "[!] Installed Kernel builds $installedbuild"
				echo "[?] Choose a Prebuild Kernel/Module Version"
				while read line; do
					i=$(( i + 1 ))
					BUILDVER=$(echo $line | sed -e 's/<[^>]*>//g')
					echo "[$i] $BUILDVER"
				done < $KERPREMASHTML

				read choice
				case $choice in
					*)
						if [[ "$choice" == "" ]]; then
							choice=1
						fi
						if [ "$choice" -le "$i" ];then
							BUILDVERCHOOSEN=$choice
							CHOOSENLINE=$(sed -n "$BUILDVERCHOOSEN"'p' $KERPREMASHTML)
							BUILDVER=$(echo $CHOOSENLINE| sed -e 's/<[^>]*>//g')
							KERCOMMITID=$(echo $CHOOSENLINE | sed -e 's/^[^"]*"\([^"]*\)".*/\1/')
							KERCOMMITID=${KERCOMMITID##*/}".tar.gz"

							CHOOSENLINE=$(sed -n "$BUILDVERCHOOSEN"'p' $MODPREMASHTML)
							MODCOMMITID=$(echo $CHOOSENLINE | sed -e 's/^[^"]*"\([^"]*\)".*/\1/')
							MODCOMMITID=${MODCOMMITID##*/}".tar.gz"

							echo "[$BUILDVERCHOOSEN] You choose: $BUILDVER"
							break
						fi
						echo "Choice is out of range";;
				esac
			done

			echo "[-] Downloading Kernel and its Modules..."
			# Download Kernel
			DownLoadFile "$URL/kernel/prebuilts/$majmin/x86-64/+archive/" $KERCOMMITID $KERDST
			# Download Modules
			DownLoadFile "$URL/kernel/prebuilts/common-modules/virtual-device/$majmin/x86-64/+archive/" $MODCOMMITID $MODDST

			echo "[*] Extracting kernel-$majmin to bzImage"
			tar -xf $KERDST kernel-$majmin -O > bzImage
			echo "[-] Extracting $INITRAMFS"
			tar -xf $MODDST $INITRAMFS

			InstallKernelModules=true
		fi
	fi

	if ( "$InstallKernelModules" ); then
		if [ -e "$INITRAMFS" ]; then
			echo "[!] Installing new Kernel Modules"
			echo "[*] Copy initramfs.img $TMPDIR/initramfs"
			mkdir -p $TMPDIR/initramfs
			CMPRMTH=$(compression_method $INITRAMFS)
			cp $INITRAMFS $TMPDIR/initramfs/initramfs.cpio$CMPRMTH
		else
			return 0
		fi

		echo "[-] Extracting Modules from $INITRAMFS"
		cd $TMPDIR/initramfs > /dev/null
			$BASEDIR/magiskboot decompress initramfs.cpio$CMPRMTH
			$BASEDIR/busybox cpio -F initramfs.cpio -i *lib* > /dev/null 2>&1
		cd - > /dev/null

		if [ ! -d "$TMPDIR/initramfs/lib/modules" ]; then
			echo "[!] $INITRAMFS has no lib/modules, aborting"
			rm -rf bzImage 2>/dev/null
			return 0
		fi

		OLDVERMAGIC=$(cat $(find $TMPDIR/ramdisk/. -name '*.ko' | head -n 1 2> /dev/null) | strings | grep vermagic= | sed 's/vermagic=//;s/ .*$//' 2> /dev/null)
		OLDANDROID=$(cat $(find $TMPDIR/ramdisk/. -name '*.ko' | head -n 1 2> /dev/null) | strings | grep 'Android (' | sed 's/ c.*$//' 2> /dev/null)
		echo "[*] Removing Stock Modules from ramdisk.img"
		rm -f $TMPDIR/ramdisk/lib/modules/*
		echo "[!] $OLDVERMAGIC"
		echo "[!] $OLDANDROID"

		echo "[-] Installing new Modules into ramdisk.img"
		cd $TMPDIR/initramfs > /dev/null
			find ./lib/modules -type f -name '*' -exec cp {} . \;
			find . -name '*.ko' -exec cp {} $TMPDIR/ramdisk/lib/modules/ \;
			NEWVERMAGIC=$(cat $(find . -name '*.ko' | head -n 1 2> /dev/null) | strings | grep vermagic= | sed 's/vermagic=//;s/ .*$//' 2> /dev/null)
			NEWANDROID=$(cat $(find . -name '*.ko' | head -n 1 2> /dev/null) | strings | grep 'Android (' | sed 's/ c.*$//' 2> /dev/null)
			cp modules.alias modules.dep modules.load modules.softdep $TMPDIR/ramdisk/lib/modules/
		cd - > /dev/null

		echo "[!] $NEWVERMAGIC"
		echo "[!] $NEWANDROID"

		echo "[*] Adjusting modules.load and modules.dep"
		cd $TMPDIR/ramdisk/lib/modules > /dev/null
			sed -i -E 's~[^[:blank:]]+/~/lib/modules/~g' modules.load
			sort -s -o modules.load modules.load
			sed -i -E 's~[^[:blank:]]+/~/lib/modules/~g' modules.dep
			sort -s -o modules.dep modules.dep
		cd - > /dev/null
	fi
}

InstallMagiskToAVD() {

	if [ -z $PREPBBMAGISK ]; then
		ProcessArguments $@
		PrepBusyBoxAndMagisk
		ExecBusyBoxAsh $@
	fi

	echo "[-] We are now in Magisk Busybox STANDALONE (D)ASH"
	# Don't use $BB from now on

	echo "[*] rootAVD with Magisk $MAGISK_VER Installer"

	get_flags
	api_level_arch_detect

	$ENVFIXTASK && construct_environment

	if $RANCHU; then
		detect_ramdisk_compression_method
		decompress_ramdisk
		test_ramdisk_patch_status
		patching_ramdisk
		repacking_ramdisk
	fi
}

FindSystemImages() {
	local HOME=~/
	local SYSIM_DIR_M=Library/Android/sdk/system-images
	local SYSIM_DIR_L=Android/Sdk/system-images
	local SYSIM_DIR=""
	local SYSIM_EX=""

	if [ -d "$HOME$SYSIM_DIR_M" ]; then
		SYSIM_DIR=$SYSIM_DIR_M
	elif [ -d "$HOME$SYSIM_DIR_L" ]; then
		SYSIM_DIR=$SYSIM_DIR_L
	else
		return 1
	fi



	cd $HOME > /dev/null
			for SI in $(find -s $SYSIM_DIR -type f -iname ramdisk.img); do
				if ( "$ListAllAVDs" ); then
					SYSIM_EX+=" ~/$SI"
				else
					SYSIM_EX="~/$SI"
				fi		
			done
	cd - > /dev/null
	
	echo "${bold}./rootAVD.sh${normal}"
	echo "${bold}./rootAVD.sh ListAllAVDs${normal}"
	echo "${bold}./rootAVD.sh EnvFixTask${normal}"
	echo "${bold}./rootAVD.sh InstallApps${normal}"	
	echo ""
	
	for SYSIM in $SYSIM_EX;do
		if [[ ! $SYSIM == "" ]]; then
			echo "${bold}./rootAVD.sh $SYSIM${normal}"
			echo "${bold}./rootAVD.sh $SYSIM DEBUG PATCHFSTAB GetUSBHPmodZ${normal}"
			echo "${bold}./rootAVD.sh $SYSIM restore${normal}"
			echo "${bold}./rootAVD.sh $SYSIM InstallKernelModules${normal}"
			echo "${bold}./rootAVD.sh $SYSIM InstallPrebuiltKernelModules${normal}"
			echo "${bold}./rootAVD.sh $SYSIM InstallPrebuiltKernelModules GetUSBHPmodZ PATCHFSTAB DEBUG${normal}"
			echo ""
		fi
	done
}

ShowHelpText() {
bold=$(tput bold)
normal=$(tput sgr0)
echo "${bold}rootAVD A Script to root AVD by NewBit XDA${normal}"
echo ""
echo "Usage:	${bold}rootAVD [DIR/ramdisk.img] [OPTIONS] | [EXTRA_CMDS]${normal}"
echo "or:	${bold}rootAVD [ARGUMENTS]${normal}"
echo ""
echo "Arguments:"
echo "	${bold}ListAllAVDs${normal}			Lists Command Examples for ALL installed AVDs"
echo ""
echo "	${bold}EnvFixTask${normal}			Requires Additional Setup fix"
echo "					- construct Magisk Environment manual"
echo "					- only works with an already Magisk patched ramdisk.img"
echo "					- without [DIR/ramdisk.img] [OPTIONS] [PATCHFSTAB]"
echo "					- needed since Android 12 (S) rev.1"
echo "					- Grant Shell Su Permissions will pop up a few times"
echo "					- the AVD will reboot automatically"
echo ""
echo "	${bold}InstallApps${normal}			Just install all APKs placed in the Apps folder"
echo ""
echo "Main operation mode:"
echo "	${bold}DIR${normal}				a path to an AVD system-image"
echo "					- must always be the ${bold}1st${normal} Argument after rootAVD"
echo "	"
echo "ADB Path | Ramdisk DIR:"
echo "	${bold}[M]ac/Darwin:${normal}			export PATH=~/Library/Android/sdk/platform-tools:\$PATH"
echo "					~/Library/Android/sdk/system-images/android-\$API/google_apis_playstore/x86_64/"
echo "	"
echo "	${bold}[L]inux:${normal}			export PATH=~/Android/Sdk/platform-tools:\$PATH"
echo "					~/Android/Sdk/system-images/android-\$API/google_apis_playstore/x86_64/"
echo "	"
echo "	${bold}[W]indows:${normal}			set PATH=%LOCALAPPDATA%\Android\Sdk\platform-tools;%PATH%"
echo "					%LOCALAPPDATA%\Android\Sdk\system-images\android-\$API\google_apis_playstore\x86_64\\"
echo "	"
echo "	${bold}\$API:${normal}				25,29,30,S,etc."
echo "	"
echo "Except for ${bold}EnvFixTask${normal}, ramdisk.img must be ${bold}untouched (stock).${normal}"
echo "	"
echo "Options:"
echo "	${bold}restore${normal}				restore all existing ${bold}.backup${normal} files, but doesn't delete them"
echo "					- the AVD doesn't need to be running"
echo "					- no other Argument after will be processed"
echo "	"
echo "	${bold}InstallKernelModules${normal}		install ${bold}custom build kernel and its modules${normal} into ramdisk.img"
echo "					- kernel (bzImage) and its modules (initramfs.img) are inside rootAVD"
echo "					- both files will be deleted after installation"
echo "	"
echo "	${bold}InstallPrebuiltKernelModules${normal}	download and install an ${bold}AOSP prebuilt kernel and its modules${normal} into ramdisk.img"
echo "					- similar to ${bold}InstallKernelModules${normal}, but the AVD needs to be online"
echo "	"
echo "Options are ${bold}exclusive${normal}, only one at the time will be processed."
echo "	"
echo "Extra Commands:"
echo "	${bold}DEBUG${normal}				${bold}Debugging Mode${normal}, prevents rootAVD to pull back any patched file"
echo "	"
echo "	${bold}PATCHFSTAB${normal}			${bold}fstab.ranchu${normal} will get patched to automount Block Devices like ${bold}/dev/block/sda1${normal}"
echo "					- other entries can be added in the script as well"
echo "					- a custom build Kernel might be necessary"
echo "	"
echo "	${bold}GetUSBHPmodZ${normal}			The ${bold}USB HOST Permissions Module Zip${normal} will be downloaded into ${bold}/sdcard/Download${normal}"
echo "	"
echo "Extra Commands can be ${bold}combined${normal}, there is no particular order."
echo "	"
echo "${bold}Notes: rootAVD will${normal}"
echo "- always create ${bold}.backup${normal} files of ${bold}ramdisk.img${normal} and ${bold}kernel-ranchu${normal}"
echo "- ${bold}replace${normal} both when done patching"
echo "- show a ${bold}Menu${normal}, to choose the Magisk Version ${bold}(Stable || Canary)${normal}, if the AVD is ${bold}online${normal}"
echo "- make the ${bold}choosen${normal} Magisk Version to its ${bold}local${normal}"
echo "- install all APKs placed in the Apps folder"
echo "	"
echo "${bold}Command Examples:${normal}"
FindSystemImages
exit
}

ProcessArguments() {
	DEBUG=false
	PATCHFSTAB=false
	GetUSBHPmodZ=false
	ENVFIXTASK=false
	RAMDISKIMG=false
	restore=false
	InstallKernelModules=false
	InstallPrebuiltKernelModules=false
	ListAllAVDs=false
	InstallApps=false

	# While debugging and developing you can turn this flag on
	if [[ "$@" == *"DEBUG"* ]]; then
		DEBUG=true
		# Shows whatever line get executed...
		#set -x
	fi

	# Call rootAVD with PATCHFSTAB if you want the RAMDISK merge your modded fstab.ranchu before Magisk Mirror gets mounted
	if [[ "$@" == *"PATCHFSTAB"* ]]; then
		PATCHFSTAB=true
	fi

	# Call rootAVD with GetUSBHPmodZ to download the usbhostpermissons module
	if [[ "$@" == *"GetUSBHPmodZ"* ]]; then
		GetUSBHPmodZ=true
	fi

	# Call rootAVD with ListAllAVDs to show all AVDs with command examples
	if [[ "$@" == *"ListAllAVDs"* ]]; then
		ListAllAVDs=true
	fi

	# Call rootAVD with InstallApps to just install all APKs placed in the Apps folder
	if [[ "$@" == *"InstallApps"* ]]; then
		InstallApps=true
	fi

	case $1 in
	  "EnvFixTask" )  # AVD requires additional setup
			ENVFIXTASK=true
		;;

	  * )
	  		RAMDISKIMG=true
		;;
	esac

	case $2 in
	  "restore" )
			restore=true
		;;

	  "InstallKernelModules" )
			InstallKernelModules=true
		;;

	  "InstallPrebuiltKernelModules" )
			InstallPrebuiltKernelModules=true
		;;
	esac

	export DEBUG
	export PATCHFSTAB
	export GetUSBHPmodZ
	export ENVFIXTASK
	export RAMDISKIMG
	export restore
	export InstallKernelModules
	export InstallPrebuiltKernelModules
	export ListAllAVDs
	export InstallApps
}

# Script Entry Point
# Checking in which shell we are
RANCHU=false
SHELL=$(getprop ro.boot.hardware 2>/dev/null)
if [[ $SHELL == "ranchu" ]]; then
	echo "[!] We are in an emulator shell"
	RANCHU=true
fi
export RANCHU

if $RANCHU; then
	InstallMagiskToAVD $@
	return 1
fi

ProcessArguments $@

if ( "$DEBUG" ); then
	echo "[!] We are in Debug Mode"
fi

if ( ! "$ENVFIXTASK" && ! "$InstallApps"); then
	# If there is no file to work with, abort the script
	if (checkfile "$1" -eq 0); then
		ShowHelpText
	fi
fi

echo "[!] and we are NOT in an emulator shell"
CopyMagiskToAVD $@

exit
