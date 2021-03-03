#!/usr/bin/env bash
##########################################################################################
#
# Magisk Boot Image Patcher - original created by topjohnwu and modded by shakalaca's
# modded by NewBit XDA for Android Studio AVD
# Successfully tested on Android API:
# [Dec. 2019] - 29 Google Apis Play Store x86_64 Production Build
# [Jan. 2021] - 30 Google Apis Play Store x86_64 Production Build
#
##########################################################################################

MAGISK_VER='22.0'
MAGISK_VER_CODE=22000

# While debugging and developing you can turn this flag on
DEBUG=false
#DEBUG=true
# Shows whatever line get executed...
if ("$DEBUG"); then
	set -x
	echo "Debug Mode"
fi

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
	RECOVERYMODE=false
	
	export RECOVERYMODE
	export KEEPVERITY
	export KEEPFORCEENCRYPT
	echo "[*] RECOVERYMODE=$RECOVERYMODE"
	echo "[-] KEEPVERITY=$KEEPVERITY"
	echo "[*] KEEPFORCEENCRYPT=$KEEPFORCEENCRYPT"
}

api_level_arch_detect() {
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
}

detect_ramdisk_compression_method()
{
	local FIRSTFILEBYTES
	local METHOD_LZ4="02214c18"
	local METHOD_GZ="1f8b0800"
	FIRSTFILEBYTES=$($BB xxd -p -c8 -l8 "$RDF")
	
	RAMDISK_LZ4=false
	RAMDISK_GZ=false
	ENDG=""
	METHOD=""

	if [ "${FIRSTFILEBYTES:0:8}" = "$METHOD_LZ4" ]; then
		ENDG=".lz4"
		METHOD="lz4_legacy"
		RAMDISK_LZ4=true
		return		
	fi
	
	if [ "${FIRSTFILEBYTES:0:8}" = "$METHOD_GZ" ]; then
		ENDG=".gz"
		METHOD="gzip"
		RAMDISK_GZ=true
		return		
	fi
}

construct_environment() {	
	echo "[-] Constructing environment"	
	ROOT=`su -c "id -u"` 2>/dev/null
	if [[ $ROOT == "" ]]; then
		echo "[-] not root yet"
		return
	fi
	
	if [[ $ROOT -eq 0 ]]; then
		echo "[!] we are root"		
		local BBBIN=$BB
		local COMMONDIR=$BASEDIR/assets	
		local NVBASE=/data/adb
		local MAGISKBIN=$NVBASE/magisk
		#`su -c "rm -rf $MAGISKBIN/* 2>/dev/null"`
		#`su -c "mkdir -p $MAGISKBIN 2>/dev/null"`
		#`su -c "cp -af $BINDIR/. $COMMONDIR/. $BBBIN $MAGISKBIN"`
		#`su -c "chown root.root -R $MAGISKBIN"`
		#`su -c "chmod -R 755 $MAGISKBIN"`
		#`su -c "reboot"`
		`su -c "rm -rf $MAGISKBIN/* 2>/dev/null && \
				mkdir -p $MAGISKBIN 2>/dev/null && \
				cp -af $BINDIR/. $COMMONDIR/. $BBBIN $MAGISKBIN && \
				chown root.root -R $MAGISKBIN && \
				chmod -R 755 $MAGISKBIN && \
				reboot \
				"`
	fi
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
		adb install -r "$f"
	done
}

CopyMagiskToAVD() {
	# If there is no file to work with, abort the script
	if (checkfile "$1" -eq 0); then
	  echo "rootAVD needs a path with file to an AVD ramdisk"
	  echo "rootAVD will backup your ramdisk.img and replace it when finished"
	  echo "./rootAVD.sh ~/Android/Sdk/system-images/android-30/google_apis_playstore/x86_64/ramdisk.img"
	  exit 0
	fi

	echo "[-] Test if ADB SHELL is working"
	ADBWORKS=$(adb shell 'echo true' 2>/dev/null) 
	if (! "$ADBWORKS"); then
		echo "no ADB connectoin possible"
		exit 0
	fi

	# Set Folders and FileNames
	echo "[*] Set Directorys"
	PATHWITHFILE="$1"
	PATHTOFILE=${PATHWITHFILE%/*}
	FILE=${PATHWITHFILE##*/}
	fileIsKernel=false
	fileIsRamdisk=false
	BACKUPFILE=$FILE".backup"
	# The Folder where the script was called from
	ROOTAVD="`getdir "${BASH_SOURCE:-$0}"`"
	MAGISKZIP=$ROOTAVD/Magisk.zip

	echo "[-] In any AVD via ADB, you can execute code without root in /data/data/com.android.shell"
	ADBWORKDIR=/data/data/com.android.shell
	ADBBASEDIR=$ADBWORKDIR/Magisk
	
	# change to ROOTAVD directory
	cd $ROOTAVD

	# Is it a ramdisk named file?
	if [ $FILE != "ramdisk.img" ]; then
		echo "[!] please give a path to a ramdisk file"    
		exit 0
	fi

	# If no backup file exist, create one
	if (checkfile $PATHTOFILE/$BACKUPFILE -eq 0); then
		echo "[*] create Backup File"
		cp $PATHWITHFILE $PATHTOFILE/$BACKUPFILE
	else
		echo "[-] Backup exists already"
	fi

	# Download the Magisk apk/zip file -> Magisk-v22.0
	MAGISKZIPDL=https://github.com/topjohnwu/Magisk/releases/download/v22.0/Magisk-v22.0.apk
	# If Magisk.zip file already exist, don't download it again
	if (checkfile $MAGISKZIP -eq 0); then	
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
	
	echo "[-] Copy the original AVD ramdisk.img into Magisk DIR"
	ADBPUSHECHO=$(adb push $PATHWITHFILE $ADBBASEDIR 2>/dev/null) 
	echo "[*] $ADBPUSHECHO"
	
	echo "[-] Copy rootAVD Script into Magisk DIR"
	ADBPUSHECHO=$(adb push rootAVD.sh $ADBBASEDIR 2>/dev/null) 
	echo "[*] $ADBPUSHECHO"

	echo "[-] Convert Script to Unix Ending"
	adb -e shell "dos2unix $ADBBASEDIR/rootAVD.sh"
	
	echo "[-] run the actually Boot/Ramdisk/Kernel Image Patch Script"
	echo "[*] from Magisk by topjohnwu and modded by NewBit XDA"
	
	adb shell sh $ADBBASEDIR/rootAVD.sh "ranchu"

	# In Debug-Mode we can skip parts of the script
	if (! "$DEBUG"); then

		echo "[-] After the ramdisk.img file is patched and compressed,"
		echo "[*] pull it back in the Magisk DIR"
		ADBPUSHECHO=$(adb pull $ADBBASEDIR/ramdiskpatched4AVD.img 2>/dev/null) 
		echo "[*] $ADBPUSHECHO"
		
		echo "[-] pull Magisk.apk to Apps/"
		ADBPUSHECHO=$(adb pull $ADBBASEDIR/Magisk.apk Apps/ 2>/dev/null) 
		echo "[*] $ADBPUSHECHO"
			
		echo "[-] Clean up the ADB working space"
		adb shell rm -rf $ADBBASEDIR
		
		echo "[*] Move and rename the patched ramdisk.img to the original AVD DIR"
		mv ramdiskpatched4AVD.img $PATHWITHFILE
		
		installapps

		echo "[-] reboot the AVD and see if it worked"
		echo "[-] Root and Su with Magisk for Android Studio AVDs"
		echo "[-] Modded by NewBit XDA - Jan. 2021"
		echo "[!] Huge Credits and big Thanks to topjohnwu and shakalaca"
	fi
}

InstallMagiskToAVD() {

	if echo $MAGISK_VER | grep -q '\.'; then
  		PRETTY_VER=$MAGISK_VER
	else
  		PRETTY_VER="$MAGISK_VER($MAGISK_VER_CODE)"
	fi
	echo "[*] rootAVD with Magisk $PRETTY_VER Installer"
	echo "[-] Switch to the location of the script file"
	BASEDIR="`getdir "${BASH_SOURCE:-$0}"`"
	TMPDIR=$BASEDIR/tmp
	BB=$BASEDIR/busybox
	RDF=$BASEDIR/ramdisk.img

	cd $BASEDIR

	echo "[-] Get Flags"
	get_flags
	
	echo "[*] Extracting busybox and Magisk.zip ..."
	unzip Magisk.zip -oq
	chmod -R 755 lib
	mv -f lib/x86/libbusybox.so $BB
	$BB >/dev/null 2>&1 || mv -f lib/armeabi-v7a/libbusybox.so $BB
	chmod -R 755 $BASEDIR

	# Detect version and architecture
	# To select the right files for the patching
	echo "[-] Api Level Arch Detect"
	api_level_arch_detect

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
	
	echo "[*] Detecting ramdisk.img compression"
	detect_ramdisk_compression_method
	
	echo "[!] Ramdisk.img uses $METHOD compression"
	
	mv $RDF $RDF"$ENDG"
	
	echo "[-] taken from shakalaca's MagiskOnEmulator/process.sh"
	echo "[*] executing ramdisk splitting / extraction / repacking"
	# extract and check ramdisk
	
	if [[ $API -ge 30 ]]; then
		$RAMDISK_GZ && $BB gzip -fdk ${RDF}$ENDG
		$RAMDISK_LZ4 && RDF=$RDF"$ENDG"
		echo "[-] API level greater then 30"
		echo "[*] Check if we need to repack ramdisk before patching .."
		COUNT=`$BB strings -t d $RDF | $BB grep TRAILER\!\!\! | $BB wc -l`
	  if [[ $COUNT -gt 1 ]]; then
		echo "[-] Multiple cpio archives detected"
		REPACKRAMDISK=1
	  fi
	fi

	if [[ -n $REPACKRAMDISK ]]; then
		$RAMDISK_GZ && rm ${RDF}$ENDG
	  	echo "[*] Unpacking ramdisk .."
	  	mkdir -p $TMPDIR/ramdisk
	  	LASTINDEX=0
	  	IBS=1
	  	OBS=4096
	  	OF=$TMPDIR/temp$ENDG

	  	RAMDISKS=`$BB strings -t d $RDF | $BB grep TRAILER\!\!\!`

	  	for OFFSET in $RAMDISKS
	  	do
			# calculate offset to next archive
			if [[ $OFFSET == *"TRAILER"* ]]; then
				# find position of end of TRAILER!!! string in image
				if $RAMDISK_GZ; then
					LEN=${#OFFSET}
					START=$((LASTINDEX+LEN))			
					# find first occurance of string in image, that will be start of cpio archive
					dd if=$RDF skip=$START count=$OBS ibs=$IBS obs=$OBS of=$OF > /dev/null 2>&1
					HEAD=(`$BB strings -t d $OF | $BB head -1`)
					# vola
					LASTINDEX=$((START+HEAD[0]))		  	
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
		$BB find . | $BB cpio -H newc -o > $RDF
		cd - > /dev/null
		#rm $OF*
	else
		echo "[*] After decompressing ramdisk.img, magiskboot will work"
		./magiskboot decompress $RDF$ENDG
	fi
		
	mv $RDF "ramdisk.cpio"

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
			echo "[!] aborting the script"
			exit 0
		;;
	  2 )  # Unsupported
		echo "[!] Boot image patched by unsupported programs"
		echo "[!] Please restore back to stock boot image"
		;;
	esac

	if [ $((STATUS & 8)) -ne 0 ]; then
	  echo "[!] TWOSTAGE INIT image detected - Possibly using 2SI, export env var"
	  export TWOSTAGEINIT=true
	fi

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
		echo "/devices/*/block/sd* auto auto defaults voldmanaged=usb:auto" >> fstab.ranchu
		# cat fstab.ranchu
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
	
	if [ $((STATUS & 4)) -ne 0 ]; then
		echo "[!] Compressing ramdisk before zipping it"
	  ./magiskboot cpio ramdisk.cpio compress
	fi

	echo "[*] zipping ramdisk"
	# Rename and compress ramdisk.cpio back to ramdiskpatched4AVD.img
	./magiskboot compress=$METHOD "ramdisk.cpio" "ramdiskpatched4AVD.img"
	
	echo "[!] Rename Magisk.zip back to Magisk.apk"
	mv Magisk.zip Magisk.apk
	return 0
}

# Script Entry Point
# Checking in which shell we are
SHELL=$(getprop ro.kernel.androidboot.hardware 2>/dev/null)
if [[ $SHELL == "ranchu" ]]; then
	if [[ $SHELL == $1 ]]; then
		echo "[!] We are in an emulator shell"
		InstallMagiskToAVD
	fi		
else
	echo "[!] We are in a bash shell"
	CopyMagiskToAVD $1
fi
exit 0
